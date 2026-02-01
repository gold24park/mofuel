# Symbol Variables

The following is a list of every variable that can be modified with `value_to_change` in a symbol effect:

| Type | Variable | Notes |
| ----------- | ----------- | ----------- |
| Bool | destroyed | The symbol is destroyed if this is `true` (and the symbol is not indestructible). |
| Bool | removed | The symbol is removed (not destroyed) if this is `true`. |
| String | type | Changing this value will change what type the symbol is. |
| Int | value_bonus | Changing this value will add to the symbol's additive bonus value this spin. |
| Float | value_multiplier | Changing this value will add to the symbol's multiplicative bonus value this spin. |
| Int | permanent_bonus | Changing this value will make the symbol permanently give extra coins additively. |
| Float | permanent_multiplier | Changing this value will make the symbol permanently give extra coins multiplicatively. |
| Int/Float | saved_value | Changing this value won't do anything unless there is an effect that uses `saved_value`. Some existing symbols already use this variable for their effects. Can cause conflicts if modified by multiple different mods. `saved_values` should be used instead to avoid conflicts. |
| Bool | indestructible | The symbol cannot be destroyed if this is `true`. |
| Bool | wildcarded | If `true`, the symbol will have the logic of the Wildcard symbol. |
| Dictionary | pointing_directions | Changing this value will make the symbol point different directions for the purpose of `pointed_symbols`.<br>For example, `{"directions": ["NW", "W"]}` will make the symbol point Northwest and West. The possible directions are `"ALL"`, "RAND", `"N"`, `"NE"`, `"E"`, `"SE"`, `"S"`, `"SW"`, `"W"`, and `"NW"` |
| Int | texture | The index number of the additional texture to change the symbol's texture to.<br>For example, `{"value_to_change": "texture", "diff": 5}` on a symbol called "cool_symbol" will change the texture to `cool_symbol5.png` |
| Int | symbols_to_choose_from | The total symbols to choose from an `"add_tile"` email. |
| Int | items_to_choose_from | The total items to choose from an `"add_item"` email. |
| Int | extra_symbol_choices | The total additional `"add_tile"` emails that appear after a spin |
| Int | extra_item_choices | The total additional `"add_item"` emails that appear after a spin. |
| Int | spins_left | Modifying this variable will increase or decrease the total numbers of spins left before rent is due. |
| Dictionary | permanent_bonuses | Modifying this variable will add an essence-style permanent bonus to the related symbols. <br>For example, the following will change the permanent multiplier by 5x of all current and future Rabbits this game:<br>`{"value_to_change": "permanent_bonuses", "diff": {"type": "rabbit", "multiplier": 5}, "add_to_array": true}`<br>`"bonus"` can be used in place of `"multiplier"` for a flat increase or decrease instead of a multiplier. `"groups"` can be used in place of `"type"` to apply the bonus to a symbol group instead of a symbol type.<br>Rarity multipliers can also be added to a permanent bonus. For example, the following will make Uncommon symbols 0.5x less likely to appear, Very Rare symbols 50,000x more likely to appear, and Uncommon items 3.5x more likely to appear: `{"value_to_change": "permanent_bonuses", "diff": {"rarity": {"symbols": {"uncommon": 0.5, "very_rare": 50000}, "items": {"uncommon": 3.5}}}, "add_to_array": true}`<br>The effect _needs_ to have `"add_to_array": true` in it for `permanent_bonuses` to function properly. |
| Bool | forced_add | If `true`, the next `"add_tile"` email will not have the Skip button. Will not apply if the email is the last one before rent is due. |
| Bool | forced_skip | If `true`, the next `"add_tile"` email will not have any symbols to choose from. Will not apply if the email is the last one before rent is due. |
| Multiple | saved_values | Changes the number in the `saved_values` Array in the index position of the `"value_num"` in the effect.<br>For example, the following will increase the 7th value in the `saved_values` Array by `1`:<br>`{"value_to_change": "saved_values", "value_num": 6, "diff": 1}` |