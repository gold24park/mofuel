게임 실행 검증 — Godot MCP로 게임을 실행하고 에러를 확인합니다.

## 작업 절차

1. **게임 실행**: `mcp__godot__run_project`로 `res://scenes/game/game.tscn` 실행
2. **대기**: 3초 대기 후 디버그 출력 확인
3. **에러 분석**: `mcp__godot__get_debug_output`으로 출력 확인
   - `Debugger Break` 또는 `ERROR` → 에러 원인 분석 + 수정 제안
   - `WARNING`만 있으면 → 기존 경고인지 새 경고인지 구분
   - 정상 출력 → 성공 보고
4. **정리**: `mcp__godot__stop_project`로 게임 종료
5. **결과 보고**: 에러/경고 요약 + 수정 필요 여부

## 알려진 기존 경고 (무시 가능)
- `"context" is never used in evaluate()` — dice_effect_resource.gd, modifier_effect.gd
- `signal "XXX" is declared but never explicitly used` — game_state.gd의 여러 시그널
- `"_prev_active_dice" is declared but never used` — game.gd
- `"values" is never used in _on_all_dice_finished()` — rolling_state.gd
- `"indices" is declared but never used` — post_roll_state.gd
- `signal "dice_clicked" is declared but never explicitly used` — dice.gd

## 주의사항
- 새 class_name 파일 추가 후에는 `godot --headless --import` 먼저 실행 필요
  - Godot 바이너리 경로: `/Applications/Godot.app/Contents/MacOS/Godot`
  - 명령: `"/Applications/Godot.app/Contents/MacOS/Godot" --headless --path /Users/jieunpark/GodotProjects/mofuel --import`
- `Identifier "XXX" not declared` 에러 → re-import 필요 신호
