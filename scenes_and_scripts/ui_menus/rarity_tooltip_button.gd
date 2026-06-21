class_name RarityTooltipButton extends Button

const TOOLTIP_SETTINGS: LabelSettings = preload("res://label_settings_and_fonts/yellow_40.tres")
const TOOLTIP_WIDTH: float = 360.0
const TOOLTIP_FONT_SCALE: float = 0.5

func _make_custom_tooltip(for_text: String) -> Object:
	var label: RichTextLabel = RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.custom_minimum_size = Vector2(TOOLTIP_WIDTH, 0)
	label.add_theme_font_override(&"normal_font", TOOLTIP_SETTINGS.font)
	label.add_theme_font_size_override(&"normal_font_size", int(TOOLTIP_SETTINGS.font_size * TOOLTIP_FONT_SCALE))
	label.add_theme_color_override(&"default_color", TOOLTIP_SETTINGS.font_color)
	label.text = for_text
	return label
