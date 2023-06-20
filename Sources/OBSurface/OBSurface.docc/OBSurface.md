# ``OBSurface``

A SwiftUI application that dynamically arranges/tiles/crops OSB sources inside a scene.
Operates OBS from a MIDI control surface.


## Overview

OBSurface is a purpose-built application to help record instructional
videos that switch between a number of different screen capture
sources. Rather than use a different scene for each permutation of
inputs, OBSurface programmatically manages the position and scale of
sources.

OBSurface (and indirectly: OBS itself) may be operated using a
connected MIDI control surface. Using the MIDI surface does not change
window focus, making it fast and easy to control OBS with few
side-effects.

### Dynamic source placement

Each source can be toggled on or off (using the top row of the controller)
or made primary (using the bottom row of the controller).

The primary source is scaled to fill the output (see "sizing/crop" below for
how that is set up); the other visible sources are scaled
down and tiled on the right. 


### Window sizing/crop

To minimize aliasing, I generally want to capture windows at 1:1. One
application source always scales 2:1, so I capture at 1:2. There is also a
variable scale that can be adjusted with the surface's rotary encoder.

The "setCrops" command sets the window crop to achieve the desired scale. It
also has a configurable crop offset to skip the title bar or tool ribbons to
increase the content capture.

After the OBS capture of the window has been configured, I open the application
and manually size/place it on the workspace to fit the content I hope to capture.
The windows generally live at the top left of my screen, which is closest to
my primary camera and leaves the remaining screen area for notes and scratch.


### Application Launcher

I found it very difficult to remember to tell the recording software when I
change application focus. I sort of want a "source follows focus" function
where the tiling is adjusted when I change applications, but (1) an application
with permissions to read/manage the screen is more work to audit, and (2) I want
to be more deliberate about the changes to the recording.

As a solution, I use the surface to raise the application when I make it the
primary source. The MIDI controller acts as my task switcher. This pattern
is explicit about intent but doesn't require any coordination.

It calls the system "open" command, which does not require special permissions.


### Scripting/MIDI control

For a couple of other functions, I use the surface to route simple messages to
OBS:

- toggle record (and monitor record status on LED)
- simple toggle scene (for the whiteboard function)
- adjust/monitor input level (this is just an exercise in controls)




## Experience/Environment

Not only does OBS provide all the features that make this application feasible,
its rich capabilities inspired this workflow.

There are a few techniques that do not need support from OBSurface,
but can be set up completely within OBS Studio. These have been
particularly useful in this instructional environment:

### Whiteboard/Lightboard

I use a document camera with a small whiteboard and some vibrant dry-erase
markers to implement a screen annotation mechanism.

- <doc:VisualMarkup>

### Telepromper

OBS window capture and the source "flip horizontal" transform are
useful for driving a teleprompter. This is useful in both recording
sessions and in interactive videoconferencing meetings.

- <doc:Teleprompter>

###  MIDI

MIDI is kind of amazing for an automation controller: events are published to
all applications that ask for them, so the surface can easily be shared by
applications and even have events be overloaded.

The MIDI controller doesn't have any focus pattern, so events get to the
appliction even if a different application has focus, mode, etc.

## Running a SwiftUI app built from Swift Package Manager

This distribution of OBSurface is as a Swift Package Manager package.

It will build and run via both Xcode and the command line, but
with Xcode 14.3/macOS 13.4, the application seems to want a little more
environment to work properly. Symptomatically, the application inherits its
windows from its parent, so there is difficulty switching to the application.
Most importantly, the application menus and the settings shortcut keys
are not plumbed for the application.

To work normally, it appears the application needs to be launched as if it
were a full application. No bundles, resources, plists, signing, etc. is
needed: it simply needs to have the directory structure of an application.

From somewhere (I go into the build directory, but this gets erased on clean):

```
mkdir -p OBSurface.app/Contents
ln -s ${PARENT_OF_EXECUTABLE} OBSurface.app/Contents/MacOS
```

Then use "open -a OBSurface.app" or edit the Xcode Product Scheme
and change the Run target Executable (in the Info tab) to the .app
directory made above. Xcode will launch and attach to the executable
normally, and the executable will function as an independent app with
its own windows and shortcut keys.


## Topics

### Articles

- <doc:VisualMarkup>
- <doc:Teleprompter>

### Interfacing with OBS

- ``StudioModel``
- ``SourceSwitcherView``
- ``OBSurface/OBSurface``

### MIDI support

- ``SurfaceController``

### Managing geometry

- ``FrameTrim``
- ``ManagedSource``

