class_name Platform
## 플랫폼 감지 유틸리티 (static class — Autoload 불필요)


static func is_mobile() -> bool:
	return OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios")
