# Modding Variables

The following is a list of every variable that can be modified in a mod's script file:

## Required Variables

| Type | Variable | Notes |
| ----------- | ----------- | ----------- |
| String | mod_type | Accepted Variables: `"symbol"`/`"item"`/`"existing_symbol"`/`"existing_item"`/[`"email"`](https://github.com/TrampolineTales/LBAL-Modding-Docs/wiki/Modding-Variables#email-exclusive-variables)/[`"fine_print"`](https://github.com/TrampolineTales/LBAL-Modding-Docs/wiki/Fine-Print)/[`"art_replacement"`](https://github.com/TrampolineTales/LBAL-Modding-Docs/wiki/Art-Replacement)/[`"group_addition"`](https://github.com/TrampolineTales/LBAL-Modding-Docs/wiki/Group-Addition)/[`"apartment_floor"`](https://github.com/TrampolineTales/LBAL-Modding-Docs/wiki/Apartment-Floors)/[`"inherited_effects"`](https://github.com/TrampolineTales/LBAL-Modding-Docs/wiki/Inherited-Effects)/`"counted_adjacent_symbols"` |
| String | type | An identifier for your symbol, item, or email. Make sure this is unique from your other mods!<br>If you assign `mod_type` to `"existing_symbol"` or `"existing_item"`, this value HAS to be the type of the symbol/item you're modifying/replacing |
| String | display_name | The name of the mod that is displayed to the player.<br>Does not have to match the `type` variable. |
| Int | value | The base number of coins that a symbol/item will give each spin (without any effects). |
| String | [description](https://github.com/TrampolineTales/LBAL-Modding-Docs/wiki/Tutorial-1.9:-Descriptions) | The description of the mod's effects that are displayed to the player. |
| String | rarity | Accepted Variables: `"common"`/`"uncommon"`/`"rare"`/`"very_rare"`/`"essence"`/`"none"` |
| Array | values | Base values that can be accessed within `effects` and/or `description`.<br>If you don't mind hard-coding your variables, you can ignore this. |
| Array | groups | The groups that an item or symbol belongs to for the purpose of `effects` and `description`. |
| Array | [effects](https://github.com/TrampolineTales/LBAL-Modding-Docs/wiki/Effects) | The array of effects that make up the logic of the symbol, item, email, or fine print. |

## Optional Variables
| Type | Variable | Notes |
| ----------- | ----------- | ----------- |
| Bool | inherit_effects | For an `existing_symbol` or `existing_item`.<br>If `true`, the mod will have the effects of the base symbol/item (Any additional effects in the `effects` Array will be appended). If `false`, the mod will not have any of the effects of the base symbol/item. |
| Bool | inherit_art | For an `existing_symbol` or `existing_item`.<br>If `true`, the mod will not look in the `/art` directory for its Sprite. If `false`, the mod will. |
| Bool | inherit_groups | For an `existing_symbol` or `existing_item`.<br>If `true`, the mod will have the groups of the base symbol/item (Any additional effects in the `groups` Array will be appended). If `false`, the mod will not have any of the groups of the base symbol/item. |
| Bool | inherit_description | For an `existing_symbol` or `existing_item`.<br>If `true`, the mod will append the contents of `description` to the base symbol/item's description |
| Dictionary | localized_names | Will replace the `display_name` if the game is played in a supported language.<br>Accepted Variables: `"en"`/`"pt_BR"`/`"zh"`/`"ru"`/`"fr"`/`"it"`/`"de"`/`"es_ES"`/`"da_DK"`/`"ja"`/`"ko"`/`"zh_TW"`/`"es"`/`"pl"`/`"vi"`/`"pt_PT"`/`"tr"`/`"th"`/`"bg"`<br>(English/Brazilian-Portuguese/Simplified Chinese/Russian/French/Italian/German/Spain-Spanish/Danish/Japanese/Korean/Traditional Chinese/LatAm-Spanish/Polish/Vietnamese/European-Portuguese/Turkish/Thai/Bulgarian)<br>Example: `localized_names = {"en": "Ninja and Mouse", "pt_BR": "Ninja e Rato", "zh: "忍者和老鼠", "ru": Ниндзя и мышь"}` |
| Array | inherited_effects | An array of types of Inherited Effects mods that this symbol or item will inherit. Can be used to reduce copy/pasting the same effect in multiple script files. |
| Dictionary | localized_description | Will replace the `description` if the game is played in a supported language.<br>Supports the same variables and functions the same as `localized_names`. |
| Bool | cannot_be_disabled | If `true`, the item cannot be disabled by the player. Item-exclusive. |
| Bool | manually_destroyable | If `true`, the item can be manually destroyed by the player. Item-exclusive.<br>Automatically appends the text "(Click on this item to destroy it)" to the item's description. |
| Bool | can_be_destroyed_before_rent | If `true`, the item can be manually destroyed by the player on the prompt before paying rent. Item-exclusive.
| Bool | skip_rent_on_destroy | If `true`, the item allows the player to skip a rent payment if destroyed in the email prompt when rent is due. Doesn't do anything if `can_be_destroyed_before_rent` is `false`. Item-exclusive.
| Array | symbol_triggers | An Array of dictionaries which determine if an item's `symbol_trigger` variable is `true` this spin. Item-exclusive.
| Dictionary | [value_text](https://github.com/TrampolineTales/LBAL-Modding-Docs/wiki/Tutorial-1.6:-Value-Text) | Determines what is displayed for a symbol or item's reminder text.
| Int | count_at_start | The number of this symbol or item that are added to the player's inventory at the beginning of a new game.
| Array | symbols_removed_pre_spin | An Array of dictionaries that determine symbol types and/or groups that an item removes before a spin. Item-exclusive.<br>Example: `[{"type": "cherry"}, {"type": "cat"}, {"groups": "human"}]` will remove all Cherries, Cats, and symbols in the `"human"` group before a spin.

## Email-Exclusive Variables
| Type | Variable | Notes |
| ----------- | ----------- | ----------- |
| String | header_text | The text that appears in the header section of an email. |
| Dictionary | localized_header_text | Will replace the `header_text` if the game is played in a supported language.<br>Supports the same variables and functions the same as `localized_names`. |
| String | text | The text that appears in the body of an email. |
| Dictionary | localized_text | Will replace the `text` if the game is played in a supported language.<br>Supports the same variables and functions the same as `localized_names`. |
| Array | replies | Strings that appear in the reply buttons at the bottom of an email. |
| Dictionary | localized_replies | Will replace the `replies` if the game is played in a supported language.<br>Supports the same variables and functions the same as `localized_names`. |
| Bool | prompt | Determines if the email uses the compact "prompt" interface (the pop-ups that appear from items like Swapping Device and Oil Can). |
| Array | reply_results | An array of dictionaries that correspond to each reply. The 1st dictionary in the `reply_results` array will occur if the 1st `replies` button is pressed. The 2nd dictionary will occur if the 2nd button is pressed, and so on. The syntax for the dictionaries is the same as [effects](https://github.com/TrampolineTales/LBAL-Modding-Docs/wiki/Effects). |

## Fine Print-Exclusive Variables
| Type | Variable | Notes |
| ----------- | ----------- | ----------- |
| String | text | The description of the fine print. |
| Dictionary | localized_text | Will replace the `text` if the game is played in a supported language.<br>Supports the same variables and functions the same as `localized_names`. |
| String | relevant_type | The type of the symbol or item that the fine print affects. |
| String | relevant_group | The group of the symbol or item that the fine print affects. |
| Int | difficulty | If `1`, the fine print is considered difficult and will not appear if the apartment floor is 14 or lower. |
| Bool | for_items | Must be `true` if the fine print affects one or more items, the fine print will not function properly otherwise. |

## Apartment Floor-Exclusive Variables

* See [here](https://github.com/TrampolineTales/LBAL-Modding-Docs/wiki/Apartment-Floors)