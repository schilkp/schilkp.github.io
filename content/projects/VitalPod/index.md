+++
title="VitalPod"
description="An in-ear multi-vital sign monitor that measures heart rate, blood oxygenation (SpO2), and skin temperature."
template="project_page.html"
weight=202

[extra]
thumbnail_img="header.jpeg"
+++

{{ centered_img(src="projects/VitalPod/header.jpeg", downscale_to_width=1000) }}

{{ toc() }}

## Overview

The design, construction, and evaluation of the VitalPod was the subject of my bachelor thesis at ETH, and the first of a series of 
earbud-related projects. It is a BLE-enabled true-wireless earbud, that features a number
of sensors capable of sensing body temperature, heart rate, and blood oxygen concentration.

I later "refactored" the main board into a general-purpose embedded systems platform,
the [VitalCore](@/projects/VitalCore/index.md), which found use for a number of other projects,
such as the [RadarBud](@/projects/RadarBud/index.md).

## Paper

We published a paper about this project, which you can find below. It contains more detailed information, especially regarding the final performance of the system.

📚 [Philipp Schilk, Kanika Dheman, Michele Magno, "VitalPod: A Low Power In-Ear Vital Parameter Monitoring System", *WIMOB'22*, 2022.](https://doi.org/10.1109/WIMOB55322.2022.9941646)

## Electrical Design

{{ centered_img(src="arch.svg", width="50%") }}

The main PCB contains an ultra-low power Ambiq Apollo 4 Blue SoC with BLE capabilities and associated on-board antenna, 
battery management and power conversion, an IMU, a microphone, and an audio codec. There are two small external
sensor modules that are connected to the main PCB: A PPG module based on the MAX30208, and a MAX30101 body temperature sensor.

For details on their operation, algorithms, and their performance, please see the paper.

Because the Ambiq does not support BLE 5.3/audio via BLE, I also designed a second variant of the PCB that replaces
the SoC with an NRF5340. Unfortunately, due to time constraints, I never had time to bring-up that board and test audio
playback.

{{ gallery() }}
    {{ gallery_img(src="pcb.png", desc="Layout of the main PCB.") }}
    {{ gallery_img(src="pcb_coin.png", desc="Pictures of the front and back side of the main PCB, with a coin for scale.") }}
{{ gallery_end() }}

The main PCB featuring some *bodge wires* ™️ is shown above. It is a 6-layer HDI board with double-sided loading that I
hand-assembled.

## Mechanical Design

{{ gallery() }}
    {{ gallery_img(src="3dprint1.png", desc="The two 3D-printed case halves.") }}
    {{ gallery_img(src="3dprint2.png", desc="An empty but assembled case.") }}
{{ gallery_end() }}

{{ gallery() }}
    {{ gallery_img(src="render_front.png") }}
    {{ gallery_img(src="render_explode.png") }}
    {{ gallery_img(src="render_back.png") }}
{{ gallery_end() }}

I designed the case in SolidWorks, and printed it on a FormLabs 3L resin printer. It is split into two halves and a battery cover.
A 32mAh Panasonic battery is housed in the stem, the sensors are installed in the front case, and the PCBs are sandwiched in between.

## Device 

{{ centered_img(src="projects/VitalPod/in_hand.jpg", downscale_to_width=1000) }}

The final device is pictured above. All modules were connected manually using enamel wire. The firmware is FreeRTOS based,
and currently limited to transmitting the raw sensor data over Bluetooth. I used my [BLELog](@/projects/BLELog/index.md) script
to receive and process that data in real time. Again, due to time limitations, I did not implement the algorithms on the device
itself, but they are rather simple and could easily be ported.

{{ centered_img(src="spo2_time.png", width="50%") }}

Above is an example blood oxygen concentration measurement. Please have a look at the paper for precise results.

## Positional Analysis

{{ gallery() }}
    {{ gallery_img(src="pos.png", desc="Investigated PPG Sensor Positions.") }}
    {{ gallery_img(src="molds.png", desc="Example Ear Molds.") }}
{{ gallery_end() }}

One of the more interesting details I encountered during the development process is the performance difference of various
PPG sensor positions.
To decide on a sensor position while developing the case, I made a number of silicon casts of my ear, in which I then installed
the PPG sensor in various places.

Interestingly, I found that all positions are roughly equivalent in terms of the recorded signal amplitude, but vary wildly in
the susceptibility to different kinds of motion artifacts.
{{ gallery() }}
    {{ gallery_img(src="artif_jaw.svg") }}
    {{ gallery_img(src="artif_nod.svg") }}
    {{ gallery_img(src="artif_side.svg") }}
{{ gallery_end() }}
Specifically, forward positions in the ear canal were much more susceptible to jaw
movement, but less impacted by head movement. For more details, please have a look at the paper.

## Links + References

- 📚 [Paper](https://doi.org/10.1109/WIMOB55322.2022.9941646)
- ⚙️ [VitalCore](@/projects/VitalCore/index.md)

Our paper may be cited as follows:
```bibtex
@inproceedings{VitalCore,
  author={Schilk, Philipp and Dheman, Kanika and Magno, Michele},
  booktitle={2022 18th International Conference on Wireless and Mobile Computing, Networking and Communications (WiMob)}, 
  title={VitalPod: A Low Power In-Ear Vital Parameter Monitoring System}, 
  year={2022},
  pages={94-99},
  doi={10.1109/WiMob55322.2022.9941646}
}
```

