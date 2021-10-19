---
layout: default
title: PmodADC
---
# PmodADC 

<center>
    <a href="/assets/img/pmodadc/pmodadc_full_board.jpeg">
        <img src="/assets/img/pmodadc/pmodadc_full_board.jpeg" width="70%">
    </a>
</center>
<br>

## Overview

A fully discrete, 14-bit, 41kHz, Successive-Approximation Analog-to-Digital converter,
controlled by an iCE40 FPGA. Audio can be streamed to and from the PC in real time 
via USB.

The converter interfaces with an iCEbreaker FPGA board using a standard PMOD connector - which is
also where it takes it's name from.

Because a 14-bit R2R DAC sits at the core of this design, I also built a second dedicated
audio DAC board: the PmodDAC. Details of this design are also included below.

This project is a continuation of my [previous SAR-ADC](/projects/74SeriesADC.md), which was a much simpler
and slower converter controlled by a state machine implemented in discrete 74-series logic gates.

- [Overview](#overview)
- [Design: PmodADC](#design-pmodadc)
- [Design: PmodDAC](#design-pmoddac)
- [Construction](#construction)
- [Demonstration](#demonstration)
- [Characterization](#characterization)
- [Future Ideas and Possible Improvements](#future-ideas-and-possible-improvements)
- [Links](#links)
- [Other Notes](#other-notes)

## Design: PmodADC
 
Below is a short overview of the different blocks of the PmodADC and PmodDAC schematics.

For the full schematics, see the [links](#links) section at the end of this page.

The schematic snippets below can be enlarged by clicking on them.

### Analog Frontend, Sample & Hold

<center>
    <a href="/assets/img/pmodadc/pmodadc_sch_input.svg">
        <img src="/assets/img/pmodadc/pmodadc_sch_input.svg" width="70%">
    </a>
</center>
<br>

The input stage takes care of buffering, amplification, filtering, and biasing, before feeding a 
sample & hold amplifier.

First, the input signal (which is usually an audio signal with less than 1Vpp) is AC-coupled, buffered, and may 
be amplified with a variable gain of up to 20db.

A second order 20kHz Sallen-Key low-pass filter to reduce aliasing is in turn 
followed by a passive biasing network. The bias point is derived from the same 5V reference that also feeds the R2R DAC. A small 
trimmer provides a few millivolt of bias-point adjustment.

The frontend also includes some jumpers to reconfigure or bypass the signal path.
This is useful as it provides a DC-coupled connection to the ADC during characterization.

The sample & hold stage is a LF398 amplifier implemented as recommended.
The actual sampling capacitor is a 10nF C0G ceramic. It too can be bypassed by some
configuration jumpers. Oscilloscope traces showing the operation of the sample & hold amplifier
are included below.

<center>
    <a href="/assets/img/pmodadc/pmodadc_s&h.png">
        <img src="/assets/img/pmodadc/pmodadc_s&h.png" width="50%">
    </a>
</center>
<br>

### DAC, Comparator, Voltage Reference

<center>
    <a href="/assets/img/pmodadc/pmodadc_sch_adc.svg">
        <img src="/assets/img/pmodadc/pmodadc_sch_adc.svg" width="70%">
    </a>
</center>
<br>

A REF3450 5V reference sets the full scale voltage of the DAC at the center of the 
converter, hence providing the reference voltage for the whole ADC.

The DAC is a standard discrete 14-bit R2R design. 
It is controlled by the FPGA via two shift registers which also handle level shifting of the
3.3V FPGA signals to 5V. The shift register outputs are buffered by two octal logic buffers
which are powered directly from the 5V reference.

The DAC and sample & hold amplifier feed a LT1711 comparator, chosen for it's low offset voltage
and speed.

### Power

<center>
    <a href="/assets/img/pmodadc/pmodadc_sch_power.svg">
        <img src="/assets/img/pmodadc/pmodadc_sch_power.svg" width="50%">
    </a>
</center>
<br>

I originally wanted the board to be powered solely by the 3.3V provided by the Pmod Connector,
so I designed and implemented the above power architecture:

The 3.3V input is first boosted to 10V, and then regulated to the 5V and 9V rails needed using two LDO regulators.
The 9V rail is required because the LF398 Sample & Hold amplifier needs quite some supply voltage overhead to work up to 5V.
To generate the negative -5V rail, the 3.3V input is first inverted to -6V, and then regulated
using another LDO regulator.

Annoyingly, I overlooked that the 3.3V rail on the iCEbreaker board is produced by a small
SOT-23-5 sized LDO regulator that is not able to continuously provide the 50-100mA that both
boards draw. I ended up chopping out the 3.3V pins of the Pmod Connector and powering
both boards from a lab supply. 

## Design: PmodDAC

As mentioned above, I also built a 14-bit, 41kHz Audio DAC board as most of the components
required had already been designed.

The power supply, FPGA interface, and R2R DAC are identical to the ADC above. 
Only the output stage differs:

<center>
    <a href="/assets/img/pmodadc/pmodadc_dac_output.svg">
        <img src="/assets/img/pmodadc/pmodadc_dac_output.svg" width="70%">
    </a>
</center>
<br>

First the DAC output is buffered to prevent errors due to loading. The signal is then AC-coupled, and may be 
attenuated using a potentiometer. This is again followed by a buffer. 

Because there where extra op amps available anyway, I decided to include two Sallen-Key low pass filters,
but one may be bypassed using configuration jumpers.

## Construction

The board was assembled at home using standard methods. Below are some pictures of the process.

<div class="row gallery_scope">
    <div class="column">
        <a href="/assets/img/pmodadc/pmodadc_build_stencil.jpeg">
            <img src="/assets/img/pmodadc/pmodadc_build_stencil.jpeg">
        </a>
        <br>
        Solder paste being applied using a stencil.
    </div>
    <div class="column">
        <a href="/assets/img/pmodadc/pmodadc_build_paste.jpeg">
            <img src="/assets/img/pmodadc/pmodadc_build_paste.jpeg">
        </a>
        <br>
        Solder paste on the board.
    </div>
    <div class="column">
        <a href="/assets/img/pmodadc/pmodadc_build_placed.jpeg">
            <img src="/assets/img/pmodadc/pmodadc_build_placed.jpeg">
        </a>
        <br>
        Components placed before soldering.
    </div>
</div>        
<br>

A video of the 0402 R2R DAC Resistors being re-flowed on an early revision of the board:
<center>
    <div class="youtube-video-container">
        <iframe width="560" height="315" src="https://www.youtube-nocookie.com/embed/AxqhHt8jnj0" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
    </div>
</center>

<br>

## Demonstration

The quality of both the ADC and DAC were actually much better than I expected. 

When used to convert audio signals they both impart some conversion artifacts and
add a very noticeable noise floor, but the audio remains of very acceptable quality.

As a quick demonstration, below is a video of music coming being recorded by the 
ADC and played back by the DAC:

<center> 
    <div class="youtube-video-container">
        <iframe width="390" height="220" src="https://www.youtube-nocookie.com/embed/QIoPao8BHm0" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>  
    </div>
</center>

<br>
As a more direct comparison, the table below contains short music clips as they are, after being recorded by the ADC,
and after playback by the DAC respectively.

| *Song* 	| *Original* 	| *PmodADC Demo* 	| *PmodDAC Demo* 	|
|:-:	|:-:	|:-:	|:-:	|
| Protofunk 	| [here](https://soundcloud.com/user-489490213/protofunk-reference/s-mYtDzv4H0rD) 	| [here](https://soundcloud.com/user-489490213/protofunk-pmodadc/s-5CrWlwWIQJU) 	| [here](https://soundcloud.com/user-489490213/protofunk-pmoddac/s-AqIKrZKs7Aa) 	|
| New Hero in Town 	| [here](https://soundcloud.com/user-489490213/new-hero-in-town-reference/s-YKGpP2wkpSc) 	| [here](https://soundcloud.com/user-489490213/new-hero-in-town-pmodadc/s-A1OPIKn5Tv4) 	| [here](https://soundcloud.com/user-489490213/new-hero-in-town-pmoddac/s-smGRP41zKKE) 	|
| Whiskey on the Mississippi 	| [here](https://soundcloud.com/user-489490213/whiskey-on-the-mississippi-reference/s-0ekaJDO2ERm) 	| [here](https://soundcloud.com/user-489490213/whiskey-on-the-mississippi-pmodadc/s-d2xfiT4uBGa) 	| [here](https://soundcloud.com/user-489490213/whiskey-on-the-mississippi-pmoddac/s-CflAaRhN0gA) 	|
| The Parting 	| [here](https://soundcloud.com/user-489490213/the-parting-reference/s-s09MCjP3SIX) 	| [here](https://soundcloud.com/user-489490213/the-parting-pmodadc/s-gcHSaS2ZzWT) 	| [here](https://soundcloud.com/user-489490213/the-parting-pmoddac/s-kLg3MuZsgWg) 	|

<small> All music used is by Kevin MacLeod and is available under the Creative Commons 4.0 license, see [here](#other-notes).</small>

## Characterization

I was very fortunate to be given the opportunity do some basic characterization of my ADC and DAC design at the Center for
Project-based learning at ETHZ.

<center>
    <a href="/assets/img/pmodadc/pmodadc_lab.jpeg">
        <img src="/assets/img/pmodadc/pmodadc_lab.jpeg" width="80%">
    </a>
</center>
<br>

### ADC Linearity

All ADC Linearity tests where performed with the input stage bypassed to DC couple the 
Keysight B2902A Source Meter used as test voltage source.

The absolute deviation from the ideal ADC transfer function is shown in the left plot below.
When adjusting for the rather significant gain and offset errors, the nonlinearities are 
at most 40LSB, as can be seen in the right plot.

The most likely sources for these errors are DAC nonlinearities, since the DAC linearity 
measurements (below) feature a similar magnitude.

<div class="row gallery_scope">
  <div class="column">
    <a href="/assets/img/pmodadc/pmodadc_adc_lin.svg">
        <img src="/assets/img/pmodadc/pmodadc_adc_lin.svg">
    </a>
  </div>
  <div class="column">
    <a href="/assets/img/pmodadc/pmodadc_adc_lin_adj.svg">
        <img src="/assets/img/pmodadc/pmodadc_adc_lin_adj.svg">
    </a>
  </div>
</div>        


### ADC Noise

With the input AC-coupled but shorted, the ADC will read as is show in the plot below.

The readings feature a standard deviation of 3.43

<center>
    <a href="/assets/img/pmodadc/pmodadc_adc_noise.svg">
        <img src="/assets/img/pmodadc/pmodadc_adc_noise.svg" width="50%">
    </a>
</center>
<br>

### ADC Frequency Response

A rough measurement of the frequency-response of the ADC was taken by
sampling single-tone signals from a Keysight 33600 function generator 
and examining the recorded signal amplitude.

I was surprised by this measurement: 
Both the input high-pass/AC-coupling and anti-aliasing low-pass seem to perform 
exactly as designed. The passband-ripple is less than 0.5dB.

<center>
    <a href="/assets/img/pmodadc/pmodadc_adc_fresp.svg">
        <img src="/assets/img/pmodadc/pmodadc_adc_fresp.svg" width="50%">
    </a>
</center>
<br>

### ADC SNR and THD

Some very rough SNR and THD measurements yield the following:

<div class="row gallery_scope">
  <div class="column">
    <a href="/assets/img/pmodadc/pmodadc_adc_snr.svg">
        <img src="/assets/img/pmodadc/pmodadc_adc_snr.svg">
    </a>
  </div>
  <div class="column">
    <a href="/assets/img/pmodadc/pmodadc_adc_thd.svg">
        <img src="/assets/img/pmodadc/pmodadc_adc_thd.svg">
    </a>
  </div>
</div>



### DAC Linearity

Measuring the DAC linearity again using the Keysight B2902A Sourcemeter 
yielded the following:

<center>
    <a href="/assets/img/pmodadc/pmodadc_dac_lin.svg">
        <img src="/assets/img/pmodadc/pmodadc_dac_lin.svg" width="50%">
    </a>
</center>
<br>

Because this DAC is identical to the one at the core of the ADC, and the
nonlinearities are very similar in magnitude to those seen on the ADC,
it is likely that DAC non-idealities are large source of the ADC errors.

### DAC THD

Some very rough THD measurement yields the following:

<center>
    <a href="/assets/img/pmodadc/pmodadc_dac_thd.svg">
        <img src="/assets/img/pmodadc/pmodadc_dac_thd.svg" width="50%">
    </a>
</center>
<br>

A big thank-you again to Dr. Vogt and the ETH PBL Center for giving me the opportunity to put
my design through it's paces.

## Future Ideas and Possible Improvements

The logical next step would probably be to integrate the ADC, DAC, FPGA and USB interface onto the 
same board. This could simplify the somewhat convoluted power architecture, possibly
reducing noise.

This would also enable me to select the external oscillator FPGA to give more flexibility in sampling
rate selection. A more standard frequency (44.1 kHz) would make sense. The FPGA could also be directly
connected to the ADC: Skipping the shift registers and their high-speed serial communication would
probably also yield noise improvements.

Another interesting idea would be to implement a charge-redistribution ADC from discrete components.
I would presume that this would not be as straight forward, but definitely worth a try. An integrating/multislope
ADC would also make for a fun challenge.

## Links
- [📁 Repo](https://github.com/TheSchilk/PmodADC)
- [📦 Production Files](https://github.com/TheSchilk/PmodADC/releases/)

- PmodADC
    - [📝 Schematic](https://github.com/TheSchilk/PmodADC/releases/download/v0.2/PmodADC_Schematic.pdf)
    - [📃 Interactive BOM](https://github.com/TheSchilk/PmodADC/releases/download/v0.2/PmodADC_ibom.html)
- PmodDAC
    - [📝 Schematic](https://github.com/TheSchilk/PmodADC/releases/download/v0.2/PmodDAC_Schematic.pdf)
    - [📃 Interactive BOM](https://github.com/TheSchilk/PmodADC/releases/download/v0.2/PmodDAC_ibom.html)

## Other Notes

The music used during all demonstration was:
```
Protofunk by Kevin MacLeod  
Link: https://incompetech.filmmusic.io/song/4247-protofunk  
License: http://creativecommons.org/licenses/by/4.0/  

Whiskey on the Mississippi by Kevin MacLeod  
Link: https://incompetech.filmmusic.io/song/4624-whiskey-on-the-mississippi  
License: http://creativecommons.org/licenses/by/4.0/  
  
New Hero In Town by Kevin MacLeod  
Link: https://incompetech.filmmusic.io/song/5742-new-hero-in-town  
License: http://creativecommons.org/licenses/by/4.0/  

The Parting by Kevin MacLeod  
Link: https://incompetech.filmmusic.io/song/4501-the-parting  
License: http://creativecommons.org/licenses/by/4.0/  
```

