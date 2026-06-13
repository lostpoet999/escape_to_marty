extends Node

const STORE_PATH: String = "user://escape_to_marty_save.cfg"
const ACTIVE_PROFILE: String = "profile_0"

var _store: ConfigFile = ConfigFile.new()
var _loaded: bool = false

func _ready() -> void:
	_ensure_loaded()

func _ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	_load_store()

func _load_store() -> void:
	var error: Error = _store.load(STORE_PATH)
	if error != OK and error != ERR_FILE_NOT_FOUND:
		push_warning("SaveProgression: load failed (%d), starting empty" % error)

func _save_store() -> void:
	var error: Error = _store.save(STORE_PATH)
	if error != OK:
		push_warning("SaveProgression: save failed (%d)" % error)

func is_memory_seen(memory_id: StringName) -> bool:
	_ensure_loaded()
	return bool(_store.get_value(ACTIVE_PROFILE, "memory/" + String(memory_id), false))

func mark_memory_seen(memory_id: StringName) -> void:
	_ensure_loaded()
	var key: String = "memory/" + String(memory_id)
	if bool(_store.get_value(ACTIVE_PROFILE, key, false)):
		return
	_store.set_value(ACTIVE_PROFILE, key, true)
	_save_store()

func set_memory_trophy(floor_index: int, item_path: String) -> void:
	_ensure_loaded()
	_store.set_value(ACTIVE_PROFILE, "trophy/%d" % floor_index, item_path)
	_save_store()

func memory_trophy_path(floor_index: int) -> String:
	_ensure_loaded()
	return String(_store.get_value(ACTIVE_PROFILE, "trophy/%d" % floor_index, ""))

func has_memory_trophy(floor_index: int) -> bool:
	return memory_trophy_path(floor_index) != ""

func reset_progress() -> void:
	_ensure_loaded()
	if _store.has_section(ACTIVE_PROFILE):
		_store.erase_section(ACTIVE_PROFILE)
	_save_store()
