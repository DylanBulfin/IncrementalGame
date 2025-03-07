extends Control

var total_delta: float = 0
var last_update: float = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var entry_scene = preload("res://scenes/components/facility_entry.tscn")
	
	for facility in State.facilities():
		var node = entry_scene.instantiate()
		node.base = facility
		%FacilityContainer.add_child(node)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	total_delta += delta
	
	# deltaDelta
	var dd = total_delta - last_update
	
	# It looks awful if you update every frame
	if dd >= State.update_interval_s:
		var outputs = State.facilities().map(func(f): return f.material_multi() * f.count() * f.output() * dd)
		var total = outputs.reduce(func(a,b): return a+b)

		for i in range(len(outputs)):
			State.facility_update_percent(i, outputs[i] / total * 100 if total > 0 else 0)

		if total > 0:
			State.bank_credit(total)
	
		last_update = total_delta
