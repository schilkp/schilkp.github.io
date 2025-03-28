+++
title="Fets & Crosses"
description="A game of Knots-and-Crosses (Tic-Tac-Toe) built from 2458 individual mosfets, featuring both player-vs-player and player-vs-computer modes."
template="project_page.html"
weight=101

[extra]
thumbnail_img="fetsncrosses_header.jpeg"
+++

{{ centered_img(src="fetsncrosses_full.jpeg") }}

{{ toc() }}

## Overview + Features

An implementation of the classic Tic-Tac-Toe / Knots and Crosses game built entirely from 2458 discrete transistors.

## Simulation / Design

While playing around with a graphical [logic simulator](http://www.cburch.com/logisim/) during a 'Digital Design' lecture, I came up
with a simple Tic-Tac-Toe game, featuring both a player-vs-player or player-vs-computer mode. It is capable of detecting
all possible win/draw states, and features a move validator, allowing it to reject invalid inputs from the user.

The 'Engine' against which a player can play was originally implemented using a parallel input/output ROM as a large lookup table:
The current board state was applied to the 18-bit applied to the ROM address input, and the engine's move read from memory.
This worked well, but was very inefficient: less than 5% of all possible inputs corresponded to possible game states.

In a second step I replaced this implementation with a purely combinatorial logic-gate based module, also capable of
perfect play.


{{ centered_img(src="sim.png", desc="The simulation in LOGISIM.") }}

{{ centered_img(src="block.png", desc="A high-level block diagram of the system.") }}

## Hardware Implementation

The final circuit was much simpler than I first expected it to be: It only requires 19 Flip-Flops (18 for the
current game state, and one to track the active player), and a handful of basic gates. Some quick
estimates put that around 2000 transistors when implemented in CMOS - how hard could that be too implemented?

_Well._

In a workflow (very!) vaguely reminiscent of actual IC design, I first designed the set of basic cells I needed.
This was done in KiCad, with each cell contained in a hierarchical schematic sheet.

For example, here is the basic NOT gate:

{{ centered_img(src="not.svg", width="40%") }}

I should note that the specific mosfets models were chosen using the highly scientific process of "sorting by cheapest first" on [lcsc.com](https://www.lcsc.com).

I then systematically constructed more complex gates from these basic cells. For example, a 2-input AND gate was built from an NAND and NOT gate:

{{ centered_img(src="2and.svg", width="50%") }}

Then, I re-drew the logic circuit in KiCad, using the hierarchical sheets instead of components. A similar
procedure is used during layout: each basic cell is routed once, and then the layout applied to all instances
of that gate using the [replicate layout](https://github.com/MitjaNemec/Kicad_action_plugins) plugin (since 
this project predates KiCad's mutlichannel design feature!). Then all that is left to do is to assemble and 
route all connections between these cells.

I split the design into two boards:

The main board contains the user interface, power regulation, a 555-timer based clock, and all logic except
for the engine against which a player can play. There is a slot for a large FLASH memory, which, just as
in the first iteration, can act as this engine. Alternatively the transistor-based engine, which is
built on a separate PCB, can be connected to a series of pin-headers on the top.

The PCBs are both 2 layer, and the routing was done in a [Manhattan style](https://en.wikipedia.org/wiki/Manhattan_wiring), with the top layer used for all
transistor footprints and vertical routing, while the bottom layer was used for all horizontal routing:

{{ centered_img(src="route.jpeg", desc="A close-up of some of the routing on the main board.") }}

{{ gallery() }}
    {{ gallery_img(src="fetsncrosses_render_board.png", desc="Main PCB render.") }}
    {{ gallery_img(src="fetsncrosses_render_engine.png", desc="Engine PCB render.") }}
{{ gallery_end() }}

## Assembly

For some reason I decided to assemble these boards by hand. Did I mention that it took 3 revisions to get this all to work?

To make the process a little easier, I built a [vacuum pick and place pen]({% link projects/VacTool.md %}) which
allowed me to quickly transfer the components to the board directly from the reel. Since all transistors
shared the same orientation on the board, this was actually a pretty quick process.

Here is a timelapse of one such assembly:

{{ youtube(src="https://www.youtube-nocookie.com/embed/Lz2p190qZ2Q") }}

(~Not included is me dropping the board from the solder hot-plate around 5 minutes after I stopped filming.~)

Only after three revisions and once I had convinced myself that everything worked, did I spend the money
to have five engines and main boards assembled: The uneven heating of the PCB during my manual
soldering had introduce such significant warpage that my prototypes would break randomly after a few 
weeks due to tension breaking solder joints.

## Full Hardware Test

{{ centered_img(src="fetsncrosses_testing.jpeg") }}

As a final step, I implemented a small STM32-based test bench that allows the engine to be
connected to the PC. I also developed a small python script that plays every single
possible game of Tic-Tac-Toe against the engine (there aren't that many!) and confirmed that
the engine never loses.

## Links
- 📁 [Repo](https://github.com/schilkp/Fets_and_Crosses)
- 📝 [LOGISIM File](https://github.com/schilkp/Fets_and_Crosses/tree/master/Logisim)
- 📃 [Interactive BOM (Main Board)](ibom_main.html)
- 📃 [Interactive BOM (Engine)](ibom_engine.html)
- 📃 [Interactive BOM (Engine Tester)](ibom_engine_test.html)
- 📦 [Production Files (Schematics, Gerbers)](https://github.com/schilkp/Fets_and_Crosses/releases/)
