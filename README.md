# nx Gamepad

This repository aims to sum up the extent of the open-source project **nx Gamepad** which not only provides a Flutter plugin for utilizing platform-specific game controller inputs on an application. Inspired by the Wii U console, the library additionally aims to unlock the potential of using a smartphone in combination with a controller peripheral as a gamepad for your computer.

In order to showcase and explain this concept in more detail, the [releases page](https://github.com/devEnju/nx_gamepad/releases) lists all of the installable applications and mods of this project. The following sub respositories provide corresponding examples with comprehensive documentation on how to implement such functionality yourself:

- [n Gamepad - Available Flutter plugin for game development](https://github.com/devEnju/n_gamepad)
- [tx Gamepad - Concrete implementation of the Flutter plugin](https://github.com/devEnju/tx_gamepad)
- [rx Gamepad - Example for a specific game server application](https://github.com/devEnju/rx_gamepad)

## Overview

The project's core is the Flutter plugin, with platform-specific implementations responsible for sending input events from a connected controller to a compatible game. It supports Android devices and has planned support for iPhones and the Steam Deck. New user interfaces and interactions are easily implemented for an application which serves as the gamepad, while games need to integrate to react and respond to the before mentioned events.

## Integration Details

The following diagram illustrates possible communication flows:

```
+---------------+         +----------------+
| FlutterClient | <-----/ | PlatformClient |  - Android (working)
+---------------+         +----------------+
      |   ˄                       |           - iOS     (planned)
      |   |                       |           - Linux   (planned)
      |   |                       |
      ˅   |                       |
  +------------+                  |
  | GameServer | <----------------+
  +------------+
```

Input events are sent via UDP over the local network from either the Flutter or *PlatformClient* to a *GameServer*. The *FlutterClient* is able to communicate with a dedicated platform integration to also receive input events, but is mainly focused on managing custom interactions with its user interface, which needs to be retrieved according to changes from the server. This modular design ensures an easy addition of new platforms and allows to only need to integrate the client once.

For a detailed description of input events and the client-server communication please refer to the [wiki page](https://github.com/devEnju/nx_gamepad/wiki) of this repository.

## Features

- User interface and interactions only need to be written once
- Available connection setup and communication with game servers
- Support for touch, gyro, button, dpad, joystick, and trigger input events
- Event channel for input events between platforms and Flutter

## Considerations & Limitations

While Flutter provides a powerful toolset for 2D UI development, it still has limitations when it comes to 3D models and rendering. Furthermore, the project only focuses on using Wi-Fi for gamepad connections, as it offers higher bandwidth for streaming compared to Bluetooth. Lastly, it is well tested with the Razer Kishi v1 controller for Android but other gamepad peripherals may require additional development.

Fortunately, all those points are able to be worked on and should therefore be crossed off over time. Even Flutter is receiving a new rendering engine called [Impeller](https://github.com/flutter/flutter/wiki/Impeller), which looks very promising to fill in the gap for the 3D related shortcomings.

## Future Plans

Planned developments for the **nx Gamepad** project include:

- Adding Linux and iOS platform support
- Implementing [gyro controls](http://gyrowiki.jibbsmart.com/) with Flick Stick
- Support usage of multiple controllers 
- Integrate shared preferences for settings
- Expanding gamepad peripheral compatibility
- Develop compatible Unity plugin for games
- Alternative connection options like Bluetooth
- Improve security and encryption for connection
- Additional mode to stream game contents

Community contributions are highly encouraged to make this project as accessible to game developers as possible.

## How to Contribute

To contribute to any of the previously mentioned repositories, please follow these steps:

1. Fork the repository of your choice
2. Create a new branch for your changes
3. Commit your changes to your branch
4. Push your changes to your fork
5. Open a pull request to that repository

We will review your pull request and provide feedback or merge your changes as quickly as possible. If you have questions or need assistance, please do not hesitate to reach out. For problems with specific libraries, use the issue tracker of the respective repository. Feature suggestions can be discussed on the [issues page](https://github.com/devEnju/nx_gamepad/issues) of this one. Your input and help in improving this project are invaluable!
