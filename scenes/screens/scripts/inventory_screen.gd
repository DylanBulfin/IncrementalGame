extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var entry_scene = preload("res://scenes/components/inventory_entry.tscn")
	
	for item in State.inventory():
		var node = entry_scene.instantiate()
		node.base = item
		%InventoryContainer.add_child(node)
