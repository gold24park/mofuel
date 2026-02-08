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
    game_state.gd     # Match state management (inventory + deck 소유)
    meta_state.gd     # Between-match state (upgrades)
    inventory.gd      # Inventory — 영구 주사위 컬렉션 (class_name Inventory)
    inventory_manager.gd  # Deck — 스테이지 로컬 덱 (class_name Deck)
    dice_registry.gd  # Dice type loader
    category_registry.gd  # Category loader
    scoring.gd        # Score calculation
    dice_*.gd         # Dice type/instance classes
    category_*.gd     # Category/upgrade classes
    effect_context.gd     # 효과 실행 컨텍스트
    effect_result.gd      # 효과 결과 (시각적 피드백 포함)
    effect_processor.gd   # 수집→적용 파이프라인
    effect_condition.gd   # 조건부 효과 (Resource)
    composite_condition.gd # AND/OR 복합 조건
    /state_machine/       # Game state machine
      game_state_machine.gd   # State machine controller
      game_state_base.gd      # Base state class
      /states/
        setup_state.gd        # 게임 초기화
        pre_roll_state.gd     # 첫 굴림 전 (Hand→Active 선택)
        rolling_state.gd      # 물리 시뮬레이션 중
        post_roll_state.gd    # 굴린 후 (Keep/Reroll/Score)
        scoring_state.gd      # 카테고리 선택
        game_over_state.gd    # 승/패 결과
    /effects/             # Dice effect subclasses
      modifier_effect.gd           # 범용 점수 수정 (Data-driven)
      action_effect.gd             # 게임 상태 변경 (드로우/파괴/변환)

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
    /hand_display/    # Hand bar (고정 10슬롯 + DiscardSlot + DrawButton)
    /quick_score/     # Scoring options (유일한 스코어링 UI, Burst 포함)
    /game_over/       # Win/lose screen
    /upgrade_screen/  # Category upgrade UI

  /resources/         # Data definitions
    /dice_types/      # (비어있음 — 데이터는 globals/dice_types.gd)
    /categories/      # Category .tres files
```

### Game Flow
1. **SETUP**: 게임 초기화, Inventory → Deck(deep-copy) → Hand로 주사위 드로우 (초기 5개)
2. **PRE_ROLL**: Hand에서 5개를 선택하여 Active로 배치
   - Hand == 5 & Active == 0 → **자동 활성화** (순차 애니메이션)
   - Hand > 5 → Hand UI에서 주사위 클릭 → Active로 올라감 (애니메이션)
   - Active 주사위 클릭 → Hand로 내려감
   - **Discard**: Hand 주사위를 DiscardSlot(빨간 X)으로 드래그 앤 드롭 (hand > 5일 때만)
   - **Draw 버튼**: Hand 바 우측 "+" 버튼, Deck pool에서 Hand로 1개 드로우 (라운드당 횟수 제한)
   - 5개 선택 완료 시 Roll 버튼 활성화
3. **ROLLING**: Swipe to roll all 5 dice (물리 시뮬레이션 중 입력 차단)
4. **POST_ROLL**:
   - **자동 정렬**: 굴림 완료 후 주사위 눈 오름차순으로 자동 정렬 (물리적 위치 이동)
   - **효과 발동**: 정렬된 순서(인접 관계)에 따라 ON_ROLL, ON_ADJACENT_ROLL 효과 적용
   - Click dice to select for reroll (리롤 시에도 정렬 및 효과 재적용)
   - REROLL 버튼 (Roll 버튼과 겸용): 선택된 주사위 리롤 (최대 2회)
   - Quick Score panel로 직접 점수 선택 (End Turn 없음)
5. **SCORING**: QuickScore에서 카테고리 선택 (ScoreCard 제거됨)
   - 모든 카테고리 무제한 사용 가능
   - **Burst**: 0점으로 턴 넘기기 옵션 (항상 표시)
6. **라운드 전환**: Active 5개가 Hand로 돌아감 → PRE_ROLL (자동 드로우 없음)
7. **GAME_OVER**: 100 points in 5 rounds to win

### State Management

**State Machine 기반 게임 흐름 관리:**

```
enum Phase { SETUP, PRE_ROLL, ROLLING, POST_ROLL, SCORING, GAME_OVER }
```

| Phase | 설명 | 허용 액션 |
|-------|------|-----------|
| `SETUP` | 게임 초기화 (1회성) | - |
| `PRE_ROLL` | 첫 굴림 전 | Hand→Active 선택, Discard, Draw, Roll |
| `ROLLING` | 물리 시뮬레이션 중 | 입력 차단 |
| `POST_ROLL` | 굴린 후 | Keep, Reroll, Score |
| `SCORING` | QuickScore에서 카테고리 선택 | Score 선택 |
| `GAME_OVER` | 승/패 결과 | Restart, Upgrade |

**상태 전환 흐름:**
```
SetupState → PreRollState → RollingState → PostRollState
                 ↑              ↑               │
                 │              └───(reroll)────┤
                 │                              │
                 └──────────────────────────────┤
                                                ↓
                                         ScoringState
                                                │
                                    ┌───────────┴───────────┐
                                    ↓                       ↓
                              PreRollState            GameOverState
                              (다음 라운드)
```

**핵심 클래스:**
- **GameStateMachine**: 상태 전환 관리, game.tscn의 자식 노드
- **GameStateBase**: 상태 베이스 클래스 (enter/exit/update/handle_input)
- **GameState**: Autoload singleton for match data (Phase, score, rerolls, inventory, deck 등)
- **MetaState**: Autoload singleton for upgrades (persists between matches)
- **Inventory**: 영구 주사위 컬렉션 (RefCounted, `GameState.inventory`)
- **Deck**: 스테이지 로컬 덱 — pool/hand/active_dice (RefCounted, `GameState.deck`)

### Dice Type System
- Resource-based architecture for 100+ dice types
- **face_values**: DiceTypeResource 속성, 0=와일드카드 센티널
- **ModifierEffect**: 점수 수정 (value_bonus, value_multiplier, permanent_bonus, permanent_multiplier)
- **ActionEffect**: 게임 상태 변경 (ADD_DRAWS, DESTROY_SELF, TRANSFORM)
- Comparisons(조건부 필터)는 베이스 클래스(DiceEffectResource)에서 공유
- Extensible via `DiceTypes.ALL` in `globals/dice_types.gd`

### Category System (9 카테고리)
- **하이다이스** (HIGH_DICE): 가장 높은 주사위 1개 점수
- **원 페어** (ONE_PAIR): 같은 눈 2개의 합
- **투 페어** (TWO_PAIR): 서로 다른 페어 2쌍의 합
- **트리플** (TRIPLE): 같은 눈 3개의 합
- **스몰 스트레이트** (SMALL_STRAIGHT): 연속 4개 → 고정 15점
- **풀하우스** (FULL_HOUSE): 3+2 조합 → 전체 합
- **라지 스트레이트** (LARGE_STRAIGHT): 연속 5개 → 고정 30점
- **포카드** (FOUR_CARD): 같은 눈 4개 → 전체 합
- **파이브카드** (FIVE_CARD): 같은 눈 5개 → 고정 50점
- 모든 카테고리 무제한 사용 가능
- Multiplier upgrade: Increase score multiplier (MetaState 경유)
- **Burst**: 특수 카테고리 (category_id: "burst"), 0점으로 턴 넘기기. CategoryRegistry에 없고 QuickScore에서 하드코딩

### Inventory / Deck System
- **`Inventory`** (`globals/inventory.gd`): 플레이어의 영구 주사위 컬렉션. 스테이지를 넘어 유지. 상점에서 매매 가능.
  - `init_starting_inventory()`: 게임 시작 시 `DiceTypes.STARTING_INVENTORY`로 초기 구성
  - `create_stage_copies()`: 모든 주사위를 `clone_for_stage()`로 deep-copy하여 반환
  - `add()` / `remove()`: 상점 매매용
- **`Deck`** (`globals/inventory_manager.gd`): 스테이지 로컬 덱. pool(draw pile) + hand + active_dice 관리.
  - `init_from_inventory(inv)`: Inventory에서 deep-copy하여 덱 초기화
  - `HAND_MAX = 10`: hand + active 합계 기준
  - `discard_from_hand()`: hand에서 영구 제거 (최소 5개 유지)
  - 파괴된 주사위는 Deck에서만 사라짐 (Inventory 원본 무사)
- **`DiceInstance.clone_for_stage()`**: 영구 보너스 유지, 스테이지 로컬 상태 초기화
- **`GameState.inventory`**: Inventory 인스턴스 (영구)
- **`GameState.deck`**: Deck 인스턴스 (스테이지 로컬)
- Draw: `GameState.draw_one()` → `draws_remaining` 차감, 라운드당 횟수 제한
- Signal: `pool_changed` (기존 `inventory_changed` → 리네임)

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
- **Private variables**: Prefix with `_` (e.g., `_swap_mode`, `_cached_values`)
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
- **Constructor parameters**: Use `self.` to disambiguate, not `p_` prefix
  ```gdscript
  # Good
  func _init(bias_values: Array[int] = []) -> void:
      self.bias_values = bias_values

  # Avoid
  func _init(p_bias_values: Array[int] = []) -> void:
      bias_values = p_bias_values
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
- **Match patterns**: 중첩 if 대신 match의 고급 패턴 활용
  ```gdscript
  # Pattern guard — 같은 enum을 조건별로 분기
  match op:
      CompareOp.EQ when actual is Array:
          return expected in actual
      CompareOp.EQ:
          return actual == expected

  # Array pattern — 구조적 매칭 (정렬된 배열에 적합)
  var freq = counts.values()
  freq.sort()
  match freq:
      [2, 3], [5]:    # full house or five-of-a-kind
          return true
      _:
          return false

  # Dictionary pattern + var binding — 키 존재 확인 + 구조분해
  match data:
      {"material": var mat_path, ..} when mat_path != "":
          dt.material = load(mat_path)

  # Avoid — match arm 안에 중첩 if/return
  match op:
      CompareOp.EQ:
          if actual is Array:      # 이렇게 하지 말 것
              return expected in actual
          return actual == expected
  ```

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
- Use `set_enabled()` pattern to disable input during transitions/animations

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
| `DiceEffectResource` | 효과 베이스 클래스 (Target, CompareField, CompareOp enum + comparison 로직) |
| `ModifierEffect` | 점수 수정 효과 (ModifyTarget enum, delta) |
| `ActionEffect` | 게임 상태 변경 효과 (Action enum, delta, params) |
| `EffectContext` | 효과 실행 시 컨텍스트 (source_dice, all_dice 등) |
| `EffectResult` | 효과 결과 + 시각적 피드백 정보 |
| `EffectProcessor` | 수집→적용 파이프라인 (ModifierEffect만 처리, ActionEffect는 별도) |
| `EffectCondition` | Resource 기반 조건 (Inspector에서 편집) |

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

### Comparisons (조건부 필터)

DiceEffectResource 베이스 클래스에서 공유되는 조건 시스템:
```gdscript
enum CompareField { TYPE, GROUP, VALUE, PROBABILITY, INDEX, ROLL_COUNT }
enum CompareOp { EQ, NOT, IN, GTE, LT, MOD }
```

JSON 예시:
```json
"comparisons": [{"a": "group", "b": "peasant"}, {"a": "value", "b": 6, "op": "gte"}]
```

### Adjacency System

5개 주사위 배치에서 인접 관계:
```
[0] - [1] - [2] - [3] - [4]
 └─────┘   └─────┘   └─────┘
 adjacent  adjacent  adjacent
```

### Scoring Formula (Balatro-style)

모든 주사위가 bonus/multiplier로 기여하는 풀 기반 점수 계산:

```
final_score = (base + Σ value_bonus) × (1 + Σ extra_mult)
```

- **base**: 카테고리가 결정하는 기본 점수 (패턴 매칭된 주사위의 raw value 합)
- **Σ value_bonus**: 모든 활성 주사위의 value_bonus 합산
- **Σ extra_mult**: 모든 활성 주사위의 (value_multiplier - 1) 합산
  - 기본 배수 1.0을 빼서 합산 → 효과 없는 주사위(×1)는 0 기여

| 풀 | 구성 | 설명 |
|-----|------|------|
| `base` | 카테고리별 | 패턴 매칭된 주사위의 raw value 합 (고정점수 카테고리는 fixed_score) |
| `value_bonus` | 모든 주사위 | 효과에 의한 가산 (양수/음수 모두 가능) |
| `extra_mult` | 모든 주사위 | value_multiplier - 1 (×3 주사위 → +2 기여) |

예시: 주사위 `[3,3,2,5,6]`, bonus `[+1,+2,0,0,+3]`, mult `[1,1,2,1,1]`, 원페어(3-3)
→ `(6 + 6) × (1 + 1) = 24`

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
var groups: Array[String] = ["gem", "valuable"]

func has_group(group: String) -> bool:
    return group in groups
```

### Reference

- 로컬 문서: `docs/luckbe_a_landload_modding_docs/`
- 원본 위키: https://github.com/TrampolineTales/LBAL-Modding-Docs/wiki

## Adding New Content

### New Dice Type
1. Add entry in `globals/dice_types.gd` → `DiceTypes.ALL`
2. Set `id`, `display_name`, `description`, `groups`
3. Set `face_values` for custom face mapping (0 = wildcard)
4. Add effects array (enum 직접 참조: `T.ADJACENT`, `M.VALUE_BONUS` 등)

### New Category
1. Create `.tres` in `/resources/categories/`
2. Set `category_type` to one of 9 types (HIGH_DICE ~ FIVE_CARD)
3. Set `fixed_score` for fixed-score categories (SMALL_STRAIGHT, LARGE_STRAIGHT, FIVE_CARD)
4. Configure `base_uses`, `max_uses`, `base_multiplier`, `max_multiplier`
5. Add scoring logic in `scoring.gd` if new CategoryType added

### New Effect

`DiceTypes.ALL`의 effects 배열에 Dictionary로 추가 (enum 직접 참조):

**ModifierEffect** (점수 수정):
```gdscript
{
    "type": "ModifierEffect",
    "target": T.ADJACENT,
    "comparisons": [{"a": F.GROUP, "b": "peasant"}],
    "modify_target": M.VALUE_BONUS,
    "delta": 2,
    "anim": "bounce",
}
```
4 orthogonal axes: target (WHO), comparisons (WHEN), modify_target (WHAT), delta (HOW MUCH)

**ActionEffect** (게임 상태 변경):
```gdscript
{
    "type": "ActionEffect",
    "target": T.SELF,
    "comparisons": [{"a": F.VALUE, "b": 6}],
    "action": A.ADD_DRAWS,
    "delta": 1,
}
```
Actions: `A.ADD_DRAWS`, `A.DESTROY_SELF`, `A.TRANSFORM` (params: `{"to": "type_id"}`)

### Built-in Effects

| 효과 | 설명 |
|------|------|
| `ModifierEffect` | 점수 수정: value_bonus, value_multiplier, permanent_bonus, permanent_multiplier |
| `ActionEffect` | 게임 상태 변경: ADD_DRAWS, DESTROY_SELF, TRANSFORM |

면 매핑과 와일드카드는 `DiceTypeResource.face_values`로 처리 (효과가 아닌 주사위 속성).

## Common Pitfalls

### DiceManager 배치 메서드 구분
- `set_dice_to_hand_position()`: 모든 주사위를 화면 아래로 이동 + **`visible = false`** (숨김용)
- `set_active_positions_immediate(count)`: 주사위를 Active 위치에 배치 + **`visible = true`** (즉시 표시)
- `animate_single_to_active(index)`: Hand→Active 애니메이션 (visible=true 포함, await 가능)
- 자동 활성화 시 반드시 `set_dice_to_hand_position()` → `animate_single_to_active()` 순서로 호출

### PRE_ROLL 자동 활성화 조건
`_try_auto_activate()`는 3가지 조건이 **모두** 충족될 때만 발동:
1. `!_is_animating`
2. `hand.size() == 5`
3. `active_dice.size() == 0`

호출 시점: PRE_ROLL 진입 후, Discard 완료 후, Draw 완료 후

### Hand/Active 용량 체크
- `can_draw()`: `hand.size() + active_dice.size() < HAND_MAX` (active 포함!)
- Draw 시 active를 hand로 되돌리지 않음 — active 상태 유지가 자연스러운 UX
- Discard: Hand 주사위를 DiscardSlot으로 드래그 앤 드롭, `hand.size() > 5`일 때만 가능

### Burst 카테고리
- CategoryRegistry에 등록되지 않은 특수 ID ("burst")
- QuickScore에서 하드코딩으로 항상 마지막에 표시
- `GameState.record_score("burst", 0)`: upgrade 조회 스킵, 점수 0
- `ScoringState._process_scoring()`: burst일 때 효과 계산 스킵

### 시그널 연결/해제 대칭
- State의 `_connect_signals()`/`_disconnect_signals()`는 반드시 대칭이어야 함
- 시그널 추가 시 양쪽 모두 업데이트 — 한쪽만 하면 disconnect 에러 또는 중복 연결
- RollButton은 PRE_ROLL(Roll)과 POST_ROLL(Reroll) 겸용 — phase에 따라 다른 시그널 emit
