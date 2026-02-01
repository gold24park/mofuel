# var_math

A dictionary with the key of `"var_math"` can be passed to both the `"a"` and `"b"` variables of a [comparison](https://github.com/TrampolineTales/LBAL-Modding-Docs/wiki/Comparisons), as well as an effect's `"diff"` variable.

The Dictionary will eventually become a number. The number will be based on the key/value pairs within the Array.

For example, let's say this is part of an effect on a symbol:

`"diff": {"starting_value": 6, "var_math": [{"*": "times_coins_given"}, {"/": "times_displayed"}], "round": true}`

`diff` will be equal to 6, multiplied by the number of times the symbol has given 1 coin or more, divided by the number of times the symbol has appeared. The final result will be rounded up.

### Variables

The following are the variables that can be passed to the Dictionary:

### Dictionary Variables

| Type | Variable | Notes |
| ----------- | ----------- | ----------- |
| Array | var_math | An Array of Dictionaries. The dictionaries must contain one of the following keys as the first key in the dictionary: `"+"`, `"-"`, `"*"`, or `"/"` |
| Multiple | starting_value | The value that will be modified by the key/value pairs in the `var_math` Array. `0` by default. Can be passed an Int/Float, or a String which will be replaced with the variable with the same name as the String. |
| Bool | target_self | If `true`, the `starting_value` will check for replacement variables on the originating symbol/item. Useful if the effect containing this Dictionary is applied to a symbol/item other than the originating one. |
| Bool | abs | If `true`, the resulting value will be its [absolute value](https://en.wikipedia.org/wiki/Absolute_value). |

### var_math Variables

The following are the variables that can be passed to the `var_math` Array:

| Type | Variable | Notes |
| ----------- | ----------- | ----------- |
| Multiple | + | A value to be added. Can be passed an Int/Float, or a String which will be replaced with the variable with the same name as the String. |
| Multiple | - | A value to be subtracted. Can be passed an Int/Float, or a String which will be replaced with the variable with the same name as the String. |
| Multiple | * | A value to be multiplied. Can be passed an Int/Float, or a String which will be replaced with the variable with the same name as the String. |
| Multiple | / | A value to be divided. Can be passed an Int/Float, or a String which will be replaced with the variable with the same name as the String. |
| Bool | target_self | If `true`, the `+`, `-`, `*`, or `/` will check for replacement variables on the originating symbol/item. Useful if the effect containing this Dictionary is applied to a symbol/item other than the originating one. |
| Bool | abs | If `true`, the resulting value will be its [absolute value](https://en.wikipedia.org/wiki/Absolute_value). |

Keep in mind that these keys will be read from left to right, and will ignore the algebraic order of operations.

### rand_num Variables

`rand_num` is a Dictionary that can be passed to `+`, `-`, `*`, `/`, or `starting_value` which will be replaced with a random number.

The following are the variables that can be passed to the `rand_num` Dictionary:

| Type | Variable | Notes |
| ----------- | ----------- | ----------- |
| Int/Float | min | The minimum value that the random number generator can roll. |
| Int/Float | max | The maximum value that the random number generator can roll. |
| Bool | floor | If `true`, the resulting number will be reduced to the nearest integer. |
| Bool | ceil | If `true`, the resulting number will be increased to the nearest integer. |
| Bool | round | If `true`, the resulting number will be rounded up to the nearest integer. |

Keep in mind the random number will have numbers past the decimal point if you don't use `floor`, `ceil`, or `round`.

### Symbol Variables

The following are the variables that can replace the String in `+`, `-`, `*`, `/`, or `starting_value` if the effect targets a symbol:

* Every value listed under [Symbol Variables](https://github.com/TrampolineTales/LBAL-Modding-Docs/wiki/Symbol-Variables)

* Every value listed under [Comparisons - "a" variables](https://github.com/TrampolineTales/LBAL-Modding-Docs/wiki/Comparisons#a-variables) that doesn't specify "Item Exclusive."

### Item Variables

The following are the variables that can replace the String in `+`, `-`, `*`, `/`, or `starting_value` if the effect targets an item:

* Every value listed under [Item Variables](https://github.com/TrampolineTales/LBAL-Modding-Docs/wiki/Item-Variables)

* Every value listed under [Comparisons - "a" variables](https://github.com/TrampolineTales/LBAL-Modding-Docs/wiki/Comparisons#a-variables) that doesn't specify "Cannot be used on Items."

### Caveats

The following variables must be passed as a dictionary to `+`, `-`, `*`, `/`, or `starting_value`:

| Type | Variable | Notes |
| ----------- | ----------- | ----------- |
| Int | counted_symbols | For example, the following will be equal to the total number of Emeralds minus 5: `{"starting_value": {"counted_symbols": "emerald"}, "var_math": [{"-": 5}]}` |
| Multiple | saved_values | For example, the following will be equal to the 4th value in the `saved_values` Array times 2: `{"starting_value": {"saved_values": {"value_num": 3}}, "var_math": [{"*": 2}]}` |