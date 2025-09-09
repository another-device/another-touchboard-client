# Another Touchboard Client

Turn your touch device into a virtual keyboard for your computer.

## Introduction

another-touchboard-client is the companion client application for [another-touchboard-server](https://github.com/another-device/another-touchboard-server). It enables you to remotely control your computer's keyboard input using a touch device (such as a phone or tablet). Simply connect to the server within the same local network to transform your touch device into a convenient virtual keyboard, suitable for scenarios like presentations and remote operations.

## Features

- Seamless integration with the server for low-latency keyboard input simulation
- Support for synchronized press and release states of standard keyboard keys
- Automatic discovery of servers within the local network to simplify connection process
- Lightweight design with low resource consumption

## Working Principle

1. The client discovers running servers via LAN UDP broadcasts
2. Establishes a TCP connection with the server and maintains connection stability through heartbeat detection
3. Converts key operations on the touch device into standardized commands and sends them to the server
4. The server receives commands and simulates corresponding keyboard events to achieve remote input

## Usage

1. First, deploy and start [another-touchboard-server](https://github.com/another-device/another-touchboard-server) on your computer
2. Install and open this client on your touch device
3. The client will automatically search for servers in the local network; select the target server to connect
4. Once connected, you can operate the virtual keyboard on your touch device, and inputs will be synchronized to the computer

## License

This project is open-source under the MIT License. For details, see the [LICENSE](LICENSE) file.
