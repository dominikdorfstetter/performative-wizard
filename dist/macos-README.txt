PERFORMATIVE WIZARD — macOS demo
================================

The app is ad-hoc signed (no Apple Developer ID), so the FIRST launch needs
one extra step on modern macOS:

1. Double-click "Performative Wizard.app".
   macOS will say it "could not verify" the app. Close that dialog.
2. Open  System Settings -> Privacy & Security,  scroll down, and click
   "Open Anyway" next to the Performative Wizard entry.
3. Confirm once. Every later launch works normally.

(On macOS 14 and older you can instead right-click the app and choose "Open".)

Notes
-----
- Your save lives in ~/Library/Application Support/Godot/app_userdata/.
  Runs checkpoint on the map; meta unlocks (Clout, wardrobe) always persist.
- Fullscreen: Cmd+Ctrl+F (or toggle it in Options). Pause: Esc.
- Feedback / bugs: https://github.com/dominikdorfstetter/performative-wizard/issues

Third-party notices: see THIRDPARTY.txt in this archive.
