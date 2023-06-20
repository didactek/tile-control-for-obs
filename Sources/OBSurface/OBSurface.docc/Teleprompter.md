# Managing a Teleprompter with OBS

Using OBS to drive a teleprompter for recording sessions or interaactive
videoconferencing meetings.

## Teleprompter

I have a scene that takes my record output and flips it horizontally. I preview
this on a second monitor that is a small LCD panel under a teleprompter.
The flip filter compensates for the mirror (and the fact that neither my
panel nor macOS will do a screen *flip*, though both do screen rotations).


## Setup

I use the same, single "Teleprompter" scene for recorded and
interactive sessions.  I enable depending on use.

For recording, the only source is the "SurfaceTiled" scene that I
manage with OBSurface.

For videoconferences, there is a collection of captured and filtered
windows.

Each source is given a "flip horizontal" transform to adapt to the
teleprompter mirror.

The scene is then displayed on the teleprompter panel using either a
fullscreen or windowed Scene Projector.

### Video

- capture Zoom windows
- filter out backgrounds from chat and participant list; overlay these on camera preview

### Sources

- Zoom windows


