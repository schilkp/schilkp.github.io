+++
title="ETH Zürich Embedded Systems"
description="A full practical university-level embedded systems course based on a custom hardware platform and tooling running annually at ETH Zürich with 250+ participants."
template="project_page.html"
weight=104

[extra]
thumbnail_img="header.jpg"
+++

{{ centered_img(src="projects/ES/header.jpg", downscale_to_width=1000) }}

## Overview

During the 2023 Fall Semester, I had the incredible opportunity to build from scratch
the practical components of the Embedded Systems course taught annually for 250+ students
at the ETH Zürich Department for Electrical Engineering and Information Science.

> 🚧 **Note**
>
> While the course run successfully run for its first semester, we are still working on updating and
> improving many different aspects. We plan on publishing and open-sourcing all course materials once
> they are ready.

## Hardware

My previous experience has shown me that most typical microcontroller development boards are
hopelessly ineffective as a teaching tool. In general, manufacturer-provided boards fall into
one of two categories:

Basic development boards (such as ST's Nucleo line) feature nothing but a microcontroller and
programmer, intending for the user to connect different peripherals via some connectors. The lack
of different buttons, potentiometers, LEDs, and other "fun" components makes it hard to
design visual and engaging exercises. While it would be possible to attach such parts
to the board, this does not really scale with 250 students in a room - There are already
sufficient problems that require debugging!

Full-featured development boards, on the other hand, tend to be stuffed to the brim with top-of-the-line
parts that a manufacturer is trying to sell. While a full-color LCD and 24-bit audio DAC may sound
like great peripherals to have for course exercises, I have found them to be far too complex for a
student that has just started working with microcontrollers to tackle. Even if they are not used,
the complicated schematics and documentation tend to lead to much confusion.

Because of this, we opted to develop a custom hardware platform for our course. At first,
we investigated a completed board with an integrated programmer, but quickly dropped the idea
because the programmer firmware licenses of different manufacturers would make this
either rather difficult or completely illegal. 

Instead, we opted to develop a "shield" that is connected to an otherwise bare-bones NUCLEO-L476RG
board. It features many rather simple peripherals, each of which provides both opportunities for
learning and fun applications:

- Two basic LEDs for the essential "Blinky" exercise. This covers everything from the compilation and programming 
  flow, GPIOs, schematic reading to the low-level details of registers and bit manipulation.
- Five buttons, placed in a game-pad arrangement. This provides much more flexibility for fun games and interactive
  exercises than the usual one or two switches found on most other boards.
- A bi-color 4x3 LED matrix controlled by three shift registers makes for a rather usable display with a bit
  of creativity. The shift registers lend themselves as a great introduction to serial communication and SPI.
- A potentiometer, serving as another control input for interactive exercises and a great application for learning
  about ADC operation.
- The I2C temperature sensor is a perfect introduction to both I2C and external peripherals, with a 
  small enough register map and simple enough documentation to allow students to build up their own
  driver from scratch.
- Two PDM microphones, who's high data rate makes for a great motivation for the introduction of DMA. Furthermore,
  they naturally lend themselves to simple FTT-based signal processing that allows us to take a look
  at the advantages of hardware-accelerated DSP routines.
- A SPI IMU is a good example of a more complicated external peripheral, and introduces students to 
  integrating a simple driver into their project.
- Two mikroBUS connectors make expansion very easy, should students want to explore other sensors
  and peripherals.
- Finally, a Wuerth WIFI module (mounted on the bottom of the shield and not pictured above) allows
  students to explore a whole range of networking and integration topics.

## Labs

{{ gallery() }}
    {{ gallery_img(src="ex1.png", desc="Snake on the LED Matrix.") }}
    {{ gallery_img(src="ex2.png", desc="Tic-Tac-Toe on the LED Matrix.") }}
    {{ gallery_img(src="ex3.png", desc="Golf and racing game.") }}
{{ gallery_end() }}

With our new hardware in hand, I developed a set of 10 labs, each with multiple practical and theoretical
exercises, code handouts, slides, and hundreds of pages of documentation.

Some examples include:

- A number of basic and low level exercises, tackling bitwise operations, GPIOs, the manufacturer-provided library and 
  direct register manipulation.
- A task where students have to correctly interface with the four on-board buttons, allowing them to play a game of
  SNAKE! on the LED matrix.
- A task where students have to correctly set up UART communication, allowing them to control a game of Tic-Tac-Toe on the
  LED matrix.
- A task where students have to implement a simple Caesar cipher to decode a secret message sent via UART, allowing them
  to experiment with ASCII encoding.
- Detailed theoretical exercises covering the I2C and UART protocols, including a task that requires students to both
  decode and "debug" an I2C bus based on provided oscilloscope captures.
- Detailed theoretical exercises covering the operation of a Successive-Approximation ADC.
- A task where students learn about ADC calibration, including the concept of a transfer standard.
- Various timer exercises.
- Practical exercises that allow students to experiment with different RTOS scheduling algorithms and 
  topics, such as task priorities, preemption, time slicing, priority inheritance, and deadlock.
- A task where students see RTOS stack-overflow protection in action - including some of its limitations.
- A series of tasks guiding students in developing an RTOS-compatible logging system.
- A task that demonstrates both RTOS tasks and queues by having a single IMU control both a game of golf
  on the LED matrix, and a simple racing game shown via UART.
- A task that has students implement simple DSP routines using both vanilla C and ARM SIMD instructions and
  profile the speed difference.
- A task that has students read data from the on-board microphones using the PDM interface and DMA, and
  use an FFT to identify the dominant frequency. The performance of a hardware-accelerated FFT routine
  is compared to a pure software implementation.

## Software

{{ centered_img(src="/projects/tonbandgeraet/tband_banner.png" width="100%") }}

Last semester, I found that students had a hard time understanding what exactly was happening inside 
the microcontroller - especially when dealing with more complicated RTOS setups.

Unfortunately, I was not able to find an embedded system tracer that fulfilled all my requirements:

- Cross-platform (Windows/Mac/Linux)
- Free to use
- Does not require a specific debugger/programmer

So I decided to build my own! You can read all about *Tonbandgerät* [here](/projects/tonbandgeraet/). It will be used in the upcoming semester.
