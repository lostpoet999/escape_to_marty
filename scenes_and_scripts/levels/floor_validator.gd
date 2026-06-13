class_name FloorValidator extends RefCounted

const OFFSETS: Array[Vector2i] = [Vector2i(0, -1), Vector2i(0, 1), Vector2i(1, 0), Vector2i(-1, 0)]

# reads the exit bool by property (not RoomEntry.has_door) so it works on the
# placeholder instances the editor hands non-@tool resources
static func _slot_door(slot: RoomEntry, offset: Vector2i) -> bool:
	match offset:
		Vector2i(0, -1): return slot.north_exit
		Vector2i(0, 1): return slot.south_exit
		Vector2i(1, 0): return slot.east_exit
		Vector2i(-1, 0): return slot.west_exit
	return false

static func validate(floor: FloorData) -> Array[Dictionary]:
	var issues: Array[Dictionary] = []
	if floor == null:
		issues.append({severity = "error", text = "No FloorData selected."})
		return issues

	var slots: Array[RoomEntry] = floor.room_entries
	var by_coords: Dictionary = {}
	for slot: RoomEntry in slots:
		if slot == null:
			continue
		var key: String = RoomEntry.make_key(slot.room_coords)
		if by_coords.has(key):
			issues.append({severity = "error", text = "Two slots share coords %s." % key})
		by_coords[key] = slot
		var c: Vector2i = slot.room_coords
		if c.x < 1 or c.y < 1 or c.x > floor.grid_size.x or c.y > floor.grid_size.y:
			issues.append({severity = "error", text = "Slot %s is off the %dx%d grid." % [key, floor.grid_size.x, floor.grid_size.y]})

	var start_slot: RoomEntry = null
	for slot: RoomEntry in slots:
		if slot != null and slot.is_static and slot.content != null and slot.content.room_type == RoomContent.ROOM_TYPES.starting_room:
			start_slot = slot
			break
	if start_slot == null:
		issues.append({severity = "error", text = "No static starting_room slot."})

	for slot: RoomEntry in slots:
		if slot == null:
			continue
		for off: Vector2i in OFFSETS:
			if _slot_door(slot, off) and not by_coords.has(RoomEntry.make_key(slot.room_coords + off)):
				issues.append({severity = "error", text = "Slot %s has an exit into empty cell %s." % [RoomEntry.make_key(slot.room_coords), RoomEntry.make_key(slot.room_coords + off)]})

	if start_slot != null:
		var reachable: Dictionary = _reachable_keys(start_slot, by_coords)
		for slot: RoomEntry in slots:
			if slot != null and not reachable.has(RoomEntry.make_key(slot.room_coords)):
				issues.append({severity = "error", text = "Slot %s is unreachable from start." % RoomEntry.make_key(slot.room_coords)})
		for slot: RoomEntry in slots:
			if slot == null or slot.content == null or not slot.content.is_secret:
				continue
			var skey: String = RoomEntry.make_key(slot.room_coords)
			var without: Dictionary = _reachable_keys_excluding(start_slot, by_coords, skey)
			var blocked: Array[String] = []
			for other: RoomEntry in slots:
				if other == null or other == slot:
					continue
				var okey: String = RoomEntry.make_key(other.room_coords)
				if reachable.has(okey) and not without.has(okey):
					blocked.append(okey)
			if not blocked.is_empty():
				issues.append({severity = "error", text = "Secret room %s blocks the only path to %s." % [skey, ", ".join(blocked)]})

	var open_count: int = 0
	for slot: RoomEntry in slots:
		if slot != null and not slot.is_static:
			open_count += 1
	var required: Array[RoomContent] = []
	var filler_count: int = 0
	for content: RoomContent in floor.room_pool:
		if content == null:
			continue
		if content.required:
			required.append(content)
		else:
			filler_count += 1
	if required.size() > open_count:
		issues.append({severity = "error", text = "%d required rooms but only %d non-static slots." % [required.size(), open_count]})
	if required.size() + filler_count < open_count:
		issues.append({severity = "error", text = "Pool supplies %d rooms for %d non-static slots." % [required.size() + filler_count, open_count]})
	elif filler_count > open_count - required.size():
		issues.append({severity = "info", text = "Spare filler in pool — a random subset appears each run."})

	if floor.required_composition.is_empty():
		issues.append({severity = "info", text = "No required_composition set — room-type minimums unchecked."})
	else:
		var guaranteed: Dictionary = {}
		for slot: RoomEntry in slots:
			if slot != null and slot.is_static and slot.content != null:
				guaranteed[slot.content.room_type] = int(guaranteed.get(slot.content.room_type, 0)) + 1
		for content: RoomContent in required:
			guaranteed[content.room_type] = int(guaranteed.get(content.room_type, 0)) + 1
		for type_value: int in floor.required_composition:
			var need: int = floor.required_composition[type_value]
			var have: int = int(guaranteed.get(type_value, 0))
			if have < need:
				issues.append({severity = "error", text = "Need %d %s, only %d guaranteed." % [need, _type_name(type_value), have]})

	_check_boss_count(floor, slots, issues)
	_check_missing_scenes(floor, slots, issues)

	if _no_errors(issues):
		issues.append({severity = "ok", text = "No blocking issues."})
	return issues

# only one boss room is usable per floor — its FloorPortal ends the floor on click,
# so a second boss room is wasted/skipped. count static boss slots + pooled boss
# content (required always placed, filler may be). >1 guaranteed is broken; a filler
# boss that could double the count is a warning.
static func _check_boss_count(floor: FloorData, slots: Array[RoomEntry], issues: Array[Dictionary]) -> void:
	var boss_type: int = RoomContent.ROOM_TYPES.boss
	var static_boss: int = 0
	for slot: RoomEntry in slots:
		if slot != null and slot.is_static and slot.content != null and slot.content.room_type == boss_type:
			static_boss += 1
	var required_boss: int = 0
	var filler_boss: int = 0
	for content: RoomContent in floor.room_pool:
		if content == null or content.room_type != boss_type:
			continue
		if content.required:
			required_boss += 1
		else:
			filler_boss += 1
	var guaranteed: int = static_boss + required_boss
	var possible: int = guaranteed + filler_boss
	if guaranteed > 1:
		issues.append({severity = "error", text = "%d boss rooms always spawn — only one is usable (its portal ends the floor)." % guaranteed})
	elif possible > 1:
		issues.append({severity = "error", text = "Up to %d boss rooms can spawn — a filler boss in the pool may double the boss." % possible})

static func _check_missing_scenes(floor: FloorData, slots: Array[RoomEntry], issues: Array[Dictionary]) -> void:
	for slot: RoomEntry in slots:
		if slot != null and slot.is_static and slot.content != null and slot.content.room_scene == null:
			issues.append({severity = "error", text = "Static slot %s has content but no room scene." % RoomEntry.make_key(slot.room_coords)})
	for i: int in floor.room_pool.size():
		var content: RoomContent = floor.room_pool[i]
		if content != null and content.room_scene == null:
			issues.append({severity = "error", text = "Pool entry %d (%s) has no room scene." % [i, _type_name(content.room_type)]})


static func _reachable_keys(start: RoomEntry, by_coords: Dictionary) -> Dictionary:
	var seen: Dictionary = {RoomEntry.make_key(start.room_coords): true}
	var stack: Array[RoomEntry] = [start]
	while not stack.is_empty():
		var slot: RoomEntry = stack.pop_back()
		for off: Vector2i in OFFSETS:
			var nkey: String = RoomEntry.make_key(slot.room_coords + off)
			if not by_coords.has(nkey) or seen.has(nkey):
				continue
			var neighbor: RoomEntry = by_coords[nkey]
			if _slot_door(slot, off) or _slot_door(neighbor, -off):
				seen[nkey] = true
				stack.append(neighbor)
	return seen

# reachability with one slot removed, to test whether it is the sole access path
static func _reachable_keys_excluding(start: RoomEntry, by_coords: Dictionary, exclude_key: String) -> Dictionary:
	if RoomEntry.make_key(start.room_coords) == exclude_key:
		return {}
	var seen: Dictionary = {RoomEntry.make_key(start.room_coords): true}
	var stack: Array[RoomEntry] = [start]
	while not stack.is_empty():
		var slot: RoomEntry = stack.pop_back()
		for off: Vector2i in OFFSETS:
			var nkey: String = RoomEntry.make_key(slot.room_coords + off)
			if nkey == exclude_key or not by_coords.has(nkey) or seen.has(nkey):
				continue
			var neighbor: RoomEntry = by_coords[nkey]
			if _slot_door(slot, off) or _slot_door(neighbor, -off):
				seen[nkey] = true
				stack.append(neighbor)
	return seen

static func _type_name(type_value: int) -> String:
	var names: Array = RoomContent.ROOM_TYPES.keys()
	return names[type_value] if type_value >= 0 and type_value < names.size() else str(type_value)

static func _no_errors(issues: Array[Dictionary]) -> bool:
	for issue: Dictionary in issues:
		if issue.severity == "error":
			return false
	return true
