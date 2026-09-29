extends RefCounted

static func make() -> FontFile:
	var font := FontFile.new()
	font.data = FileAccess.get_file_as_bytes("res://fonts/PixelifySans.ttf")
	font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	font.allow_system_fallback = false
	var thai_pixel := FontFile.new()
	thai_pixel.data = FileAccess.get_file_as_bytes("res://fonts/Unifont-17.0.04.otf")
	thai_pixel.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	thai_pixel.allow_system_fallback = false
	var fallback_fonts: Array[Font] = [thai_pixel]
	font.fallbacks = fallback_fonts
	return font
