+++
title="VitalCore"
description="A self-contained, miniaturized, BLE-enabled embedded platform for low-power, wearable, and hearable applications."
template="project_page.html"
weight=200

[extra]
thumbnail_img="vitalcore_paper_small.jpeg"
+++
    
{{ centered_img(src="vitalcore_paper_small.jpeg", no_br="true", width="60%", desc="<small> (📸 Frank K. Gürkaynak, 2022) </small>") }}

{{ toc() }}

## Overview

VitalCore is an open-source, highly integrated, miniaturized embedded systems platform that includes everything
a low-power wearable project usually requires - except application specific sensors
and transducers. 

Its small 17.6mm*12.6mm size allows it to be integrated even in the most constrained
applications, include in-ear and hearable projects. Built around an NRF5340 SoC, VitalCore features
a dual-core Cortex-M33 processor running at up to 128 MHz, 1 MB of Flash, 512 KB RAM, and BLE 5.2
complete with an on-board chip antenna.

{{ gallery() }}
    {{ gallery_img(src="vitalcore_paper.jpg", desc="") }}
    {{ gallery_img(src="lego.jpg", desc="") }}
{{ gallery_end() }}

<!-- FIXME Link to other projects that use it: VitalPod, In-Ear Voice, RadarBud -->

## VitalPack Interface

On its back, the VitalCore features a 0.4mm pitch 50-position connector that can be used to attach
application-specific 'VitalPack' expansion boards. This connector exposes power inputs and outputs,
the SoC's programming interface and USB port, and 28 GPIO pins with ADC, I2C, SPI, I2S, UART, QSPI, and PDM
interfaces available. The SWD pin, battery and charger connections, and QVAR inputs are also available as SMD solder
pads on the back side.

The exact pinout is given in the [provided documentation](https://github.com/ETH-PBL/VitalCore/blob/main/hardware/VC_NRF5340/Documentation/Complete_1.3/VC_NRF5340_FULL_DOC.PDF).

To accommodate different stacking heights, the following combinations of header (on the VitalCore) and receptacles (on
the VitalPack) can be used:

| **Stacking Height** | **Header**                           | **Receptacle**                       |
| ----------------- | ---------------------------------- | ---------------------------------- |
| 0.7mm             | JAE Electronics WP7B-P050VA1-R8000 | JAE Electronics WP7B-S050VA1-R8000 |
| 1.5mm             | Hirose DF40C-50DP-0.4V(51)         | Hirose DF40C-50DS-0.4V(51)         |
| 2.0mm             | Hirose DF40C-2.0-50DP-0.4V(51)     | Hirose DF40C-2.0-50DS-0.4V(51)     |
| 2.5mm             | Hirose DF40C-2.5-50DP-0.4V(51)     | Hirose DF40C-2.5-50DS-0.4V(51)     |

## Power

{{ centered_img(src="VC_Power.svg", width="80%") }}

A MAX77654 PMIC provides a full power subsystem, including a software-controlled battery charger with power path
switching and up to 300mA charge current, a battery monitor, three software-controllable switch mode buck-boost converters each
with an output range of 0.8V to 5.5V, and two software-controlled LDOs each with an output range of 1.71V to 5.3V. 

All on-board devices (SoC and peripherals) are powered using a dedicated 1.8V buck converter, leaving all SMPS and LDO
outputs available for application-specific circuitry via the VitalPack connector.


## Peripherals

The VitalCore comes equipped with the following peripherals:

 - A high-performance LSM6DSV16BX IMU with accelerometer, gyroscope and QVAR frontend.
 - A 256Mb W25Q256JWYIM QSPI Flash.
 - An RGB LED and IS31FL3194 driver capable of LED animations/patterns.

## Panel

{{ centered_img(src="broken_panel.JPG", width="50%") }}

The VitalCore Altium project and gerber files include a panel to be used during development.
It exposes the NRF's SWD programming interface, USB port, power inputs, and power rail test points. It
can be removed manually by cutting the small PCB bridges, or be excluded before production entirely.

## Links

- 📁 [Repo](https://github.com/ETH-PBL/VitalCore)
- 📄 [Full Documentation](https://github.com/ETH-PBL/VitalCore/blob/main/hardware/VC_NRF5340/Documentation/Complete_1.3/VC_NRF5340_FULL_DOC.PDF)
- 🌍 [Interactive HTML BOM](./VC_NRF5340-Complete.html)
- 📦 [Gerbers](https://github.com/ETH-PBL/VitalCore/blob/main/hardware/VC_NRF5340/Documentation/Complete_1.3/Manufacturing)
- 📦 [PnP Files](https://github.com/ETH-PBL/VitalCore/blob/main/hardware/VC_NRF5340/Documentation/Complete_1.3/PickAndPlace)
- ⚙️  [Altium Project](https://github.com/ETH-PBL/VitalCore/blob/main/hardware/VC_NRF5340/)
