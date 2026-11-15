# Time Out Web release

Upload `Time-Out-Web.zip` as an HTML5 game on itch.io. The ZIP contains `index.html` at its root. For local testing, serve the contents of `web` using an HTTP server on localhost.

## Controls

- Left and right arrows move.
- Up jumps. Press it again in the air for a double jump.
- E or Enter interacts. A/D turns the clock dial.
- F1 toggles the controls guide. Esc returns to the menu.

## Build and verification

- Engine: Godot 4.7.2 stable.
- Export preset: Web, single-threaded, Compatibility renderer.
- The Godot resource pack was checked from the export directory.
- Browser-side WebAssembly playback was not verified. The browser automation session was stopped before it could launch the game.
- The menu music is the user-supplied MP3 named `hyde-indie-rock-arctic-monkeys-styled-instrumental.mp3`. Its redistribution license was not verified.
