# Group Addition

A Group Addition mod is a quick way to mass-add a number of symbols to a group without having to create a new script file for every symbol we want to modify.

In order to create a Group Addition mod, we need a GD file in our mod's `scripts` folder. The content of the file must be as follows:

```
extends "res://Mod Data.gd"

func _init():
	mod_type = "group_addition"
	effects = []
```

The `effects` array is where we'll declare which symbols will be added to which group. For example:

```
extends "res://Mod Data.gd"

func _init():
	mod_type = "group_addition"
	display_name = "Group Additions"
	effects = [{"human": ["apple", "cat"]}, {"organism": ["void_stone", "void_fruit"]}]
```

This Group Addition mod will add the Apple and Cat symbols to the `human` group and the Void Stone and Void Fruit symbols to the `organism` group.