Look, Don't Touch
---

This Lua module for Defold ensures selected "game.project" settings keep their
expected values by reading from inside the bundle, inhibiting the extraordinary
tampering Defold allows if players edit "game.projectc".

Called as a function, it constructs a new .projectc-formatted file from the
developer's desired constants and the user's desired configuration, then reboots
the game using the merged config. The file exposes the same settings as before
("look"), but in an unassuming hidden file called ".projectc" that has no effect
on the game if edited ("don't touch").

Setup:
1. Include this module & "inifile" with your project, and add "look_dont_touch"
to a script at game start with "require()"
2. Create a ".lua" file that returns an empty table for saving project constants;
if the project has been bundled before, Look Don't Touch fills the table in debug
3. A table in "look_dont_touch.lua" named "lookup" defines configurable settings;
it includes common game options, maybe missing some troubleshooting/compatibility
5. Call the module as a function; it returns `true` if successful
```lua
look_dont_touch(consts_path, consts_table, passkey)
  -- consts_path = path string to save the constants module
  -- consts_table = the constants module
  -- passkey = the body of a "--config=" argument, like "bootstrap.rebooted=true"
```
The constants table only picks up changes when running the project in debug,
after bundling the project at least one time with the correct settings.

The "game.projectc" file may be tidied up by deleting unwanted categories or
keys. Note: *Defold still requires file paths if it cannot resolve an
alternative.* For example, if the "main_collection" key is omitted, Defold
looks for it at the engine default value: "/logic/main.collectionc"
