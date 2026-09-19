extends Node

const ID_STORE_PATH: String = "user://escape_to_marty_telemetry.cfg"
const BOARD_PREFIX: String = "etm_"
const BOARD_ROWS: int = 10
const NAME_MAX_LENGTH: int = 12
const NAME_SUFFIX_TRIES: int = 9

var _identified: bool = false
var _identifying: bool = false
var _pending: Array[PendingEvent] = []
var _first_launch_sent: bool = false
var _first_clear_sent: bool = false
var _last_entry_id: int = -1
var last_fetch_failed: bool = false


class PendingEvent:
	var event: String
	var props: Dictionary[String, String]

	func _init(event_name: String, event_props: Dictionary[String, String]) -> void:
		event = event_name
		props = event_props


func _ready() -> void:
	if not OS.has_feature("web"):
		return
	Signalbus.player_died.connect(track.bind("death"))
	Signalbus.floor_cleared.connect(track.bind("floor_clear"))
	Signalbus.boss_defeated.connect(track.bind("boss_defeated"))
	Signalbus.level_cleared.connect(_on_level_cleared)
	Signalbus.practice_seal_cleared.connect(track.bind("practice_cleared"))
	Signalbus.game_state_playing.connect(_on_game_state_playing)
	track("boot")
	_identify()


func enabled() -> bool:
	return OS.has_feature("web") and SettingsManager.share_gameplay_data


func track(event: String) -> void:
	if not enabled():
		return
	var props: Dictionary[String, String] = _build_props()
	if not _identified:
		_pending.append(PendingEvent.new(event, props))
		return
	_send(event, props)


static func board_name(tier: String) -> String:
	return BOARD_PREFIX + tier.to_lower()


static func sanitize_name(raw: String) -> String:
	var cleaned: String = ""
	for character: String in raw.strip_edges():
		if character.is_valid_ascii_identifier() or character == " " or character.is_valid_int():
			cleaned += character
	return cleaned.to_upper().left(NAME_MAX_LENGTH).strip_edges()


static func format_rows(rows: Array[Dictionary]) -> String:
	if rows.is_empty():
		return "no runs posted yet"
	var lines: PackedStringArray = PackedStringArray()
	for index: int in rows.size():
		var row: Dictionary = rows[index]
		var line: String = "%2d. %-12s %8d" % [index + 1, String(row["name"]), int(row["score"])]
		if bool(row["mine"]):
			line = "[color=#ebede9]%s[/color]" % line
		lines.append(line)
	return "\n".join(lines)


func submit_score(tier: String, run_score: int, player_name: String) -> bool:
	if not enabled():
		return false
	return await _submit(tier, run_score, player_name)


func claim_name(player_name: String) -> String:
	var clean_name: String = sanitize_name(player_name)
	if clean_name.is_empty() or not enabled():
		return clean_name
	if not await _is_name_taken(clean_name):
		return clean_name
	var base: String = clean_name.left(NAME_MAX_LENGTH - 1)
	for suffix: int in range(1, NAME_SUFFIX_TRIES + 1):
		var candidate: String = base + str(suffix)
		if not await _is_name_taken(candidate):
			return candidate
	return ""


func fetch_top(tier: String) -> Array[Dictionary]:
	if not enabled():
		return []
	return await _fetch(tier)


func _submit(tier: String, run_score: int, player_name: String) -> bool:
	var clean_name: String = sanitize_name(player_name)
	if clean_name.is_empty():
		return false
	if not _identified:
		await _identify()
	if not _identified:
		return false
	var props: Dictionary[String, Variant] = {"name": clean_name}
	var result: LeaderboardsAPI.AddEntryResult = await Talo.leaderboards.add_entry(board_name(tier), float(run_score), props)
	if result == null or not result.success:
		return false
	_last_entry_id = result.entry.id
	return true


func _is_name_taken(player_name: String) -> bool:
	if not _identified:
		await _identify()
	if not _identified or Talo.current_player == null:
		return false
	var my_id: String = Talo.current_player.id
	for tier: String in SettingsManager.TIER_NAMES:
		var options: LeaderboardsAPI.GetEntriesOptions = LeaderboardsAPI.GetEntriesOptions.new()
		options.prop_key = "name"
		options.prop_value = player_name.uri_encode()
		var page: LeaderboardsAPI.EntriesPage = await Talo.leaderboards.get_entries(board_name(tier), options)
		if page == null:
			continue
		for entry: TaloLeaderboardEntry in page.entries:
			if entry.player_alias.player.id != my_id:
				return true
	return false


func _fetch(tier: String) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var page: LeaderboardsAPI.EntriesPage = await Talo.leaderboards.get_entries(board_name(tier))
	last_fetch_failed = page == null
	if page == null:
		return rows
	for entry: TaloLeaderboardEntry in page.entries:
		if rows.size() >= BOARD_ROWS:
			break
		rows.append({
			"name": entry.get_prop("name", "???"),
			"score": int(entry.score),
			"mine": entry.id == _last_entry_id,
		})
	return rows


func _identify() -> void:
	if _identified or _identifying:
		return
	_identifying = true
	var alias: TaloPlayerAlias = await Talo.players.identify("anonymous", _load_or_create_player_id())
	_identifying = false
	if alias == null:
		_pending.clear()
		return
	_identified = true
	for item: PendingEvent in _pending:
		_send(item.event, item.props)
	_pending.clear()


func _load_or_create_player_id() -> String:
	var store: ConfigFile = ConfigFile.new()
	store.load(ID_STORE_PATH)
	var player_id: String = String(store.get_value("player", "id", ""))
	if player_id.is_empty():
		player_id = Talo.players.generate_identifier()
		store.set_value("player", "id", player_id)
		store.save(ID_STORE_PATH)
	return player_id


func _build_props() -> Dictionary[String, String]:
	var props: Dictionary[String, String] = {}
	props["floor"] = str(GameManager.current_floor)
	props["room"] = GameManager.current_room_id
	props["tier"] = SettingsManager.tier_name()
	props["score"] = str(PlayerData.get_player_score())
	return props


func _send(event: String, props: Dictionary[String, String]) -> void:
	Talo.events.track(event, props)
	Talo.events.flush()


func _on_level_cleared() -> void:
	if _first_clear_sent:
		return
	_first_clear_sent = true
	track("first_room_clear")


func _on_game_state_playing() -> void:
	if _first_launch_sent:
		return
	_first_launch_sent = true
	track("first_launch")
