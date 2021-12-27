---
layout: default
title: psASM
---

# psASM: The Assembler

psASM is the assembler written specifically for the psMCU, which takes human-readable assembly programs and
converts them to binaries for both physical hardware and simulation.

It is written in python, and based on an ANTLR4 lexer/parser frontend. The full lexer and parser grammars
can be found [here]( TODOOOOO ) and [here]( TODOOOO ).

psASM's hallmark feature is it's C-style preprocessor, which includes many constructs that make writing
assembly a little more bearable - see the examples below.

## Examples

Below are some example snippets of assembly with commentary that demonstrate most of psASM's capabilities:

### The Basics

The basic assembler features are pretty similar to most other assemblers.

The most bare program is a listing of instructions with their operands: 

{% include psASM_snippets/psASM_basics00.html %}

A program can be split into multiple files, and the contents of another file can be included
(inlined) as such:

{% include psASM_snippets/psASM_basics01a.html %}
{% include psASM_snippets/psASM_basics01b.html %}
{% include psASM_snippets/psASM_basics01c.html %}

### Definitions & Conditionals 

Constants can be defined as follows:

{% include psASM_snippets/psASM_def_cond00.html %}

Any instruction can be given a label. This label will then automatically correspond to
the address this instruction was placed at in memory:

{% include psASM_snippets/psASM_def_cond01.html %}

The assembler also supports the (almost) same set of operators as seen in C:

{% include psASM_snippets/psASM_def_cond02.html %}

Sections of assembly can also be included or excluded depending on various conditions:

{% include psASM_snippets/psASM_def_cond03.html %}

But, because I have standards, the include guard above can be replaced with a purpose-made
directive. The following two files would function identically:

{% include psASM_snippets/psASM_def_cond04a.html %}
{% include psASM_snippets/psASM_def_cond04b.html %}

### Scope of labels and defines

The scope of a preprocessor object depends on the first character of it's name:

{% include psASM_snippets/psASM_scope00.html %}

A global object can be accessed from anywhere and must be unique.

A file object exists only within the current file.

A local object exists only within the current block, which is delimited by global labels:

{% include psASM_snippets/psASM_scope01.html %}

This is very useful, because it allows basic labels like 'end', 'loop', and 'stop' to
be re-used in different functions.

### Macros, Loops

Macros can be used to create and repeat basic assembly building blocks:

{% include psASM_snippets/psASM_macro_loop_string00a.html %}
{% include psASM_snippets/psASM_macro_loop_string00b.html %}

For-loops can be used to generate larger amounts of assembly:

{% include psASM_snippets/psASM_macro_loop_string01a.html %}
{% include psASM_snippets/psASM_macro_loop_string01b.html %}

### Strings

Lastly, psASM supports string literals.

The following macro saves a string to RAM:
{% include psASM_snippets/psASM_macro_loop_string02a.html %}
{% include psASM_snippets/psASM_macro_loop_string02b.html %}
