# Value Text

Some symbols have reminder texts that are displayed alongside them, such as Thief:

![](https://raw.githubusercontent.com/TrampolineTales/LBAL-Modding-Docs/main/images/thief_reminder_text.png)

The yellow number represents the number that will be added to Thief's `value_bonus` when the symbol is destroyed, in this case, `4`.

We actually want to give Cool Symbol reminder text that is very similar to that of the Thief symbol. To achieve this, we'll start by adding a `value_text` variable to our script file:

```
extends "res://Mod Data.gd"

func _init():
	mod_type = "symbol"
	type = "cool_symbol"
	inherit_effects = false
	inherit_art = false
	inherit_groups = false
	inherit_description = false
	display_name = "Cool Symbol"
	localized_names = {}
	value = 5
	description = ""
	localized_descriptions = {}
	value_text = {}
	values = []
	rarity = "none"
	groups = []
	effects = [
	{"comparisons": [{"a": "destroyed", "b": true}], "value_to_change": "value_bonus", "diff": 25},
	{"effect_type": "adjacent_symbols", "comparisons": [{"a": "type", "b": "coin"}], "value_to_change": "destroyed", "diff": true, "anim": "bounce", "anim_targets": "adjacent_symbol"},
	{"effect_type": "adjacent_symbols", "comparisons": [{"a": "type", "b": "cat"}], "value_to_change": "permanent_bonus", "diff": 2, "anim": "circle", "anim_targets": "adjacent_symbol"},
	{"value_to_change": "permanent_multiplier", "anim": "shake", "diff": {"starting_value": 2, "var_math": [{"+": "times_displayed"}]}},
	]
```

The actual line that the `value_text` is on doesn't matter (so long as it's indented and after `func _init():`), in this case, we put it on the line just after `localized_descriptions`

Let's make the reminder text display double the number of times Cool Symbol has been displayed. To do this, we'll assign the following to `value_text`:

`value_text = {"color": "symbol_reminder_up_text", "value": {"starting_value": 2, "var_math": [{"*": "times_displayed"}]}}`

Let's break this down.

The `"color"` variable has to be a string. It either needs to be a six-character hex code (`"color": "FF0000"` would be red, for example) or one of the modifiable colors in the settings.

The full list of modifiable color identifiers can be found on this page: [Color Index](https://github.com/TrampolineTales/LBAL-Modding-Docs/wiki/Color-Index).

Using a modifiable color identifier is highly recommended and good practice. Many players modify their reminder text colors to make the contrast easier on the eyes, so forcing, say, `"color": "FFFFFF"` on a player is highly discouraged.

The `"value"` variable works identically to the way "`diff`" does in the sense that it can be passed an Int/Float, or a `var_math` Dictionary. Because of this, we know that the reminder text will be equal to `2 * times_displayed` or "Double the number of times the symbol has appeared."

Based on our script file, which should currently look like this...

```
extends "res://Mod Data.gd"

func _init():
	mod_type = "symbol"
	type = "cool_symbol"
	inherit_effects = false
	inherit_art = false
	inherit_groups = false
	inherit_description = false
	display_name = "Cool Symbol"
	localized_names = {}
	value = 5
	description = ""
	localized_descriptions = {}
	value_text = {"color": "symbol_reminder_up_text", "value": {"starting_value": 2, "var_math": [{"*": "times_displayed"}]}}
	values = []
	rarity = "none"
	groups = []
	effects = [
	{"comparisons": [{"a": "destroyed", "b": true}], "value_to_change": "value_bonus", "diff": 25},
	{"effect_type": "adjacent_symbols", "comparisons": [{"a": "type", "b": "coin"}], "value_to_change": "destroyed", "diff": true, "anim": "bounce", "anim_targets": "adjacent_symbol"},
	{"effect_type": "adjacent_symbols", "comparisons": [{"a": "type", "b": "cat"}], "value_to_change": "permanent_bonus", "diff": 2, "anim": "circle", "anim_targets": "adjacent_symbol"},
	{"value_to_change": "permanent_multiplier", "anim": "shake", "diff": {"starting_value": 2, "var_math": [{"+": "times_displayed"}]}},
	]
```

...Cool Symbol should look like this (after the first spin):

![](https://raw.githubusercontent.com/TrampolineTales/LBAL-Modding-Docs/main/images/cool_symbol_reminder_text.png)

The `2` is added via `value_text`, the `3x` is added via the 4th effect in `effects` (`{"value_to_change": "permanent_multiplier", "anim": "shake", "diff": {"starting_value": 2, "var_math": [{"+": "times_displayed"}]}}`).

In the next tutorial, we'll go over how to add art to Cool Symbol:

[Tutorial: Art](https://github.com/TrampolineTales/LBAL-Modding-Docs/wiki/Tutorial-1.7:-Art)