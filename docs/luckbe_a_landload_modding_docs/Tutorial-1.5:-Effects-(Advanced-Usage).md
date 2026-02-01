# Effects (Advanced Usage)

We're going to have 3 goals that we'd like to complete by the end of this tutorial:

1. Let's spruce up Cool Symbol by adding some animations to its effects
2. Let's also have Cool Symbol make adjacent Cats permanently give 2 additional coins.
3. To make things even _more_ complicated, let's also have Cool Symbol increase its permanent multiplier by a number equal to the number of times Cool Symbol has appeared this game, plus 2.

To follow along, your Sandbox should be identical to this:

```
{"sandbox": true, "coins": 1, "reroll_tokens": 0, "removal_tokens": 0, "essence_tokens": 0, "items": []}
{"symbols1": ["coin", "coin", "coin", "coin", "coin"]}
{"symbols2": ["coin", "coin", "cool_symbol", "coin", "coin"]}
{"symbols3": ["coin", "cat", "cat", "reroll_capsule", "coin"]}
{"symbols4": ["coin", "coin", "coin", "coin", "coin"]}
```

### 1. Let's spruce up Cool Symbol by adding some animations to its effects

In order to do this, we need to make use of two variables `"anim"` and `"anim_targets"`:

`"anim"` can be added to an effect to make the originating symbol do 1 of 4 animations:

`"circle"`

![](https://raw.githubusercontent.com/TrampolineTales/LBAL-Modding-Docs/main/images/circle_anim.gif)

`"rotate"`

![](https://raw.githubusercontent.com/TrampolineTales/LBAL-Modding-Docs/main/images/rotate_anim.gif)

`"bounce"`

![](https://raw.githubusercontent.com/TrampolineTales/LBAL-Modding-Docs/main/images/bounce_anim.gif)

and `"shake"`

![](https://raw.githubusercontent.com/TrampolineTales/LBAL-Modding-Docs/main/images/shake_anim.gif)

There's also `"rand_texture_cycle"` and `"ordered_texture_cycle"` which can be used to cycle between other textures, like the Five-Sided Die and Golden Arrow symbols do, but that's beyond the scope of what we're doing right now.

For now, we'll make Cool Symbol bounce when it destroys an adjacent coin by updating our effects to look like this:

```
effects = [
	{"comparisons": [{"a": "destroyed", "b": true}], "value_to_change": "value_bonus", "diff": 25},
	{"effect_type": "adjacent_symbols", "comparisons": [{"a": "type", "b": "coin"}], "value_to_change": "destroyed", "diff": true, "anim": "bounce"},
	{}
	]
```

But wait a minute, something's not quite right when we test in the Sandbox...

![](https://raw.githubusercontent.com/TrampolineTales/LBAL-Modding-Docs/main/images/wrong_coin_anim.gif)

The Coins are animating instead of Cool Symbol! But actually, this makes sense based on this effect:

`{"effect_type": "adjacent_symbols", "comparisons": [{"a": "type", "b": "coin"}], "value_to_change": "destroyed", "diff": true, "anim": "bounce"}`

Since we have the `effect_type` of `"adjacent_symbols"`, the `anim` is being applied to to the Coin, just like how the `value_to_change` is.

A simple workaround in this situation is to use `anim_targets`:

`{"effect_type": "adjacent_symbols", "comparisons": [{"a": "type", "b": "coin"}], "value_to_change": "destroyed", "diff": true, "anim": "bounce", "anim_targets": "adjacent_symbol"}`

Having the variable be `"adjacent_symbol"` will make the Coin and Cool Symbol bounce in tandem, just what we wanted!

![](https://raw.githubusercontent.com/TrampolineTales/LBAL-Modding-Docs/main/images/right_coin_anim.gif)

### 2. Let's also have Cool Symbol make adjacent Cats permanently give 2 additional coins.

Increasing the permanent bonus of adjacent Cats is actually the simplest of our 3 tasks. We just have to add the following effect to Cool Symbol:

`{"effect_type": "adjacent_symbols", "comparisons": [{"a": "type", "b": "cat"}], "value_to_change": "permanent_bonus", "diff": 2, "anim": "circle", "anim_targets": "adjacent_symbol"}`

### 3. To make things even _more_ complicated, let's also have Cool Symbol increase its permanent multiplier by a number equal to the number of times Cool Symbol has appeared this game.

Now here's where things get tricky. We want to increase Cool Symbol's `permanent_multiplier` variable by a variable that symbols use called `times_displayed`. Unfortunately, due to limitations of the API, we can't just type `"diff": times_displayed` thanks to the simplicity of script files. However, we can use a somewhat complicated (but very powerful) feature of the modding API: `var_math`:

`{"value_to_change": "permanent_multiplier", "anim": "shake", "diff": {"starting_value": 2, "var_math": [{"+": "times_displayed"}]}}`

Let's break this down.

There are multiple fields that normally expect Ints/Floats. These fields can also be passed a Dictionary where the first key is `"var_math"`. One of the fields where this works is the `"diff"` key in an effect.

To keep things simple, we'll refer to the value that will replace the Dictionary as `X`.

`X` starts at 0 by default, but this can be changed if we add a `"starting_value"` key to our Dictionary. The value of `X` will become equal to the `"starting_value"` at the start of our calculations.

`X` then looks at the series of Dictionaries in the `"var_math"` Array, which need to have a key/value pair, where the key is `"+"`, `"-"`, `"*"`, or `"/"`. In order, these keys correspond to addition, subtraction, multiplication, and division.

In this instance, since the key is `"+"`, whatever the value of `times_displayed` is on Cool Symbol is added to `X`.

Keep in mind that these values are applied to `X` from left to right, ignoring the algebraic order of operations.

If the symbol has appeared 3 times, `X` will become 5. If the symbol has appeared 10 times, `X` will become 12, etc.

`"var_math"` is also how we can access random numbers, more information on that can be found in the [documentation for `"var_math"`](https://github.com/TrampolineTales/LBAL-Modding-Docs/wiki/var_math).

Our script file should look like this:

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
	{"effect_type": "adjacent_symbols", "comparisons": [{"a": "type", "b": "coin"}], "value_to_change": "destroyed", "diff": true, "anim": "bounce", "anim_targets": "adjacent_symbol"},
	{"effect_type": "adjacent_symbols", "comparisons": [{"a": "type", "b": "cat"}], "value_to_change": "permanent_bonus", "diff": 2, "anim": "circle", "anim_targets": "adjacent_symbol"},
	{"value_to_change": "permanent_multiplier", "anim": "shake", "diff": {"starting_value": 2, "var_math": [{"+": "times_displayed"}]}},
	]
```

In the next tutorial, we'll go over how to add reminder text to Cool Symbol:

[Tutorial: Value Text](https://github.com/TrampolineTales/LBAL-Modding-Docs/wiki/Tutorial-1.6:-Value-Text)