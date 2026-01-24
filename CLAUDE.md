# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**mofuel** is a Godot 4.5 mobile game project featuring a Yacht-like dice game with physics simulation and meta-progression.

## Development Commands

```bash
# Open project in Godot editor
godot --editor --path .

# Run the project
godot --path .

# Run the game scene
godot --path . res://scenes/game/game.tscn

# Export for mobile (requires export templates configured)
godot --headless --export-debug "Android" ./build/mofuel.apk
```

## Architecture

### Entry Point
- **Main Scene:** `scenes/game/game.tscn` - Yacht-like dice game

### Directory Structure
```
/mofuel/
  /globals/           # Autoload singletons and shared classes
    game_state.gd     # Match state management
    meta_state.gd     # Between-match state (upgrades)
    dice_registry.gd  # Dice type loader
    category_registry.gd  # Category loader
    scoring.gd        # Score calculation
    dice_*.gd         # Dice type/effect/instance classes
    category_*.gd     # Category/upgrade classes

  /entities/          # Reusable game entities
    /dice/            # 3D dice with physics
    /dice_manager/    # Manages 5 dice for game
    /table/           # Play surface with walls

  /scenes/            # Game scenes
    /game/            # Main game scene
      /components/    # Reusable scene components (SwipeDetector, etc.)
    /world/           # Legacy single-dice demo

  /ui/                # UI components
    /hud/             # Top status bar
    /action_buttons/  # Reroll, Replace, End Turn buttons
    /reserve_display/ # Reserve dice display (bottom center)
    /quick_score/     # Fast scoring options (right side after roll)
    /score_card/      # Category selection (full scorecard)
    /game_over/       # Win/lose screen
    /upgrade_screen/  # Category upgrade UI

  /resources/         # Data definitions
    /dice_types/      # Dice type .tres files
    /categories/      # Category .tres files
```

### Game Flow
1. **Setup**: Draw 7 dice to Reserve, place 5 in Active
2. **Round Start**: Swipe to roll all 5 dice (direction/speed affects throw)
3. **Action**:
   - Click dice to Keep (moves to top, locked for round)
   - Swipe to reroll unkept dice (2 rerolls max)
   - Quick Score panel appears on right for fast category selection
   - Replace option available (swap kept dice with Reserve)
4. **Scoring**: Select category from Quick Score or Score Card
5. **Win/Lose**: 100 points in 5 rounds to win

### Replace Mechanic
- Select exactly 1 active dice → Replace button enabled (if Reserve > 0)
- Press Replace → enters replace mode (action buttons hidden)
- Click a dice from Reserve display → selected active dice is discarded, reserve dice takes its place
- ESC to cancel replace mode

### State Management
- **GameState**: Autoload singleton for match state
- **MetaState**: Autoload singleton for upgrades (persists between matches)
- **Signal-based**: UI reacts to state changes via signals

### Dice Type System
- Resource-based architecture for 100+ dice types
- Effects: NORMAL, BIASED, FIXED, MULTIPLIER, WILDCARD
- Extensible via .tres files in `/resources/dice_types/`

### Category Enhancement System
- Uses upgrade: Increase category usage count
- Multiplier upgrade: Increase score multiplier
- Persists between matches via MetaState

## Godot 4.5 Conventions

- **GDScript style:** Use snake_case for functions/variables, PascalCase for classes
- **Scene files:** `.tscn` (text-based scene format)
- **Resources:** `.tres` (text-based resource format)
- **3D assets:** GLB format (binary glTF 2.0)
- **Rendering:** Mobile renderer configured
- **Autoloads:** DiceRegistry, CategoryRegistry, MetaState, GameState (load order matters)

## Coding Guidelines

### Separation of Concerns
- **Scene scripts (scenes/)**: High-level composition, signal connections, game flow coordination
- **Entity scripts (entities/)**: Reusable game logic, self-contained behavior
- **Component scripts**: Extract input handling, animations, etc. into separate components
  - Example: `SwipeDetector` handles swipe input, emits `swiped` signal
  - Scene script connects to signal and handles game logic
- **Globals (globals/)**: State management, registries, pure logic (no UI/visuals)

### Code Style
- **Private variables**: Prefix with `_` (e.g., `_replace_mode`, `_cached_values`)
- **Typed arrays**: Use `Array[int]`, `Array[RigidBody3D]` instead of untyped `Array`
- **@export variables**: Use for Inspector-tunable values instead of constants
  ```gdscript
  # Good - tunable in Inspector
  @export var roll_height: float = 12.0

  # Avoid - requires code change
  const ROLL_HEIGHT: float = 12.0
  ```
- **Helper functions**: Extract repeated logic into private helper functions
  ```gdscript
  func _keep_all_dice() -> void:
      for i in range(5):
          if i not in dice_manager.get_kept_indices():
              dice_manager.keep_dice(i)
  ```
- **Region blocks**: Use `#region` / `#endregion` to organize code sections

### Mobile Considerations
- Touch input: Track first touch index only (`event.index == 0`) to avoid multi-touch glitches
- Swipe detection: Exclude UI margins (top/bottom) from swipe zone
- Use `set_enabled()` pattern to disable input during modal states (e.g., Replace mode)

### Signal Design
- Emit rich data when effects need visual feedback
- UI components should emit high-level intents, not raw input data
  ```gdscript
  # Good - high-level intent
  signal swiped(direction: Vector2, strength: float)

  # Avoid - raw input
  signal mouse_released(position: Vector2)
  ```

## Adding New Content

### New Dice Type
1. Create `.tres` in `/resources/dice_types/`
2. Set `id`, `display_name`, `description`, `color`, `rarity`
3. Add effects array with DiceEffectResource

### New Category
1. Create `.tres` in `/resources/categories/`
2. Set scoring rules in `category_type`
3. Configure `base_uses`, `max_uses`, `base_multiplier`, `max_multiplier`

### New Effect Type
1. Add to `DiceEffectResource.EffectType` enum
2. Implement logic in `DiceInstance.roll()` or `apply_to_score()`
