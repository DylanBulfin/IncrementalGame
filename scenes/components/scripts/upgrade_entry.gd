extends Button

var base: Models.Upgrade

var name_label: Label = Label.new()
var cost_label: Label = Label.new()
var multi_label: Label = Label.new()
var level_label: Label = Label.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	State.connect('upgrade_changed', _on_upgrade_changed)
	State.connect('bank_change', _on_bank_change)
	
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cost_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	multi_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	level_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	%GridContainer.add_child(name_label)
	%GridContainer.add_child(cost_label)
	%GridContainer.add_child(multi_label)
	%GridContainer.add_child(level_label)
	
	update_text()
	update_vis()

func _on_upgrade_changed(id: int):
	if id == base.id():
		update_text()
		update_vis()
		
		if id <= Models.UpgradeType.Facility8 as int:
			# Single-building multiplier
			State.facility_set_upgrades_multiplier(id, base.multiplier() * base.count())
			
			

func _on_bank_change():
	update_vis()


func _pressed() -> void:
	if State.bank_try_debit(base.cost()):
		var new_level = base.level() + 1
		var new_cost = base.cost() * base.cost_ratio()
		
		State.upgrades_update_state(base.id(), new_level, new_cost)


func update_text() -> void:
	name_label.text = base.fname()
	cost_label.text = str("Cost: ", State.fnum(base.cost()))
	multi_label.text = str("Mult.: ", State.fnum(base.multiplier()))
	level_label.text = str("Lvl " + State.fnum(base.level()))


func update_vis() -> void:
	self.disabled = !State.bank_can_afford(self.base.cost())
