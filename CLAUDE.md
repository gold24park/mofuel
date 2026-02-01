# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**mofuel** is a Godot 4.6 mobile game project featuring a Yacht-like dice game with physics simulation and meta-progression.

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
    effect_context.gd     # 효과 실행 컨텍스트
    effect_result.gd      # 효과 결과 (시각적 피드백 포함)
    effect_processor.gd   # 수집→정렬→적용 파이프라인
    effect_condition.gd   # 조건부 효과 (Resource)
    composite_condition.gd # AND/OR 복합 조건
    /effects/             # Dice effect subclasses
      bias_effect.gd
      score_multiplier_effect.gd
      wildcard_effect.gd           # trigger_values로 조건부/항상 와일드 통합
      face_map_effect.gd           # 고정값, 짝수/홀수만 등 모두 표현 가능
      adjacent_bonus_effect.gd     # 인접 주사위 보너스
      group_bonus_effect.gd        # 그룹 태그 매칭 보너스
      on_adjacent_roll_effect.gd   # 인접 굴림 반응 효과

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
    /action_buttons/  # Reroll, Swap, End Turn buttons
    /reserve_display/ # Hand dice display (bottom center)
    /quick_score/     # Fast scoring options (right side after roll)
    /score_card/      # Category selection (full scorecard)
    /game_over/       # Win/lose screen
    /upgrade_screen/  # Category upgrade UI

  /resources/         # Data definitions
    /dice_types/      # Dice type .tres files
    /categories/      # Category .tres files
```

### Game Flow
1. **Game Start**: Inventory에서 Hand로 주사위 드로우 (초기 7개)
2. **Round Start**: Hand에서 랜덤하게 5개를 Active로 뽑아옴
3. **Roll**: Swipe to roll all 5 dice (direction/speed affects throw)
4. **Action**:
   - Click dice to Keep (moves to top, locked for round)
   - Swipe to reroll unkept dice (2 rerolls max)
   - Quick Score panel appears on right for fast category selection
   - Swap option available (swap 1 active dice with Hand)
5. **Scoring**: Select category from Quick Score or Score Card
6. **Round End**: Active 5개가 Hand로 돌아감, Inventory에서 1개 드로우
7. **Win/Lose**: 100 points in 5 rounds to win

### Swap Mechanic
- Select exactly 1 active dice → Swap button enabled (if Hand > 0)
- Press Swap → enters swap mode (action buttons hidden)
- Click a dice from Hand display → selected active dice goes to Hand, Hand dice takes its place
- ESC to cancel swap mode

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

## Godot 4.6 Conventions

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

### Sanitize on Init
데이터 유효성 검사를 사용 시점이 아닌 설정 시점에 수행하여 반복적인 방어적 코드 제거.

- **설정 시점에 검증**: 생성자, 세터, 팩토리 메서드에서 검증 - 사용 시점 아님
  ```gdscript
  # Good - 생성 시 한 번만
  static func create(index: int, all_dice: Array) -> Context:
      assert(index >= 0 and index < all_dice.size(),
          "index out of bounds")
      # ...

  # Avoid - 매번 사용할 때
  func process() -> void:
      if index >= 0 and index < all_dice.size():  # 불필요한 반복 검사
          do_something()
  ```
- **불변성은 assert + 세터**: 구조적으로 보장되는 조건 (배열 크기, 범위 등)
  ```gdscript
  # @export 변수에 세터로 검증 (.tres 로딩 시에도 동작)
  @export var face_map: Array[int] = [0, 1, 2, 3, 4, 5, 6]:
      set(value):
          face_map = value
          assert(face_map.size() == 7, "face_map must have exactly 7 elements")
          for i in range(1, 7):
              assert(face_map[i] >= 1 and face_map[i] <= 6,
                  "face_map[%d] must be 1-6" % i)
  ```
- **외부 입력은 Guard.verify**: UI, 파일, API에서 오는 데이터
  ```gdscript
  # 외부에서 호출되는 API
  func start_breathing(indices: Array) -> void:
      for i in indices:
          if not Guard.verify(i >= 0 and i < dice_nodes.size(),
                  "Invalid index %d" % i):
              continue
          dice_nodes[i].start_breathing()
  ```
- **데이터 계약 문서화**: 불변성을 주석으로 명시
  ```gdscript
  ## face_map must have exactly 7 elements (index 0 unused, 1-6 for dice faces)
  @export var face_map: Array[int] = [0, 1, 2, 3, 4, 5, 6]
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

## Effect System (LbaL-Style)

슬롯머신 로그라이크 게임 "Luck be a Landlord"에서 영감을 받은 효과 시스템.
주사위가 일렬로 정렬되어 인접 시너지를 발생시키는 구조.

### Core Classes

| 클래스 | 역할 |
|--------|------|
| `DiceEffectResource` | 효과 베이스 클래스 (Trigger, Target enum 정의) |
| `EffectContext` | 효과 실행 시 컨텍스트 (source_dice, all_dice 등) |
| `EffectResult` | 효과 결과 + 시각적 피드백 정보 |
| `EffectProcessor` | 수집→정렬→적용 파이프라인 |
| `EffectCondition` | Resource 기반 조건 (Inspector에서 편집) |

### Triggers (발동 시점)

```gdscript
enum Trigger {
    ON_ROLL,          # 주사위 굴림 완료 후
    ON_KEEP,          # 주사위 킵(잠금) 시
    ON_SCORE,         # 점수 계산 시
    ON_ADJACENT_ROLL, # 인접 주사위가 굴려졌을 때
}
```

### Targets (효과 적용 대상)

```gdscript
enum Target {
    SELF,           # 자신에게만 적용
    ADJACENT,       # 좌/우 인접 주사위에 적용
    ALL_DICE,       # 모든 활성 주사위에 적용
    MATCHING_VALUE, # 같은 눈의 주사위에 적용
    MATCHING_GROUP, # 같은 그룹 태그의 주사위에 적용
}
```

### Adjacency System

5개 주사위 배치에서 인접 관계:
```
[0] - [1] - [2] - [3] - [4]
 └─────┘   └─────┘   └─────┘
 adjacent  adjacent  adjacent
```

### Multi-Layer Scoring

```
final_score = (base_value + value_bonus) × value_multiplier
              × permanent_multiplier + permanent_bonus
```

| 변수 | 지속성 | 설명 |
|------|--------|------|
| `value_bonus` | 라운드 | 임시 가산 |
| `value_multiplier` | 라운드 | 임시 배수 |
| `permanent_bonus` | 영구 | 게임 전체 가산 |
| `permanent_multiplier` | 영구 | 게임 전체 배수 |

### Visual Feedback

`EffectResult`에 출처 정보 포함:
```gdscript
result.source_index  # 효과 발생 주사위 인덱스
result.source_name   # 주사위 이름 (툴팁용)
result.effect_name   # 효과 이름

# DiceManager에서 시그널 발생
signal effects_applied(effect_data: Array[Dictionary])
# effect_data: [{from: 1, to: 2, name: "인접 보너스"}, ...]
```

### Group/Tag System

```gdscript
# DiceTypeResource
@export var groups: Array[String] = ["gem", "valuable"]

func has_group(group: String) -> bool:
    return group in groups
```

### Reference

- 로컬 문서: `docs/luckbe_a_landload_modding_docs/`
- 원본 위키: https://github.com/TrampolineTales/LBAL-Modding-Docs/wiki

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
2. Set trigger, target, priority in `_init()`
3. Override `evaluate(context) -> EffectResult`

```gdscript
# Example: globals/effects/adjacent_bonus_effect.gd
class_name AdjacentBonusEffect
extends DiceEffectResource

@export_group("Bonus Settings")
@export var bonus_value: int = 1
@export var bonus_multiplier: float = 1.0

func _init() -> void:
    trigger = Trigger.ON_SCORE
    target = Target.ADJACENT
    priority = 200
    effect_name = "인접 보너스"

func evaluate(context) -> EffectResult:
    var result := EffectResult.new()
    result.value_bonus = bonus_value
    result.value_multiplier = bonus_multiplier
    return result
```

### Built-in Effects

| 효과 | 트리거 | 설명 |
|------|--------|------|
| `BiasEffect` | ON_ROLL | 특정 값들이 더 자주 나오도록 확률 조작 |
| `FaceMapEffect` | ON_ROLL | 물리적 면 값을 다른 값으로 매핑 |
| `ScoreMultiplierEffect` | ON_SCORE | 점수에 배수 적용 |
| `WildcardEffect` | ON_SCORE | 특정 값일 때 와일드카드로 사용 |
| `AdjacentBonusEffect` | ON_SCORE | 인접 주사위에 보너스 부여 |
| `GroupBonusEffect` | ON_SCORE | 같은 그룹 주사위에 보너스 부여 |
| `OnAdjacentRollEffect` | ON_ADJACENT_ROLL | 인접 주사위 굴림 시 자신에게 보너스 |
