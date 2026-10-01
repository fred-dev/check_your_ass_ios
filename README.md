# BackCheck

An iPhone app for checking your back (or any angle you can't see) without a mirror. Prop the phone up, pick a timer, turn around, and it records a few seconds of video. Then drag across the screen to scrub back through the frames and find the one you need.

## Using it

- **Timer buttons** (2 or 5 seconds): counts down with a beep each second, quicker beeps in the last second and a tone when recording starts, like the iOS camera timer.
- **Capture**: starts recording straight away.
- **Switch camera**: front or back camera. The front camera is shown mirrored, the back camera as-is, both live and in playback.
- Records about 200 frames (around 7 seconds), then switches to playback. Drag left and right to scrub; double tap to go back to the live view.
- Works in any orientation. Rotating during a countdown or recording is applied once it finishes.

## Build

- openFrameworks 0.12 or later with ofxiOS
- Addon: `ofxMSAInteractiveObject`
- Generate an iOS project with projectGenerator, open it in Xcode, set your signing team and run it on a phone. Camera access is requested on first launch.
- Assets are in `bin/data`: button icons, timer sounds and the interface font (`gui_resources/Gaultier-Regular.ttf`, not included in the repo; add your own or any TTF with that name).

Originally made in 2013 for OF 0.7; rewritten in 2026 for current openFrameworks.
