class_name FishArt
extends Control
## Native pixel sprites shared by catch cards, net slots and the field guide.
## Drawn from a tiny grid so they stay crisp at every viewport scale.
static var _textures: Dictionary = {}
var species: StringName = &"sardine"
var silhouette: bool = false

func setup(id: StringName, unknown: bool = false) -> void:
	species = id
	silhouette = unknown
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()

static func sprite(id: StringName) -> Texture2D:
	if _textures.has(id):
		return _textures[id]
	var ids := [&"sardine", &"mackerel", &"horse_mackerel", &"mullet", &"sea_bass", &"red_seabream", &"gold_butterflyfish", &"grouper", &"moon_angelfish", &"golden_tuna"]
	var index := maxi(ids.find(id), 0)
	var colors := ["96c6ce", "638c9d", "89b7a5", "9caca3", "8da873", "e39b80", "e9c86f", "a99670", "b7a4da", "dcc16b"]
	var base := Color(colors[index])
	var image := Image.create(40, 26, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var tall := index in [5, 6, 8]
	var radius_y := 7.5 if tall else (5.5 if index in [4, 7, 9] else 4.0)
	var radius_x := 11.0 if tall else 13.0
	# Tail, fins, layered body and a dark stepped outline.
	for y in range(26):
		for x in range(40):
			var tail := x >= 29 and x <= 37 and absf(y - 12.0) <= float(x - 28) * 0.85
			var fin := x >= 14 and x <= 24 and y >= 12 - radius_y - 3 and y <= 12 + radius_y + 3 and absf(x - 20.0) + absf(y - 12.0) < radius_y + 8
			if tail or fin:
				image.set_pixel(x, y, base.darkened(0.28 if (x+y)%3 else 0.42))
	for y in range(26):
		for x in range(40):
			var dx := (x - 18.0) / radius_x
			var dy := (y - 12.0) / radius_y
			if dx*dx + dy*dy <= 1.0:
				var color := base
				if y < 10: color = base.darkened(0.28)
				if y > 13: color = base.lightened(0.22)
				if dx*dx + dy*dy > 0.78: color = base.darkened(0.48)
				if index in [1, 2, 6] and x%5 <= 1 and x > 13: color = base.darkened(0.40)
				if index == 7 and (x*7+y*3)%11 < 3: color = base.darkened(0.35)
				if index == 5 and y == 11: color = base.lightened(0.35)
				if index == 8 and x%7 == 0: color = base.lightened(0.3)
				image.set_pixel(x, y, color)
	image.set_pixel(8 if not tall else 9, 10, Color("f7e4b3"))
	image.set_pixel(8 if not tall else 9, 11, Color("182d3d"))
	image.set_pixel(9 if not tall else 10, 10, Color("182d3d"))
	image.set_pixel(6 if not tall else 8, 13, Color("182d3d"))
	var texture := ImageTexture.create_from_image(image)
	_textures[id] = texture
	return texture

func _draw() -> void:
	var factor := minf(size.x / 40.0, size.y / 26.0)
	var dimensions := Vector2(40, 26) * factor
	draw_texture_rect(sprite(species), Rect2((size - dimensions) / 2, dimensions), false, Color("46505a") if silhouette else Color.WHITE)
