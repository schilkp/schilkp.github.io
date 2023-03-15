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

<center>
    <a href="/assets/img/fetsncrosses/block.png">
        <img src="/assets/img/fetsncrosses/block.png" width="100%">
    </a>
</center>
<br>


While playing around with a graphical [logic simulator](http://www.cburch.com/logisim/) during a 'Digital Design' lecture, I came up 
with a simple Tic-Tac-Toe game, featuring both a player-vs-player or player-vs-computer mode. It is capable of detecting 
all possible win/draw states, and features a move validator, allowing it to reject invalid inputs from the user.

The 'Engine' against which a player can play was originally implemented using a parallel input/output ROM as a large lookup table:
The current board state was applied to the 18-bit applied to the ROM address input, and the engine's move read from memory.
This worked well, but was very inefficient: less than 5% of all possible inputs corresponded to possible game states.

In a second step I replaced this implementation with a purely combinational logic-gate based module, also capable of 
perfect play.

## Hardware Implementation

The final circuit was much simpler than I first expected it to be: It only requires 19 Flip-Flops (18 for the 
current game state, and one to track the active player), and a handful of basic gates. Some quick 
estimates put that around 2000 transistors when implemented in CMOS - how hard could that be to implementen?

#### WIP

<div class="row gallery_scope">
  <div class="column">
    <center>
        <a href="/assets/img/fetsncrosses/fetsncrosses_render_board.png">
            <img src="/assets/img/fetsncrosses/fetsncrosses_render_board.png" width="70%">
        </a> <br>
        Main PCB render. Click to enlarge.
    </center>
  </div>
  <div class="column">
    <center>
        <a href="/assets/img/fetsncrosses/fetsncrosses_render_engine.png">
            <img src="/assets/img/fetsncrosses/fetsncrosses_render_engine.png" width="70%" allign="bottom">
        </a> <br>
        Engine PCB render. Click to enlarge.
    </center>
  </div>
</div>        
<br>

## Assembly

<center>
    <div class="youtube-video-container">
        <iframe width="560" height="315" src="https://www.youtube-nocookie.com/embed/Lz2p190qZ2Q" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>         
    </div>
</center>
<br>

## Full Hardware Test
<center>
    <a href="/assets/img/fetsncrosses/fetsncrosses_testing.jpeg">
        <img src="/assets/img/fetsncrosses/fetsncrosses_testing.jpeg" width="70%">
    </a>
</center>
<br>

## Links
- [📁 Repo](https://github.com/schilkp/Fets_and_Crosses)
- [📝 LOGISIM File](https://github.com/schilkp/Fets_and_Crosses/tree/master/Logisim)
- [📦 Production Files](https://github.com/schilkp/Fets_and_Crosses/releases/)
