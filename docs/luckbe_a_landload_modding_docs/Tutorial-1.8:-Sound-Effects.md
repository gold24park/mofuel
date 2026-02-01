# Sound Effects

There are a few best practices we should follow to keep our modded sound effects in-line with the game's base sound effects. First we'll go over how to make a non-jarring sound effect, then we'll go over how to add it to a symbol effect.

## Best Practices

### Timing

Depending on the animation that the symbol effect uses, we should make our sound effect follow different timings to match the animation (at the default animation speed).

#### Circle

![](https://raw.githubusercontent.com/TrampolineTales/LBAL-Modding-Docs/main/images/circle_anim.gif)

If our effect uses the `"circle"` animation, we should keep our sound effect to about 0.56 seconds.

#### Rotate

![](https://raw.githubusercontent.com/TrampolineTales/LBAL-Modding-Docs/main/images/rotate_anim.gif)

If our effect uses the `"rotate"` animation, we should keep our sound effect to about 0.52 seconds.

#### Shake

![](https://raw.githubusercontent.com/TrampolineTales/LBAL-Modding-Docs/main/images/shake_anim.gif)

If our effect uses the `"shake"` animation, we should keep our sound effect to about 0.26 seconds.

#### Bounce

![](https://raw.githubusercontent.com/TrampolineTales/LBAL-Modding-Docs/main/images/bounce_anim.gif)

If our effect uses the `"bounce"` animation, we should keep our sound effect to about 0.49 seconds.

We should also time our bounce sounds (or whatever sounds we're making) to the times when the symbol will bounce in the animation. For example, if our symbol goes "ha Ha HA!" we want to time the start of each "ha" to 0.03 seconds, 0.215 seconds, and 0.395 seconds, respectively.

### Volume

In order to keep our sound effects from shattering eardrums -- while making them audible at all -- we should keep our peaks no louder than -6dB and our quietest sounds no quieter than -15dB.

## Implementation

Once we've edited and exported a sound effect in our audio editor of choice (sound effects _MUST_ be saved as `.wav` files) we can add it to the `sfx` folder of our mod folder.

We can save the name of the `.wav` file as whatever we want, except for the fact that it _MUST_ end in the number 0. If we wanted a sound effect named "hahaha" our file name would be `hahaha0.wav`.

The reason we have the "0" is in case we want to have variants of the sound effect that can play randomly. Like how the dice symbols actually have 10 different random variants of their "rolling" sound effect. If we have three different files named `hahaha0.wav`, `hahaha1.wav`, and `hahaha2.wav` the game will select one at random if we associate our symbol effect with the "hahaha" family of sound effects.

In order to have one of our "hahaha" sound effects play during an effect with an animation, we just need to add the following to said effect: `"sfx_override": "hahaha"`. If we want to use a different modded sound effect or a sound effect that's in the base game, we just need to replace "hahaha" with a [string of that sound effect family](https://github.com/TrampolineTales/LBAL-Modding-Docs/wiki/Sound-Effect-Index).

In the next tutorial, we'll go over how to add a description to Cool Symbol:

[Tutorial: Descriptions](https://github.com/TrampolineTales/LBAL-Modding-Docs/wiki/Tutorial-1.9:-Descriptions)