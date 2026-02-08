문서 동기화 — 코드 변경 후 CLAUDE.md와 MEMORY.md를 최신 상태로 업데이트합니다.

## 작업 절차

1. **변경 감지**: `git diff` 또는 최근 대화 컨텍스트에서 변경된 파일/구조 파악
2. **CLAUDE.md 검사** (프로젝트 루트):
   - Directory Structure 섹션: 새 파일/폴더 반영?
   - Game Flow 섹션: 흐름 변경 반영?
   - State Management 핵심 클래스: 새 클래스 추가?
   - Inventory/Deck System: 구조 변경?
   - Effect System: 새 효과 타입?
   - Adding New Content: 가이드 최신?
   - Common Pitfalls: 새로운 주의사항?
3. **MEMORY.md 검사** (`~/.claude/projects/-Users-jieunpark-GodotProjects-mofuel/memory/`):
   - Architecture Decisions: 구조적 결정 기록
   - Common Pitfalls: 발견된 함정 기록
   - 200줄 이내 유지 (truncation 방지)
4. **구 참조 스캔**: CLAUDE.md에서 더 이상 존재하지 않는 클래스명/시그널명/메서드명 검색
5. **업데이트 실행**: 필요한 섹션만 정밀 수정 (전체 재작성 X)

## 검사 패턴 (Grep)
```
# 구 참조 탐지 — 코드에 없는데 문서에 남은 이름
Grep: pattern="InventoryManager|inventory_changed|inventory_manager" path=CLAUDE.md
```

## 주의사항
- CLAUDE.md는 프로젝트 지침 파일 — 코드 변경과 항상 동기화 필수
- MEMORY.md는 세션 간 학습 기록 — 실수/패턴/결정 위주
- 파일명 vs class_name 불일치 (예: inventory_manager.gd → class Deck) 명시적 기록
