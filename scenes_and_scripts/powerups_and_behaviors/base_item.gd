class_name BaseItem extends Resource

enum RarityType{
	COMMON = 0,
	UNCOMMON = 1,
	RARE = 2,
	VERY_RARE = 3,
}

const RARITY_COLORS: Dictionary = {
	RarityType.COMMON: Color("a8b5b2"),
	RarityType.UNCOMMON: Color("75a743"),
	RarityType.RARE: Color("4f8fba"),
	RarityType.VERY_RARE: Color("c65197"),
}
const RARITY_NAMES: Dictionary = {
	RarityType.COMMON: "Common",
	RarityType.UNCOMMON: "Uncommon",
	RarityType.RARE: "Rare",
	RarityType.VERY_RARE: "Very Rare",
}
const RARITY_COSTS: Dictionary = {
	RarityType.COMMON: 10,
	RarityType.UNCOMMON: 20,
	RarityType.RARE: 45,
	RarityType.VERY_RARE: 65,
}

const PULSE_SECONDS: float = 0.4
const SHAKE_FIRST_DELAY: float = 0.4
const SHAKE_INTERVAL_MIN: float = 1.6
const SHAKE_INTERVAL_MAX: float = 3.2
const PULSE_STYLEBOXES: Array[StringName] = [&"normal", &"hover", &"focus"]
const PULSE_TWEEN_META: StringName = &"rarity_border_pulse"
const PULSE_PENDING_META: StringName = &"rarity_border_pulse_pending"

static func rarity_color(value: RarityType) -> Color:
	return RARITY_COLORS.get(value, RARITY_COLORS[RarityType.COMMON])

static func rarity_label(value: RarityType) -> String:
	return RARITY_NAMES.get(value, RARITY_NAMES[RarityType.COMMON])

static func rarity_tooltip(item: BaseItem) -> String:
	var title_color: String = rarity_color(item.rarity).to_html(false)
	return "[color=#%s]%s (%s):[/color] %s" % [title_color, item.powerup_name, rarity_label(item.rarity), item.shop_description]

static func style_button_with_rarity(button: Button, value: RarityType, border_width: int = 4, corner_radius: int = 10, content_margin: float = 8.0, pulse_border: bool = false, color_override: Color = Color(0, 0, 0, 0)) -> void:
	var color: Color = color_override if color_override.a > 0.0 else rarity_color(value)
	button.flat = false
	button.add_theme_stylebox_override(&"normal", _rarity_box(color, 0.12, border_width, corner_radius, content_margin))
	button.add_theme_stylebox_override(&"hover", _rarity_box(color.lightened(0.2), 0.26, border_width, corner_radius, content_margin))
	button.add_theme_stylebox_override(&"pressed", _rarity_box(color, 0.4, border_width, corner_radius, content_margin))
	button.add_theme_stylebox_override(&"focus", _rarity_box(color.lightened(0.2), 0.0, border_width, corner_radius, content_margin))
	button.add_theme_stylebox_override(&"disabled", _rarity_box(color.darkened(0.45), 0.06, border_width, corner_radius, content_margin))
	_set_active_emphasis(button, color, pulse_border)

static func _set_active_emphasis(button: Button, color: Color, active: bool) -> void:
	if button.has_meta(PULSE_TWEEN_META):
		var running: Tween = button.get_meta(PULSE_TWEEN_META) as Tween
		if running != null and running.is_valid():
			running.kill()
		button.remove_meta(PULSE_TWEEN_META)
	ApolloPalette.stop_idle_shake(button)
	if not active:
		return
	if not button.is_inside_tree():
		if not button.has_meta(PULSE_PENDING_META):
			button.set_meta(PULSE_PENDING_META, true)
			button.tree_entered.connect(_on_emphasis_button_entered_tree.bind(button), CONNECT_ONE_SHOT)
		return
	_start_active_emphasis(button, color)

static func _on_emphasis_button_entered_tree(button: Button) -> void:
	button.remove_meta(PULSE_PENDING_META)
	var box: StyleBoxFlat = button.get_theme_stylebox(&"normal") as StyleBoxFlat
	if box == null:
		return
	_start_active_emphasis(button, box.border_color)

static func _start_active_emphasis(button: Button, color: Color) -> void:
	ApolloPalette.start_idle_shake(button, SHAKE_INTERVAL_MIN, SHAKE_INTERVAL_MAX, SHAKE_FIRST_DELAY)
	var boxes: Array[StyleBoxFlat] = []
	for box_name: StringName in PULSE_STYLEBOXES:
		var box: StyleBoxFlat = button.get_theme_stylebox(box_name) as StyleBoxFlat
		if box != null:
			boxes.append(box)
	if boxes.is_empty():
		return
	var tween: Tween = button.create_tween()
	tween.set_loops()
	tween.tween_method(_blend_border.bind(boxes, color), 0.0, 1.0, PULSE_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(_blend_border.bind(boxes, color), 1.0, 0.0, PULSE_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	button.set_meta(PULSE_TWEEN_META, tween)

static func _blend_border(weight: float, boxes: Array[StyleBoxFlat], color: Color) -> void:
	var blended: Color = color.lerp(Color.WHITE, weight)
	for box: StyleBoxFlat in boxes:
		box.border_color = blended

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
@export var max_copies_outside_shops: int = 2
@export var min_floor: int
@export var inventory_icon: Texture2D
@export var removable: bool = true
@export var emphasis_color: Color = Color(0, 0, 0, 0)
@export var reveals_adjacent_rooms: bool = false
@export var enables_minimap: bool = false
@export var clears_barriers: bool = false
## which floor's memory-trophy slot this item owns; 0 = not a trophy
@export var trophy_floor: int = 0

var cost: int:
	get:
		var base: int = RARITY_COSTS.get(rarity, RARITY_COSTS[RarityType.COMMON])
		if PlayerData.inventory == null:
			return base
		var owned: int = PlayerData.inventory.get_items().count(self)
		return base * (1 << owned)
