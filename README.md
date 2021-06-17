# hammerspoon-mouse-wheel-autoscroll
Hammerspoon config snippet to enable autoscroll with mouse wheel button.
Makes a wheel on a normal mouse or a trackball actually useable with a mac.

When mouse wheel button is pressed and mouse moved, toggles interactive scrolling of top-most window (4 directions).
Retains mouse wheel button press if button pressed and released within the deadzone.
The further the mouse will be moved from the centre of the "click", the faster the scroll will be.

# Rudimentary setup:

- `local mouseScrollButtonId = 2`
  - KeyID of the mouse button to use scrolling with. `2` is mouse wheel button

- `local scrollSpeedMultiplier = 0.15`
  - scrolling speed multiplier for the distance from the centre of the "click"
- `local scrollSpeedSquareAcceleration = false`
  - whether scroll speed is exponential (squared) or linear depending on the distance from the centre of the "click"
- `local reverseVerticalScrollDirection = false`
  - `false` for scrolling up when mouse is moved up, etc.; `true` for scrolling up when mouse is moved down, etc.
- `local mouseScrollTimerDelay = 0.01`
  - how often scroll events are sent

- `local mouseScrollCircleRad = 10`
  - radius, in pixels, of the scrolling circle
- `local mouseScrollCircleDeadZone = 5`
  - deadzone, radius in pixels, where mouse can be moved and when released a normal mouse wheel button click will register. Scrolling will not start in deadzone to prevent jitter and allow easy mouse wheel button clicks

# Installation
- install hammerspoon from http://www.hammerspoon.org/
- click the hammerspoon menubar icon, click `Open Config`
- add contents of the `config snippet.lua` file to your hammerspoon config
- click the hammerspoon menubar icon, click `Reload Config`
- press and hold the mouse wheel button, and move the mouse
