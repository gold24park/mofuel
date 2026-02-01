# Fine Print

In order to create a Fine Print mod, we need a GD file in our mod's `scripts` folder for each fine print we'd like to add. The content of the file must be as follows:

```
extends "res://Mod Data.gd"

func _init():
	mod_type = "fine_print"
	display_name = ""
	text = ""
	effects = []
```

Let's say we want to create fine print that destroys a random Pepper item. We can do so with the following:

```
extends "res://Mod Data.gd"

func _init():
	mod_type = "fine_print"
	difficulty = 0
	display_name = "Fine Print #1"
	for_items = true
	relevant_type = ""
	relevant_group = "item_pepper"
	text = "<dynamic_item_pepper> is <text_color_keyword>destroyed<end>."
	effects = [{"comparisons": [{"a": "type", "b": "dynamic_item"}], "value_to_change": "destroyed", "diff": true}]
```

The `difficulty` variable determines if the fine print can appear on apartment floors lower than floor 15. If the `difficulty` is `1`, the fine print cannot appear on apartment floors lower than floor 15. 

The `display_name` variable is just displayed in the Mods menu when the player is deciding if they want to toggle the fine print within the mod. `localized_names` can also be used.

The `for_items` variable _must_ be set to `true` if our fine print affects items. The fine print will not function properly otherwise.

The `relevant_type` variable is used if we want to only affect a single static type of symbol or item. Since we want to pick a random pepper out of the `item_pepper` group, we'll leave this variable as an empty string.

The `relevant_group` variable is used if we want to affect a single random type of symbol or item from a group. This variable being set to `"item_pepper"` means the fine print will randomly pick a Pepper in the player's inventory to affect when the landlord adds the fine print.

The `text` variable determines the fine print's description text. The `<dynamic_item_pepper>` tag will be replaced with the Pepper that is randomly selected when the landlord adds the fine print. `<dynamic_>` can also be used with symbol groups if our fine print affects symbols instead of items. Like so: `<dynamic_hex> is <text_color_keyword>destroyed<end>.`

We can also add to a `localized_text` dictionary if we'd like.

Lastly, the `effects` array will function the same as the `effects` array in a symbol, item, or email. Of note, `"dynamic_item"` or `"dynamic_symbol"` can be used in the `comparisons` array and will be replaced with item or symbol the fine print randomly selected.

Also, if we want to test all the fine print we've made, we can make sure `"fine_print": true` is in our [sandbox file](https://github.com/TrampolineTales/LBAL-Modding-Docs/wiki/Tutorial-1.3:-Testing-in-the-Sandbox). This will make the sandbox load with an email that adds all the modded fine print that isn't disabled.