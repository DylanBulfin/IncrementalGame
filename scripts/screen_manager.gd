extends Node

var current_screen_index: int = 0
var last_screen_index: int = 0

var screen_nodes: Array#[Node]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	screen_nodes = [
		preload("res://scenes/screens/facility_screen.tscn"),
		preload("res://scenes/screens/upgrade_screen.tscn"),
		preload("res://scenes/screens/inventory_screen.tscn"),
		preload("res://scenes/screens/crafting_screen.tscn"),
		preload("res://scenes/screens/dummy_screen.tscn"),
		preload("res://scenes/screens/dummy_screen.tscn"),
		preload("res://scenes/screens/dummy_screen.tscn"),
		preload("res://scenes/screens/dummy_screen.tscn"),
		preload("res://scenes/screens/dummy_screen.tscn"),
		preload("res://scenes/screens/settings_screen.tscn"),
	].map(func(sc): return sc.instantiate())
	
	for node in screen_nodes:
		node.visible = false
		%ScreenContainer.add_child(node)
		
	screen_nodes[0].visible = true
	
	State.connect("screen_change", _on_screen_change)

func _on_screen_change(index: int) -> void:
	if current_screen_index != index:
		screen_nodes[current_screen_index].visible = false
	
	screen_nodes[index].visible = true
	current_screen_index = index

func _process(_delta: float) -> void:
	check_action("screen1", func(): State.change_screen(0))
	check_action("screen2", func(): State.change_screen(1))
	check_action("screen3", func(): State.change_screen(2))
	check_action("screen4", func(): State.change_screen(3))
	
	check_action("screen10", func(): State.change_screen(9))

# If action is pressed, call the callback and unpress it
func check_action(action: String, callback: Callable):
	if Input.is_action_pressed(action):
		callback.call()
		
		# Unpress button
		var ev = InputEventAction.new()
		ev.action = action
		ev.pressed = false
		# Feedback.
		Input.parse_input_event(ev)
