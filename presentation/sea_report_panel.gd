class_name SeaReportPanel
extends PanelContainer
## Shows today's sea and the next-cast odds. Reads model snapshots only; no rule decisions.

const SAFE := Color("8fd3a8")
const WARNING := Color("f0c674")
const DANGER := Color("f08a76")

@onready var _title: Label = %SeaTitle
@onready var _grid: GridContainer = %SeaGrid
@onready var _forecast_label: Label = %ForecastLabel


## Colour for a break chance; shared with the net weight bar so both warn together.
static func risk_color(forecast: CatchForecast) -> Color:
	if forecast == null:
		return Color("d9aa6b")
	if forecast.get_bust_chance() >= 0.35:
		return DANGER
	if forecast.get_bust_chance() >= 0.15:
		return WARNING
	return SAFE


func render(day: FishingDay, config: GameConfig, forecast: CatchForecast) -> void:
	_render_counts(day, config)
	_render_forecast(forecast, config)


func _render_counts(day: FishingDay, config: GameConfig) -> void:
	var initial := day.get_sea_initial_counts()
	var remaining := day.get_sea_remaining_counts()
	var chances := day.get_next_cast_chances()
	for child in _grid.get_children():
		_grid.remove_child(child)
		child.queue_free()
	if remaining.is_empty():
		_title.text = "Fish in these waters"
	else:
		var left := 0
		for species_id in remaining:
			left += remaining[species_id]
		_title.text = "Today's sea  ·  %d left" % left
	for definition in config.fish_definitions:
		var range_text := "—" if definition.is_empty_catch else "%d–%d kg" % [definition.min_weight_kg, definition.max_weight_kg]
		var amount_text: String
		var faded := false
		if remaining.is_empty():
			amount_text = "%d%%" % roundi(chances.get(definition.species_id, definition.probability) * 100.0)
		else:
			var now: int = remaining.get(definition.species_id, 0)
			amount_text = "%d / %d" % [now, initial.get(definition.species_id, 0)]
			faded = now == 0
		for text in [definition.display_name, range_text, amount_text]:
			var cell := Label.new()
			cell.text = text
			cell.add_theme_font_size_override("font_size", 18)
			if faded:
				cell.modulate = Color(1, 1, 1, 0.35)
			_grid.add_child(cell)


func _render_forecast(forecast: CatchForecast, config: GameConfig) -> void:
	if forecast == null:
		_forecast_label.text = "Next cast  —"
		_forecast_label.remove_theme_color_override("font_color")
		return
	_forecast_label.text = "Next cast  ·  Break %s  ·  Exactly %d kg %s\nRoom left %d kg  ·  No catch %s" % [
		_percent(forecast.get_bust_chance()),
		config.weight_cap_kg,
		_percent(forecast.get_perfect_chance()),
		forecast.get_room_kg(),
		_percent(forecast.get_empty_chance()),
	]
	_forecast_label.add_theme_color_override("font_color", risk_color(forecast))


static func _percent(value: float) -> String:
	if value > 0.0 and value < 0.01:
		return "<1%"
	return "%d%%" % roundi(value * 100.0)
