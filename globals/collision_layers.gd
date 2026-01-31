class_name CollisionLayers

# Physics collision layers
const FLOOR := 1 << 0          # Layer 1: 바닥
const ROLLING_DICE := 1 << 1   # Layer 2: 굴리는 주사위
const ALIGNED_DICE := 1 << 2   # Layer 4: 정렬된 주사위, 입력 전용
const WALL := 1 << 3           # Layer 8: 벽

# Common masks
const ROLLING_MASK := FLOOR | ROLLING_DICE | WALL
const BURST_MASK := FLOOR | WALL  # 버스트 시 주사위끼리 충돌 안 함
