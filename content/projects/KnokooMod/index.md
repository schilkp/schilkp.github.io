+++
title="Fume Extractor Mod"
description="A small mod board to control a Knokoo Fume Extractor with a pedal."
template="project_page.html"

weight=10

[extra]
thumbnail_img="knokoomod_full.jpeg"
+++

{{ centered_img(src="knokoomod_full.jpeg") }}

{{ toc() }}

## What and Why

Some time ago I bought a Knokoo FES150W fume extractor to use while soldering,
especially when working under my microscope.

Overall I am very happy with it. I have no way to test the filtration of the
unit, but the suction is strong enough to be able to work a comfortable distance
away from the end of the flexible arm, and I don't notice any fumes rising
directly towards my face. Also, the smell in the room after an extended soldering
session is much less than before.

It is, however, not the quietest unit. I don't mind the noise while I am working,
but would rather only quickly have it run while I am actually soldering. I found
having to reach under my desk to turn the dial (or trying to do it with my foot)
rather annoying, so I decided to design a small mod that would allow me to
control the unit with a foot pedal.

## Design

Because the unit goes into standby when the power-dial on the front is turned
to 0, the easiest way to turn of the unit is to simply cut the 5V supply to the
potentiometer making the unit think it has been turned down. This way the custom
board can also simply be powered from the same 5V.

I designed a small PCB with a PIC12F1572 to handle all this.

By pressing the foot pedal once, the extractor will run for a set duration
controlled by a potentiometer and automatically turn off after.

By pressing the pedal twice, the extract will run until the pedal is pressed again.

An additional LED blinks while in timer mode, or remains on while running indefinitely.

If no pedal is attached, the unit will function normally.

{{ youtube(src="https://www.youtube-nocookie.com/embed/2ysy9WUZLiE")}}

## Installation Reference:

Once the PCB is assembled and programmed, it can easily be mounted next to the actual PCB:

{{ centered_img(src="knokoomod_modboard.jpeg", width="50%") }}

A short 4-pin to 3-pin JST XH cable must be made to connect the board to the main PCB:

{{ centered_img(src="knokoomod_small_cable.jpeg", width="50%") }}

The 1/4" jack for the pedal, status LED, and timer potentiometer are must be connected
to the board with an 8-pin JST XH cable:

{{ centered_img(src="knokoomod_large_cable.jpeg", width="50%") }}

If the 1/4" jack does not have a switch, tie PEDC to GND (for example POT-). In this
case the unit will *not* return to normal operation when no pedal is connected.

The timer potentiometer can be replaced by populating R6 and R7. In this case
the timer will be fixed to approximately (15) * (R6 / (R6 * R7)) minutes.

## Possible future changes/improvements:

I am currently working on a JBC-Compatible soldering station. If that works
out I will probably add a second input to allow the soldering station to automatically
turn the extractor on while I am soldering.

The easiest method would probably be a second 1/4" input that simply overrides
the current pedal/timer state and turns the extract on while it is active.

Instead of using a 3-pin connector for the connection to the main board, a 4-pin
would make a lot more sense. That way a 4-pin to 4-pin cable could be used.

## Links:

- [📁 Repo](https://github.com/schilkp/VacTool)
- [📦 Production Files](https://github.com/schilkp/VacTool/releases/tag/pcb_v0.0)
- [📝 Schematic](https://github.com/schilkp/VacTool/releases/download/pcb_v0.0/Schematic.pdf)
- [📃 Interactive BOM](https://github.com/schilkp/VacTool/releases/download/pcb_v0.0/InteractiveBOM.html)
