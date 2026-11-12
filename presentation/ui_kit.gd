class_name UiKit
extends RefCounted
## Shared layout helpers and the game theme. Static functions so every UI component can use them
## without inheriting from a common base class.

const INK := Color("f6f3dd")
const PAPER := Color("ede0b5")
const DARK := Color("193b49")


static func box(color: Color, radius: int = 12, margin: int = 18, border: Color = Color.TRANSPARENT, width: int = 0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.set_content_margin_all(margin)
	style.border_color = border
	style.set_border_width_all(width)
	return style


## Adds `node` under `parent` with a unique name owned by `scene_owner`, so `%Name` lookups work.
static func named(node: Node, node_name: String, parent: Node, scene_owner: Node) -> Node:
	node.name = node_name
	parent.add_child(node)
	node.owner = scene_owner
	node.unique_name_in_owner = true
	return node


static func label(text: String, font_size: int = 22, color: Color = INK) -> Label:
	var item := Label.new()
	item.text = text
	item.add_theme_font_size_override("font_size", font_size)
	item.add_theme_color_override("font_color", color)
	return item


static func button(text: String) -> Button:
	var item := Button.new()
	item.text = text
	item.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return item


static func column(parent: Node, separation: int = 12) -> VBoxContainer:
	var item := VBoxContainer.new()
	item.add_theme_constant_override("separation", separation)
	parent.add_child(item)
	return item


static func row(parent: Node, separation: int = 12) -> HBoxContainer:
	var item := HBoxContainer.new()
	item.add_theme_constant_override("separation", separation)
	parent.add_child(item)
	return item


static func space(parent: Node, vertical: bool = true) -> Control:
	var item := Control.new()
	if vertical:
		item.size_flags_vertical = Control.SIZE_EXPAND_FILL
	else:
		item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(item)
	return item


static func panel(parent: Node, color: Color, radius: int = 12, margin: int = 18) -> PanelContainer:
	var item := PanelContainer.new()
	item.add_theme_stylebox_override("panel", box(color, radius, margin))
	parent.add_child(item)
	return item


## Full-screen dimmed layer, hidden until shown.
static func dim(overlay: ColorRect, opacity: float) -> void:
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.035, 0.09, 0.13, opacity)
	overlay.hide()


static func centered(parent: Control) -> CenterContainer:
	var item := CenterContainer.new()
	parent.add_child(item)
	item.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return item


static func art(parent: Node, species_id: StringName, dimensions: Vector2, unknown: bool = false) -> FishArt:
	var item := FishArt.new()
	item.custom_minimum_size = dimensions
	item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item.setup(species_id, unknown)
	parent.add_child(item)
	return item


static func rarity_color(rarity: String) -> Color:
	return {
		"Common": Color("c9d7d4"),
		"Uncommon": Color("9ac8a0"),
		"Rare": Color("8fc9e9"),
		"Epic": Color("c6a3e8"),
		"Legendary": Color("f1cb70"),
	}.get(rarity, INK)


static func make_theme() -> Theme:
	var ui := Theme.new()
	ui.default_font_size = 22
	ui.set_color("font_color", "Label", INK)
	ui.set_color("font_color", "Button", INK)
	ui.set_color("font_disabled_color", "Button", Color("73928f"))
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var color := Color("286a70")
		if state in ["hover", "focus"]:
			color = Color("408a8c")
		if state == "pressed":
			color = Color("1d535d")
		if state == "disabled":
			color = Color("25434b")
		var focused: bool = state == "focus"
		ui.set_stylebox(state, "Button", box(color, 10, 16, Color("b9d8d3") if focused else Color.TRANSPARENT, 2 if focused else 0))
	ui.set_stylebox("panel", "PanelContainer", box(DARK))
	ui.set_stylebox("background", "ProgressBar", box(Color("0b2c38"), 4, 0))
	ui.set_stylebox("fill", "ProgressBar", box(Color("9cd6bc"), 4, 0))
	return ui


## Colours a single action without changing other controls or its input rules.
static func style_action(button: Button, color: Color, text_color: Color = INK) -> void:
	button.add_theme_stylebox_override("normal", box(color, 10, 16))
	button.add_theme_stylebox_override("hover", box(color.lightened(0.12), 10, 16))
	button.add_theme_stylebox_override("pressed", box(color.darkened(0.16), 10, 16))
	button.add_theme_stylebox_override("disabled", box(color.darkened(0.45), 10, 16))
	button.add_theme_stylebox_override("focus", box(Color.TRANSPARENT, 10, 16, Color("f6df9c"), 2))
	button.add_theme_color_override("font_color", text_color)
	button.add_theme_color_override("font_hover_color", text_color)
	button.add_theme_color_override("font_pressed_color", text_color)
	button.add_theme_color_override("font_focus_color", text_color)
	button.add_theme_color_override("font_disabled_color", Color("b0b7ba"))
