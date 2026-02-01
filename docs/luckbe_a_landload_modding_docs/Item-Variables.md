# Item Variables

The following is a list of every variable that can be modified with `value_to_change` in an item effect if the `effect_type` isn't `symbols`:

| Type | Variable | Notes |
| ----------- | ----------- | ----------- |
| Bool | destroyed | The item is destroyed if this is `true`. |
| Int | value | The number of coins that the item gives each spin. Resets each spin. |
| Int | reroll_value | The number of Reroll Tokens that the item gives each spin. Resets each spin. |
| Int | removal_value | The number of Removal Tokens that the item gives each spin. Resets each spin. |
| Int | essence_value | The number of Essence Tokens that the item gives each spin. Resets each spin. |
| Int/Float | saved_value | Changing this value won't do anything unless there is an effect that uses `saved_value`. Some existing items already use this variable for their effects. Can cause conflicts if modified by multiple different mods. `saved_values` should be used instead to avoid conflicts. |
| Int | symbols_to_choose_from | The total symbols to choose from an `"add_tile"` email. |
| Int | items_to_choose_from | The total items to choose from an `"add_item"` email. |
| Int | extra_symbol_choices | The total additional `"add_tile"` emails that appear after a spin |
| Int | extra_item_choices | The total additional `"add_item"` emails that appear after a spin. |
| Int | spins_left | Modifying this variable will increase or decrease the total numbers of spins left before rent is due. |
| Int | item_count | The number of copies of the item in the player's inventory. |
| Dictionary | permanent_bonuses | Modifying this variable will add an essence-style permanent bonus to the related symbols. <br>For example, the following will change the permanent multiplier by 5x of all current and future Rabbits this game:<br>`{"value_to_change": "permanent_bonuses", "diff": {"type": "rabbit", "multiplier": 5}, "add_to_array": true}`<br>`"bonus"` can be used in place of `"multiplier"` for a flat increase or decrease instead of a multiplier. `"groups"` can be used in place of `"type"` to apply the bonus to a symbol group instead of a symbol type.<br>Rarity multipliers can also be added to a permanent bonus. For example, the following will make Uncommon symbols 0.5x less likely to appear, Very Rare symbols 50,000x more likely to appear, and Uncommon items 3.5x more likely to appear: `{"value_to_change": "permanent_bonuses", "diff": {"rarity": {"symbols": {"uncommon": 0.5, "very_rare": 50000}, "items": {"uncommon": 3.5}}}, "add_to_array": true}`<br>The effect _needs_ to have `"add_to_array": true` in it for `permanent_bonuses` to function properly. |
| Bool | forced_add | If `true`, the next `"add_tile"` email will not have the Skip button. Will not apply if the email is the last one before rent is due. |
| Bool | forced_skip | If `true`, the next `"add_tile"` email will not have any symbols to choose from. Will not apply if the email is the last one before rent is due. |
| Multiple | saved_values | Changes the number in the `saved_values` Array in the index position of the `"value_num"` in the effect.<br>For example, the following will decrease the 5th value in the `saved_values` Array by `23`:<br>`{"value_to_change": "saved_values", "value_num": 4, "diff": -23}` |