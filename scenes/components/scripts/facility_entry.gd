extends Button

var base: Models.Facility

var name_label: Label = Label.new()
var cost_label: Label = Label.new()
var output_label: Label = Label.new()
var percent_label: Label = Label.new()
var count_label: Label = Label.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	State.connect('facility_changed', _on_facility_changed)
	State.connect('bank_change', _on_bank_change)
	State.connect('buy_quant_change', _on_buy_quant_change)
	
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cost_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	output_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	percent_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	count_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	%GridContainer.add_child(name_label)
	%GridContainer.add_child(cost_label)
	%GridContainer.add_child(output_label)
	%GridContainer.add_child(percent_label)
	%GridContainer.add_child(count_label)
	
	update_text()

func _on_facility_changed(id: int):
	if id == base.id():
		update_text()
		update_dis()
		
func _on_bank_change():
	update_dis()


func _on_buy_quant_change():
	update_dis()
	
	
func _pressed() -> void:
	if State.bank_try_debit(State.get_total_cost(base.cost(), base.cost_ratio())):
		var new_output = base.output()
		var new_count = base.count() + State.buy_count()
		
		if State.buy_count() == 100:
			# Guaranteed to trigger exactly 9 10-multis and 1 100-multi
			new_output *= base.hnds_multi()
			new_output *= base.tens_multi() ** 9
		elif State.buy_count() == 10:
			# Triggers either a ten or hundreds multiplier
			if base.count() % 100 > new_count % 100:
				# Means a hundreds wrap occurred
				new_output *= base.hnds_multi()
			else:
				new_output *= base.tens_multi()
		elif State.buy_count() == 1:
			if new_count % 100 == 0:
				new_output *= base.hnds_multi()
			elif new_count % 10 == 0:
				new_output *= base.tens_multi()
		
		var new_cost = base.cost() * (base.cost_ratio() ** State.buy_count())
		
		State.facility_update_state(base.id(), new_count, new_output, new_cost)

func update_text() -> void:
	name_label.text = base.fname()
	cost_label.text = str("Cost: ", State.fnum(get_total_cost()))
	output_label.text = str("Output: ", State.fnum(base.output() * base.material_multi()))
	percent_label.text = str(State.fnum(base.percent()), "%")
	count_label.text = str("Count: ", base.count())

# Update disabled status
func update_dis() -> void:
	self.disabled = !State.bank_can_afford(get_total_cost())


func get_total_cost() -> float: 
	return State.get_total_cost(base.cost(), base.cost_ratio())
