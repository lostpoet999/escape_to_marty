@tool
class_name LevelPopupHint extends Node2D

## Reacts by showing or hiding itself when something enters the detection area.
## Tool node, essentially a configurable label with an area.

enum Watchable {
	PLACED_ENEMY = 0,
}

const DEBUG: bool = false
const TICK_SKIP: int = 10 ## Only run the area check once every X physics ticks.
var _ticks: int = 0

@export var persist_in_editor: bool = true ## Will show the children as nodes in the editor scene tree. This also persists the children to the scene file.
@export_category("Prefer changing settings here--do not modify children (if in scene tree)")
@export_tool_button("Refresh Editor Instance") var refresh_button: Callable = setup.bind(true)

## If false, hides when inside area.
@export var show_when_inside_area: bool = true
@export var fade_time: Vector2 = Vector2(1.0, 1.0) ## X: fade in, Y: fade out, in seconds.
@export var watch_class: Watchable ## The type of object to react to entering and exiting the area.

#@export_group("Label Settings")
@export_multiline("Text") var text: String = "Placeholder text!":
	set(v):
		text = v
		if _label:
			_label.text = text
			
@export var label_offset: Vector2 = Vector2.ZERO:
	set(v):
		label_offset = v
		if _label:
			_label.position = label_offset
			
@export var label_settings: LabelSettings = preload("uid://x1nhefjv38q7")

#@export_group("Area Settings")
@export var shape: Shape2D = RectangleShape2D.new()

var _label: Label
var _area: Area2D
var _collision_shape: CollisionShape2D

@onready var original_modulate: Color = Color.WHITE #self.modulate

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not Engine.is_editor_hint():
		hide()
	setup()
	
	visible = not show_when_inside_area
	

func p(args: Variant) -> void:
	if DEBUG:
		print_rich("[bgcolor=YELLOW][color=BLACK]Hint: ", args)


func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if not _area:
		return
		
	_ticks += 1
	if _ticks < TICK_SKIP:
		return
	_ticks = 0
	
	var bodies: Array[Node2D] = _area.get_overlapping_bodies()
	var found: bool = false
	for body: Node2D in bodies:
		p("overlapping %s" % body)
		if check(body):
			p("it's a match!")
			found = true
			break
	
	if show_when_inside_area:
		showing(found)
	else:
		showing(not found)


var fading_in: bool = false
var fading_out: bool = false
var tween: Tween
func showing(yes: bool) -> void:
	if not yes:
		if not visible:
			p("A")
			return
		if fading_out:
			p("B")
			return
	else:
		if visible and not fading_out:
			p("C")
			return
		if fading_in:
			p("D")
			return
			
	p("E")
		
	fading_in = false
	fading_out = false
	
	if tween:
		tween.kill()
	tween = create_tween()
	if not yes:
		fading_out = true
		tween.tween_property(self, ^"modulate", Color.TRANSPARENT, fade_time.y)
		tween.tween_callback(hide)
		tween.tween_property(self, ^"fading_out", false, 0.0)
	else:
		fading_in = true
		tween.tween_property(self, ^"modulate", original_modulate, fade_time.x)
		tween.parallel().tween_callback(show)
		tween.tween_property(self, ^"fading_in", false, 0.0)


func setup(and_clear: bool = false) -> void:
	## Delete old node components
	if and_clear:
		if _label:
			_label.free()
		_label = null
		if _area:
			_area.free()
		_area = null
		_collision_shape = null
	
	## Create and configure node components
	if not _label:
		_label = Label.new()
		add_child(_label, true)
		if persist_in_editor and Engine.is_editor_hint():
			_label.owner = get_tree().edited_scene_root
		
	if label_settings:
		_label.label_settings = label_settings
	_label.text = text if text else ""
	_label.position = label_offset
	
	if not _area:
		_area = Area2D.new()
		
		_area.monitorable = false
		_area.set_collision_layer_value(1, false)
		_area.input_pickable = false ## Requires one collision layer to use anyway
		
		add_child(_area, true)
		if persist_in_editor and Engine.is_editor_hint():
			_area.owner = get_tree().edited_scene_root
	
	if not _collision_shape:
		_collision_shape = CollisionShape2D.new()
		_collision_shape.shape = shape
		_area.add_child(_collision_shape, true)
		if persist_in_editor and Engine.is_editor_hint():
			_collision_shape.owner = get_tree().edited_scene_root
	
	## Connect signals
	#if not area.body_entered.is_connected(on_body_entered):
		#area.body_entered.connect(on_body_entered)
	#
	#if not area.body_exited.is_connected(on_body_exited):
		#area.body_exited.connect(on_body_exited)


func check(object: Node) -> bool:
	## uncomment if you add more types
	#match Watchable:
		#Watchable.PLACED_ENEMY:
			#foo
	return object is PlacedEnemy
	

#func on_body_entered(body: Node) -> void:
	#pass
	#
#func on_body_exited(body: Node) -> void:
	#pass
