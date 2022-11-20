# nx Gamepad

This project aims to be a proof of concept and generic implementation of every possible input event from a smartphone as a gamepad to a computer. Furthermore, it can be seen as an homage to my favorite console the Wii U, which in my opinion unfortunately never really lived to its full potential.

## Project Overview

The core of this project is written with the Flutter framework and heavily depends on the platform implementations to send input events from a connected gamepad to a server as shown in the diagram below:

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

The input events are sent via UDP over Wi-Fi from either the *FlutterClient* or the *PlatformClient* to the *GameServer*. The *FlutterClient* is also able to communicate with a dedicated platform, but is supposed to be limited to setting a local address and changing the brightness of the device with information on the success of these actions. Settings are planned to be stored via shared preferences and should also only be updated with a method channel call to fetch all settings on the platform at once. Input events from the *PlatformClient* to the *FlutterClient* are able to be subscribed to, with a yet to be programmed event channel.

 - Flutter method channel to `set` and `reset` a local address
 - Flutter method channel to `toggle` screen brightness to save battery and do not cause burn-ins
 - Flutter method channel to `update` all settings like turning off gyro data packets
 - Platform informs Flutter about the success of those method channels
 - Flutter event channel to also `receive` specific input events as a stream

This will theoretically ensure to only need to integrate each platform once and keep the development of the user interface interaction and state within the bounds of the Flutter framework. Therefore, the *GameServer* also strictly communicates with the *FlutterClient* about the connection setup and state changes or updates. The specifications of input events as sent from the *FlutterClient* to a *GameServer* can be seen in the following table:

|       Bitmask|    Event Data| Data Type|Sent from|Information|
|-------------:|:------------:|---------:|--------:|:----------|
|`0b_0000_0xx1`|         touch|     `n/a`|  Flutter|Touch events are used in order to establish a connection and update the client's state. See the other two tables for a breakdown of the recommended touch event packet protocol.|
|`0b_0000_0010`|          gyro|`3x Float`| Platform|Gyroscope events are constantly sent as x, y, z, 100 times per second, if available, turned on, and if a connection has already been established.|
|`0b_0000_0100`|        button| `1x Char`| Platform|Both key down and up events are sent whenever a digital button is pressed or released. For further information look at the list for the different character key button bindings.|
|`0b_0000_1000`|          dpad| `1x Byte`| Platform|Dpad events are broken down into four bits in the order of north, south, east, west, and only two can be activated at a time.|
|`0b_0001_0000`| left joystick|`2x Float`| Platform|Joystick events are only sent when one is moved, and an event is broken down into x and y.|
|`0b_0010_0000`|right joystick|`2x Float`| Platform|Joystick events are only sent when one is moved, and an event is broken down into x and y.|
|`0b_0100_0000`|  left trigger|`1x Float`| Platform|Trigger events are only sent as z when one gets moved.|
|`0b_1000_0000`| right trigger|`1x Float`| Platform|Trigger events are only sent as z when one gets moved.|

Touch events on the *FlutterClient* can vary widely and should issue action requests in order to update the state whenever it is needed. The following tables show how the first three bits are reserved in order to allow for proper synchronizations between a client and server:

### Client

|Bitmask Byte [0]|Byte [1]|  Message|Description|
|---------------:|-------:|:-------:|-----------|
|       `0b_0001`|     `x`|   action|Sends individual data to a server in order to get a new state. The `x` marks what action needs to be performed on the server, so that each one can have different amounts of additional bytes.|
|       `0b_0011`|   `n/a`|broadcast|The client should send a unique code after the bitmask as a broadcast, which should only be recognised by one specific game, and then wait for the answers from different compatible servers in the local network.|
|       `0b_0101`|     `x`|    state|This bit sequence tells the server to send all necessary information for the requested state and signals it to be changed. Each value for `x` stands for an individual state and could be interpreted as a specific user interface.|
|       `0b_0111`|     `x`|   update|The last bit sequence from a client toggles a frequent update stream for single purpose widgets on or off. The `x` tells which update is meant and should be used, if updating the whole state of a user interface is too expensive.|

### Server

|Bitmask Byte [0]|Byte [1]|Message|Information|
|---------------:|-------:|:-----:|-----------|
|       `0b_0001`|   `n/a`|   info|After receiving a broadcast, the server can send some information more relatable than just the address to the client in order to tell that it is available.|
|       `0b_0010`|   `n/a`|   quit|The server can quit the connection to a client and add additional information for its reason.|
|       `0b_0100`|     `x`|  state|Answer to a specific state change request with the same `x` value as a response and all other necessary additional bytes to build a new user interface from scratch.|
|       `0b_0110`|     `x`| update|Frequent stream of data to a specific widget, with `x` as a label to the specific update, and the latest bytes required to change it.|

The *HomePage* of the *FlutterClient* deals with all incoming UDP messages from a server with streams, and redirects state changes to a separate stream onto the *GamePage*. In order to have a better separation between business logic and views, streams should probably be in their own class, as individual updates need to be funneled through the *HomePage* to the specific part of *GamePage* layout.

Furthermore, it is recommended to have a new layout for each state to easily update everything at once. Specific actions, states, and updates have to be implemented on the server side to only send a response, if the current active state on the server allows for it. This should easily be achievable with the state pattern.

Input events from the dpad, joysticks, and triggers are put together into a single packet, as on the Android platform they are all processed at once. This might not be the case for iOS and Linux but it means that the server has to check for all of these events in one cycle, so that a packet consisting of both left and right joystick events for example, would have `0b_0011_0000` as the first byte and 16 additional bytes for the 4 floating point values. Lastly, the following list shows all key button events mapped to their specific character which can be received on a server:

|     Button| down|   up|
|:---------:|:---:|:---:|
|          A|`'a'`|`'A'`|
|          B|`'b'`|`'B'`|
|          X|`'x'`|`'X'`|
|          Y|`'y'`|`'Y'`|
|          L|`'l'`|`'L'`|
|          R|`'r'`|`'R'`|
| Left Thumb|`'t'`|`'T'`|
|Right Thumb|`'z'`|`'Z'`|
|     Select|`'c'`|`'C'`|
|      Start|`'s'`|`'S'`|

## Considerations & Limitations

Flutter is a great tool to create two dimensional user interfaces but also comes with some downsides. In order to highlight them and why I think it is still superior to something like a fully fledged game engine like Unity boils down to the ease of development, great first party support for mobile, and because everything is open source. Unfortunately, it is really cumbersome to implement anything requiring three dimensional models or anything else in this regard. I honestly do not think it is that big of an issue, since I would not recommend to have another scence rendered onto the mobile device anyway, but it is definitely something to keep in mind before starting to use the project.

I have also debated whether the gamepad connection to the computer should run over Bluetooth, but there are a couple of reasons why I decided against it. The discontinued Stadia controller from Google and any other cloud based gaming device is one of them, since they perfectly show that gaming via a UDP based internet connection is feasible, and so should be a local network. Another reason are video streams which go in hand with the cloud gaming example as they would not be feasible to be sent via Bluetooth, and should in theory not be too difficult to implement with Flutter. The last one is the Wii U gamepad itself, which already proved to be quite reliable over its special Wi-Fi signal, but to sum it up, that does not necessarily mean a Bluetooth connection might never be a choice for this project, which brings me to the outlook.

## Outlook

There could very well be an alternative connection option, if the local network does not allow for a stable or any Wi-Fi connection at all. At this stage it is a low priority but could very well be put on the roadmap, depending on the demand.

As already mentioned there is still some work to do in regards to the event channel for input events from a platform to Flutter. The shared preferences for settings are also really important but taking the feedback from [my first showcase](https://redd.it/yxw2wa), a Linux implementation for the Steam Deck might be the most anticipated addition, next to the implementation of iOS as another platform, in order to complete this demo.

For now, everything has just been tested with the v1 Kishi controller from Razer for Android, so other gamepad peripherals might either work or still need some extra care in order to do so properly. I am specifically referring to joystick ranges, which are mentioned in the official [Android documentation for controller actions](https://developer.android.com/develop/ui/views/touch-and-input/game-controllers/controller-input#joystick). They did not need to be implemented in my case but are probably good to have as a best practice in the long run. Moreover, tests are something I completely neglected in this demo but are really important for the overall health of an open source project like this. All streams would definitely need to be pulled out from the *HomePage* and *GamePage* to be able to properly test them.

I am depending on your contribution to make this project as accessible to game developers as possible, to not only have a mod for Minecraft but maybe even official implementations for other games.

Two things could be especially interesting to work on. Security and encryption are not my strengths but might be needed for extra reliability. In additon, I have rudimentarily decided to run everything over just one port but this might not be the best choice, as it could backfire in case the port is not available on one of the devices and makes local testing with only one device impossible.

The last feature I would also be really excited to implement, is the addition of gyro controls with Flick Stick. When I started this project, I immediately thought about bringing Splatoon control schemes to this project and luckily stumbled upon Flick Stick over the course of my research. I highly recommend checking out the [documentation from Jibb Smart about great gyro controls](http://gyrowiki.jibbsmart.com/), as this could bring even more quality to the project in a whole but might be more on the server side.

For legal reasons, I am unable to release my changes to the source code of Minecraft but I hope this repository presents the general idea on how the data flows between a game and mobile device, so you would have all the building blocks to start and embed controls in form of a mod.

## How to Contribute

Feel free to leave a pull request and I will try to give my feedback or accept it as quick as possible. Please be aware that this is my first attempt of an open source project but am really eager to get your help and input on it.