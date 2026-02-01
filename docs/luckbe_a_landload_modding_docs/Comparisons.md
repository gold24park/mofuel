# Comparisons

Comparisons are used to determine if an effect will trigger or not.

If every comparison returns `true` (or if there are no comparisons in the Array) the effect will trigger.

### Comparison Variables:

| Type | Variable | Notes |
| ----------- | ----------- | ----------- |
| Multiple | a | Will return a value at runtime and be compared to `b` to see if the comparison is `true`. |
| Multiple | b | Will return a value at runtime and be compared to `a` to see if the comparison is `true`. |
| String | currency | If `a` is `"value"`, `"value_bonus"`, or `"value_multiplier"` then `a` returns the currency value of the specified currency.<br>Accepted Varaibles: `"reroll_token"`/`"removal_token"`/`"essence_token"` |
| Bool | not | If `true`, the effect will check if the comparison is `false` instead of `true`. Is `false` by default. |
| Bool | not_prev | If `true`, the symbol will only take its current variables into account. In other words, this effect will not apply retroactively. Is `false` by default. |
| Bool | less_than | If `true`, the comparison will be considered `true` if `a` is less than `b`. Is `false` by default. |
| Bool | less_than_eq | If `true`, the comparison will be considered `true` if `a` is less than or equal to `b`. Is `false` by default. |
| Bool | greater_than | If `true`, the comparison will be considered `true` if `a` is greater than `b`. Is `false` by default. |
| Bool | greater_than_eq | If `true`, the comparison will be considered `true` if `a` is greater than or equal to `b`. Is `false` by default. |
| Bool | target_self | If `true`, the `"a"` variable will check for replacement variables on the originating symbol/item. Useful if the effect containing this Dictionary is applied to a symbol/item other than the originating one. Is `false` by default. |
| Int | value_num | Used when the `"a"` variable is `"saved_values"` to determine the specific instance to compare in the `saved_values` Array. |

Examples:

* `{"a": "destroyed", "b": true}` - `true` if the symbol/item is destroyed
* `{"a": "times_displayed", "b": 5, "greater_than": true}` - `true` if the symbol has appeared more than 5 times

## `"a"` variables

The following are variables that can be referenced in a comparison under the `"a"` field:

| Type | Variable | Notes |
| ----------- | ----------- | ----------- |
| Bool | destroyed | Returns `true` if the symbol or item was destroyed this spin. |
| Bool | removed | Returns `true` if the symbol was removed this spin. |
| String | type | Returns the `type` that the symbol or item is. |
| String | groups | Returns the groups that the symbol or item belongs to. The comparison will be `true` if `b` is any of the groups. |
| String | rarity | Returns the `rarity` that the symbol or item is. |
| Int | value | Returns the base value of the symbol/item. |
| Int | value_bonus | Returns the additive bonus value of the symbol. Cannot be used on Items. |
| Float | value_multiplier | Returns the multiplicative bonus value of the symbol. Cannot be used on Items. |
| Int | permanent_bonus | Returns the permanent additive bonus value of the symbol. Cannot be used on Items. |
| Float | permanent_multiplier | Returns the permanent multiplicative bonus value of the symbol. Cannot be used on Items. |
| Int | coins_earned | Returns the total number of coins a symbol has earned. Cannot be used on Items. |
| Int | times_coins_given | Returns the total number of times a symbol has given 1 coin or more. Cannot be used on Items. |
| Int | times_displayed | Returns the total number of times a symbol has been displayed. Cannot be used on Items. |
| Int | item_count | Returns the number of copies of an item in the player's inventory. Item-exclusive. |
| Int | saved_value | A value that can be increased/decreased with other effects.<br>For example, Light Bulb uses this value to keep track of the number of times its given out a multiplier (with an effect not shown here).<br>It checks to destroy itself with the following comparison:<br>`{"a": "saved_value", "b": 5, "greater_than_eq": true}`|
| Bool | indestructible | Returns whether or not the symbol is indestructible. Cannot be used on Items. |
| Int | grid_position_x | Returns the x position of the symbol, starts counting at 0. Cannot be used on Items. |
| Int | grid_position_y | Returns the y position of the symbol, starts counting at 0. Cannot be used on Items. |
| Int | hotfix_num | Returns the number of hotfixes the game has received since the last Content Patch. |
| Int | multiple_of | Checks if the end-of-spin coins gained is a multiple of `b`. If so, the comparison returns `true`. |
| Multiple | saved_values | Returns the number in the `saved_values` Array in the index position of `"value_num"`.<br>For example, the following will be `true` if the 3rd value in the `saved_values` Array is equal to `7`:<br>`{"a": "saved_values", "b": 7, "value_num": 2}` |
| Int | sprite_after_anim | Returns the sprite index of a symbol after it is done animating. Will always be `0` on symbols without additional sprites. Cannot be used on Items.<br>For example, since the `d5` symbol has 5 additional sprites (one for each possible roll), the following comparison would be `true` if a `d5` rolls a `2`:<br>`[{"a": "type", "b": "d5"}, {"a": "sprite_after_anim", "b": 2}]` |
| Int | coins | Returns the number of Coins the player has. |
| Int | reroll_tokens | Returns the number of Reroll Tokens the player has. |
| Int | removal_tokens | Returns the number of Removal Tokens the player has. |
| Int | essence_tokens | Returns the number of Essence Tokens the player has. |
| Int | rent_due | Returns the number of coins the player will have to pay when rent is due. |
| Int | spins_left | Returns the number of spins left until rent is due. |
| Int | symbols_destroyed_this_spin | Returns the number of symbols that have been destroyed this spin. |
| Int | items_destroyed_this_spin | Returns the number of items that have been destroyed this spin. |
| Int | symbols_removed_this_spin | Returns the number of symbols that have been removed by an item this spin. Item-exclusive. |
| Int | non_singular_symbols | Returns the number of symbols that have 2 or more copies of themselves in the inventory. |
| Int | extra_symbol_choices | Returns the number of extra symbol choice emails the player sees after a spin. |
| Int | extra_item_choices | Returns the number of extra item choice emails the player sees after paying rent. |
| Int | symbols_to_choose_from | Returns the number of symbols the player can choose from in an email. |
| Int | items_to_choose_from | Returns the number of items the player can choose from in an email. |
| Bool | fighting_boss | Returns `true` if the boss fight is currently underway. |
| Bool | dove_destroyed | Returns `true` if the symbol had its destruction prevented from another symbol. Cannot be used on Items. |
| Bool | void_check | Returns `true` if a symbol is ever adjacent to 0 Empty symbols. Cannot be used on Items. |
| Dictionary | counted_symbols | Returns the total number of displayed symbols (of the specified type).<br>Example: `{"a": {"counted_symbols": "coin"}, "b": 5, "greater_than": true}`<br>This comparison will be considered `true` if there are more than 5 displayed Coin symbols.<br>Symbols with the group `"eachother"` will have their `counted_symbols` value reduced by 1 (but will not be less than 0). |
| Dictionary | counted_adjacent_symbols | Returns the largest number of adjacent symbols (of the specified type or group).<br>Example: `{"a": {"counted_adjacent_symbols": {"type": "cat"}}, "b": 9, "greater_than_eq": true}`<br>This comparison will be considered `true` if there are 9 or more Cat symbols adjacent to each other.<br>If the `effect_type` is `"counted_adjacent_symbols"`, the effect will be applied to any symbols that meet the criteria for the comparison.
| Dictionary | counted_items | Returns the total number of items (of the specified type).<br>Example: `{"a": {"counted_items": "lucky_seven"}, "b": 2, "greater_than": true}`<br>This comparison will be considered `true` if there are more than 2 Lucky Seven items. |
| Dictionary | counted_destroyed_items | Returns the total number of destroyed items (of the specified type).<br>Example: `{"a": {"counted_destroyed_items": "pool_ball_essence"}, "b": 8, "less_than": true}`<br>This comparison will be considered `true` if there are less than 8 destroyed Pool Ball Essence items. |
| Dictionary | destroyed_symbol_type_count | Returns the total number of destroyed symbols (of the specified type).<br>Example: `{"a": {"destroyed_symbol_type_count": "sapphire"}, "b": 5, "greater_than": true}`<br>This comparison will be considered `true` if there are more than 5 destroyed Sapphire symbols. |
| Dictionary | removed_symbol_type_count| Returns the total number of removed symbols (of the specified type). |
| Dictionary | destroyed_symbol_group_count | Returns the total number of destroyed symbols (of the specified group).<br>Example: `{"a": {"destroyed_symbol_group_count": "human"}, "b": 5, "greater_than": true}`<br>This comparison will be considered `true` if there are more than 5 destroyed symbols in the `human` group. |
| Dictionary | removed_symbol_group_count | Returns the total number of removed symbols (of the specified group). |
| Dictionary | symbols_in_inventory | Returns the total number of symbols (of the specified type or group) in the player's inventory. This includes symbols that didn't appear during the current spin.<br>Example: `{"a": {"symbols_in_inventory": {"type": "dog"}}, "b": 101, "greater_than_eq": true}`<br>This comparison will be considered `true` if there are at least 101 Dog symbols in the player's inventory. |