class_name FishCatalogStore
extends RefCounted
## Saves and loads the fish catalogue as a small local file. Infrastructure, not game rules:
## it only moves plain dictionaries; FishCatalog interprets them. Tests pass a separate path.

var path: String
var last_error: Error = OK


func _init(save_path: String = "user://fish_catalog_v1.cfg") -> void:
	path = save_path


## Missing file = empty catalogue. Unreadable or malformed file = empty catalogue with last_error set.
func load_catalog() -> FishCatalog:
	var file := ConfigFile.new()
	last_error = file.load(path)
	if last_error == ERR_FILE_NOT_FOUND:
		last_error = OK
		return FishCatalog.new()
	if last_error != OK:
		return FishCatalog.new()
	var value: Variant = file.get_value("catalog", "discovered", {})
	if not value is Dictionary:
		last_error = ERR_INVALID_DATA
		return FishCatalog.new()
	return FishCatalog.from_dictionary(value)


## Writes to a temporary file first, then replaces the old save, so a crash cannot leave half a file.
func save_catalog(catalog: FishCatalog) -> Error:
	var file := ConfigFile.new()
	file.set_value("catalog", "version", FishCatalog.SCHEMA_VERSION)
	file.set_value("catalog", "discovered", catalog.to_dictionary())
	last_error = file.save(path + ".tmp")
	if last_error == OK:
		last_error = DirAccess.rename_absolute(ProjectSettings.globalize_path(path + ".tmp"), ProjectSettings.globalize_path(path))
	return last_error


## Test/tool helper: writes raw saved data, e.g. a version 1 file of `true` flags.
func save_raw(data: Dictionary, version: int = 1) -> Error:
	var file := ConfigFile.new()
	file.set_value("catalog", "version", version)
	file.set_value("catalog", "discovered", data)
	last_error = file.save(path)
	return last_error
