extends Button

var base: Models.Recipe
var material_nodes: Array[Label]

const px_per_line = 27

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	material_nodes.assign(base.material_costs().map(func(_mc): return Label.new()))
	
	for mn in material_nodes:
		%MaterialCostContainer.add_child(mn)
	
	var base_size = px_per_line * 3;
	var total_size = base_size + (px_per_line * len(base.material_costs()))
	
	self.custom_minimum_size.y = total_size
	self.size.y = 0
	
	update_text()

func _on_cspeed_change() -> void:
	update_text()

func update_text() -> void:
	%NameLabel.text = State.material_name(base.output())
	%BankCostLabel.text = str("Bank Cost: ", State.fnum(base.bank_cost()))
	
	var final_time = base.time_cost_s() / State.cspeed()
	
	if final_time > 0.25:
		%TimeLabel.text = str(State.fnum(base.time_cost_s() / State.cspeed()), " second(s)")
	else:
		%TimeLabel.text = str(State.fnum(1 / final_time), " / sec")
	
	var num_materials = len(base.material_costs())
	
	for i in range(num_materials):
		var mc = base.material_costs()[i]
		material_nodes[i].text = str(State.material_name(mc.material()), " Cost: ", State.fnum(mc.count()))
