# Making a Custom Symbol

Within our mod there are three directories: `art`, `scripts`, and `sfx`. For now, we just want to focus on `scripts`.

Once we move into the `scripts` folder, we'll see a file named "`script.gd`" that the Mod Uploader automatically created for us.

This script can be renamed without any issues, so long as the `.gd` extension remains.

Each file in the script directory corresponds to a symbol or item. The script itself is what assigns values and logic to a symbol or item.

We'll want to edit the file with our text editor of choice. For the sake of this tutorial, we'll be using [Notepad++](https://notepad-plus-plus.org/).

By default, the script file will look like this:

```
extends "res://Mod Data.gd"

func _init():
	mod_type = ""
	type = ""
	inherit_effects = false
	inherit_art = false
	inherit_groups = false
	inherit_description = false
	display_name = ""
	localized_names = {}
	value = 0
	description = ""
	localized_descriptions = {}
	values = []
	rarity = "none"
	groups = []
	effects = [
	{"comparisons": [{"a": "destroyed", "b": true}], "value_to_change": "value_bonus", "diff": 5},
	{},
	{}
	]

```

(You should never modify the first three lines of a script file, the engine won't accept any mods without those three exact lines)

We'll be going over each of these variables in more detail over the course of these tutorials. For now, we'll be focusing on just a few: `mod_type`, `type`, `display_name`, and `value`.

`mod_type` lets the game know what kind of mod our script file is. Since we're making a custom symbol, we want the line to look like this: `mod_type = "symbol"`

`type` is an identifier that can be referenced by other symbols and items. We want this to be unique from any other mods we create. We'll have the line look like this: `type = "cool_symbol"`

`display_name` is a String that is displayed to the player. It should be a human-readable version of the `type` variable. We want the line to look like this: `display_name = "Cool Symbol"`

`value` is the base amount of coins that a symbol will give when it appears in a spin. We want our symbol to give 5 coins, so the line needs to look like this: `value = 5`

After saving our script file, we'll test our symbol in the Sandbox to make sure everything works properly.

We'll demonstrate how to do that in the next tutorial:

[Tutorial: Testing in the Sandbox](https://github.com/TrampolineTales/LBAL-Modding-Docs/wiki/Tutorial-1.3:-Testing-in-the-Sandbox)