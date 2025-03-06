extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var entry_scene = preload("res://scenes/components/recipe_entry.tscn")
	
	for rec in State.recipes():
		var node = entry_scene.instantiate()
		node.base = rec
		%RecipeContainer.add_child(node)
