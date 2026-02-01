# Inherited Effects

An Inherited Effects mod can be used to add effects to multiple symbols and items without having to copy/paste the same effect in multiple script files.

In order to create an Inherited Effects mod, we need a GD file in our mod's `scripts` folder. The content of the file must be as follows:

```
extends "res://Mod Data.gd"

func _init():
	mod_type = "inherited_effects"
	type = ""
	effects = []
```

The `type` variable must be a unique string so modded symbols and items can reference it in their `inherited_effects` array.

The `effects` array is where we'll add effects that we want modded symbols or items to potentially inherit.