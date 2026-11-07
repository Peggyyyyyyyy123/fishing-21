class_name FishingView
extends Control
## Lightweight native 2D scenery; no game state or rule calculations.

var _time: float = 0.0
var _casting: bool = false


func set_casting(value: bool) -> void:
	_casting = value


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var horizon := size.y * 0.36
	draw_rect(Rect2(Vector2.ZERO, size), Color("102c41"))
	draw_rect(Rect2(0, horizon, size.x, size.y - horizon), Color("123e50"))
	draw_circle(Vector2(size.x * 0.74, horizon - 35), 48, Color("e7b87c"))
	for index in range(12):
		var y := horizon + 28 + index * 26
		var x := fmod(index * 139.0 + _time * 9.0, maxf(size.x, 1.0))
		draw_line(Vector2(x, y), Vector2(x + 78, y), Color(0.55, 0.79, 0.78, 0.16), 2)
	var boat := Vector2(size.x * 0.37, size.y * 0.51 + sin(_time * 1.5) * 3)
	draw_colored_polygon(PackedVector2Array([boat + Vector2(-87, 0), boat + Vector2(92, 0), boat + Vector2(64, 30), boat + Vector2(-59, 30)]), Color("bb8056"))
	draw_line(boat + Vector2(-83, 0), boat + Vector2(88, 0), Color("edc38e"), 5)
	draw_circle(boat + Vector2(-12, -48), 12, Color("e8c9a0"))
	draw_line(boat + Vector2(-12, -34), boat + Vector2(-7, -4), Color("88b3a7"), 14)
	draw_line(boat + Vector2(-8, -26), boat + Vector2(23, -22), Color("e8c9a0"), 6)
	var tip := boat + Vector2(98, -100 if _casting else -66)
	draw_line(boat + Vector2(19, -19), tip, Color("efd9b1"), 3)
	var float_point := boat + Vector2(180 + sin(_time * 8) * 8 if _casting else 150, 28)
	draw_line(tip, float_point, Color(0.85, 0.92, 0.9, 0.7), 1)
	draw_circle(float_point, 4, Color("ee9471"))
	if _casting:
		draw_arc(float_point, 16 + fmod(_time * 35, 14), 0, TAU, 32, Color("78b8b9"), 2)
