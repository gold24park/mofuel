# Art Replacement

An Art Replacement mod is a quick way to mass-replace the art of the existing symbols and items without having to create a new script file for every symbol/item we want to modify.

In order to create an Art Replacement mod, we simply need a file named `art_replacement.gd` in our mod's `scripts` folder. The content of the file must be as follows:

```
extends "res://Mod Data.gd"

func _init():
	mod_type = "art_replacement"
```

After creating our `art_replacement.gd` file, we can create new PNGs with art of the symbols and items we wish to modify. However, we do need to name each file _exactly_ the same as the symbol's or item's `type`. For example, our `art` folder would have these files in it if we wanted to change the art for Gambler, Thief, and Eldritch Creature:

```
gambler.png
thief.png
eldritch_beast.png
```

Note that Eldritch Creature needs to be named `eldritch_beast.png` as it -- and some other symbols/items -- have slight caveats to the naming of their `type` variables.

And just like that, whatever great art we've created in the PNGs will replace the art for Gambler, Thief, and Eldritch Creature respectively!

![](https://raw.githubusercontent.com/TrampolineTales/LBAL-Modding-Docs/main/images/art_replacement_example.png)

(The above art is from [Shadowed Texture Pack](https://steamcommunity.com/workshop/filedetails/?id=2861089875) by Anubscorpiak)