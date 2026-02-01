# Testing in the Sandbox

The Sandbox is a powerful tool that allows us to test any symbol or item mod we've created (as well as any existing symbols and items).

In order to access the sandbox, we need to modify the `LBAL-Sandbox-Data.save` file. It can be found in the following directory:

Windows: `%USERPROFILE%/AppData/Roaming/Godot/app_userdata/Luck be a Landlord/LBAL-Sandbox-Data.save`

macOS: `~/Library/Application Support/Godot/app_userdata/Luck be a Landlord/LBAL-Sandbox-Data.save`

Linux: `~/.local/share/godot/app_userdata/Luck be a Landlord/LBAL-Sandbox-Data.save`

We'll open the file with our text editor, which by default, should look like this:

```
{"sandbox": false, "fine_print": false, "sandbox_consistent": true, "apartment_floor_type": null, "apartment_floor_num": 1, "coins": 1, "reroll_tokens": 0, "removal_tokens": 0, "essence_tokens": 0, "items": []}
{"symbols1": ["coin", "coin", "coin", "coin", "coin"]}
{"symbols2": ["coin", "coin", "coin", "coin", "coin"]}
{"symbols3": ["coin", "coin", "coin", "coin", "coin"]}
{"symbols4": ["coin", "coin", "coin", "coin", "coin"]}
```

Making the `"sandbox"` variable `true` instead of `false` will force the game to load specific symbols and items when we press "Start" on the title screen.

Each "symbols" Array corresponds to a row of symbols in the slot machine. Since we have 4 rows of 5 coin symbols, the sandbox will look like this:

![](https://raw.githubusercontent.com/TrampolineTales/LBAL-Modding-Docs/main/images/base-sandbox.png)

Since we want to test the symbol we created in the [previous tutorial](https://github.com/TrampolineTales/LBAL-Modding-Docs/wiki/Tutorial:-Making-a-Custom-Symbol), we'll replace one of the coins with our symbol's `type`: `"cool_symbol"`

```
{"sandbox": false, "fine_print": false, "sandbox_consistent": true, "apartment_floor_type": null, "apartment_floor_num": 1, "coins": 1, "reroll_tokens": 0, "removal_tokens": 0, "essence_tokens": 0, "items": []}
{"symbols1": ["coin", "coin", "coin", "coin", "coin"]}
{"symbols2": ["coin", "coin", "cool_symbol", "coin", "coin"]}
{"symbols3": ["coin", "coin", "coin", "coin", "coin"]}
{"symbols4": ["coin", "coin", "coin", "coin", "coin"]}
```

Now the sandbox will look like this:

![](https://raw.githubusercontent.com/TrampolineTales/LBAL-Modding-Docs/main/images/sandbox1.png)

Our symbol gives 5 coins and has the display name of "Cool Symbol" just like we wanted!

By default, the symbol's texture will be a pink question mark. We'll create some art for our symbol in a later tutorial.

In the next tutorial, we'll make our Cool Symbol destroy some of those Coin symbols:

[Tutorial: Effects](https://github.com/TrampolineTales/LBAL-Modding-Docs/wiki/Tutorial-1.4:-Effects)