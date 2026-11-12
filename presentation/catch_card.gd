class_name CatchCard
extends ColorRect
## The keep-or-release card shown after each catch. Displays what it is given and emits the choice;
## the rule (what keeping does) stays in FishingDay.

signal keep_requested
signal release_requested

var _art: FishArt
var _name: Label
var _weight: Label
var _rarity: Label
var _price: Label
var _badge: Label
var _keep: Button
var _release: Button


func build(scene_owner: Node) -> void:
	UiKit.dim(self, 0.42)
	var layout := UiKit.column(UiKit.centered(self), 14)
	_badge = UiKit.named(UiKit.label("NEW DISCOVERY", 25, UiKit.DARK), "NewCatchLabel", layout, scene_owner)
	_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_badge.add_theme_stylebox_override("normal", UiKit.box(Color("cfdfcc"), 6, 12))
	var card := UiKit.panel(layout, Color("6599af"), 6, 22)
	card.custom_minimum_size = Vector2(360, 480)
	var style := UiKit.box(Color("6599af"), 6, 22, Color("f8f5df"), 7)
	style.shadow_color = Color(0.02, 0.09, 0.14, 0.5)
	style.shadow_offset = Vector2(9, 10)
	style.shadow_size = 1
	card.add_theme_stylebox_override("panel", style)
	var face := UiKit.column(card, 8)
	var weight_row := UiKit.row(face)
	_weight = UiKit.named(UiKit.label("1 kg", 46, Color("faffed")), "CatchWeight", weight_row, scene_owner)
	UiKit.space(weight_row, false)
	weight_row.add_child(UiKit.label("◆", 34, Color("f4d177")))
	UiKit.space(face)
	_art = UiKit.art(face, &"sardine", Vector2(300, 160))
	_name = UiKit.named(UiKit.label("SARDINE", 29), "CatchChoiceDetails", face, scene_owner)
	_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_rarity = UiKit.named(UiKit.label("COMMON", 20), "CatchRarity", face, scene_owner)
	_rarity.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiKit.space(face)
	_price = UiKit.named(UiKit.label("10 gold", 40, Color("ffe291")), "CatchPrice", face, scene_owner)
	_price.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var actions := UiKit.row(layout, 12)
	_keep = UiKit.named(UiKit.button("Keep"), "KeepButton", actions, scene_owner)
	_release = UiKit.named(UiKit.button("Release"), "ReleaseButton", actions, scene_owner)
	for item in [_keep, _release]:
		item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_keep.pressed.connect(func(): keep_requested.emit())
	_release.pressed.connect(func(): release_requested.emit())


## `value` is the fish's sale value only (no discovery reward, no perfect multiplier).
func present(fish: Fish, display_name: String, rarity: String, value: int, is_new: bool, overweight: bool) -> void:
	_name.text = display_name.to_upper()
	_weight.text = "%d kg" % fish.get_weight_kg()
	_price.text = "%d gold" % value
	_rarity.text = rarity.to_upper()
	_rarity.add_theme_color_override("font_color", UiKit.rarity_color(rarity))
	_badge.visible = is_new
	_art.setup(fish.get_species_id())
	# Keeping an overweight fish is allowed but breaks the net, so it is labelled and not focused.
	_keep.text = "Keep · Overweight" if overweight else "Keep"
	show()
	if overweight:
		_release.grab_focus()
	else:
		_keep.grab_focus()


func close() -> void:
	hide()


func get_species() -> StringName:
	return _art.species
