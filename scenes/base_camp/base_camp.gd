extends Node2D

## 베이스 캠프 씬 — 카메라 추적 + 레벨 리밋 관리

@onready var player: Player = %Player
@onready var camera: Camera2D = %Camera2D
@onready var tile_map: TileMapLayer = %TileMapLayer

## 타일 크기 (px)
const TILE_SIZE := 32


func _ready() -> void:
	_setup_camera_limits()


func _process(_delta: float) -> void:
	camera.position = player.position


func _setup_camera_limits() -> void:
	#var used_rect := tile_map.get_used_rect()
	#camera.limit_left = used_rect.position.x * TILE_SIZE
	#camera.limit_top = used_rect.position.y * TILE_SIZE
	#camera.limit_right = used_rect.end.x * TILE_SIZE
	#camera.limit_bottom = used_rect.end.y * TILE_SIZE
	pass
