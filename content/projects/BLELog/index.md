+++
title="BLELog"
description="A simple python BLE data logger which receives, decodes, stores, and plots characteristic data in real time."
template="project_page.html"
weight=2

[extra]
thumbnail_img=""
+++

A simple python BLE data logger which receives, decodes, stores, and plots characteristic data in real time, that has proven quite convenient and flexible.
It is based on the [bleak](https://github.com/hbldh/bleak) cross-platform Bluetooth library.

{{ centered_img(src="blelog.png", width="50%") }}

---

## Overview

<!-- Fixme: Link to vitalcore, radarbud -->

After having written one to many quick and dirty "receive and store BLE characteristic notification" python script,
I took the time to write a generic BLE data logger that can adapted quickly to the most common requirements.

*BLELog* will continuously scan for Bluetooth devices with a given address or a given name, connect to them,
subscribe to a specified set of characteristics. Its exact behavior 
(such as the number of active connections to maintain and various timeouts) can be configured.

Once connected, it will pass all received data to a set of user-provided and application specific characteristic decoder functions.
Their output is in turn passed to a configurable set of so-called *consumers*.

Included are a `log2csv` consumer that simply saves all data to disk, and a `plot` consumer which, given a bit of adaptation
to the exact data format, deals with spawning matplotlib in a separate python subprocess and continuously plotting the received
data.

It also features a simple TUI interface that displays information about current connections and received data.

## Usage
For installation and usage instructions, take a look at the [README.md](https://github.com/ETH-PBL/BLELog)

## Links
- 📁 [Repo](https://github.com/ETH-PBL/BLELog)
