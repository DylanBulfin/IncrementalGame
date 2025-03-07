extends ColorRect

var base: Models.InventoryItem
var curr_multi: float = 1.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Buttons have nice built-in styling but these should not behave as buttons
	State.connect("inventory_change", _on_inventory_change)
	update_text()

func _on_inventory_change() -> void:
	# Update multiplier
	if base.material() <= Models.CraftingMaterial.Diamond:
		# Int value of material matches facility id
		var new_multi
		if base.count() == 0:
			new_multi = 1
		else:
			new_multi = ((log(base.count()) / log(10)) + 1) ** 2
		State.facility_set_material_multiplier(base.material() as int, new_multi)
		curr_multi = new_multi
	
	update_text()
	
func update_text() -> void:
	%MaterialLabel.text = base.material_name()
	%CountLabel.text = str("Count: ", State.fnum(base.count()))
	%MultiLabel.text = str("Giving ", State.fnum(curr_multi), "x multiplier")
