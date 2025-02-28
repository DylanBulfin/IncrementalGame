extends Button

var base: Globals.FacilityModel

var name_label: Label = Label.new()
var cost_label: Label = Label.new()
var output_label: Label = Label.new()
var percent_label: Label = Label.new()
var count_label: Label = Label.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Globals.connect('facility_changed', _on_facility_changed)
	
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
	
func _pressed() -> void:
	if Globals.try_debit_bank(base.cost()):
		var new_output = base.output()
		var new_count = base.count() + 1
		
		if new_count % 100 == 0:
			new_output *= base.hnds_multi()
		elif new_count % 10 == 0:
			new_output *= base.tens_multi()
		
		var new_cost = base.cost() * base.cost_ratio()
		
		Globals.update_facility_state(base.id(), new_count, new_output, new_cost)

func update_text() -> void:
	name_label.text = base.fname()
	cost_label.text = str("Cost: ", Globals.fnum(base.cost()))
	output_label.text = str("Output: ", Globals.fnum(base.output()))
	percent_label.text = str(Globals.fnum(base.percent()), "%")
	count_label.text = str("Count: ", base.count())
