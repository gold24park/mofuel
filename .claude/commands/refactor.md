안전한 리팩터링 — 크로스 코드베이스 이름 변경 및 구조 변경을 수행합니다.

$ARGUMENTS

## 작업 절차

1. **영향 범위 파악**:
   - Grep으로 변경 대상 이름의 모든 참조 검색 (*.gd, *.tscn, *.tres)
   - 코드 참조 vs 주석/문서 참조 구분
   - 시그널 연결/해제 대칭 확인 (connect ↔ disconnect)
2. **변경 계획 작성**:
   - 파일별 변경 내용 테이블
   - 의존성 순서 (어떤 파일을 먼저 바꿔야 하는지)
   - 시그널 이름 변경 시 emit/connect/disconnect 모두 포함
3. **실행**:
   - 핵심 클래스부터 변경 (globals/ → entities/ → ui/ → scenes/)
   - 각 파일에서 Edit 도구로 정밀 치환
   - 주석 내 구 이름도 업데이트
4. **검증**:
   - Grep으로 구 이름 잔여 참조 검색 (코드 + 주석)
   - /game-test로 게임 실행 검증
   - /sync-docs로 문서 동기화

## GDScript 리팩터링 체크리스트
- [ ] class_name 변경 → 모든 타입 참조 업데이트
- [ ] signal 이름 변경 → emit, connect, disconnect 모두 업데이트
- [ ] 변수/메서드 이름 → 프록시 메서드 (GameState 등) 포함
- [ ] .tscn 파일 내 script 참조 확인
- [ ] Autoload 이름 변경 시 project.godot 업데이트
- [ ] 새 class_name 추가 시 Godot re-import 필요

## 주의사항
- State의 `_connect_signals()`/`_disconnect_signals()`는 반드시 대칭
- GameState의 프록시 메서드 (move_single_to_active 등) 빠뜨리지 않기
- UI 파일들이 GameState 시그널을 직접 연결하므로 시그널 이름 변경 시 UI도 확인
