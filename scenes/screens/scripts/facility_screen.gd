extends Control

var total_delta: float = 0
var last_update: float = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var entry_scene = preload("res://scenes/components/facility_entry.tscn")
	
	for facility in Globals.facilities:
		var node = entry_scene.instantiate()
		node.base = facility
		%FacilityContainer.add_child(node)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	total_delta += delta
	
	var dd = total_delta - last_update
	
	if dd >= .2:
		# Time to update again
		var outputs = Globals.facilities.map(func(f): return f.count * f.output * dd)
		var total = outputs.reduce(func(a,b): return a+b)

		for i in range(len(outputs)):
			Globals.facilities[i].percent = outputs[i] / total * 100 if total > 0 else 0
			Globals.register_facility_change(i)
			
		if total > 0:
			Globals.credit_bank(total)
	
		last_update = total_delta
