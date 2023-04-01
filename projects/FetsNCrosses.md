---
layout: default
title: Fets & Crosses
---

# Fets & Crosses

<center>
    <a href="/assets/img/fetsncrosses/fetsncrosses_full.jpeg">
        <img src="/assets/img/fetsncrosses/fetsncrosses_full.jpeg" width="70%">
    </a>
</center>
<br>

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

<center>
    <a href="/assets/img/fetsncrosses/sim.png">
        <img src="/assets/img/fetsncrosses/sim.png" width="80%">
    </a> <br>
    The simulation in LOGISIM.
</center>
<br>

<center>
    <a href="/assets/img/fetsncrosses/block.png">
        <img src="/assets/img/fetsncrosses/block.png" width="100%">
    </a> <br>
    A high-level block diagram of the system.
</center>
<br>

## Hardware Implementation

The final circuit was much simpler than I first expected it to be: It only requires 19 Flip-Flops (18 for the 
current game state, and one to track the active player), and a handful of basic gates. Some quick 
estimates put that around 2000 transistors when implemented in CMOS - how hard could that be to implemented?

_Well._

I reached this point just as the first corona lockdown started: So if there was one thing I had, it was time.

In a workflow (very!) vaguely reminiscent of actual IC design, I first designed the set of basic cells I needed.
This was done in KiCad, with each cell contained in a hierarchical schematic sheet.

For example, here is the basic NOT gate:

<center>
    <a href="/assets/img/fetsncrosses/not.svg">
        <img src="/assets/img/fetsncrosses/not.svg" width="40%">
    </a>
</center>
<br>

I then systematically constructed more complex gates from these basic cells. For example, a 2-input AND gate was built from an NAND and NOT gate:

<center>
    <a href="/assets/img/fetsncrosses/2and.svg">
        <img src="/assets/img/fetsncrosses/2and.svg" width="50%">
    </a>
</center>
<br>

Then, I re-drew the logic circuit in KiCad, using the hierarchical sheets instead of components. A similar 
procedure is used during layout: each basic cell is routed once, and then the layout applied to all instances 
of that gate using the [replicate layout](https://github.com/MitjaNemec/Kicad_action_plugins) plugin. Then all 
that is left to do is to assemble and route all connections between these cells.

I split the design into two boards:

The main board contains the user interface, power regulation, a 555-timer based clock, and all logic except 
for the engine against which a player can play. There is a slot for a large FLASH memory, which, just as 
in the first iteration, can act as this engine. Alternatively the transistor-based engine, which is 
built on a separate PCB, can be connected to a series of pin-headers on the top.

The PCBs are both 2 layer, and the routing was done in a (Manhattan style)[https://en.wikipedia.org/wiki/Manhattan_wiring], with the top layer used for all 
transistor footprints and vertical routing, while the bottom layer was used for all horizontal routing:

<br>
<center>
    <a href="/assets/img/fetsncrosses/route.jpeg">
        <img src="/assets/img/fetsncrosses/route.jpeg" width="70%">
    </a> <br>
    A close-up of some of the routing on the main board. 
</center>
<br>

<div class="row gallery_scope">
  <div class="column">
    <center>
        <a href="/assets/img/fetsncrosses/fetsncrosses_render_board.png">
            <img src="/assets/img/fetsncrosses/fetsncrosses_render_board.png" width="70%">
        </a>
    </center>
  </div>
  <div class="column">
    <center>
        <a href="/assets/img/fetsncrosses/fetsncrosses_render_engine.png">
            <img src="/assets/img/fetsncrosses/fetsncrosses_render_engine.png" width="70%" allign="bottom">
        </a>
    </center>
  </div>
</div>
<div class="row">
  <div class="column">
    <center>
        Main PCB render. 
    </center>
  </div>
  <div class="column">
    <center>
        Engine PCB render. 
    </center>
  </div>
</div>
<br>

## Assembly

For some reason I decided to assemble these boards by hand. Like I said. Corona. Lot's of time. Did I mention 
that it took 3 revisions to get this all to work?

To make the process a little easier, I built a [vaccum pick and place pen]({% link projects/VacTool.md %}) which 
allowed me to quickly transfer the components to the board directly from the reel. Since all transistors 
shared the same orientation on the board, this was actually a pretty quick process. 

Here is a timer lapse of one such assembly:

<center>
    <div class="youtube-video-container">
        <iframe width="560" height="315" src="https://www.youtube-nocookie.com/embed/Lz2p190qZ2Q" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>         
    </div>
</center>
<br>

_Not included is me dropping the board of the solder hot-plate around 5 minutes after I stopped filming._

## Full Hardware Test
<center>
    <a href="/assets/img/fetsncrosses/fetsncrosses_testing.jpeg">
        <img src="/assets/img/fetsncrosses/fetsncrosses_testing.jpeg" width="70%">
    </a>
</center>
<br>

As a final step, I implemented a small STM32-based testbench that allows the engine to be 
connected to the PC. I also developed a small python script that plays every single 
possible game of Tic-Tac-Toe against the engine (there aren't that many!) and confirmed that 
the engine never loses.

## Links
- [📁 Repo](https://github.com/schilkp/Fets_and_Crosses)
- [📝 LOGISIM File](https://github.com/schilkp/Fets_and_Crosses/tree/master/Logisim)
- [📃 Interactive BOM (Main Board)](/assets/img/fetsncrosses/ibom_main.html)
- [📃 Interactive BOM (Engine)](/assets/img/fetsncrosses/ibom_engine.html)
- [📃 Interactive BOM (Engine Tester)](/assets/img/fetsncrosses/ibom_engine_test.html)
- [📦 Production Files (Schematics, Gerbers)](https://github.com/schilkp/Fets_and_Crosses/releases/)
