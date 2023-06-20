# Visually Marking Up Content with OBS

Use a document camera and chroma key filter to annotate content.

## Overview

My presentation style includes annotating content by drawing on top of it.
This setup is a relatively simple way of incorporating annotation into
my lecture recording workflow.

I use a document camera with a small whiteboard, vibrant dry-erase
markers, and the OBS chroma key filter to implement a screen annotation
overlay. The effect is similar to a lightboard. The physical markers have
natural haptics, and the visibility of the marker tip in the overlay
allows registration with content.

### Wish list

- use a stylus-like instrument for familiar precision
- can see drawing implement before drawing
  - registration isn't an issue: get feedback to position (sorta)
  - can use as pointer and not simply as annotation instrument
- avoid distraction of seeing hand


## Implementation


### Camera

Considerations:

- document camera should have decent response time/fps
- record in resolution that matches output resolution

Continuity Camera may be even lower cost (depending on mounting)


### Whiteboard

In the first iteration, I used markers on printer paper. This is
reasonably functional, but has a few limitations:

- I needed to keep the camera pretty close to fill its field with the paper
- the smaller field made it more likely I obscured annotations during drawing
- paper moves easily, ruining registration

In the current iteration, I am using a small dry-erase board. I added some
foam stand-offs on the back to keep it from sliding on the desk, to make it
more comfortable, and to help it maintain alignment with the camera.


### OBS Settings

Chroma Key

- Key Color Type: Custom Color
- Key Color: #f4ffe4
- Similarity: 103
- Smoothness: 1
- Key Color Spill Reduction: 1
- Opacity: 1.0
- Contrast: 0.0
- Brightness 0.0
- Gamma: 0.0

Color Correction

- Gamma: 0.62
- Contrast: 0.68
- Brightness: 0.0813
- Saturation: 0.53
- Hue Shift: 0.00
- Opacity: 1.0000
- Color Multiply: #ffffff
- Color Add: #000000

### OBSurface support

OBSurface has hardcoded support for a "Whiteboard" source. This is
simply kept in the foreground (ahead of other managed sources) and
visibility toggled.

On the MIDI surface, the rightmost rotary encoder has worked well for
toggling the whiteboard (the whiteboard is to the right of the
control).


## Experience

Overall, this has worked extremely well.

### Shortcomings

- some shimmering
- hand bleed-through
- brain is sensitive to orientation of camera: if angle doesn't match screen, it's hard to position things
- while it's easy to orient start of stroke, mapping of continued stroke is harder
- chroma settings are moderately dependent on ambient light conditions
- existing markings can be obscured during drawing

### Strengths

- can overlay any part of OBS-managed output
- physical erase/edit is really easy
- doesn't change focus on the computer, so it's easy to continue working with applications


## Alternatives

### Lightboard

- glass surface
  - cool
  - requires lots of room
  - expensive materials
  - complicated build
  - not fantastic for mixing media

### drawing-based annotation tools

- low sample rate makes annotations angular
- trackpad is not as good as mouse for drawing (pressing on surface increases friction for drawing)
- common OBS pattern is to overlay drawing on content: has registration problem
- focus must be in annotation window; switching back and forth between content and annotation is hard
