---
layout: default
title: PmodADC
---

# WS2812B SPI Driver

<center>
    <a href="/assets/img/ws2812b_spi/ws2812b_header.svg">
        <img src="/assets/img/ws2812b_spi/ws2812b_header.svg" width="95%">
    </a>
</center>
<br>

This simple driver allows the usage of a standard SPI peripheral to communicate with WS2812B-Style LEDs. 
It generates binary data, which, once transmitted, will form pulses with the appropriate timing to
mimic the PWM/one-wire interface required. 

The input of the first LED is connected to the SDO pin of the SPI peripheral. No other
SPI outputs are needed.

Because the exact timings of the output will depend on implementation details and
the specific device used, a number of adjustment parameters can be used to compensate. Using these it
should be possible to generate a usable signal using most SPI peripherals that are capable of running 
fast enough. 

This driver was written mostly as an excuse to try unit-testing in C.

The binary data can be generated all at once (buffered mode) or requested piece by piece
(unbuffered mode).

A detailed guide on how to use this driver, the different adjustment parameters, and example code
can be found in the repository README file.

## Links
- [📁 Repo](https://github.com/TheSchilk/ws2812b_spi)
