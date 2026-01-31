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
    dice_*.gd         # Dice type/instance classes
    category_*.gd     # Category/upgrade classes
    /effects/         # Dice effect subclasses
      bias_effect.gd
      score_multiplier_effect.gd
      wildcard_effect.gd       # trigger_values로 조건부/항상 와일드 통합
      face_map_effect.gd       # 고정값, 짝수/홀수만 등 모두 표현 가능

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
- Effect subclasses: BiasEffect, ScoreMultiplierEffect, WildcardEffect, FaceMapEffect
- Each effect is a separate class with typed @export properties
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
- **Typed arrays/dictionaries**: Use `Array[int]`, `Dictionary[String, Resource]` instead of untyped collections
  ```gdscript
  # Good - type-safe
  var categories: Dictionary[String, CategoryResource] = {}
  func get_all() -> Array[CategoryResource]:

  # Avoid - no type safety
  var categories: Dictionary = {}
  func get_all() -> Array:
  ```
- **Typed local variables**: Use `:=` for type inference
  ```gdscript
  var upgrade := CategoryUpgrade.new()
  var cat := CategoryRegistry.get_category(id)
  ```
- **@export variables**: Use for Inspector-tunable values instead of hardcoded constants
  ```gdscript
  # Good - tunable in Inspector
  @export var roll_height: float = 12.0
  @export var multiplier_upgrade_step: float = 0.5

  # Avoid - requires code change
  const ROLL_HEIGHT: float = 12.0
  extra_multiplier += 0.5  # magic number
  ```
- **Helper functions**: Extract repeated logic into private helper functions
  ```gdscript
  func _keep_all_dice() -> void:
      for i in range(5):
          if i not in dice_manager.get_kept_indices():
              dice_manager.keep_dice(i)
  ```
- **Region blocks**: Use `#region` / `#endregion` to organize code sections
- **class_name**: Add `class_name` to classes that are referenced by other scripts for type safety

### Type Safety & Null Handling
- **Return types**: Always specify return types for public functions
  ```gdscript
  # Good
  func get_upgrade(id: String) -> CategoryUpgrade:

  # Avoid
  func get_upgrade(id: String):
  ```
- **Assert for invariants**: Use `assert()` for conditions that must always be true
  ```gdscript
  func get_total_uses() -> int:
      assert(category != null, "CategoryUpgrade not initialized")
      return category.base_uses + extra_uses
  ```
- **Avoid magic numbers**: Extract to constants or @export variables
  ```gdscript
  # Good - self-documenting
  return category_type <= CategoryType.SIXES

  # Avoid - what does 5 mean?
  return category_type <= 5
  ```

### DRY (Don't Repeat Yourself)
- **Generic filter functions**: Use Callable for filtering logic
  ```gdscript
  func _filter_categories(predicate: Callable) -> Array[CategoryResource]:
      var result: Array[CategoryResource] = []
      for cat in categories.values():
          if predicate.call(cat):
              result.append(cat)
      return result

  func get_number_categories() -> Array[CategoryResource]:
      return _filter_categories(func(cat): return cat.is_number_category())
  ```
- **Helper methods on Resources**: Add query methods to Resource classes
  ```gdscript
  # In CategoryResource
  func is_number_category() -> bool:
      return category_type <= CategoryType.SIXES
  ```
- **Factory helpers**: Extract object creation into private functions
  ```gdscript
  func _create_upgrade(cat: CategoryResource) -> CategoryUpgrade:
      var upgrade := CategoryUpgrade.new()
      return upgrade.init_with_category(cat)
  ```

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
1. Create new class in `/globals/effects/` extending `DiceEffectResource`
2. Add @export properties for effect parameters
3. Override relevant methods:
   - `apply_to_roll(base_value: int) -> int` for roll modification
   - `get_score_multiplier() -> float` for score modification
   - `is_wildcard_value(value: int) -> bool` for wildcard behavior
```gdscript
# Example: globals/effects/lucky_seven_effect.gd
class_name LuckySevenEffect
extends DiceEffectResource

@export var bonus_multiplier: float = 1.5

func apply_to_roll(base_value: int) -> int:
    # 7이 나올 확률 추가 (주사위는 1-6이므로 특수 처리)
    return base_value

func get_score_multiplier() -> float:
    return bonus_multiplier
```
