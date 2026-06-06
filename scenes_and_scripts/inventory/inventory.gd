class_name PlayerInventory extends Node

## A script to do amazing things, and maybe more ...

const DEBUG: bool = true
const PLACEHOLDER_TEX: Texture2D = preload("uid://cn44s8tnj8dg2") #putting here so other interfaces can get it easy

var items: Array[BaseItem] ## Powerups, passives or actives for ball, paddle, or click. One active passive for each type.
var core_items: Array[BaseItem]

@warning_ignore_start("untyped_declaration")
## Print method with decorator.
static func p(arg): print_rich("[bgcolor=black][color=white]", "Inventory: ", arg)
## Print method with decorator.
@warning_ignore("unsafe_call_argument")
static func dp(arg): if DEBUG: p(arg)

#region Instance

## Static instance, we (probably?) should only have one inventory in the scene tree at any time.
## Cross that bridge when we get there...
static var instance: PlayerInventory:
	set(value):
		if value != null && instance != null:
			assert(
				not (is_instance_valid(instance) and not instance.is_queued_for_deletion()),
				"More than one instance of PlayerInventory exists."
				)
		instance = value

## This method uses an assertion and should be used when you don't expect to handle a null value.
static func get_instance() -> PlayerInventory:
	assert(instance, "Get instance called and no inventory instance exists.")
	return instance

func _enter_tree() -> void:
	instance = self
	dp("Entering tree.")

func _exit_tree() -> void:
	if instance == self:
		instance = null
	dp("Exiting tree.")

#endregion

func _ready() -> void:
	Signalbus.paddle_swap_resolved.connect(replace_paddle_active)
	init_starting_items()

func init_starting_items() ->void:
	const BALL_PASSIVE_POWERUPS: Array = [
		## Add testing inventory items here that will be added in _ready
	preload("uid://ctjeqnpuca6lq"), # base ball
]
	items.append_array(BALL_PASSIVE_POWERUPS)
	const CORE_ITEMS: Array = [
		## Add testing inventory items here that will be added in _ready
	preload("uid://b61d4hm0o24k0") # basic bounce
]
	core_items.append_array(CORE_ITEMS)

func get_items() -> Array:
	return items
	
func get_core_items() -> Array:
	return core_items

## Load power-ups from inventory for appropriate object
func get_items_for_ball() -> Array[BallPassive]:
	var _items: Array[BallPassive] = []
	for item:BaseItem in items:
		if item is BallPassive:
			_items.append(item)
	return _items
	
func get_items_for_paddle() -> Array[PaddlePowerup]: ###passives for paddle
	var _items: Array[PaddlePowerup]
	for item: BaseItem in items:
		if item is PaddlePowerup:
			_items.append(item)
	return _items

## current ball damage derived from owned ball passives. mirrors Ball.update_base_dmg
## so the inventory panel can report it without a live Ball in the tree.
func get_ball_damage() -> float:
	var dmg: float = Ball.DEFAULT_BALL_DMG
	var ball_items: Array[BallPassive] = get_items_for_ball()
	for passive: BallPassive in ball_items:
		dmg += passive.global_bonus
	for passive: BallPassive in ball_items:
		dmg *= passive.global_multi
	return dmg

func get_ball_bounce() -> BaseBounceEffect:
	for item: BaseItem in core_items:
		if item is BaseBounceEffect:
			return item
	return null

func get_paddle_active() -> PaddleActive:	#inventory logic prevents more than one, so returning on first one should be good
	for item:BaseItem in core_items:
		if item is PaddleActive:
			return item
	return null

func get_items_for_click() -> Array[ClickPowerUp]:
	var _items: Array[ClickPowerUp] = []
	for item: BaseItem in items:
		if item is ClickPowerUp:
			_items.append(item)
	return _items

func get_items_for_defense() -> Array[DefensivePowerup]:
	var _items: Array[DefensivePowerup] = []
	for item: BaseItem in items:
		if item is DefensivePowerup:
			_items.append(item)
	return _items

func get_reflect_reduction() -> float:
	var total: float = 0.0
	for powerup: DefensivePowerup in get_items_for_defense():
		total += powerup.reflect_reduction
	return clampf(total, 0.0, PlayerData.MAX_REFLECT_REDUCTION)

func get_max_health_bonus() -> int:
	var total: int = 0
	for powerup: DefensivePowerup in get_items_for_defense():
		total += powerup.max_health_bonus
	return total

func has_room_scanner() -> bool:
	for item: BaseItem in items:
		if item.reveals_adjacent_rooms:
			return true
	for item: BaseItem in core_items:
		if item.reveals_adjacent_rooms:
			return true
	return false

func get_gesture_damage() -> float:
	var dmg: float = MouseGestures.DEFAULT_CLICK_DMG
	var click_items: Array[ClickPowerUp] = get_items_for_click()
	for power: ClickPowerUp in click_items:
		dmg += power.global_bonus
	for power: ClickPowerUp in click_items:
		dmg *= power.global_multi
	return dmg

func add_item(new_item) -> void:	
	if new_item is PaddleActive:
		if core_items.has(new_item):#:TODO already has exactly this active
			return
		var existing: Array = core_items.filter(func(i: BaseItem) -> bool: return i is PaddleActive)
		var old_active: PaddleActive = null
		if existing.is_empty():							
			Signalbus.paddle_active_assigned.emit(new_item) #signal a new active is assiagned with reference to what was assigned
			core_items.push_front(new_item)
			Signalbus.inventory_changed.emit()
		elif existing.size() > 1:
			assert(existing.size() <=1,"more than one paddle active found: there should only be one---kinda like highlander")
		else:
			old_active = existing.front()
			Signalbus.paddle_active_swap_needed.emit(old_active,new_item)			


	elif new_item is BallPassive or new_item is PaddlePowerup or new_item is ClickPowerUp or new_item is DefensivePowerup or new_item is UtilityPowerup:
			items.push_back(new_item) #this will move when we do quantity update from above
			Signalbus.inventory_changed.emit()
			if new_item is DefensivePowerup:
				var defense: DefensivePowerup = new_item
				if defense.heal_on_pickup > 0:
					PlayerData.change_player_health(defense.heal_on_pickup)
	
func replace_paddle_active(new_item: PaddleActive): #where item is replaced in player inventory
	var index: int = core_items.find_custom(func(i): return i is PaddleActive)
	core_items.remove_at(index)
	core_items.push_front(new_item)
	Signalbus.inventory_changed.emit()


func remove_item(item) -> void:
	if not item in items:
		dp("Tried to remove, but couldn't find item %s." % item)
	else:
		items.erase(item)
		dp("Removed item %s.")
		
	Signalbus.inventory_changed.emit()

func use_item(item: BaseItem) -> void:
	dp("Using item %s..." % item)
	remove_item(item)
	if item is BallPassive:
		## TODO
		pass
	#elif item is PaddlePowerUp:
		#pass
	#elif item is ClickPowerUp:
		#pass
		
	#changed.emit() ## ?
