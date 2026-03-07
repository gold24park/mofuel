# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**mofuel** is a Godot 4.6 mobile game — a roguelike deck-building dice poker with real-time tension.

**핵심 컨셉:** 은행을 턴 후, 경찰의 추격을 따돌리고 베이스 캠프까지 무사히 도주하는 하이 텐션 다이스 레이싱. 플레이어는 주사위를 굴려 점수를 얻고, 그 점수를 **거리 환산**(도주 진행) 또는 **시간 확보**(타이머 연장) 중 하나로 치환하며, 제한 시간 안에 목표 거리를 달성해야 한다.

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
- **Main Scene:** `scenes/game/game.tscn` - 다이스 레이싱 (은행 도주)

### Directory Structure
```
/mofuel/
  /globals/           # Autoload singletons and shared classes
	game_state.gd     # Match state management (inventory + deck 소유)
	meta_state.gd     # Between-match state (upgrades)
	inventory.gd      # Inventory — 영구 주사위 컬렉션 (class_name Inventory)
	deck.gd              # Deck — 스테이지 로컬 덱
	dice_registry.gd  # Dice type loader
	hand_rank_registry.gd # Hand Rank loader
	scoring.gd        # Score calculation
	dice_*.gd         # Dice type/instance classes
	hand_rank_*.gd    # Hand Rank/upgrade classes
	gear_resource.gd      # 기어(Gear) 타입 정의 (shape, effects)
	gear_instance.gd      # 기어 배치 상태 인스턴스
	gear_grid.gd          # 트렁크(Trunk) 그리드 순수 로직
	gear_types.gd         # 기어 데이터 정의 (DiceTypes 패턴)
	gear_registry.gd      # 기어 로더 (Autoload)
	effect_context.gd     # 효과 실행 컨텍스트
	effect_result.gd      # 효과 결과 (시각적 피드백 포함)
	effect_processor.gd   # 수집→적용 파이프라인
	/state_machine/       # Game state machine
	  game_state_machine.gd   # State machine controller
	  game_state_base.gd      # Base state class
	  /states/
		setup_state.gd        # 게임 초기화 (은행 선택 후)
		pre_roll_state.gd     # 주사위 드로우 + 5개 선택 (타이머 정지)
		rolling_state.gd      # 주사위 스핀 애니메이션 (타이머 정지)
		post_roll_state.gd    # 굴린 후 (Nitro/Smoke/Reroll) + 점수→거리/시간 즉시 치환
		game_over_state.gd    # 도주 성공/체포 결과
	/effects/             # Dice effect subclasses
	  modifier_effect.gd           # 범용 점수 수정 (Data-driven)
	  action_effect.gd             # 게임 상태 변경 (드로우/파괴/변환)

  /entities/          # Reusable game entities
	/dice/            # 3D dice with physics
	/dice_manager/    # Manages 5 dice for game

  /scenes/            # Game scenes
	/game/            # Main game scene
	  /components/    # Reusable scene components (SwipeDetector, etc.)

  /ui/                # UI components
	/hud/             # 화면 최상단: 타이머 바 + 남은 거리 시각화
	/hand_display/    # 화면 하단: Hand bar (고정 8슬롯 + DrawButton)
	/score_display/   # 발라트로 스타일 점수 표시 (chips × mult)
	/action_bar/      # POST_ROLL 액션 (Nitro/Smoke/Reroll + 리롤 모드: Roll/Double Down)
	/game_over/       # 도주 성공/체포 화면
	/upgrade_screen/  # Hand Rank upgrade UI
	/gear_grid/       # 트렁크(Trunk) UI — 기어 테트리스 배치 + 로드아웃
	/chase_bg/        # 도주 배경 (차량 + 경찰차, 타이머 연동 멈춤/채도)

  /resources/         # Data definitions
	/dice_types/      # (비어있음 — 데이터는 globals/dice_types.gd)
	/hand_ranks/      # Hand Rank .tres files
```

### Game Flow

**기획서 기반 핵심 루프 — 실시간 타이머 + 거리 도달 승리 조건**

1. **은행 선택** (TODO): 목표 거리와 난이도, 특성이 다른 은행 중 하나를 선택. 기본 타이머 7초.
2. **SETUP**: 게임 초기화, Inventory → Deck(deep-copy), 캐릭터 특성 적용
3. **PRE_ROLL** (타이머 **정지**): 인벤토리에서 무작위 8개를 Hand로 드로우. 5개를 선택하여 Active로 배치.
   - Hand == 5 & Active == 0 → **자동 활성화** (순차 애니메이션)
   - Hand > 5 → Hand UI에서 주사위 클릭 → Active로 올라감 (애니메이션)
   - Active 주사위 클릭 → Hand로 내려감
   - **리드로우**: 게임당 2회, Hand 전체를 새로 8개로 교체 (Draw 버튼과 별도)
   - 5개 선택 완료 시 Roll 버튼 활성화
4. **ROLLING** (타이머 **정지**): 5개 주사위 제자리 스핀 (Tween 기반, 물리 없음). 입력 차단.
5. **POST_ROLL** (점수 연출 중 타이머 **정지** → ActionBar 표시 후 **진행**):
   - **자동 정렬**: 굴림 완료 후 주사위 눈 오름차순으로 자동 정렬 (물리적 위치 이동)
   - **효과 발동**: 정렬된 순서(인접 관계)에 따라 ON_ROLL, ON_ADJACENT_ROLL 효과 적용
   - **ScoreDisplay**: 발라트로 스타일 점수 연출 (Hand Rank명 → chips × mult → 최종 점수)
   - **자동 족보 선택**: 시스템이 최고 점수 Hand Rank 자동 선택 (수동 선택 없음)
   - **ActionBar**: Smoke / Reroll / Nitro 버튼 (1단계 의사결정)
	 - **Nitro** (거리 환산): 점수를 거리로 즉시 치환
	 - **Smoke** (시간 확보): 점수를 시간으로 즉시 치환
	 - **Reroll**: 리롤 모드 진입 (타이머 정지) → 주사위 선택 → Roll/Double Down
   - 리롤 모드: Roll 확정 (리롤 1개 소모) / Double Down (리롤 2개 소모, 전체 리롤, 점수 ×2)
   - 유효 족보 없으면 자동 0점 (burst) — 선택 없이 즉시 다음으로
   - 더블다운 후에는 무조건 거리 환산 (올인 결정)
6. **반복**: Active 5개가 Hand로 돌아감 → PRE_ROLL. 시간이 남아있고 거리 미달이면 반복.
7. **GAME_OVER**: 거리 달성 → 도주 성공 (베이스 캠프 도착) / 시간 초과 → 체포 (게임 오버)
   - **베이스 캠프** (TODO): 돈 정산, 상점, 트렁크(기어 배치) + 로드아웃 정비, 특별 NPC

### State Management

**State Machine 기반 게임 흐름 관리:**

```
enum Phase { SETUP, PRE_ROLL, ROLLING, POST_ROLL, GAME_OVER }
```

| Phase | 설명 | 타이머 | 허용 액션 |
|-------|------|--------|-----------|
| `SETUP` | 게임 초기화 (1회성) | 정지 | - |
| `PRE_ROLL` | 주사위 드로우 + 5개 선택 | **정지** | Hand→Active 선택, Redraw, Roll |
| `ROLLING` | 주사위 스핀 애니메이션 | **정지** | 입력 차단 |
| `POST_ROLL` | 굴린 후 (ScoreDisplay + ActionBar + 즉시 치환) | 연출 중 **정지** → ActionBar 후 **진행** | Nitro, Smoke, Reroll, Double Down |
| `GAME_OVER` | 도주 성공 / 체포 | 정지 | Restart, Base Camp |

**상태 전환 흐름:**
```
SetupState → PreRollState → RollingState → PostRollState
				 ↑              ↑               │
				 │              ├───(reroll)────┤
				 │              └──(dbl down)───┤
				 │                              │ (nitro/smoke/auto)
				 │              ┌───────────────┤
				 │              │               │
				 │              ↓ (거리 미달     ↓ (거리 달성 OR
				 │              & 시간 남음)      시간 초과)
				 └──────────────┘          GameOverState
```

**핵심 클래스:**
- **GameStateMachine**: 상태 전환 관리, game.tscn의 자식 노드
- **GameStateBase**: 상태 베이스 클래스 (enter/exit/update/handle_input)
- **GameState**: Autoload singleton for match data (Phase, timer, distance, rerolls, inventory, deck 등)
  - 게임 상수: `DICE_COUNT = 5`, `MAX_FACE_VALUE = 6`, `MAX_REROLLS = 3` (게임당), `DOUBLE_DOWN_COST = 2`, `MAX_REDRAWS = 2` (게임당), `HAND_DRAW_COUNT = 8`
  - 타이머: `remaining_time`, `timer_running`, `BASE_TIME = 7.0`
  - 거리: `remaining_distance`, `target_distance`
  - Double Down: `is_double_down`, `can_double_down()`, `DOUBLE_DOWN_MULTIPLIER = 2.0`
  - 치환: `convert_to_distance(score)`, `convert_to_time(score)`
- **MetaState**: Autoload singleton for upgrades + gear (persists between matches)
  - `gear_grid`: GearGrid — 트렁크(Trunk) 적재 그리드 (6x6 기본)
  - `owned_gears`: Array[GearInstance] — 보유 기어(Gear) 목록
- **Inventory**: 영구 주사위 컬렉션 (RefCounted, `GameState.inventory`)
- **Deck**: 스테이지 로컬 덱 — pool/hand/active_dice (RefCounted, `GameState.deck`)

### Dice Type System
- Resource-based architecture for 100+ dice types
- **face_values**: DiceTypeResource 속성, 0=와일드카드 센티널
- **ModifierEffect**: 점수 수정 (value_bonus, value_multiplier, permanent_bonus, permanent_multiplier)
- **ActionEffect**: 게임 상태 변경 (ADD_DRAWS, DESTROY_SELF, TRANSFORM)
- Comparisons(조건부 필터)는 베이스 클래스(DiceEffectResource)에서 공유
- Extensible via `DiceTypes.ALL` in `globals/dice_types.gd`

### Hand Rank System (9 Hand Ranks)
- **하이다이스** (HIGH_DICE): base_chips 0 + 가장 높은 주사위 1개
- **원 페어** (ONE_PAIR): base_chips 2 + 같은 눈 2개의 합
- **투 페어** (TWO_PAIR): base_chips 4 + 서로 다른 페어 2쌍의 합
- **트리플** (TRIPLE): base_chips 6 + 같은 눈 3개의 합
- **스몰 스트레이트** (SMALL_STRAIGHT): base_chips 8 + 패턴값의 합
- **풀하우스** (FULL_HOUSE): base_chips 8 + 전체 합
- **라지 스트레이트** (LARGE_STRAIGHT): base_chips 12 + 패턴값의 합
- **포카드** (FOUR_CARD): base_chips 12 + 전체 합
- **파이브카드** (FIVE_CARD): base_chips 15 + 전체 합
- `base_chips`: Hand Rank 고유 기본 점수. 족보 계층 보장 (높은 족보 = 높은 base_chips)
- `NO_MATCH` 센티널 (`-1`): 패턴 미매칭 시 반환, bonus_pool 적용 방지
- 모든 Hand Rank 무제한 사용 가능
- Multiplier upgrade: Increase score multiplier (MetaState 경유)
- **Burst**: 유효 족보 없을 때 자동 0점 (hand_rank_id: "burst"). HandRankRegistry 미등록

### Inventory / Deck System
- **`Inventory`** (`globals/inventory.gd`): 플레이어의 영구 주사위 컬렉션. 스테이지를 넘어 유지. 상점에서 매매 가능.
  - `init_starting_inventory()`: 게임 시작 시 `DiceTypes.STARTING_INVENTORY`로 초기 구성
  - `create_stage_copies()`: 모든 주사위를 `clone_for_stage()`로 deep-copy하여 반환
  - `add()` / `remove()`: 상점 매매용
- **`Deck`** (`globals/deck.gd`): 스테이지 로컬 덱. pool(draw pile) + hand + active_dice 관리.
  - `init_from_inventory(inv)`: Inventory에서 deep-copy하여 덱 초기화
  - `HAND_MAX = 10`: hand + active 합계 기준
  - 파괴된 주사위는 Deck에서만 사라짐 (Inventory 원본 무사)
- **`DiceInstance.clone_for_stage()`**: 영구 보너스 유지, 스테이지 로컬 상태 초기화
- **`GameState.inventory`**: Inventory 인스턴스 (영구)
- **`GameState.deck`**: Deck 인스턴스 (스테이지 로컬)
- **Draw**: `GameState.draw_one()` → `draws_remaining` 차감
- **Redraw** (NEW): 게임당 2회, Hand 전체를 pool로 되돌리고 `HAND_DRAW_COUNT`(8)개를 새로 드로우
  - `GameState.redraw()` → `redraws_remaining` 차감, `deck.redraw_hand(HAND_DRAW_COUNT)`
- Signal: `pool_changed` (기존 `inventory_changed` → 리네임)

### Gear & Trunk System (기어 + 트렁크)

**용어 정리:**
- **기어(Gear)**: 개별 아이템. 발라트로의 조커카드 역할. 고유한 패시브 효과 보유.
- **트렁크(Trunk)**: 기어를 배치하는 적재 공간. 6x6(기본) 테트리스 그리드.
- **로드아웃(Loadout)**: 트렁크에 어떤 기어를 실을지 전략적으로 선택하는 행위/화면.

- **접근 시점**: 베이스 캠프 (도주 성공 후 정비 단계)
- **`GearResource`** (`globals/gear_resource.gd`): 기어 타입 정의 (shape, color, effects)
  - `shape`: `Array[Vector2i]` 오프셋 (앵커 = (0,0))
  - `passive_effects`: 글로벌 패시브 `[{"type": "reroll_bonus"/"draw_bonus", "delta": N}]`
  - `dice_effects`: `Array[DiceEffectResource]` — EffectProcessor에 주입
  - `rotate_shape()`: static, `(x,y) → (y,-x)` + normalize
- **`GearInstance`** (`globals/gear_instance.gd`): 기어 배치 상태 (RefCounted)
  - `grid_position`, `rotation` (0~3), `is_placed`, `get_occupied_cells()`
- **`GearGrid`** (`globals/gear_grid.gd`): 트렁크 그리드 순수 로직 (RefCounted)
  - `can_place()` / `place()` / `remove()` / `get_cell()`
  - `get_all_passive_effects()` / `get_all_dice_effects()`
- **`GearTypes`** (`globals/gear_types.gd`): DiceTypes 패턴, `const ALL` + `STARTING_GEARS`
- **`GearRegistry`** (Autoload): 파싱 + `create_instance(id)`
- **패시브 적용**: `PreRollState._apply_gear_passives()` — rerolls/draws 보너스
- **주사위 효과**: `EffectProcessor.process_effects()` — 기어의 dice_effects 자동 주입
  - `EffectContext.create_global()`: source_dice=null, source_index=-1 (글로벌 효과용)
  - 기어 효과는 `ALL_DICE` 타겟만 사용 (SELF/ADJACENT 무의미)
- **UI**: `ui/gear_grid/gear_grid_ui.tscn` — click-to-place, 회전, 제거

## Godot 4.6 Conventions

- **GDScript style:** Use snake_case for functions/variables, PascalCase for classes
- **Scene files:** `.tscn` (text-based scene format)
- **Resources:** `.tres` (text-based resource format)
- **3D assets:** GLB format (binary glTF 2.0)
- **Rendering:** Mobile renderer configured
- **Autoloads:** DiceRegistry, HandRankRegistry, GearRegistry, MetaState, GameState (load order matters)

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
  var hand_ranks: Dictionary[String, HandRankResource] = {}
  func get_all() -> Array[HandRankResource]:

  # Avoid - no type safety
  var hand_ranks: Dictionary = {}
  func get_all() -> Array:
  ```
- **Typed local variables**: Use `:=` for type inference
  ```gdscript
  var upgrade := HandRankUpgrade.new()
  var hr := HandRankRegistry.get_hand_rank(id)
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
  func get_upgrade(id: String) -> HandRankUpgrade:

  # Avoid
  func get_upgrade(id: String):
  ```
- **Assert for invariants**: Use `assert()` for conditions that must always be true
  ```gdscript
  func get_total_multiplier() -> float:
	  assert(hand_rank != null, "HandRankUpgrade not initialized")
	  return hand_rank.base_multiplier + extra_multiplier
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
  - `GameState.MAX_REROLLS` (3): **게임당** 최대 리롤 (라운드당이 아님!)
  - `GameState.MAX_REDRAWS` (2): **게임당** 리드로우 횟수
  - `GameState.HAND_DRAW_COUNT` (8): PRE_ROLL에서 Hand로 드로우하는 수
  - `GameState.BASE_TIME` (7.0): 기본 타이머 초
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
  func _filter_hand_ranks(predicate: Callable) -> Array[HandRankResource]:
      var result: Array[HandRankResource] = []
      for hr in hand_ranks.values():
          if predicate.call(hr):
              result.append(hr)
      return result

  func get_number_hand_ranks() -> Array[HandRankResource]:
      return _filter_hand_ranks(func(hr): return hr.is_number_hand_rank())
  ```
- **Helper methods on Resources**: Add query methods to Resource classes
  ```gdscript
  # In HandRankResource
  func is_number_hand_rank() -> bool:
      return hand_rank_type <= HandRankType.SIXES
  ```
- **Factory helpers**: Extract object creation into private functions
  ```gdscript
  func _create_upgrade(hr: HandRankResource) -> HandRankUpgrade:
      var upgrade := HandRankUpgrade.new()
      return upgrade.init_with_hand_rank(hr)
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
final_score = (base_chips + pattern_value + Σ value_bonus) × (1 + Σ extra_mult) × hand_rank_mult × (DD ? 2 : 1)
```

- **base_chips**: Hand Rank 고유 기본 점수 (족보 계층 보장용)
- **pattern_value**: 패턴 매칭된 주사위의 raw value 합
- **Σ value_bonus**: 모든 활성 주사위의 value_bonus 합산
- **Σ extra_mult**: 모든 활성 주사위의 (value_multiplier - 1) 합산
  - 기본 배수 1.0을 빼서 합산 → 효과 없는 주사위(×1)는 0 기여
- **hand_rank_mult**: Hand Rank 업그레이드 배수 (MetaState 경유)
- **DD**: Double Down 시 ×2

| 풀 | 구성 | 설명 |
|-----|------|------|
| `base` | `base_chips + pattern_value` | Hand Rank 기본점수 + 패턴 매칭된 주사위의 합. NO_MATCH(-1)이면 0점 |
| `value_bonus` | 모든 주사위 | 효과에 의한 가산 (양수/음수 모두 가능) |
| `extra_mult` | 모든 주사위 | value_multiplier - 1 (×3 주사위 → +2 기여) |

예시: 주사위 `[3,3,2,5,6]`, bonus `[+1,+2,0,0,+3]`, mult `[1,1,2,1,1]`, 원페어(base_chips=2, 3+3=6)
→ `(2 + 6 + 6) × (1 + 1) = 28`

### Score Conversion (점수 치환)

점수 계산 후 PostRollState에서 Nitro/Smoke 버튼으로 즉시 치환:
```
거리 환산: remaining_distance -= final_score × distance_factor
시간 확보: remaining_time    += final_score × time_factor
```
- `distance_factor` / `time_factor`: 밸런싱 상수 (캐릭터 특성으로 변동 가능)
- 핵심 의사결정: 높은 점수일수록 고민 — 거리를 확 줄일까, 시간을 벌어 더 많이 굴릴까?

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

### New Hand Rank
1. Create `.tres` in `/resources/hand_ranks/`
2. Set `hand_rank_type` to one of 9 types (HIGH_DICE ~ FIVE_CARD)
3. Set `base_chips` for hierarchy positioning (높은 족보일수록 높은 값)
4. Configure `base_multiplier`, `max_multiplier`, `multiplier_upgrade_step`
5. Add scoring logic in `scoring.gd` if new HandRankType added

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

### New Gear (기어)
1. Add entry in `globals/gear_types.gd` → `GearTypes.ALL`
2. Set `id`, `display_name`, `description`, `color` (Array[float] RGB)
3. Set `shape` as `Array[Vector2i]` offsets (anchor = (0,0)) — 트렁크에 배치할 테트리스 모양
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

호출 시점: PRE_ROLL 진입 후, Draw 완료 후

### Hand/Active 용량 체크
- `can_draw()`: `hand.size() + active_dice.size() < HAND_MAX` (active 포함!)
- Draw 시 active를 hand로 되돌리지 않음 — active 상태 유지가 자연스러운 UX

### Burst Hand Rank
- HandRankRegistry에 등록되지 않은 특수 ID ("burst")
- 유효 족보 없을 때 PostRollState에서 자동 0점 처리
- burst 시 PostRollState에서 선택 없이 즉시 다음 PRE_ROLL로

### Double Down
- 리롤 2개 소모 (`DOUBLE_DOWN_COST = 2`), 5개 전체 리롤
- `GameState.is_double_down = true` → PostRollState에서 `DOUBLE_DOWN_MULTIPLIER (2.0)` 적용 → 자동 거리 환산
- 게임당 제한: `can_double_down()`: `rerolls >= 2 and not is_double_down`
- `PreRollState.enter()`에서 `is_double_down = false` 리셋

### Timer System
- **타이머 진행 구간** (플레이어 결정 중): POST_ROLL(ActionBar 표시 후만)
- **타이머 정지 구간**: SETUP, PRE_ROLL, ROLLING, POST_ROLL(점수 연출 중), GAME_OVER
- **시각 피드백**: 타이머 정지 시 chase_bg 스크롤/차량 멈춤 + 2D/3D 채도 감소 (부드러운 전환)
- **원칙**: 플레이어의 실제 결정 순간(Nitro/Smoke/Reroll/DD)에만 시간이 흐른다
- **POST_ROLL 세부**: `enter()`에서 정지 → 점수 애니메이션 완료 후 ActionBar 표시 직전에 `set_timer_running(true)`
- **긴박감 연출**: `remaining_time < 2.0` → HUD 붉은색 표시 (TODO: 화면 점멸 + 사이렌)
- **시간 초과**: `remaining_time <= 0` → 즉시 GameOverState(체포)로 전환
- 타이머는 `GameState._process(delta)`에서 `timer_running` 플래그로 제어
- 각 State의 `enter()`에서 `GameState.set_timer_running(bool)` 호출

### Nitro/Smoke System (점수 즉시 치환)
- PostRollState에서 Nitro(거리)/Smoke(시간) 버튼으로 즉시 치환 (별도 상태 없음)
- **Nitro** (거리 환산): `remaining_distance -= score × distance_factor`
- **Smoke** (시간 확보): `remaining_time += score × time_factor`
- 더블다운 후에는 무조건 Nitro (거리 환산)
- 치환 후: 거리 달성 → GameOver(성공), 시간 남음 → PreRoll, 시간 초과 → GameOver(체포)

### 자식 노드 Local vs World Space
- RigidBody3D에 자식으로 추가한 노드(OmniLight3D 등)의 `position`은 **로컬 좌표**
- 주사위의 `final_rotation`이 적용되면 자식 노드도 함께 회전 → 의도한 위치에서 벗어남
- 예: `position = Vector3(0, 2.5, 0)` + X축 180° 회전 → 실제로는 Y-2.5 (주사위 아래)
- **해결**: 활성화 시 `transform.basis.inverse() * 원하는_월드_오프셋`으로 역보정

### 시그널 연결/해제 대칭
- State의 `_connect_signals()`/`_disconnect_signals()`는 반드시 대칭이어야 함
- 시그널 추가 시 양쪽 모두 업데이트 — 한쪽만 하면 disconnect 에러 또는 중복 연결
- RollButton은 PRE_ROLL 전용 (ROLL! 만). POST_ROLL 액션은 ActionBar가 담당

### 타이머 정지/재개 대칭
- State의 `enter()`에서 `set_timer_running(true/false)` 호출 시 `exit()`에서 반대 동작 불필요
  - 다음 State의 `enter()`에서 자신의 타이머 상태를 설정하므로
- **타이머 원칙**: 플레이어의 실제 결정 순간(Stand/Reroll/DD, 거리/시간)에만 진행
- **POST_ROLL 예외**: `enter()`에서 정지 → 점수 애니메이션 끝 → `set_timer_running(true)` → ActionBar 표시

### 리롤 모드 (낙장불입)
- **흐름**: ActionBar에서 REROLL 클릭 → 리롤 모드 진입 (타이머 정지, 취소 불가) → 주사위 선택 → ROLL 확정
- **주사위 선택**: `dice_manager.set_selection_enabled(true/false)`로 제어. 리롤 모드에서만 활성화
- **ActionBar 모드**: 일반(Stand/Reroll/DD) ↔ 리롤(Roll만 표시)
- **낙장불입**: 리롤 모드 진입 시 Back 버튼 없음. 반드시 주사위를 선택하고 Roll 해야 함

### 리롤 vs 리드로우 구분
- **리롤** (Reroll): POST_ROLL 리롤 모드에서 선택한 주사위만 다시 굴림 (게임당 3회)
- **리드로우** (Redraw): PRE_ROLL에서 Hand 전체를 pool로 되돌리고 8개 새로 드로우 (게임당 2회)
- 별도 카운터: `rerolls_remaining` vs `redraws_remaining`
- UI도 별도: ActionBar의 Reroll 버튼 vs HandDisplay의 Redraw 버튼

### 라운드 없는 반복 구조
- 라운드 개념 없음 — `current_round` / `max_rounds` 삭제됨
- 루프 종료 조건: `remaining_distance <= 0` (성공) 또는 `remaining_time <= 0` (실패)
- 리롤/리드로우는 **게임 전체** 공유 리소스 (PreRollState에서 리셋하지 않음)

## UI Layout (기획서 기준)

| 위치 | 내용 |
|------|------|
| **화면 최상단** | 남은 시간 타이머, 베이스 캠프까지 남은 거리 시각화 |
| **화면 중앙** | 주사위 및 족보 이펙트, 결정 버튼들 |
| **화면 중앙하단 (배경)** | 도주하는 차량과 쫓아오는 경찰차 (2D). 시간 임박 시 거리 좁혀짐 (TODO) |
| **화면 하단** | 주사위 핸드, 리드로우 버튼 |
| **화면 우 하단** | 트렁크 그리드. 점수 확정 시 기어가 영향 주면 반짝이며 게임 쥬스 |

### 긴박감 연출 (TODO)
- 시간 2초 미만: 화면 붉은 점멸 + 사이렌 볼륨 상승
- 성공 시: 플레이어 차가 화면 밖으로 가속 탈출
- 실패 시: 반대편에서 경찰차가 막아서며 체포

## Character System (TODO)

게임 시작 시 갱단을 창설하고 캐릭터를 선택. 각 캐릭터는 고유 특성:

| 캐릭터 | 특성 |
|--------|------|
| **Driver** | 거리 환산 보너스 (`distance_factor` 상승) |
| **Thug** | 더블 다운 점수 배율 상승 (`DOUBLE_DOWN_MULTIPLIER` 증가) |
| **Mastermind** | 리드로우 1회 추가 (`MAX_REDRAWS` + 1) |

구현 시 `GameState`에 캐릭터 특성 적용 메서드 추가, `SetupState`에서 적용.

## Bank Selection (TODO)

은행마다 목표 거리, 난이도, 특수 조건이 다름:
- `target_distance`: 베이스 캠프까지 거리
- `base_time`: 기본 타이머 (기본 7초, 은행마다 다를 수 있음)
- `bank_traits`: 특수 조건 (예: 리롤 -1, 거리 보너스 등)

## Base Camp (TODO)

도주 성공 후 베이스 캠프에서 다음 습격을 준비:
- **상점**: 주사위 및 기어 구매/판매
- **트렁크 (적재 공간)**: 6x6(기본) 그리드에 기어를 테트리스 배치 (기존 GearGridUI)
- **로드아웃**: 트렁크에 어떤 기어를 실을지 전략적으로 선택
- **특별 NPC**: 무작위 이벤트로 주사위/족보 업그레이드 기회, 트렁크 확장 등
