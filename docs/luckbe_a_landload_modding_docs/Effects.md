# Effects

Effects are Dictionaries that are assigned to Symbols and Items and trigger each spin if all of the [comparisons](https://github.com/TrampolineTales/LBAL-Modding-Docs/wiki/Comparisons) return `true`.

### Effect Variables:

| Type | Variable | Notes |
| ----------- | ----------- | ----------- |
| Array | [comparisons](https://github.com/TrampolineTales/LBAL-Modding-Docs/wiki/Comparisons) | An Array of Dictionaries that must be true for the effect to trigger. |
| String | [effect_type](https://github.com/TrampolineTales/LBAL-Modding-Docs/wiki/Effect-Types) | Determines multiple properties of the effect and which symbols or items the affect is added to.<br>Accepted Variables: `"self"`/`"adjacent_symbols"`/`"rand_adjacent_symbol"`/`"same_rand_adjacent_symbol"`/`"symbols"`/`"pointed_symbols"`/`"spend_removal_token"`/`"spend_reroll_token"`/`"skip"`/`"symbol_added"`/`"item_added"`/`"rent_paid"`/`"reverse_adjacent_symbol"`.<br>Defaults to `"self"`. |
| Int | anim_result | The index number of the additional texture to end an animation on if `{"anim": "ordered_texture_cycle"}`.<br>For example, `{"anim": "ordered_texture_cycle", "anim_result": 3}` on a symbol called "cool_symbol" will make sure the texture at the end of the animation will be `cool_symbol3.png`.<br>Required when using `{"anim": "ordered_texture_cycle"}` |
| String | value_to_change | The variable to modify with `diff` when the effect triggers. |
| Multiple | diff | The value to modify `value_to_change` with when the effect triggers. |
| String | anim | Determines the type of animation that the symbols will use.<br>Accepted Variables: `"circle"`/`"rotate"`/`"bounce"`/`"shake"/"rand_texture_cycle"/"ordered_texture_cycle"` |
| String | anim_targets | Determines which symbols will animate when the effect triggers if the `anim` variable is not `null`.<br>`"all_adjacent_symbols"` for every adjacent symbol (including the triggering symbol).<br>`"adjacent_symbol"` for the affected symbol and the triggering symbol.<br>`null` for just the triggering symbol. |
| Dictionary | rarity_mod | A Dictionary of multipliers that affect symbol/item rarity.<br>Example: `"rarity_mod": {"symbols": [{"uncommon": 0.5}], "items": [{"very_rare": 3}]}`<br>This will make Uncommon Symbols 0.5x as likely to appear, and Very Rare items 3x as likely to appear. |
| Dictionary | forced_rarities | Forces symbols/items of the specified rarities to appear after the spin.<br>Example: `"forced_rarities": {"symbols": ["rare", "rare", "uncommon"], "or_better": true}`<br>Will force 2 Rare symbols (or better) and 1 Uncommon symbol (or better) to appear after this spin. This does not increase any rarity chances, it only makes more common symbols/items impossible to obtain.<br>Since this only effects the spin directly after its effect, forcing the rarity of items will only be relevant if an item choice would be possible.
| Array | required_items | An Array of Strings of items that are must be in the player's inventory for the effect to trigger. |
| Array | required_disabled_items | An Array of Strings of items that are must be in the player's inventory for the effect to trigger. Only checks disabled items. |
| Array | required_destroyed_items | An Array of Strings of items that must have been destroyed this game for the effect to trigger. |
| Array | forbidden_items | An Array of Strings of items that cannot be in the player's inventory for the effect to trigger. |
| Array | forbidden_disabled_items | An Array of Strings of items that cannot be in the player's inventory for the effect to trigger. Only checks disabled items. |
| Array | forbidden_destroyed_items | An Array of Strings of items that cannot have been destroyed this game for the effect to trigger. |
| Bool | target_self | If `true`, the `value_to_change`/`diff` will be applied to the source symbol. Even if the `effect_type` is not `"self"`  |
| Bool | one_time | If `true`, the effect can only be applied to a symbol once per spin. Cannot be used on items. |
| Bool | overwrite | If `true`, the `diff` will replace the `value_to_change` instead of being added to it. Only works if `diff` and `value_to_change` are numbers. |
| Bool | capsule_effect | `true` if an effect should have its `diff` multiplied in relation to `capsule_machine` and `capsule_machine_essence`. |
| String | currency | If `value_to_change` is `"value_bonus"` or `"value_multiplier"`, the currency modified will be something other than Coins.<br>Accepted Varaibles: `"reroll_token"`/`"removal_token"`/`"essence_token"` |
| String | item_to_destroy | The type of item to destroy if the effect triggers. |
| String | [sfx_override](https://github.com/TrampolineTales/LBAL-Modding-Docs/wiki/Tutorial-1.8:-Sound-Effects) | The type of sound effect to play if the effect triggers. |
| Array | tiles_to_add | An Array of symbols to add when the effect triggers.<br>Example: `"tiles_to_add": [{"type": "apple"}, {"type": "apple"}, {"group": "gem", "min_rarity": "rare"}, {"group": "hex"}]`<br>This will add 2 Apples, a symbol with the group of Gem with the Rarity of Rare or better, and and a symbol with the group of Hex when the effect triggers.<br>If you want to get a random previously destroyed symbol (like Time Capsule), add a string equal to "prev_destroyed_symbol" where you would normally put a dictionary. |
| Array | items_to_add | An Array of items to add when the effect triggers. |
| Array | emails_to_add | An Array of emails to add when the effect triggers.<br>Example: `"emails_to_add": [{"type": "add_item"}]`<br>This will add an email that allows the player to choose an item. |
| Array | reverse_groups | An Array of groups to be checked if the `effect_type` is `"reverse_adjacent_symbol"`. Checks if the adjacent symbol belongs to any of the groups. |
| String | reverse_type | A type to be checked if the `effect_type` is `"reverse_adjacent_symbol"`. Checks if the adjacent symbol is the same type. |
| Bool | add_to_array | If `true`, the `value_to_change`/`diff` will be appended to the end of an array. Necessary for some variables, like `permanent_bonuses`. |
| Bool | last | If `true`, the effect will be executed after all other "normal" effects have been executed. |
| Bool | push_front | If `true`, the effect will be executed before all other "normal" effects will be executed. |
| Bool | unconditional | If `true`, the effect will apply to every symbol that appears in the affected symbols' `grid_position`. For example, this is used on symbols like Buffing Capsule or Golden Arrow to make them increase the value of symbols that are added during a spin. Cannot be used in combination with a `type` or `groups` comparison. Cannot be used on items. |
| Bool | back_to_main_menu | If `true`, the email effect will force the player back to the main menu. Email-exclusive. |
| Bool | unlock_next_floor | If `true` and on a modded apartment floor, the email effect will unlock the next floor. Email-exclusive. |
| Bool | start_endless_mode | If `true`, the email effect will start endless mode. Email-exclusive. |
| Bool | retry | If `true`, the email effect will restart the run from the beginning. Email-exclusive. |
| Bool | start_bossfight | If `true`, the email effect will start the boss fight. Email-exclusive. |