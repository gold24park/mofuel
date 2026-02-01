# Descriptions

Before we make a description for Cool Symbol, we should get a better understanding of how the syntax of a description string works.

## Syntax

### <icon_X>

Replacing "X" with a symbol or item type will make a sprite of that symbol or item appear in-line in the description. The sprite can be hovered over to add a tooltip of that symbol's or item's description.

For example, `"I love my <icon_cat>, he is friends with a <icon_mouse>."` will render like so:

![](https://raw.githubusercontent.com/TrampolineTales/LBAL-Modding-Docs/main/images/icon_example.png)

#### Caveats

`<icon_hover_coin>` should be used if we want to refer to the Coin symbol. If we want to refer to the Coin currency, we should use `<icon_coin>`.

### <color_X> and &lt;end>

Replacing "X" with a color code will make all the text in-between `<color_X>` and `<end>` the color of "X."

For example, `"I am <color_FF0000>angry<end>!"` will render like so:

![](https://raw.githubusercontent.com/TrampolineTales/LBAL-Modding-Docs/main/images/color_example.png)

For a list of commonly used color codes, see the [Color Index](https://github.com/TrampolineTales/LBAL-Modding-Docs/wiki/Color-Index) page of this wiki.

When possible, it's better for us to use `<text_color_X>` as opposed to `<color_X>` so that the color can dynamically change with the player's color settings.

### <value_X>

Replacing "X" with a number will make the number in the symbol's or item's `values` array be displayed. For example, if we have a symbol with a `values` array of `[42, 105, 0, 293]`, then `"My first number in my values array is <value_1>! My second number in my values array is <value_2>!"` will render like so:

![](https://raw.githubusercontent.com/TrampolineTales/LBAL-Modding-Docs/main/images/value_example.png)

#### Caveats

`<value_1>` will get the first number in the `values` array. `<value_0>` will not work.

### <group_X> and <last_X>

Replacing "X" in `<group_X>` with a symbol or item group will make every sprite of that group **except one** appear in-line in the description. We can replace "X" in `<last_X>` to get the final sprite of a group to appear in-line in the description. This is useful if we want to put a word between the second-to-last sprite in the group and the last sprite in the group. For example, `"My favorite animals are <group_animal> and <last_animal>."` will render like so:

![](https://raw.githubusercontent.com/TrampolineTales/LBAL-Modding-Docs/main/images/group_example.png)

#### Caveats

Item groups need to have the prefix of `item_` here. For example, to display every Pepper item, we can do the following: `"Dan's famous chili recipe:\n1. Add <group_item_pepper> and <last_item_pepper>.\n2. Stir in a pot?\n3. I dunno, I've never made chili. I admit it."` which will render like so:

![](https://raw.githubusercontent.com/TrampolineTales/LBAL-Modding-Docs/main/images/item_group_example.png)

Note the instances of `\n` in the above example. `\n` can used to create a line-break in any text.

### <dynamic_X>

`<dynamic_X>` is only used in Fine Print. See the [Fine Print](https://github.com/TrampolineTales/LBAL-Modding-Docs/wiki/Fine-Print) page of this wiki for more details.

### <text_color_X> and &lt;end>

`<text_color_X>` functions the same as `<color_X>` but we replace "X" with a color identifier instead of a color code. For example, `The background color is <text_color_background>this<end>.` Will make the color of the word "this" whatever the Background color setting is set to ([FF8300](https://www.color-hex.com/color/FF8300) by default).

For a list of every color identifier that can be used, see the [Color Index](https://github.com/TrampolineTales/LBAL-Modding-Docs/wiki/Color-Index) page of this wiki.

## Cool Symbol's Description

Since Cool Symbol has the following effects...

* Gives 25 coins on destruction: `{"comparisons": [{"a": "destroyed", "b": true}], "value_to_change": "value_bonus", "diff": 25}`
* Destroys adjacent Coins: `{"effect_type": "adjacent_symbols", "comparisons": [{"a": "type", "b": "coin"}], "value_to_change": "destroyed", "diff": true, "anim": "bounce", "anim_targets": "adjacent_symbol"}`
* Increases adjacent Cats' Permanent Bonus by 2: `{"effect_type": "adjacent_symbols", "comparisons": [{"a": "type", "b": "cat"}], "value_to_change": "permanent_bonus", "diff": 2, "anim": "circle", "anim_targets": "adjacent_symbol"}`
* Increases its Permanent Multiplier by 2 plus the number of times it has appeared: `{"value_to_change": "permanent_multiplier", "anim": "shake", "diff": {"starting_value": 2, "var_math": [{"+": "times_displayed"}]}}`

...a good description for Cool Symbol would be as follows: `"Gives <icon_coin><color_FBF236>25<end> when <text_color_keyword>destroyed<end>. <text_color_keyword>Destroys<end> adjacent <icon_hover_coin>. Adjacent <icon_cat> permanently give <icon_coin><color_FBF236>2<end> more. Permanently gives <text_color_keyword>2x<end> more <icon_coin> plus <text_color_keyword>1x<end> more <icon_coin> for each appearance."`. This will render like so:

![](https://raw.githubusercontent.com/TrampolineTales/LBAL-Modding-Docs/main/images/cool_symbol_description.png)