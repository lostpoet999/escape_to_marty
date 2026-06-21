class_name BaseItem extends Resource

enum RarityType{
	COMMON,
	UNCOMMON,
	RARE,
	VERY_RARE
}

const RARITY_COLORS: Dictionary = {
	RarityType.COMMON: Color("9aa0a6"),
	RarityType.UNCOMMON: Color("57c84d"),
	RarityType.RARE: Color("3d8bff"),
	RarityType.VERY_RARE: Color("b061ff"),
}
const RARITY_NAMES: Dictionary = {
	RarityType.COMMON: "Common",
	RarityType.UNCOMMON: "Uncommon",
	RarityType.RARE: "Rare",
	RarityType.VERY_RARE: "Very Rare",
}

static func rarity_color(value: RarityType) -> Color:
	return RARITY_COLORS.get(value, RARITY_COLORS[RarityType.COMMON])

static func rarity_label(value: RarityType) -> String:
	return RARITY_NAMES.get(value, RARITY_NAMES[RarityType.COMMON])

static func style_button_with_rarity(button: Button, value: RarityType, border_width: int = 4, corner_radius: int = 10, content_margin: float = 8.0) -> void:
	var color: Color = rarity_color(value)
	button.flat = false
	button.add_theme_stylebox_override(&"normal", _rarity_box(color, 0.12, border_width, corner_radius, content_margin))
	button.add_theme_stylebox_override(&"hover", _rarity_box(color.lightened(0.2), 0.26, border_width, corner_radius, content_margin))
	button.add_theme_stylebox_override(&"pressed", _rarity_box(color, 0.4, border_width, corner_radius, content_margin))
	button.add_theme_stylebox_override(&"focus", _rarity_box(color.lightened(0.2), 0.0, border_width, corner_radius, content_margin))
	button.add_theme_stylebox_override(&"disabled", _rarity_box(color.darkened(0.45), 0.06, border_width, corner_radius, content_margin))

static func _rarity_box(color: Color, fill_alpha: float, border_width: int, corner_radius: int, content_margin: float) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = Color(color.r, color.g, color.b, fill_alpha)
	box.set_border_width_all(border_width)
	box.border_color = color
	box.set_corner_radius_all(corner_radius)
	box.set_content_margin_all(content_margin)
	return box

@export var powerup_name: String
## The description that appears when you hover over the item in shop or free item screens
@export var shop_description: String
@export var rarity: RarityType
@export var min_floor: int
@export var inventory_icon: Texture2D
@export var cost: int
@export var removable: bool = true 
@export var reveals_adjacent_rooms: bool = false
@export var enables_minimap: bool = false
