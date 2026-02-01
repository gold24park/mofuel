# Apartment Floors

In order to create an Apartment Floor mod, we need a GD file in our mod's `scripts` folder for each apartment floor we'd like to add. The content of the file must be as follows:

```
extends "res://Mod Data.gd"

func _init():
	mod_type = "apartment_floor"
	type = ""
	floor_num = 1
	display_name = ""
	localized_names = {}
	text = ""
	localized_text = {}
	locked = false
	has_bossfight = true
	landlord_hp = 750
	landlord_max_hp = 750
	starting_coins = 1
	starting_symbols = ["base"]
	starting_items = []
	dud_timer = 0
	comrade_removal_tokens = 2
	comrade_reroll_tokens = 2
	comrade_essence_tokens = 2
	difficulty = 0
	consistent_spins = false
	fine_print_multiplier = 1
	fine_print = ["base", "self"]
	symbol_packs = ["base", "self"]
	included_symbols = []
	excluded_symbols = []
	item_packs = ["base", "self"]
	included_items = []
	excluded_items = []
	intro_emails = []
	ending_emails = []
	email_packs = ["base", "self"]
	included_emails = []
	excluded_emails = []
	rent_values = ["base"]
	rent_payments = 12
	symbol_effects = []
	item_effects = []
```

Let's break down what each of these variables do.

The `mod_type` variable must be set to `"apartment_floor"`.

The `type` variable must be the same for each apartment floor you'd like to be in the same set. For example, if you have two apartment floor mods with the `type` of `"cool_apartment_floor"`, then the two mods will be separate floors within the same mod pack. This assumes that the floors have different `floor_num` variables.

The `floor_num` variable determines where the floor is in the unlock order. A floor with a `floor_num` of 1 will unlock first, a floor with a `floor_num` of 2 will unlock second, and so on.

The `display_name` variable is displayed in the Mods menu when the player is deciding if they want to toggle the apartment floor within the mod. `localized_names` can also be used.

The `text` variable is what is displayed when selecting the apartment floor, like the modifiers displayed with the apartment floors in the base game. `localized_text` can also be used.

The `locked` variable determines if the floor is locked by default. If `true`, the floor will be unlocked when the previous floor in the mod pack is cleared. Otherwise, the floor will be unlocked by default. Keep in mind that the first floor in the mod pack needs to have `locked = false` for the set to function properly.

The `has_bossfight` variable determines if your apartment floor will have a boss fight with the landlord at the end. The boss fight will trigger if `has_bossfight = true`.

The `landlord_hp` and `landlord_max_hp` determine the landlord's starting HP and maximum HP, respectively.

The `starting_coins` variable determines how many coins the player starts with.

The `starting_symbols` variable is an array of symbols that the player will start with. The `"base"` keyword can be used as shorthand for the 5 base symbols the player normally starts with. For example: `starting_symbols = ["base", "dwarf", "rabbit"]` will have the starting symbols be Coin, Cherry, Pearl, Flower, Cat, Dwarf, and Rabbit.

The `starting_items` variable is an array of items that the player will start with. The `"base"` keyword cannot be used here as the player doesn't normally start with any items.

The `dud_timer` variable determines how frequently a Dud symbol is added before the final rent payment. `dud_timer = 5` will add a Dud every 5 spins. `dud_timer = 1` will add a Dud every spin. `dud_timer = 0` will not add Duds.

The `comrade_removal_tokens`, `comrade_reroll_tokens`, and `comrade_essence_tokens` variables determine how many Removal Tokens, Reroll Tokens, and Essence Tokens the player receives from emails.

The `difficulty` variable determines if the apartment floor uses more difficult fine print. The more difficult fine print will be used if `difficulty = 1`.

The `consistent_spins` variable will make the slot machine not randomize its reels if `consistent_spins = true`.

The `fine_print_multiplier` variable will multiply the amount of fine print added from emails by its value. 

The `fine_print` variable is an array of the fine print packs that can appear during the boss fight. Valid variables are `"base"` for the fine print that normally appears in the game, `"self"` for the fine print that exists in the same mod pack, and a string of any pack's fine print that you'd like to add. For example, since [this mod pack](https://steamcommunity.com/sharedfiles/filedetails/?id=2804777762) has the id of "2804777762" (seen in the URL) we can add any fine print that might be included with that mod with `fine_print = ["2804777762"]`.

The `symbol_packs` variable is an array of the symbol packs that can appear in the apartment floor. The variables function the same as `fine_print` with the `"base"`, `"self"`, and the mod pack numbers.

The `included_symbols` variable is an array of individual symbols that we wish to include that aren't in the packs we included in `symbol_packs`.

The `excluded_symbols` variable is an array of individual symbols that we wish to exclude from the packs we included in `symbol_packs`.

The `item_packs`, `included_items`, and `excluded_items` variables function the same as the three above variables, except they're for items instead of symbols.

The `intro_emails` variable is an array of emails that we'd like to have at the beginning of our apartment floor. For example: `intro_emails = [{"type": "intro"}]` will function the same as the base game. More than one email can be added to the array.

The `ending_emails` variable is an array of emails that we'd like to have at the end of our apartment floor. For example: `ending_emails = [{"type": "ending"}]` will function the same as the base game. More than one email can be added to the array.

The `email_packs`, `included_emails`, and `excluded_emails` variables function the same as their symbol and item equivalents.

The `rent_values` variable is an array of arrays that determine how many coins are due for rent, and how many spins before rent is due. `rent_values = [[50, 6], [100, 8]]` will have 2 rent payments of 50 coins due in 6 spins and 100 coins due in 8 spins respectively. `"base"` can be used in place of arrays to use the 12 payment structure in the base game.

The `rent_payments` variable will determine how many rent payments are necessary for the boss fight to occur (or for the game to end if `has_bossfight = false`).

The `symbol_effects` and `item_effects` variables are arrays of effects that will be applied to all symbols and items while on the apartment floor.

If we want to test a modded apartment floor, we need to have `"apartment_floor_type": "X"` and `"apartment_floor_num": Y` in our [sandbox file](https://github.com/TrampolineTales/LBAL-Modding-Docs/wiki/Tutorial-1.3:-Testing-in-the-Sandbox) where X is the `type` variable and Y is the `floor_num` variable of the floor we want to test. Make sure to have quotation marks around the `type` but not the `floor_num`.