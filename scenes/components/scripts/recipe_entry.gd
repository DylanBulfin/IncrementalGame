extends Button

var base: Models.Recipe
var material_nodes: Array[Label]

const px_per_line = 27


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	material_nodes.assign(base.material_costs().map(func(_mc): return Label.new()))

	for mn in material_nodes:
		%CostContainer.add_child(mn)

	var base_size = px_per_line * 4
	var total_size = base_size + (px_per_line * len(base.material_costs()))

	self.custom_minimum_size.y = total_size
	self.size.y = 0

	State.connect("cspeed_change", _on_cspeed_change)
	State.connect("inventory_change", _on_inventory_change)
	State.connect("bank_change", _on_bank_change)

	update_text()


func _on_cspeed_change() -> void:
	update_text()


func _on_inventory_change() -> void:
	update_text()
	update_vis()


func _on_bank_change() -> void:
	self.disabled = !can_afford()


func _pressed() -> void:
	State.manufacturing_activate_recipe(base)


func can_afford() -> bool:
	return (
		State.manufacturing_can_afford_materials(base.material_costs())
		and State.bank_can_afford(base.bank_cost())
	)


func update_text() -> void:
	%NameLabel.text = State.material_name(base.output())
	%BankCostLabel.text = str("Bank Cost: ", State.fnum(base.bank_cost()))
	%CountLabel.text = str("Curr Count: ", State.fnum(State.material_count(base.output())))

	var final_time = base.time_cost_s() / State.cspeed()

	if final_time > State.fast_craft_cutoff_s:
		%TimeLabel.text = str(State.fnum(base.time_cost_s() / State.cspeed()), " second(s)")
	else:
		%TimeLabel.text = str(State.fnum(1 / final_time), " rec / sec")

	var num_materials = len(base.material_costs())

	for i in range(num_materials):
		var mc = base.material_costs()[i]
		material_nodes[i].text = str(
			State.material_name(mc.material()), " Cost: ", State.fnum(mc.count())
		)


func update_vis() -> void:
	self.disabled = !can_afford()
