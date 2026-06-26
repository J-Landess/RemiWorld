## IconLoader.gd
## Static helper for loading icon textures with a rarity-colored fallback.
## Used by BackpackUI, AvatarCloset, StoreUI, and RewardPopup so the same
## null-safe loading logic lives in one place.
##
## When a PNG exists at the given path it returns a TextureRect.
## When it doesn't (files not yet added to assets/icons/), it returns a
## rarity-tinted ColorRect so the UI is never broken.
class_name IconLoader


const RARITY_COLORS: Dictionary = {
	"common":    Color(0.72, 0.72, 0.72),
	"uncommon":  Color(0.18, 0.75, 0.28),
	"rare":      Color(0.20, 0.42, 0.95),
	"epic":      Color(0.68, 0.18, 0.95),
	"legendary": Color(1.00, 0.58, 0.00),
	"secret":    Color(1.00, 0.18, 0.40),
}


static func load_texture(path: String) -> Texture2D:
	if path.length() == 0:
		return null
	# Try the exact path (real PNG artwork)
	if ResourceLoader.exists(path):
		var res = load(path)
		if res is Texture2D:
			return res
	# Try SVG fallback (placeholder art until real PNGs are placed)
	var svg_path := path.get_basename() + ".svg"
	if ResourceLoader.exists(svg_path):
		var res = load(svg_path)
		if res is Texture2D:
			return res
	return null


## Returns a TextureRect if the PNG exists, otherwise a rarity-tinted ColorRect.
static func make_icon_rect(path: String, icon_size: Vector2, rarity: String = "common") -> Control:
	var tex := load_texture(path)
	if tex:
		var rect := TextureRect.new()
		rect.custom_minimum_size = icon_size
		rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		rect.texture = tex
		return rect
	var fallback := ColorRect.new()
	fallback.custom_minimum_size = icon_size
	fallback.color = RARITY_COLORS.get(rarity, Color(0.38, 0.36, 0.42))
	fallback.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return fallback
