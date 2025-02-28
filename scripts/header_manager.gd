extends Node

# I want each screen to have a header that formats the relevant
# information about that screen. This can be either locked to the
# current screen as default, or unlocked to change via buttons on
# screen. 

var current_header: int = 0
var labels: Array[Label] = [
	Label.new(),
	Label.new(),
	Label.new(),
	Label.new(),
	Label.new(),
	Label.new(),
	Label.new(),
	Label.new(),
]

var modules: Array#[Globals.HeaderModuleModel]
var signals: Array[String]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for label in labels:
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		%HeaderContainer.add_child(label)
	
	var curr_set = Globals.header_sets[current_header]
	
	for module in curr_set.modules:
		modules.append(module)
		for sig in module.signals:
			if not sig in signals:
				signals.append(sig)
	
	for sig in signals:
		Globals.connect(sig, _update_content)
	
	_update_content()
	

func _update_content() -> void:
	for i in len(modules):
		var mod = modules[i]
		var text = ""
		
		match mod._name:
			"bank":
				text = mod.template % Globals.fnum(Globals.bank())
				

		labels[i].text = text
