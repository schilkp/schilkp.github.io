+++
title="psMCU"
description="An 8-bit, 1MHz processor built from individual logic and memory ICs, featuring a custom ISA, peripheral interface, USB programmer and macro assembler."
template="project_page.html"
weight=103

[extra]
thumbnail_img="psmcu_header.jpeg"
+++

{{ centered_img(src="psmcu_header.jpeg") }}

{{ toc() }}

## Overview

This was my first significant hardware project, that started all the way back in high school. It's an 
8-bit, 1MHz processor built from individual logic and memory ICs, featuring a custom ISA, peripheral interface, 
USB programmer and macro assembler.

It is in a semi-working state: I programmed a simple game of Snake in my custom assembler that is able to run
using my custom LED matrix and keypad peripherals, but there are some hardware bugs and faults. Unfortunately,
once university started, I no longer had the time to revise and finish it completely. Maybe someday.

Besides being ridiculous, it is suboptimal and strange in so many ways, because I designed it before 
learning much about computer architecture and digital design 😎.

## Hardware

### psMCU

Initially I simulated my design using the graphical logic simulator [LOGISIM](http://www.cburch.com/logisim/).

It features two 8-bit registers (`A` and `B`), an ALU with support for addition, subtraction, logic operations, and
shifts, 16kB of program flash storage, 8kB of general purpose "heap" RAM, 32kB of "stack" RAM with a dedicated top-of-stack
register, hardware call and return, and interrupts. It consumes a custom 16-bit assembly format.

To manage complexity, both the instruction decoding and main state machine transition logic is implemented with flash chips that operate
as lookup tables.

### Control

{{ gallery() }}
    {{ gallery_img(src="ctrl.jpeg", desc="The psMCU control panel.") }}
    {{ gallery_img(src="prog.jpeg", desc="The USB Programmer.") }}
{{ gallery_end() }}
psMCU features a hardware breakpoint, and can single step both clock cycles and instructions using the 
control panel shown above. The clock frequency can also be controlled here.
A USB programmer board is used to load a program into the onboard flash. It is based on an STM32 with an
FTDI chip for USB communication.

### Peripherals

{{ gallery() }}
    {{ gallery_img(src="matrix.jpeg", desc="The LED Matrix Peripheral.") }}
    {{ gallery_img(src="numpad.jpeg", desc="The Numpad Peripheral.") }}
{{ gallery_end() }}
I built a number of peripherals for the processor, including the 8x8 LED matrix and numpad shown above. They can be 
chained together and connected to the memory bus connector on the main board.

## psASM

### Overview

Because it features a custom ISA, I developed a fairly full-featured macro assembler in python called *psASM*.
It features a Turing-complete C-style preprocessor with global and local label resolution, 
file inclusion/multi-file programs, macros to reduce code duplication, conditional compilation, and calculations.

Here is a short excerpt of the snake game I developed for the processor, written for psASM:
```psASM
@define RNDR_ptr 0x45
@define RNDR_bit 0x46
@define RNDR_val 0x47

RENDER: 
    # Start with the LSB
    LITA 0x01 
    SVA RNDR_bit

    # Start at the beginning of the board
    LITB BOARD_STARTD
    SVB RNDR_ptr

    # Empty first value
    LITA 0x0
    SVA RNDR_val

    # State: A = 0, B = ptr
    RENDER_LOOP: 
        LDDR         # Load board into A (A = Board, B = Ptr)
        SVB RNDR_ptr # Save the current Pointer
        LDB RNDR_bit # Load the current bit (A= Board, B = Bit)

        # If A is 0, skip ahead 
        IFSM SYS3, S3_A0
            JMP RENDER_ADVANCE_BIT

        # Otherwise, OR the current Bit into the current val:
        LDA RNDR_val
        OR
        SVA RNDR_val

        # Advance the current Bit
        RENDER_ADVANCE_BIT: SWP # A = ? B = Bit
        SHFTLL 1
        SVA RNDR_bit

        # If we did not shift out we can go on to the next pointer
        IFRM SYS3, S3_A0
            JMP RENDER_ADVANCE_PTR

        # Otherwise we need to push the current value to the stack
        # and setup for the next 8 bits:
        LDA RNDR_val
        PUSHA
        LITA 0
        SVA RNDR_val
        LITA 1
        SVA RNDR_bit

        # Advance pointer and check against end condition:
        RENDER_ADVANCE_PTR: LDB RNDR_ptr
        ADDLB 1
        LITA BOARD_END

        IFSM SYS3, S3_AB
            JMP RENDER_LOOP_DONE

        JMP RENDER_LOOP

    RENDER_LOOP_DONE: 
    # -- snip --
```

Here are some short snippets that show some of the cooler macro assembler features of psASM:
```psASM
@ifndef _HAS_BEEN_INCLUDED # Include guard, just like C
@define _HAS_BEEN_INCLUDED

@if defined(DEBUG) || defined(TESTING) 
    LITA 1        
@else 
    LITA 0
@end

# -- VARIABLES --
@define my_val 1     # Set 'my_val' to the value 1
LITA my_val          # Load 1 into register A

@define global_var 1   # A global variable/label start with a letter
global_label: JMP global_label

@define .local_var 1   # A local variable/label start with a '.'
.local_label: JMP local_label

@define _file_var  1   # A file variable/label start with a '_'
_file_label: JMP _file_label

# -- OPERATORS --
@define val 40

# Basic math operations to determine operand:
LITA ((val-10) * 2) + 5 

# Bitwise operations to determine operand:
LITA ((val & 0x0f) | ( 0xa << 2)         

# Conditional operator:
loop: JMP defined(label) ? label : loop  

# -- FILE INCLUSION --
@include "test.psASM" # Inline the file 'test.psASM'

# -- LOOPS --
@for $i, 0, $i<10, $i+1
    LITA $i 
@end

# -- MACROS & STRINGS --
@macro ascii_heap $str, $adr
    PUSHA
    @for $i, 0, $i<strlen($str), $i+1
        LITA $str[$i] 
        SVA $adr+$i
    @end
    POPA
@end

ascii_heap "Hello World!", 0x10

@end # _HAS_BEEN_INCLUDED
```

### Internals

psASM is written in python using an ANTLR4 frontend. The bulk of the complexity
is in the preprocessor, which is effectively a tree-walking interpreter that executes
the directives in multiple passes.

It has a variety of additional debug features, including the ability to output 
annotated listings and maps. I also developed a testing setup that executes psASM 
with a set of short input snippets, and compares both the output and intermediate
steps against golden reference files.

## Other Tooling

### psPROG

The USB programmer features an STM32 and FTDI USB interface. psPROG is a small python script
that takes a binary file produced by psASM and communicates with the USB programmer to write
it into psMCU's program flash.

### Syntax Highlighting

Because I was spending a significant time writing psASM code, I setup simple syntax highlighting for
Notepad++, VIM, and now even this website.

## Links

- 📁 [Repo](https://github.com/schilkp/psMCU)
- 📝 [Schematic](https://github.com/schilkp/psMCU/releases/download/v1.0/schematic_psMCU.pdf)
- 🗒️ [Snake in psASM](https://github.com/schilkp/psMCU/tree/master/Programs/8snake)

