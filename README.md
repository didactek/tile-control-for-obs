# tile-control-for-obs

A Swift application that programmatically arranges/tiles/crops/toggles
OBS Studio sources in a scene. Operations from either its SwiftUI interface
or a MIDI surface controller are sent to OBS Studio via websockets.

## Overview

This tile-control-for-obs SPM package provides OBSurface, which is a
purpose-built application to help record instructional videos.
 
These videos cycle between some number of different cameras and screen
capture sources/applications. Rather than use a manually-configured
scene for each permutation of inputs, OBSurface programmatically manages the
position and scale of sources.

OBSurface also provides MIDI control and feedback for the
above source management, and for record/pause.

## Associated libraries

- [obs-websocket-client](https://github.com/didactek/obs-websocket-client)
- [deft-midi-control](https://github.com/didactek/deft-midi-control)

## Features

- dynamic source placement within a scene
- support for setting source crops and scale
- MIDI control/feedback with a Behringer X-touch mini Mackie-mode MIDI controller
- raising applications when primary source is changed
- other OBS control, such as for record/pause

## Documentation

- [DocC for OBSurface](https://didactek.github.io/tile-control-for-obs/OBSurface/documentation/obsurface)


### Using OBS

See the documentation for articles describing how OBS Studio has proved
useful in this application:

- Visually Marking Up Content with OBS (whiteboard/lightboard)
- Managing a Teleprompter with OBS

## Acknowledgments

This work is obviously built on the incredibly useful,
inspiring, and open source [OBS Studio](https://obsproject.com).
I cannot imagine online teaching without it.
