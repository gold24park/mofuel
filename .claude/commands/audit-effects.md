효과 시스템 감사 — 모든 주사위의 효과를 분석하고 밸런스/정합성을 검토합니다.

$ARGUMENTS

## 작업 절차

1. **데이터 수집**: `globals/dice_types.gd` 전체 읽기
2. **정합성 검사**:
   - 모든 `target` 값이 유효한 Target enum인지
   - 모든 `modify_target` 값이 유효한 ModifyTarget enum인지
   - 모든 `action` 값이 유효한 Action enum인지
   - `comparisons`의 `a` 필드가 유효한 CompareField인지
   - `face_values` 배열이 7개 요소인지 (index 0 포함)
   - TRANSFORM의 `params.to`가 존재하는 주사위 ID인지
   - 텍스처 경로가 존재하는 파일인지
3. **밸런스 분석**:
   - 무조건 발동 효과 (comparisons 없음) vs 조건부 효과
   - 양수/음수 효과 균형
   - 영구 효과(PERMANENT_*)의 누적 위험성
   - 그룹별 시너지 맵 작성
   - DESTROY_SELF 위험도 (확률 계산)
4. **시너지 맵 출력**:
   ```
   king [royal] ──(+2)──▶ [peasant] (인접)
   king [royal] ──(-1)──▶ [royal] (인접)
   ```
5. **개선 제안**: 밸런스 이슈, 미활용 메카닉, 새 시너지 기회

## 밸런스 기준
- 무조건 self 보너스: +1~+2 적정, +3 이상은 트레이드오프 필요
- 인접 디버프: -1~-2 적정, 자기 버프와 균형
- 영구 보너스: 라운드당 +1이 상한 (5라운드 × +1 = +5)
- VALUE_MULTIPLIER: 1.5~2.0 적정, 조건부가 아니면 리스크 필요
- DESTROY_SELF: 1/6 (16%) 이하 확률이 적정
