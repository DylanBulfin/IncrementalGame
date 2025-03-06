extends Button

var base: Models.InventoryItem

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Buttons have nice built-in styling but these should not behave as buttons
	self.disabled = true
	State.connect("inventory_change", _on_inventory_change)
	update_text()

func _on_inventory_change() -> void:
	update_text()
	
func update_text() -> void:
	%MaterialLabel.text = base.material_name()
	%CountLabel.text = str("Count: ", base.count())
