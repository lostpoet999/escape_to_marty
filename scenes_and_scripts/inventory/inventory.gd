class_name PlayerInventory extends Node

## A script to do amazing things, and maybe more ...

const DEBUG: bool = true

var items: Array[BaseItem] ## Powerups, passives or actives for ball, paddle, or click. One active passive for each type.

const TESTING: Array = [
	## Add testing inventory items here that will be added in _ready
	preload("uid://ctjeqnpuca6lq")
]

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
	if not TESTING.is_empty():
		items.append_array(TESTING)

func get_items() -> Array:
	return items

## Load power-ups from inventory for appropriate object
func get_items_for_ball() -> Array[BallPowerUp]:	
	var _items: Array[BallPowerUp] = []
	for item:BaseItem in items:
		if item is BallPowerUp:
			_items.append(item)	
	return _items

func get_paddle_active() -> PaddleActive:	#inventory logic prevents more than one, so returning on first one should be good
	for item:BaseItem in items:
		if item is PaddleActive:
			return item
	return null

#func get_items_for_paddle() -> Array[PaddlePowerUp]:
	#var _items: Array[BallPowerUp]
	#for item in items:
		#if item is BallPowerUp:
			#_items.append(item)
	#return _items

#func get_items_for_click() -> Array[ClickPowerUp]:
	#var _items: Array[BallPowerUp]
	#for item in items:
		#if item is BallPowerUp:
			#_items.append(item)
	#return _items

func add_item(item) -> void:
	print("item: ", item.get_script().get_global_name())
	if item is PaddleActive:
			if item in items:
				print("you already have one!") #TODO: ask user to swap
			else:
				items.push_front(item)
				Signalbus.paddle_active_picked_up.emit(item) #pass the new paddle active to paddle
	elif item is BallPowerUp:
			print("entered ballpower up match")
			if item in items:
				print("you already have this one, lets stack them!") #TODO: make it so inventory panel increases quantity in visual vs takeup another spot
			else:
				print("cool, new powah")
			items.push_back(item) #this will move when we do quantity update from above
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
