# Effect Types

Every effect can has an `effect_type` variable which can greatly modify how the effect is applied.

### Accepted Variables:

| Variable | Notes |
| ----------- | ----------- |
| `"self"` | The effect is applied to the symbol or item that belongs to the script where the effect appears. The `effect_type` variable defaults to `"self"` even if no `effect_type` is present in the script. |
| `"adjacent_symbols"` | The effect is applied to all adjacent symbols. The effect IS NOT applied to the applying symbol. Cannot be used on items. |
| `"rand_adjacent_symbol"` | The effect is applied to a random adjacent symbol. Cannot be used on items. |
| `"same_rand_adjacent_symbol"` | The effect is applied to a random adjacent symbol. Any effects with this `effect_type` will be applied to the same symbol. The selected symbol resets at the end of a spin. Cannot be used on items. |
| `"symbols"` | The effect is applied to all symbols that appear during a spin. If used on a symbol, excludes itself. |
| `"pointed_symbols"` | The effect is applied to every symbol that the applying symbol is pointing to. Will only have an effect if the applying symbol's `pointing_directions` variable has been modified. Cannot be used on items. |
| `"spend_removal_token"` | The effect triggers whenever a Removal Token is spent. Ignores comparisons. Item-exclusive. |
| `"spend_reroll_token"` | The effect triggers whenever a Reroll Token is spent. Ignores comparisons. Item-exclusive. |
| `"skip"` | The effect triggers whenever the player skips an item or symbol choice. Ignores comparisons. Item-exclusive. |
| `"symbol_added"` | The effect triggers whenever the player adds a symbol while the reels are not spinning. |
| `"item_added"` | The effect triggers whenever the player adds a item while the reels are not spinning. |
| `"rent_paid"` | The effect triggers whenever the player pays their rent. |
| `"reverse_adjacent_symbol"` | Adjacent symbols apply the effect to the originating symbol if they fall under the `"reverse_groups"` or `"reverse_type"`. Cannot be used on items. |