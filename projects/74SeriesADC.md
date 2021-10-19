---
layout: default
title: 74-Series ADC
---
# A discrete 74-Series logic SAR-ADC

<center>
    <a href="/assets/img/74seriesadc/74seriesadc_full_board.jpeg">
        <img src="/assets/img/74seriesadc/74seriesadc_full_board.jpeg" width="70%">
    </a>
</center>
<center>
    <a href="/assets/img/74seriesadc/74seriesadc_render.jpeg">
        <img src="/assets/img/74seriesadc/74seriesadc_render.jpeg" width="70%">
    </a>
</center>
<br>

## What and Why?
A discrete SAR (Successive-Approximation-Register) ADC controlled by a state machine implemented in 
74-series logic.

A quick feature overview:

<center>
<div style="width: 50%;">
    <table>
        <tr>
            <th> Specification </th>
            <th> Value </th>
        </tr>
        <tr>
            <td> Resolution </td>
            <td> 8 bit </td>
        </tr>
        <tr>
            <td> Sample Rate </td>
            <td> 1Hz - 300Hz (adjustable) </td>
        </tr>
        <tr>
            <td> Input Voltage Range </td>
            <td> 0-5V </td>
        </tr>
        <tr>
            <td> Input </td>
            <td> Single-ended</td>
        </tr>
        <tr>
            <td> Input Source </td>
            <td> Included Potentiometer or External Input </td>
        </tr>
        <tr>
            <td> Output </td>
            <td> 8 bit parallel </td>
        </tr>
    </table>
</div>
</center>

The point of this project was not to design a usable ADC (8bit at 300Hz is nothing to write home about),
but rather to be a fun challenge and play around with successive-approximation analog to digital conversion.

It also makes for an approachable demonstration of how such ADCs function.

## Demonstration
Here is a short demonstration of the ADC running at a very slow speed, with the input voltage (in yellow) and DAC output voltage (in cyan) shown
on the oscilloscope. The output register is in the bottom right.

<center> 
    <div class="youtube-video-container">
        <iframe width="560" height="315" src="https://www.youtube-nocookie.com/embed/ZFlC2hURkEs" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
    </div>
</center>

<br>
At such a low speed, the successive-approximation algorithm can be seen in action:

- The ADC voltage approaches the input voltage step by step: If it is too low, it is increased, if it is too high, 
  it is decreased. 
- Watching the DAC set-point (top/middle), each bit is tested/set starting at the most significant bit. If testing a 
  specific bit results in the comparator output going high (meaning that the DAC set-point voltage is lower than the 
  input voltage), that bit is set in the Successive-Approximation-Register and will be kept high for the rest of the
  conversion while the rest of the bits are tested.
- Once the conversion is finished, the value from the Successive-Approximation-Register is latched into the output 
  register, and the process starts again.

Below are two more oscilloscope captures showing conversion:

<div class="row gallery_scope">
  <div class="column">
    <a href="/assets/img/74seriesadc/74seriesadc_trace1.png">
        <img src="/assets/img/74seriesadc/74seriesadc_trace1.png">
    </a>
  </div>
  <div class="column">
    <a href="/assets/img/74seriesadc/74seriesadc_trace2.png">
        <img src="/assets/img/74seriesadc/74seriesadc_trace2.png">
    </a>
  </div>
</div>

## Design

A quick overview of the design is below. The full schematic can be seen [here](https://github.com/TheSchilk/74Logic_SA_ADC/releases/download/v0.3/Schematic.pdf).

### Clock

The clock is generated using a standard 555-timer based variable frequency oscillator, but can be
disconnected using a jumper and manually controlled using a push-button.

### Analog Section

The current DAC set point is buffered by a 74HC245 IC in front of the actual R2R DAC.

The DAC then feeds a LM358 being used as a comparator. Because the LM358 cannot compare signals close to it's input
rails and the highest DAC set-point is 5V, it is being powered from a slightly increased 6.2V rail. This voltage,
besides being high enough to compare signals up to 5V, results in the comparator output-high state being very close to
5V. To ensure the output interfaces nicely with the control logic, a Schmitt-trigger buffer follows the comparator, but 
is probably not strictly necessary.

The input voltage that is fed to the other comparator input can either be supplied by an on-board potentiometer, or 
by an external voltage source (selectable by jumper). 

Because the ADC is too slow to meaningfully measure anything but DC, no Sample-and-hold circuit was included.

### Digital Control

The state machine is based around a 74HC161 shift register with an additional output stage. 
Since the 9 states needed (Reset, plus one for each bit) always occur in the same order, a shift register
with additional logic setting it's input high only if all outputs are low makes for a very compact
implementation. The current state is also naturally available in the one-hot encoding needed.

## Changes and Future Ideas

If I ever find the time it would be interesting to measure the linearity of the ADC. Some possible reasons
for non-linearity could be:
- DAC non-linearity due to resistor tolerances
- Comparator hysteresis
- Other comparator nonidealities close to the supply rails.

## Links
- [📁 Repo](https://github.com/TheSchilk/74Logic_SA_ADC)
- [📦 Production Files](https://github.com/TheSchilk/74Logic_SA_ADC/releases/)
- [📝 Schematic](https://github.com/TheSchilk/74Logic_SA_ADC/releases/download/v0.3/Schematic.pdf)
- [📃 Interactive BOM](https://github.com/TheSchilk/74Logic_SA_ADC/releases/download/v0.3/InteractiveBOM.html)

