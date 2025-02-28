extends Node

var current_screen_index: int = 0
var last_screen_index: int = 0

var screen_nodes: Array#[Node]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	screen_nodes = [
		preload("res://scenes/screens/facility_screen.tscn"),
		preload("res://scenes/screens/dummy_screen.tscn"),
		preload("res://scenes/screens/dummy_screen.tscn"),
		preload("res://scenes/screens/dummy_screen.tscn"),
		preload("res://scenes/screens/dummy_screen.tscn"),
		preload("res://scenes/screens/dummy_screen.tscn"),
		preload("res://scenes/screens/dummy_screen.tscn"),
		preload("res://scenes/screens/dummy_screen.tscn"),
	].map(func(sc): return sc.instantiate())
	
	for node in screen_nodes:
		node.visible = false
		%ScreenContainer.add_child(node)
		
	screen_nodes[0].visible = true
	
	State.connect("screen_change", _on_screen_change)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _on_screen_change(index: int) -> void:
	if current_screen_index != index:
		screen_nodes[current_screen_index].visible = false
	
	screen_nodes[index].visible = true
	current_screen_index = index
