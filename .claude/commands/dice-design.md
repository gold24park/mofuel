주사위 디자이너 — 새 주사위 타입을 설계하고 `globals/dice_types.gd`에 추가합니다.

$ARGUMENTS

## 작업 절차

1. **현재 상태 파악**: `globals/dice_types.gd`를 읽어 기존 주사위 목록, 그룹, 시너지 확인
2. **효과 시스템 제약 조건 확인** (필요 시 코드 읽기):
   - `globals/dice_effect_resource.gd` — Target, CompareField, CompareOp enums
   - `globals/effects/modifier_effect.gd` — ModifyTarget enum
   - `globals/effects/action_effect.gd` — Action enum
3. **설계**: 사용자 요청에 맞는 주사위 설계 (아래 레퍼런스 참고)
4. **구현**: `DiceTypes.ALL` 배열에 추가
5. **검증**: Godot MCP로 게임 실행, 에러 확인

## 효과 시스템 레퍼런스

### 타겟 (WHO gets the effect)
- `Target.SELF` — 자신에게만
- `Target.ADJACENT` — 좌/우 인접
- `Target.ALL_DICE` — 모든 활성 주사위
- `Target.MATCHING_VALUE` — 같은 눈의 다른 주사위
- `Target.MATCHING_GROUP` — 같은 그룹의 다른 주사위

### Comparisons (타겟 필터 — 타겟 주사위의 속성을 검사)
- `Field.TYPE` — dice type id (String)
- `Field.GROUP` — groups 배열 (Array, EQ는 `in` 연산)
- `Field.VALUE` — 굴린 눈 (int)
- `Field.INDEX` — 배치 위치 0~4
- `Field.ROLL_COUNT` — 누적 굴림 횟수
- `Field.PROBABILITY` — 확률 체크 (randf() < b)

### 연산자
- `Op.EQ` (기본), `Op.NOT`, `Op.IN` (배열), `Op.GTE`, `Op.LT`, `Op.MOD` (나머지=0)

### ModifierEffect (점수 수정)
```gdscript
{
    "type": "ModifierEffect",
    "target": Target.XXX,
    "comparisons": [{"a": Field.XXX, "b": value, "op": Op.XXX}],  # 선택
    "modify_target": ModifyTarget.VALUE_BONUS | VALUE_MULTIPLIER | PERMANENT_BONUS | PERMANENT_MULTIPLIER,
    "delta": number,
    "anim": "bounce" | "shake" | "",  # 선택
}
```

### ActionEffect (게임 상태 변경)
```gdscript
{
    "type": "ActionEffect",
    "target": Target.XXX,
    "comparisons": [...],  # 선택
    "action": Action.ADD_DRAWS | DESTROY_SELF | TRANSFORM,
    "delta": int,  # ADD_DRAWS용
    "params": {"to": "type_id"},  # TRANSFORM용
    "anim": "bounce" | "shake" | "",
}
```

### 스코어링 공식
```
final = (base_value + value_bonus) × value_multiplier × permanent_multiplier + permanent_bonus
```

### Face Values
- `[0, v1, v2, v3, v4, v5, v6]` — index 0 미사용, 1~6이 물리적 면
- `WILD` (0) = 와일드카드, `SKULL` = 해골 (파괴 조건)
- 생략하면 identity (1→1, 2→2, ..., 6→6)

### 핵심 제약
- `comparisons`는 **타겟** 주사위를 필터링 (소스가 아님!)
- `Target.SELF` + comparisons = 자기 조건 체크 (source == target이므로)
- "인접이 X이면 자신 버프" 같은 조건은 직접 표현 불가 → 대신 인접에 직접 영향
- 그룹은 시너지 키: `["royal"]`, `["peasant"]`, `["criminal"]`, `["undead"]`, `["holy"]`, `["wise"]` 등

## 설계 가이드라인
- 각 주사위는 명확한 트레이드오프나 시너지가 있어야 함
- 기존 주사위/그룹과의 상호작용 고려
- face_values + effects 조합으로 독특한 플레이 패턴 유도
- `#region` / `#endregion`으로 카테고리 구분
