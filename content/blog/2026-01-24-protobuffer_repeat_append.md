+++
title="Progressive encoding and decoding of 'repeated' protobuffer fields."
description="""
I have found Google's [_Perfetto_](perfetto.dev) trace viewer to be a really
useful tool to visualize arbitrary time-based traces by converting them
into the protobuffer-based format that Perfetto uses.
This is how both [Tonbandgerät](@/projects/Tonbandgeraet/index.md) and
[CircumSpect](https://github.com/schilkp/circumspect) work.

Especially with CircumSpect, the traces I am generating quickly reach into the
millions of `TracePacket` messages, and upwards of a gigabyte in size. This
makes bundling them all into a single `Trace` message that gets encoded or 
decoded in a single pass infeasible, which lead me to dig into the encoding
scheme to manually implement a streaming encoder and decoder.
"""
template="blog_post.html"

[taxonomies]
tags=[]

[extra]
katex=true
+++

> [!NOTE]
> This post assumes a basic familiarity with the user-facing aspects of
> google's open-source [protobuffer](https://protobuf.dev/) suite.
>
> In short, protobuffer allows you to define a set of messages which you
> would like to exchange using a simple DSL in a `.proto` file.
> Using this description, the `protoc` compiler (or a number of alternative
> implementations) can generate encoders and decoders for these messages
> in a large number of different programming languages (see
> [here](https://protobuf.dev/getting-started/) and
> [here](https://github.com/protocolbuffers/protobuf/blob/main/docs/third_party.md)),
> all of which share a common binary message ("wire") format.
>
> If you are curious, have a look at [protobuf.dev](protobuf.dev) for
> documentation and tutorials.

## Motivation: Interfacing with Perfetto

I have found Google's [_Perfetto_](perfetto.dev) trace viewer to be a really
useful tool to visualize arbitrary time-based traces by converting them
into the protobuffer-based format that Perfetto uses.
This is how both [Tonbandgerät](@/projects/Tonbandgeraet/index.md) and
[CircumSpect](https://github.com/schilkp/circumspect) work.

In particular, Perfetto traces are a very long sequence of individual `TracePacket`
messages, which describe the tracks and the events on them.
Below follows a greatly simplified version of this `TracePacket`
message. The full definition can be found in the Perfetto source code
[here](https://github.com/google/perfetto/tree/main/protos/perfetto).
```proto
message TracePacket {
  optional uint64 timestamp = 8;
  oneof data {
    // Different types of trace packet contents
    // ...
    TrackEvent track_event = 11;
    // ...
    TrackDescriptor track_descriptor = 60;
    // ...
  }
}
```

## The Challenge: Sequential encoding and decoding

Especially with CircumSpect, the traces I am generating quickly reach into the
millions of `TracePacket` messages, and upwards of a gigabyte in size.
This becomes problematic because of the fact that to bundle all these messages
into a single file, Perfetto uses a parent `Trace` message, which contains all
`TracePacket`s as a repeated field - the protobuffer equivalent of an array:

```proto
message Trace {
  repeated TracePacket packet = 1;
}
```

Because, unlike in zero-copy frameworks such as [Cap'n Proto](https://capnproto.org/),
protobuffer's serialised format does not double as an in-memory representation,
all serialisation and deserialisation operations move and convert data in between
a binary buffer containing the wire representation, and an in-memory data structure
with which the program interacts.

In short, this means that to serialise a large `Trace`, the full trace needs
to be in an in-memory representation.
This struct can then be serialised to the binary wire format by the protobuffer
library.
For reference, this looks roughly like the following:

```rust
// Pseudo-rust :)
pub struct Trace {
    packet: Vec<TracePacket>,
}

pub collect_trace(..) {
    let mut trace = Trace::new();

    while not_finished() {
        let pkt: TracePacket = collect_trace_packet();
        Trace.packet.push(pkt);
    }

    trace.serialise_to_file("trace.pftrace");
}
```

For a large stream of `TracePacket`s reaching into the gigabytes, this requires
an incredible amount of memory or is outright impossible.
Rather, it would be much better if `TracePacket`s could be written to disk
continously as they are generated.

Because CircumSpect can post-process traces after they are recorded, I also run
into this problem in the opposite direction:
Instead of having to load a whole trace into memory by deserialising a complete
file into a `Trace` struct, I would much prefer to be able to read individual
packets, process them, and write them back out to disk.

This is not directly supported by most protobuffer libarries.

## Protobuffer wire format

To understand how difficult this would be to achieve, we have to have a look at
how a message containing a single repeated message is serialised.
Fortunately, the protobuf wire format for a simple message like `Trace` is
not all too complicated!

What follows below is an overview of the aspects of protobuffer encoding that
are relevant for achieving this "streaming" encoding and decoding of a `Trace`
message.
If you want more detailed information, have a look at the
[official documentation](https://protobuf.dev/programming-guides/encoding/).

### VARINTs

At the heart of protobuffer encoding sit variable-length ("varlen") encoded
64 bit integers, referred to as _varints_.

This is an optimization that builds on the observation that in my applications,
while it is benefitial to support full 64 bit numbers, most of the time only
small numbers are used.
For example, in protobuffer messages, tags all the way up to
{{ katex(body="2^{29} - 1") }} are supported, while the majority of messages
have fewer than 100 fields.
If protobuffer were to use a fixed 32-bit field for encoding all tags, most
messages would contain a large number of redundant zeros.

Instead, varints enable us to encode unsigned numbers using
{{ katex(body="\max{\left\lparen \left\lceil \frac{\log_2(N)}{7} \right\rceil, 1 \right\rparen}") }}
bytes.
For example, any value less than or equal to 127 can be encoded in a single byte.
In other words, this system trades a much improved average message length for a
longer worst-case message size.

This is achieved by first splitting the value into 7-bit septets, which are each
encoded, starting with the least significant septet, as an 8-bit value, consisting
of the septet in the lower bits, and and a control bit in the most significant
bit position.
This control bit is set to `1` if there are more non-zero bits to follow,
or `0` if this is the last septet with non-zero bits and all following bits
should be assumed to be zero.

For example, consider the 32-bit value `0x5`. With the scheme above, it is
encoded as a single byte:

```
    +---> First 7 bits
 ___|___
00000101
|
+--> No more bits to follow.
```

The value `0xFF` requires more than seven bits and therefor is split into two bytes:

```
    +---> First 7 bits          +---> Next 7 bits
 ___|___                     ___|___
11111111                    00000001
|                           |
+--> More bits to follow.   +--> No more bits to follow.
```

### Basic message structure
A protobuffer message is serialised as a simple sequence of key-value pairs, with the
key being used to identify both which field in the message is to follow, and which
encoding scheme it uses.

A field is identified using the "field number" which is specified in the message
description for every field, while the following encoding schemes are supported:

| ID | Name     | Used for                                                                 |
| -  | -        | -                                                                        |
| 0  | `VARINT` | `int32`, `int64`, `uint32`, `uint64`, `sint32`, `sint64`, `bool`, `enum` |
| 1  | `I64`    | `fixed64`, `sfixed64`, `double`                                          |
| 2  | `LEN`    | `string`, `bytes`, embedded messages, packed repeated fields             |
| 5  | `I32`    | `fixed32`, `sfixed32`, `float`                                           |

<small>Table taken from the official protobuffer docs:
[protobuf.dev/programming-guides/encoding](https://protobuf.dev/programming-guides/encoding/#cheat-sheet)</small>

These two values are combined into a single 32-bit value, with the lower 3 bits
containing the encoding scheme, and all other bits containing the field number:
```c
(field_number << 3) | encoding_id
```

This 32-bit key is then encoded using the varlen scheme discussed above,
and immediatly followed by the encoded field value.

For example, consider a message with the following structure:

```proto
message Msg {
  uint64 data = 1;
}
```

Consider an instance of `Msg` with a value of `42` for the `data` field:

```json
{ "data": 42 }
```

Serialised, it looks as follows:

```text
0x08 0x2a
```

The data field has a field number of `1` and its `uint64` data type, as is
listed in the table above, is encoded using varint encoding which has an
encoding id of `0`. Therefor, the key value is `key = (1 << 3) | 0 = 0x08`,
which is varlen-encoded as `0x08`, since it is less than `128.`
The value of `42` (`0x2a` in hex) is also directly encoded as `0x2a` in using
the varlen scheme, as it too is less than `128`.

### Nested messages

Now consider a new message type `Parent`, which contains a single `Msg` field,
with a field number of `1`:

```proto
message Msg {
  uint64 data = 1;
}

message Parent {
  Msg child = 1;
}
```

In protobufs, such "embedded" messages are encoded using the `LEN` scheme
listed in the table above, which has an id of `2`.
Quite simply, the length of the encoded child message in bytes is first
serialised as a varlen-encoded value, followed by the normal encoding of
the child message.

For example, consider an instance of `Parent`, which contains a `Msg` instance
with `data = 42` as above in its `child` field:

```json
{ "child": { "data": 42 } }
```

From above, we know that such a `Msg` is encoded as `0x08 0x2a`, which is
of length 2, which gives us the following encoding for `Parent`:

```text
KEY   LEN   CHILD.....
0x0A  0x02  0x08  0x2a
```

The field `child` has a field number of 1 and a `LEN` encoding scheme, which is
of ID `2`, giving us a key value of `key = (1 << 3) | 2 = 0x0A`. As both the
key value and length are again less than `128`, their varlen representation is
equal to their one-byte value.

### Repeated Fields

Finally, let's have a look at how repeated fields - the protobuffer
equivalent of arrays - are encoded.

> [!CAUTION]
> Note that there are two encoding schemes for repeated fields, which are used
> based on the type of the field that is being repeated.
> I will not discuss the "packed" scheme, which is used for simple scalar
> values and also uses a `LEN`-style encoding here.
> In older versions of protobuffer, this "packed" scheme was opt-in, but
> in more modern versions it is the default for simple repeated scalars!

Consider the following set of definitions, where the `MultiParent` message
can contain multiple `Msg` children:

```proto
message Msg {
  uint64 data = 1;
}

message MultiParent {
  repeated Msg children = 1;
}
```

Let's have a look at how the following, a `MultiParent` containing two
`data = 42` children, would be encoded:

```json
{
  "children": [
    { "data": 42 },
    { "data": 42 }
  ]
}
```

Quite simply, for repeated embedded messages, protobuffer simply repeats another
key-value pair with the same field number. We already know that a single embedded
`Msg` with `data = 42` is encoded as `0x0A 0x02 0x08 0x2A`, so the `MultiParent`
above is encoded as:

```text
KEY   LEN   CHILD.....   KEY   LEN   CHILD.....
0x0A  0x02  0x08  0x2a   0x0A  0x02  0x08  0x2a
|- 1st Child --------|   |- 2nd Child --------|
```

> [!TIP]
> This is as deep as we will go into protobuffer encoding in this post.
> If you want to go deeper, have a look at the
> [`protoscope`](https://github.com/protocolbuffers/protoscope/tree/main)
> tool and textual representation, which is a very useful higher-level
> representation of raw, binary, key-value protobuffer messages.

## Putting it together

Armed with this basic understanding of the protobuffer wire format, and a
`protoc`-generated (or equivalent) encoder and decoder of the inner
`TracePacket` message, we can now decode and encode a large `Trace` one
`TracePacket` at a time by doing a bit of manual leg work.

Notably, the `Trace` message with which we started this post is incredibly
similar to the `MultiParent` example above: A message with a single,
repeated, embedded message field with field number `1`:

```proto
message Trace {
  repeated TracePacket packet = 1;
}
```

This means that a Perfetto trace is simply a sequence of the following
for each `TracePacket`:

- The byte `0x0A`, which is the varlen-encoded form of the key for a field at number 1 with the `LEN` encoding: `(1 << 3) | 2 = 0x0A`.
- The length of the serialized `TracePacket` in bytes, in varlen-encoded form.
- The serialized `TracePacket`.

### Progressive Serialisation/Appending

This makes progressive serialisation of a `Trace` quite easy to do, because we
can use the `protoc` generated encoding routing for an individual `TracePacket`,
and attach them together into a correctly formatted trace by prepending each
trace packet with a `0x0A` and the length of the `TracePacket` in bytes, as
a varlen-encoded value.

For example, in rust using the [`prost`](https://github.com/tokio-rs/prost)
protobuffer library, this would look roughly as follows:

```rust
/// Encode a u64 as a protobuffer-style varint, appended into the provided buffer.
pub fn encode_varint(mut v: u64, buf: &mut Vec<u8>) {
    loop {
        let septet: u8 = (v & 0x7F) as u8;
        v >>= 7;
        let ctrl_bit = if v == 0 { 0_u8 } else { 0x80_u8 };
        buf.push(septet | ctrl_bit);
        if v == 0 {
            return;
        }
    }
}

/// Append a TracePacket to the provided buffer, which contains an already encoded Trace message,
/// or is empty.
pub fn append_trace_package(pckg: &TracePacket, buf: &mut Vec<u8>) -> anyhow::Result<()> {
    // Key:
    encode_varint(0x0A, buf);
    // Length:
    encode_varint(pckg.encoded_len() as u64, buf);
    // Embedded Message:
    pckg.encode(buf)?;
    Ok(())
}
```

> [!TIP]
> The `prost` library provides builtin functions for the varlen-encoding of the 
> message length, which was implemented manually above for illustrative purposes.
>
> See 
> [`Message::encode_length_delimited()`](https://docs.rs/prost/latest/prost/trait.Message.html#method.encode_length_delimited),
> and 
> [`ecnode_length_delimiter()`](https://docs.rs/prost/latest/prost/fn.encode_length_delimiter.html).
> For decoding, have a look at 
> [`Message::decode_length_delimited()`](https://docs.rs/prost/latest/prost/trait.Message.html#method.decode_length_delimited),
> and 
> [`decode_length_delimiter()`](https://docs.rs/prost/latest/prost/fn.decode_length_delimiter.html).


### Progressive Deserialisation
Similarly, for decoding, we skip the `0x0A` byte, decode the varlen-encoded length
field, and then pass that number of bytes to the protobuffer-generated `TracePacket`
decoder. In rust this would look roughly as follows:

```rust
/// Attempt to "consume" the first byte from the buffer and advance the pointer.
pub fn consume_byte(buf: &mut &[u8]) -> Option<u8> {
    if buf.is_empty() {
        return None;
    }
    let (byte, rest) = buf.split_at(1);
    *buf = rest;
    Some(byte[0])
}

/// Decode a protobuffer-style varint from the provided buffer into a u64.
pub fn decode_varint(buf: &mut &[u8]) -> anyhow::Result<u64> {
    let mut v: u64 = 0;
    let mut offs: usize = 0;
    loop {
        let Some(byte) = consume_byte(buf) else {
            return Err(anyhow::anyhow!("Unterminated varint"));
        };
        let septet: u8 = byte & 0x7F;
        let ctrl_bit: u8 = byte & 0x80;

        v |= (septet as u64) << offs;
        offs += 7;

        if ctrl_bit == 0 {
            break;
        }

        if offs >= 70 {
            return Err(anyhow::anyhow!("Unterminated varint"));
        }
    }
    Ok(v)
}

/// Decode a TracePacket from the beginning provided buffer containing an encoded Trace message,
/// returning the package and the offset of the next TracePacket in the buffer.
pub fn decode_next_trace_package(buf: &mut &[u8]) -> anyhow::Result<(TracePacket, usize)> {
    let len_orig = buf.len();

    // Decode & validate key
    let key = decode_varint(buf)?;
    if key != 0x0A {
        return Err(anyhow::anyhow!("Incorrect Key Byte"));
    }

    // Decode & validate length
    let len = decode_varint(buf)?;
    if len == 0 {
        return Err(anyhow::anyhow!("Incorrect Len (zero)"));
    }
    if len > (buf.len() as u64) {
        return Err(anyhow::anyhow!("Incorrect Len (more than remaining bytes)"));
    }

    // Decode next "len" bytes using TracePacket::decode()
    let (mut buf_packet, buf_rest) = buf.split_at(len as usize);
    *buf = buf_rest;
    let pckg = TracePacket::decode(&mut buf_packet)?;
    if !buf_packet.is_empty() {
        return Err(anyhow::anyhow!("Incorrect Len (bytes left after decode)"));
    }

    Ok((pckg, len_orig - buf.len()))
}
```

### Complete Example

For a complete working example including a few tests, have a look at 
[this](https://github.com/schilkp/protobuffer_repeat_streaming_example) 
repository.
