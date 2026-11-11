class_name SeaReportPanel
extends PanelContainer
## Hover report of today's sea: each species, its weight range and remaining / stocked count.
## Reads model snapshots only; no rule decisions.

## Set by GameView while another overlay is open, so the report cannot pop up behind it.
var blocked := false

var _anchor: Button
var _title: Label
var _grid: GridContainer


## Builds the panel and attaches it to the button that reveals it on hover or focus.
func build(anchor: Button, scene_owner: Node) -> void:
	_anchor = anchor
	# Background alpha 0.20: the report floats over the sea without hiding it.
	add_theme_stylebox_override("panel", UiKit.box(Color(0.04, 0.12, 0.18, 0.20), 10, 20, Color(0.75, 0.87, 0.86, 0.35), 1))
	custom_minimum_size = Vector2(530, 0)
	var report := UiKit.column(self, 10)
	_title = UiKit.named(UiKit.label("Today's Sea", 25), "SeaTitle", report, scene_owner)
	_grid = UiKit.named(GridContainer.new(), "SeaGrid", report, scene_owner)
	_grid.columns = 3
	_grid.add_theme_constant_override("h_separation", 22)
	_grid.add_theme_constant_override("v_separation", 6)
	hide()
	mouse_entered.connect(reveal)
	mouse_exited.connect(_schedule_hide)
	_anchor.mouse_entered.connect(reveal)
	_anchor.mouse_exited.connect(_schedule_hide)
	_anchor.focus_entered.connect(reveal)
	_anchor.focus_exited.connect(_schedule_hide)
	_anchor.pressed.connect(func(): hide() if visible else reveal())


func render(day: FishingDay, config: GameConfig) -> void:
	var initial := day.get_sea_initial_counts()
	var remaining := day.get_sea_remaining_counts()
	for child in _grid.get_children():
		_grid.remove_child(child)
		child.queue_free()
	if remaining.is_empty():
		_title.text = "Today's Sea  ·  Species & odds"
	else:
		var left := 0
		for species_id in remaining:
			left += int(remaining[species_id])
		_title.text = "Today's Sea  ·  %d fish left" % left
	for definition in config.fish_definitions:
		var amount: String
		var faded := false
		if remaining.is_empty():
			amount = "%d%%" % roundi(definition.probability * 100)
		else:
			amount = "%d / %d" % [remaining.get(definition.species_id, 0), initial.get(definition.species_id, 0)]
			faded = int(remaining.get(definition.species_id, 0)) == 0
		var range_text := "—" if definition.is_empty_catch else "%d–%d kg" % [definition.min_weight_kg, definition.max_weight_kg]
		for text in [definition.display_name, range_text, amount]:
			_grid.add_child(UiKit.label(text, 19, Color("90a5a6") if faded else UiKit.INK))
	_reposition()


func reveal() -> void:
	if _anchor.disabled or blocked:
		return
	show()
	_reposition()


func _reposition() -> void:
	var parent := get_parent() as Control
	if parent == null or not is_instance_valid(_anchor):
		return
	reset_size()
	# Sits just above the button that opened it.
	var origin := _anchor.global_position - parent.global_position
	position = Vector2(origin.x, maxf(8, origin.y - size.y - 12))


func _schedule_hide() -> void:
	await get_tree().create_timer(0.12).timeout
	if not is_inside_tree():
		return
	var mouse := get_global_mouse_position()
	if not _anchor.get_global_rect().has_point(mouse) and not get_global_rect().has_point(mouse):
		hide()
