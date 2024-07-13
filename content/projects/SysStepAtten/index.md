+++
title="SYS Step Attenuator"
description="A 127 Step Audio Relay Step-Attenuator and 4-way input switcher designed to fit into a Schiit SYS enclosure. "
template="project_page.html"

weight=3

[extra]
thumbnail_img="sysstepatten_full_device.jpeg"
+++

{{ centered_img(src="sysstepatten_full_device.jpeg") }}

{{ gallery() }}
    {{ gallery_img(src="sysstepatten_full_back.jpeg") }}
    {{ gallery_img(src="sysstepatten_full.jpeg") }}
{{ gallery_end() }}

{{ toc() }}

## Overview

A 127-step relay audio attenuator with four-way input selector designed to fit into a [Schiit Sys](https://www.schiit.com/products/sys)
enclosure.

While browsing around for some audio gear I noticed that the "Passive Pre-amp" offered by Schiit was nothing but a
stereo potentiometer and switch inside a fancy metal enclosure (Let's save the rant about
a potentiometer being sold as a 'passive pre-amp' for another day).

I thought it would make for a fun challenge to design a relay step attenuator and input switcher
to fit into the enclosure and actually make use of all the room that is available. While I was
at it, I might as well add a four-way input switcher and relay mute.

{{ youtube(src="https://www.youtube-nocookie.com/embed/S0dtfcZPJ4Q") }}

## Design

### Attenuator

{{ centered_img(src="sysstepatten_sch_atten.svg") }}

The attenuator is a seven-stage constant input impedance relay design. It is nominally sized for a device representing
a 10k impedance at the output.

A small network on the output can be used for matching if the attached device has a (wildly) different
input impedance.

R48/R49 can be used to increase the impedance, while the two potentiometers can be used to decrease the impedance seen
by the attenuator. Jumpers can be used to enable/select the right network.

A separate relay is used to mute the signal, as the attenuator can only attenuate (Surprising, I know.)
but never completely disrupt the signal.

### Grounding

{{ centered_img(src="sysstepatten_sch_input.svg") }}

The grounding of the control unit and signals was kept as flexible as possible to prevent any possible ground-loop problems.

The input selector switches both signal and ground, so the grounds of the different inputs are kept separate.

The ground of the left and right signal are also kept separate, but can optionally be connected with a jumper.

Similarly, the signal and control ground are separate but can be connected via a small jumper. I found that with most
(isolated) 9V plug packs, connecting the control and signal grounds together greatly reduced the noise injected into the signal.

### External Remote

The device is quite light, so I often ended up accidentally pushing it around while trying to adjust the volume or
selecting a different input.

I thought it would be fun to be able to adjust it with some larger knob that was easier to reach. To enable this,
I included a small 4-pin connector on the back that could be used to connect some external potentiometer and switch.

Something like the [tc-electronic level pilot](https://www.tcelectronic.com/product.html?modelCode=P0D71) would make for a nice knob.

### Power

At first, I thought it would make sense to power the unit from an AC adapter, matching the DAC and headphone amp
available in the same enclosure. The power draw from the non-latching relays is however quite significant, and
the bulk capacitance for AC/DC conversion would have taken up a lot of space. Therefor I decided to use a standard
9V DC barrel jack input.

### Making the connectors fit

{{ centered_img(src="sysstepatten_connectors.jpeg") }}

My design required four extra connectors (one DC Input, two 3.5mm audio inputs, and one 2-by-2 2.54 mm pin header for the
external remote) and an on/off switch, but there was little space left at the back of the unit.

To get everything to fit, I stacked the two 3.5 mm connectors on top of the pin headers using two small riser PCBs, and
attached the power switch above the barrel jack, connecting it to the main board using a short cable.

### Software/UI features

The STM32 software is very simple, and the chip overkill. But hey - I had some at home and the tool chain was set up.
A few notable details:

The controller keeps the output muted for around a second during input changes. This prevents buzzing when
cycling past unconnected inputs.

The selected input is saved to flash. To prevent the memory wearing out,
some basic wear-leveling schemes are in place. First, the input is only saved once it remains unchanged for a short while to
prevent repeated writes when quickly cycling through inputs. More importantly a simple journaling scheme is used: If the
input changes, the value is not overwritten but appended after the last entry. Only once all sections are full are they
erased and the scheme repeats from the beginning.

## Possible improvements

With the current design there is a little more noise than with the original unit - especially if the control and signal
ground are kept isolated (Presumably due to some leakage/imperfections with the non-grounded supply). I am sure the routing
could be improved, especially with smaller relays. A second possibility would be to stack two PCBs: The lower PCB could
include all audio signaling/relays, while a second PCB (possibly at the height of the first 3.5mm jack) could handle the
power supply and control electronics.

Using latching relays would drastically reduce the power consumption and remove the need for a switching supply.
This would cause the unit retains to its last setting once it loses power, which may be desired for some applications.
If it is not, only the muting relay can be kept as a non-latching relay.

Using an encoder for the internal controls would allow for the volume set-point to be
restored for each input.

## Project Template

As a starting point, [here](https://github.com/schilkp/SYS_ProjectTemplate) is a KiCad project for designing a project
that fits into a Schiit Sys enclosure.

## Links

- 📁 [Repo](https://github.com/schilkp/SYS_StepAtten)
- 📦 [Production Files](https://github.com/schilkp/SYS_StepAtten/releases/)
- 📝 [Schematic](https://github.com/schilkp/SYS_StepAtten/releases/download/pcb_v1.3/SYS_StepAtten_Schematic.pdf)
- 📃 [Interactive BOM](ibom.html)
- 📁 [Riser Repo](https://github.com/schilkp/3.5mm_RiserPCB)
- 📁 [Template Repo](https://github.com/schilkp/SYS_ProjectTemplate)
