extends Node

const STORE_PATH: String = "user://escape_to_marty_save.cfg"
const ACTIVE_PROFILE: String = "profile_0"
const SAVE_VERSION: int = 1

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
	if error == ERR_FILE_NOT_FOUND:
		return
	if error != OK:
		_quarantine_store("unreadable, error %d" % error)
		return
	if int(_store.get_value("meta", "save_version", 0)) != SAVE_VERSION:
		_quarantine_store("save_version %s, expected %d" % [_store.get_value("meta", "save_version", 0), SAVE_VERSION])

func _quarantine_store(reason: String) -> void:
	push_warning("SaveProgression: discarding incompatible save (%s) -- kept as .bad" % reason)
	_store = ConfigFile.new()
	var dir: DirAccess = DirAccess.open("user://")
	if dir == null:
		return
	var file_name: String = STORE_PATH.get_file()
	if dir.file_exists(file_name + ".bad"):
		dir.remove(file_name + ".bad")
	dir.rename(file_name, file_name + ".bad")

func _save_store() -> void:
	_store.set_value("meta", "save_version", SAVE_VERSION)
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

func save_run_checkpoint(floor_index: int, player_state: Dictionary) -> void:
	_ensure_loaded()
	_store.set_value(ACTIVE_PROFILE, "run/floor", floor_index)
	_store.set_value(ACTIVE_PROFILE, "run/player", player_state)
	_save_store()

func has_run_checkpoint() -> bool:
	_ensure_loaded()
	return int(_store.get_value(ACTIVE_PROFILE, "run/floor", 0)) > 0

func run_checkpoint_floor() -> int:
	_ensure_loaded()
	return int(_store.get_value(ACTIVE_PROFILE, "run/floor", 0))

func run_checkpoint_player() -> Dictionary:
	_ensure_loaded()
	return Dictionary(_store.get_value(ACTIVE_PROFILE, "run/player", {}))

func clear_run_checkpoint() -> void:
	_ensure_loaded()
	for key: String in ["run/floor", "run/player"]:
		if _store.has_section_key(ACTIVE_PROFILE, key):
			_store.erase_section_key(ACTIVE_PROFILE, key)
	_save_store()

func record_run_score(tier: String, run_score: int) -> void:
	_ensure_loaded()
	var key: String = "best/" + tier
	if run_score <= int(_store.get_value(ACTIVE_PROFILE, key, 0)):
		return
	_store.set_value(ACTIVE_PROFILE, key, run_score)
	_save_store()

func record_run_clear(tier: String) -> void:
	_ensure_loaded()
	var key: String = "clears/" + tier
	_store.set_value(ACTIVE_PROFILE, key, int(_store.get_value(ACTIVE_PROFILE, key, 0)) + 1)
	_save_store()

func best_score(tier: String) -> int:
	_ensure_loaded()
	return int(_store.get_value(ACTIVE_PROFILE, "best/" + tier, 0))

func best_score_any() -> Dictionary:
	_ensure_loaded()
	var best: Dictionary = {}
	for tier: String in SettingsManager.TIER_NAMES:
		var value: int = best_score(tier)
		if value > int(best.get("score", 0)):
			best = {"tier": tier, "score": value}
	return best

func reset_progress() -> void:
	_ensure_loaded()
	if _store.has_section(ACTIVE_PROFILE):
		_store.erase_section(ACTIVE_PROFILE)
	_save_store()
