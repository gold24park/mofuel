# Effects

Now we'll make our Cool Symbol do some Cool Effects. Let's say we want our symbol to destroy all the Coin symbols adjacent to it. We do so by adding to the `effects` Array.

It by default, looks like this:

```
effects = [
	{"comparisons": [{"a": "destroyed", "b": true}], "value_to_change": "value_bonus", "diff": 5},
	{},
	{}
	]
```

Let's break down what the first Dictionary (a series of Key/Value pairs wrapped in {Curly Braces}) currently contains.

`"comparisons"` contains an Array of conditionals that the game will check. If they're all `true`, the effect will trigger. If any of them are `false`, the effect will not trigger. This example comparison checks if the symbol is `destroyed`. We don't need to touch it for now.

`"value_to_change"` contains a String that lets the game know which variable to modify when the effect triggers. The variable is currently `"value_bonus"`, which adds to the symbol's value this spin. If we ever want to increase a symbol's value for a spin without modifying its base value for the rest of the game, `"value_bonus"` is what we use.

`"diff"` is how much to modify the `"value_to_change"` by. Since our Cool Symbol is REALLY COOL, we should make it give 25 coins when `destroyed`, since it's an event that our Cool Symbol is no longer with us!

Our `effects` Array should look like this:

```
effects = [
	{"comparisons": [{"a": "destroyed", "b": true}], "value_to_change": "value_bonus", "diff": 25},
	{},
	{}
	]
```

The other two Dictionaries are just there to demonstrate that we can add more than one effect to our Array. There isn't a limit on how many effects can be in a script.

Back to our previously mentioned goal of making Cool Symbol destroy adjacent Coins, we want to add an effect that looks like this:

`{"effect_type": "adjacent_symbols", "comparisons": [{"a": "type", "b": "coin"}], "value_to_change": "destroyed", "diff": true}`

Let's break down what all this means.

`"effect_type"` is a String that determines what the effect is applied to. By default, the effect will be applied to the symbol or item that it originates from. In this instance, the effect is applied to all symbols that are adjacent to the originating symbol, since the `"effect_type"` is `"adjacent_symbols"`.

The `"comparisons"` in this instance check if the symbol's `type` is "coin". If we didn't include this comparison, the effect would cause our symbol to destroy every symbol adjacent to it!

The `"value_to_change"` in this instance is `"destroyed"` which becomes `true` thanks to our `"diff"`.

To recap, our effect basically can be read as "Adjacent symbols that are Coin symbols will have their destroyed value become true."

Our entire script file should now look like this:

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
	values = []
	rarity = "none"
	groups = []
	effects = [
	{"comparisons": [{"a": "destroyed", "b": true}], "value_to_change": "value_bonus", "diff": 25},
	{"effect_type": "adjacent_symbols", "comparisons": [{"a": "type", "b": "coin"}], "value_to_change": "destroyed", "diff": true},
	{}
	]
```

If we test this symbol in the Sandbox, we'll see that it destroys all the adjacent Coin symbols, just like we wanted!

![](https://raw.githubusercontent.com/TrampolineTales/LBAL-Modding-Docs/main/images/sandbox2.png)

In the next tutorial, we'll add some fancy effects to our Cool Symbol:

[Tutorial: Effects (Advanced Usage)](https://github.com/TrampolineTales/LBAL-Modding-Docs/wiki/Tutorial-1.5:-Effects-(Advanced-Usage))