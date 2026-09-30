extends RefCounted

const LATIN_FONT = preload("res://fonts/PixelifySans.ttf")
const THAI_FONT = preload("res://fonts/Unifont-17.0.04.otf")

static func make() -> FontFile:
	var font := LATIN_FONT.duplicate() as FontFile
	font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	font.allow_system_fallback = false
	var thai_pixel := THAI_FONT.duplicate() as FontFile
	thai_pixel.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	thai_pixel.allow_system_fallback = false
	var fallback_fonts: Array[Font] = [thai_pixel]
	font.fallbacks = fallback_fonts
	return font
