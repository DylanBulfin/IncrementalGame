extends ItemList

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for screen in Globals.screens:
		self.add_item(screen)
