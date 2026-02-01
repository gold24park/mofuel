class_name Guard
extends RefCounted

static func verify(condition: bool, message: String) -> bool:
	if not condition:
		# 로그 남기기
		push_error("[Guard Failed] " + message)
	# 디버그 빌드에서는 멈춤
	assert(condition, message)
	return condition
