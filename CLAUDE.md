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
    deck.gd              # Deck — 스테이지 로컬 덱
    dice_registry.gd  # Dice type loader
    category_registry.gd  # Category loader
    scoring.gd        # Score calculation
    dice_*.gd         # Dice type/instance classes
    category_*.gd     # Category/upgrade classes
    ornament_resource.gd  # 오너먼트 타입 정의 (shape, effects)
    ornament_instance.gd  # 오너먼트 배치 상태 인스턴스
    ornament_grid.gd      # 6x6 그리드 순수 로직
    ornament_types.gd     # 오너먼트 데이터 정의 (DiceTypes 패턴)
    ornament_registry.gd  # 오너먼트 로더 (Autoload)
    effect_context.gd     # 효과 실행 컨텍스트
    effect_result.gd      # 효과 결과 (시각적 피드백 포함)
    effect_processor.gd   # 수집→적용 파이프라인
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
    /score_display/   # 발라트로 스타일 점수 표시 (chips × mult)
    /category_breakdown/  # POST_ROLL 족보 현황 패널 (전체 족보 + 최고 하이라이트)
    /action_bar/      # POST_ROLL 액션 (Stand/Reroll/Double Down)
    /game_over/       # Win/lose screen (+ Ornaments 버튼)
    /upgrade_screen/  # Category upgrade UI
    /ornament_grid/   # 오너먼트 테트리스 배치 UI

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
   - **ScoreDisplay**: 발라트로 스타일 점수 연출 (카테고리명 → chips × mult → 최종 점수)
   - **자동 족보 선택**: 시스템이 최고 점수 카테고리 자동 선택 (수동 선택 없음)
   - **CategoryBreakdown**: 좌측 패널에 전체 족보 현황 표시 (매칭된 족보 + 최고 하이라이트)
   - **ActionBar**: Stand / Reroll / Double Down 버튼
     - **Stand**: 현재 최고 족보로 점수 확정
     - **Reroll**: 선택한 주사위 리롤 (리롤 1개 소모)
     - **Double Down**: 리롤 2개 소모, 전체 리롤, 점수 ×2 (1회 제한)
   - 리롤 불가 시 자동 Stand (점수 연출만 보여주고 종료)
5. **SCORING**: PostRollState에서 전달받은 점수를 자동 기록 (UI 선택 없음)
   - 유효 족보 없으면 자동 0점 (burst)
6. **라운드 전환**: Active 5개가 Hand로 돌아감 → PRE_ROLL (자동 드로우 없음)
7. **GAME_OVER**: 100 points in 5 rounds to win
   - **Ornaments 버튼**: 오너먼트 그리드 배치 화면 (매치 사이 관리)

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
| `POST_ROLL` | 굴린 후 (ScoreDisplay + ActionBar) | Stand, Reroll, Double Down |
| `SCORING` | 자동 점수 기록 | - (자동 처리) |
| `GAME_OVER` | 승/패 결과 | Restart, Upgrade, Ornaments |

**상태 전환 흐름:**
```
SetupState → PreRollState → RollingState → PostRollState
                 ↑              ↑               │
                 │              ├───(reroll)────┤
                 │              └──(dbl down)───┤
                 │                              │ (stand / auto)
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
  - 게임 상수: `DICE_COUNT = 5`, `MAX_FACE_VALUE = 6`, `MAX_REROLLS = 2`, `DOUBLE_DOWN_COST = 2`, `BASE_MAX_DRAWS = 1`
  - Double Down: `is_double_down`, `can_double_down()`, `DOUBLE_DOWN_MULTIPLIER = 2.0`
- **MetaState**: Autoload singleton for upgrades + ornaments (persists between matches)
  - `ornament_grid`: OrnamentGrid (6x6 배치 그리드)
  - `owned_ornaments`: Array[OrnamentInstance] (보유 오너먼트)
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
- **하이다이스** (HIGH_DICE): base_chips 0 + 가장 높은 주사위 1개
- **원 페어** (ONE_PAIR): base_chips 2 + 같은 눈 2개의 합
- **투 페어** (TWO_PAIR): base_chips 4 + 서로 다른 페어 2쌍의 합
- **트리플** (TRIPLE): base_chips 6 + 같은 눈 3개의 합
- **스몰 스트레이트** (SMALL_STRAIGHT): base_chips 8 + 패턴값의 합
- **풀하우스** (FULL_HOUSE): base_chips 8 + 전체 합
- **라지 스트레이트** (LARGE_STRAIGHT): base_chips 12 + 패턴값의 합
- **포카드** (FOUR_CARD): base_chips 12 + 전체 합
- **파이브카드** (FIVE_CARD): base_chips 15 + 전체 합
- `base_chips`: 카테고리 고유 기본 점수. 족보 계층 보장 (높은 족보 = 높은 base_chips)
- `NO_MATCH` 센티널 (`-1`): 패턴 미매칭 시 반환, bonus_pool 적용 방지
- 모든 카테고리 무제한 사용 가능
- Multiplier upgrade: Increase score multiplier (MetaState 경유)
- **Burst**: 유효 족보 없을 때 자동 0점 (category_id: "burst"). CategoryRegistry 미등록
- **CategoryBreakdown** (`ui/category_breakdown/`): POST_ROLL에서 전체 족보 현황 표시, 최고 족보 금색 하이라이트

### Inventory / Deck System
- **`Inventory`** (`globals/inventory.gd`): 플레이어의 영구 주사위 컬렉션. 스테이지를 넘어 유지. 상점에서 매매 가능.
  - `init_starting_inventory()`: 게임 시작 시 `DiceTypes.STARTING_INVENTORY`로 초기 구성
  - `create_stage_copies()`: 모든 주사위를 `clone_for_stage()`로 deep-copy하여 반환
  - `add()` / `remove()`: 상점 매매용
- **`Deck`** (`globals/deck.gd`): 스테이지 로컬 덱. pool(draw pile) + hand + active_dice 관리.
  - `init_from_inventory(inv)`: Inventory에서 deep-copy하여 덱 초기화
  - `HAND_MAX = 10`: hand + active 합계 기준
  - `discard_from_hand()`: hand에서 영구 제거 (최소 DICE_COUNT개 유지)
  - 파괴된 주사위는 Deck에서만 사라짐 (Inventory 원본 무사)
- **`DiceInstance.clone_for_stage()`**: 영구 보너스 유지, 스테이지 로컬 상태 초기화
- **`GameState.inventory`**: Inventory 인스턴스 (영구)
- **`GameState.deck`**: Deck 인스턴스 (스테이지 로컬)
- Draw: `GameState.draw_one()` → `draws_remaining` 차감, 라운드당 횟수 제한
- Signal: `pool_changed` (기존 `inventory_changed` → 리네임)

### Ornament System (테트리스 배치)
- 발라트로 조커처럼 덱을 강화하는 아이템, 6x6 그리드에 테트리스 스타일 배치
- **접근 시점**: 매치 사이 (GameOverState → Ornaments 버튼)
- **`OrnamentResource`** (`globals/ornament_resource.gd`): 타입 정의 (shape, color, effects)
  - `shape`: `Array[Vector2i]` 오프셋 (앵커 = (0,0))
  - `passive_effects`: 글로벌 패시브 `[{"type": "reroll_bonus"/"draw_bonus", "delta": N}]`
  - `dice_effects`: `Array[DiceEffectResource]` — EffectProcessor에 주입
  - `rotate_shape()`: static, `(x,y) → (y,-x)` + normalize
- **`OrnamentInstance`** (`globals/ornament_instance.gd`): 배치 상태 (RefCounted)
  - `grid_position`, `rotation` (0~3), `is_placed`, `get_occupied_cells()`
- **`OrnamentGrid`** (`globals/ornament_grid.gd`): 6x6 순수 로직 (RefCounted)
  - `can_place()` / `place()` / `remove()` / `get_cell()`
  - `get_all_passive_effects()` / `get_all_dice_effects()`
- **`OrnamentTypes`** (`globals/ornament_types.gd`): DiceTypes 패턴, `const ALL` + `STARTING_ORNAMENTS`
- **`OrnamentRegistry`** (Autoload): 파싱 + `create_instance(id)`
- **패시브 적용**: `PreRollState._apply_ornament_passives()` — rerolls/draws 보너스
- **주사위 효과**: `EffectProcessor.process_effects()` — ornament dice_effects 자동 주입
  - `EffectContext.create_global()`: source_dice=null, source_index=-1 (글로벌 효과용)
  - 오너먼트 효과는 `ALL_DICE` 타겟만 사용 (SELF/ADJACENT 무의미)
- **UI**: `ui/ornament_grid/ornament_grid_ui.tscn` — click-to-place, 회전, 제거

## Godot 4.6 Conventions

- **GDScript style:** Use snake_case for functions/variables, PascalCase for classes
- **Scene files:** `.tscn` (text-based scene format)
- **Resources:** `.tres` (text-based resource format)
- **3D assets:** GLB format (binary glTF 2.0)
- **Rendering:** Mobile renderer configured
- **Autoloads:** DiceRegistry, CategoryRegistry, OrnamentRegistry, MetaState, GameState (load order matters)

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
      for i in GameState.DICE_COUNT:
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
  func get_total_multiplier() -> float:
      assert(category != null, "CategoryUpgrade not initialized")
      return category.base_multiplier + extra_multiplier
  ```
- **Avoid magic numbers**: Use `GameState` constants for game-wide values
  ```gdscript
  # Good - self-documenting
  if hand.size() != GameState.DICE_COUNT:
  for v in range(GameState.MAX_FACE_VALUE, 0, -1):

  # Avoid - what does 5 mean?
  if hand.size() != 5:
  for v in range(6, 0, -1):
  ```
  - `GameState.DICE_COUNT` (5): Active 슬롯 수
  - `GameState.MAX_FACE_VALUE` (6): 주사위 최대 눈
  - `GameState.MAX_REROLLS` (2): 라운드당 최대 리롤
  - Entity(`dice_manager.gd`)는 자체 `const DICE_COUNT` 유지 (Autoload 미참조)

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
final_score = (base_chips + pattern_value + Σ value_bonus) × (1 + Σ extra_mult) × category_mult × (DD ? 2 : 1)
```

- **base_chips**: 카테고리 고유 기본 점수 (족보 계층 보장용)
- **pattern_value**: 패턴 매칭된 주사위의 raw value 합
- **Σ value_bonus**: 모든 활성 주사위의 value_bonus 합산
- **Σ extra_mult**: 모든 활성 주사위의 (value_multiplier - 1) 합산
  - 기본 배수 1.0을 빼서 합산 → 효과 없는 주사위(×1)는 0 기여
- **category_mult**: 카테고리 업그레이드 배수 (MetaState 경유)
- **DD**: Double Down 시 ×2

| 풀 | 구성 | 설명 |
|-----|------|------|
| `base` | `base_chips + pattern_value` | 카테고리 기본점수 + 패턴 매칭된 주사위의 합. NO_MATCH(-1)이면 0점 |
| `value_bonus` | 모든 주사위 | 효과에 의한 가산 (양수/음수 모두 가능) |
| `extra_mult` | 모든 주사위 | value_multiplier - 1 (×3 주사위 → +2 기여) |

예시: 주사위 `[3,3,2,5,6]`, bonus `[+1,+2,0,0,+3]`, mult `[1,1,2,1,1]`, 원페어(base_chips=2, 3+3=6)
→ `(2 + 6 + 6) × (1 + 1) = 28`

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
3. Set `base_chips` for hierarchy positioning (높은 족보일수록 높은 값)
4. Configure `base_multiplier`, `max_multiplier`, `multiplier_upgrade_step`
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

### New Ornament
1. Add entry in `globals/ornament_types.gd` → `OrnamentTypes.ALL`
2. Set `id`, `display_name`, `description`, `color` (Array[float] RGB)
3. Set `shape` as `Array[Vector2i]` offsets (anchor = (0,0))
4. Add `passive_effects` for global bonuses (reroll_bonus, draw_bonus)
5. Add `dice_effects` for score modifications (same format as dice effects)

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
2. `hand.size() == GameState.DICE_COUNT`
3. `active_dice.size() == 0`

호출 시점: PRE_ROLL 진입 후, Discard 완료 후, Draw 완료 후

### Hand/Active 용량 체크
- `can_draw()`: `hand.size() + active_dice.size() < HAND_MAX` (active 포함!)
- Draw 시 active를 hand로 되돌리지 않음 — active 상태 유지가 자연스러운 UX
- Discard: Hand 주사위를 DiscardSlot으로 드래그 앤 드롭, `hand + active > DICE_COUNT`일 때만 가능

### Burst 카테고리
- CategoryRegistry에 등록되지 않은 특수 ID ("burst")
- 유효 족보 없을 때 PostRollState에서 자동 0점 처리
- `GameState.record_score("burst", 0)`: upgrade 조회 스킵, 점수 0
- `ScoringState._process_scoring()`: burst일 때 효과 계산 스킵

### Double Down
- 리롤 2개 소모 (`DOUBLE_DOWN_COST = 2`), 5개 전체 리롤
- `GameState.is_double_down = true` → `record_score()`에서 `DOUBLE_DOWN_MULTIPLIER (2.0)` 적용
- 라운드당 1회 (`can_double_down()`: `rerolls >= 2 and not is_double_down`)
- `PreRollState.enter()`에서 `is_double_down = false` 리셋

### 자식 노드 Local vs World Space
- RigidBody3D에 자식으로 추가한 노드(OmniLight3D 등)의 `position`은 **로컬 좌표**
- 주사위의 `final_rotation`이 적용되면 자식 노드도 함께 회전 → 의도한 위치에서 벗어남
- 예: `position = Vector3(0, 2.5, 0)` + X축 180° 회전 → 실제로는 Y-2.5 (주사위 아래)
- **해결**: 활성화 시 `transform.basis.inverse() * 원하는_월드_오프셋`으로 역보정

### 시그널 연결/해제 대칭
- State의 `_connect_signals()`/`_disconnect_signals()`는 반드시 대칭이어야 함
- 시그널 추가 시 양쪽 모두 업데이트 — 한쪽만 하면 disconnect 에러 또는 중복 연결
- RollButton은 PRE_ROLL 전용 (ROLL! 만). POST_ROLL 액션은 ActionBar가 담당
