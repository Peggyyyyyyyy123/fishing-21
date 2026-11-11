class_name FieldGuideBook
extends ColorRect
## Two-page field guide: the right page lists every species (silhouettes until discovered),
## the left page shows the selected species' record. Reads a FishCatalog snapshot.

signal closed

const PAGE_INK := Color("5c5943")

var _definitions: Array[FishDefinition] = []
var _catalog := FishCatalog.new()
var _selected: StringName = &""
var _summary: RichTextLabel
var _grid: GridContainer
var _detail_name: Label
var _detail_art: FishArt
var _detail_stats: RichTextLabel
var _close: Button


func build(scene_owner: Node) -> void:
	UiKit.dim(self, 0.76)
	var book := UiKit.panel(UiKit.centered(self), Color("816844"), 6, 10)
	book.custom_minimum_size = Vector2(1160, 660)
	var cover := UiKit.box(Color("816844"), 6, 10, Color("4c4439"), 3)
	cover.shadow_color = Color(0, 0, 0, 0.4)
	cover.shadow_size = 12
	book.add_theme_stylebox_override("panel", cover)
	var pages := UiKit.row(book, 0)
	_build_detail_page(pages, scene_owner)
	var seam := ColorRect.new()
	seam.color = Color("ae996d")
	seam.custom_minimum_size.x = 8
	pages.add_child(seam)
	_build_collection_page(pages, scene_owner)


func open(definitions: Array[FishDefinition], catalog: FishCatalog) -> void:
	_definitions = definitions
	_catalog = catalog
	for child in _grid.get_children():
		_grid.remove_child(child)
		child.queue_free()
	var selection := ButtonGroup.new()
	for definition in _definitions:
		var found := _catalog.is_discovered(definition.species_id)
		_grid.add_child(_make_tile(definition, found, selection))
		if found and _selected == &"":
			_selected = definition.species_id
	_summary.text = "FIELD GUIDE\nCollected %d / %d" % [_count_discovered(), _definitions.size()]
	select(_selected)
	show()
	_close.grab_focus()


func select(species_id: StringName) -> void:
	_selected = species_id
	for tile in _grid.get_children():
		(tile as Button).set_pressed_no_signal(tile.get_meta("species") == species_id)
	var definition := _find(species_id)
	if definition == null or not _catalog.is_discovered(species_id):
		_detail_name.text = "UNEXPLORED WATERS"
		_detail_art.setup(&"sardine", true)
		_detail_stats.text = "[center]Your story starts with a cast.\n\nCatch a new species to reveal its\nportrait and record weight.[/center]"
		return
	var count := _catalog.get_catch_count(species_id)
	var best := _catalog.get_best_weight_kg(species_id)
	var price := "%d gold / kg" % definition.price_per_kg if definition.price_per_kg > 0 else "Base price"
	_detail_name.text = definition.display_name.to_upper()
	_detail_art.setup(species_id)
	_detail_stats.text = "[center]%s\n\nBIGGEST CATCH\n[font_size=36]%s[/font_size]\n\nTotal caught: %s\n%s  ·  %d–%d kg\n\nFirst discovery: +%d gold[/center]" % [
		definition.rarity,
		"%s g" % String.num_int64(best * 1000) if best > 0 else "Not recorded",
		str(count) if count > 0 else "Previously discovered",
		price,
		definition.min_weight_kg,
		definition.max_weight_kg,
		definition.discovery_reward,
	]


func close() -> void:
	hide()
	closed.emit()


func get_selected_species() -> StringName:
	return _detail_art.species


func _build_detail_page(pages: Node, scene_owner: Node) -> void:
	var left := UiKit.panel(pages, UiKit.PAPER, 2, 30)
	left.custom_minimum_size.x = 500
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var detail := UiKit.column(left, 10)
	var subtitle := UiKit.label("AN ANGLER'S FIELD GUIDE", 17, Color("8e7954"))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail.add_child(subtitle)
	_detail_name = UiKit.named(UiKit.label("SELECT A FISH", 29, Color("514f3c")), "CatalogFishName", detail, scene_owner)
	_detail_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var mount := UiKit.panel(detail, Color("d9cba0"), 2, 14)
	_detail_art = UiKit.art(mount, &"sardine", Vector2(360, 200))
	_detail_stats = UiKit.named(_rich_text(22, PAGE_INK), "CatalogFishStats", detail, scene_owner)
	_detail_stats.size_flags_vertical = Control.SIZE_EXPAND_FILL


func _build_collection_page(pages: Node, scene_owner: Node) -> void:
	var right := UiKit.panel(pages, Color("e8d9af"), 2, 26)
	right.custom_minimum_size.x = 580
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var collection := UiKit.column(right, 16)
	var heading := UiKit.row(collection)
	_summary = UiKit.named(_rich_text(22, Color("6e6246")), "CatalogDetails", heading, scene_owner)
	_summary.custom_minimum_size = Vector2(350, 44)
	UiKit.space(heading, false)
	_close = UiKit.named(UiKit.button("Close"), "CatalogClose", heading, scene_owner)
	_close.pressed.connect(close)
	collection.add_child(UiKit.label("YOUR COLLECTION  /  SELECT TO INSPECT", 16, Color("8c7956")))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size.y = 360
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	collection.add_child(scroll)
	_grid = UiKit.named(GridContainer.new(), "CatalogGrid", scroll, scene_owner)
	_grid.columns = 4
	_grid.add_theme_constant_override("h_separation", 10)
	_grid.add_theme_constant_override("v_separation", 10)
	collection.add_child(UiKit.label("Catch a species to add it to your guide.\nReleased fish count, too.\nDiscovery rewards are paid once per save.", 17, Color("8a7958")))


func _make_tile(definition: FishDefinition, found: bool, group: ButtonGroup) -> Button:
	var tile := Button.new()
	tile.set_meta("species", definition.species_id)
	tile.toggle_mode = true
	tile.button_group = group
	tile.custom_minimum_size = Vector2(118, 112)
	tile.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if found else Control.CURSOR_ARROW
	tile.tooltip_text = definition.display_name if found else "Not discovered"
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var lit: bool = state in ["hover", "pressed"]
		var chosen: bool = state == "pressed"
		tile.add_theme_stylebox_override(state, UiKit.box(Color("daceaa") if lit else Color("c9bd98"), 3, 5, Color("6c795b") if chosen else Color("9b865f"), 3 if chosen else 1))
	var portrait := UiKit.art(tile, definition.species_id, Vector2.ZERO, not found)
	portrait.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	portrait.offset_left = 4
	portrait.offset_right = -4
	portrait.offset_top = 5
	portrait.offset_bottom = -34
	var caption := UiKit.label(definition.display_name if found else "???", 12, PAGE_INK)
	tile.add_child(caption)
	caption.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	caption.offset_top = -32
	caption.offset_bottom = -3
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Undiscovered species stay silhouettes and cannot reveal their details.
	tile.disabled = not found
	if found:
		tile.pressed.connect(select.bind(definition.species_id))
		tile.button_pressed = _selected == definition.species_id
	return tile


func _rich_text(font_size: int, color: Color) -> RichTextLabel:
	var text := RichTextLabel.new()
	text.bbcode_enabled = true
	text.fit_content = true
	text.scroll_active = false
	text.add_theme_color_override("default_color", color)
	text.add_theme_font_size_override("normal_font_size", font_size)
	return text


func _count_discovered() -> int:
	var count := 0
	for definition in _definitions:
		if _catalog.is_discovered(definition.species_id):
			count += 1
	return count


func _find(species_id: StringName) -> FishDefinition:
	for definition in _definitions:
		if definition.species_id == species_id:
			return definition
	return null
