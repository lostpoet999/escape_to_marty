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
	preload("uid://ctjeqnpuca6lq")	
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
func get_items_for_ball() -> Array[BallPowerUp]:	
	var _items: Array[BallPowerUp] = []
	for item:BaseItem in items:
		if item is BallPowerUp:
			_items.append(item)	
	return _items
	
func get_items_for_paddle() -> Array[PaddlePowerup]: ###passives for paddle
	var _items: Array[PaddlePowerup]
	for item in items:
		if item is PaddlePowerup:
			_items.append(item)
	return _items

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

#func get_items_for_click() -> Array[ClickPowerUp]:
	#var _items: Array[BallPowerUp]
	#for item in items:
		#if item is BallPowerUp:
			#_items.append(item)
	#return _items

func add_item(new_item) -> void:	
	if new_item is PaddleActive:
		if core_items.has(new_item):#:TODO already has exactly this active
			return
		var existing = core_items.filter(func(i): return i is PaddleActive)
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


	elif new_item is BallPowerUp or new_item is PaddlePowerup:			
			if new_item in items:
				print("you already have this one, lets stack them!") #TODO: make it so inventory panel increases quantity in visual vs takeup another spot
			else:
				print("cool, new powah")
			items.push_back(new_item) #this will move when we do quantity update from above	
			Signalbus.inventory_changed.emit()
	
func replace_paddle_active(new_item: PaddleActive): #where item is replaced in player inventory
	var index = core_items.find_custom(func(i): return i is PaddleActive)
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

func use_item(item) -> void:
	dp("Using item %s..." % item)
	remove_item(item)
	if item is BallPowerUp:
		## TODO
		pass
	#elif item is PaddlePowerUp:
		#pass
	#elif item is ClickPowerUp:
		#pass
		
	#changed.emit() ## ?
