extends Node

# Signals
signal bank_change
signal facility_changed(id: int)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var facility_resources = preload("res://resources/facilities.tres").items
	
	# To get index
	for i in range(len(facility_resources)):
		var resource = facility_resources[i]
		facilities.append(FacilityModel.new(
			i, 
			resource.name, 
			resource.base_cost, 
			resource.base_output, 
			resource.cost_ratio, 
			resource.tens_multiplier, 
			resource.hundreds_multiplier
			)
		)
	_ready_header()

#region UI
var screens: Array[String] = preload("res://resources/side_menu_items.tres").items

#region Header
class HeaderModuleModel:
	var _name: String
	var template: String
	var signals: Array#[String]
	
	func _init(name_: String, template_: String, signals_: Array):
		self._name = name_
		self.template = template_
		self.signals = signals_
		
class HeaderSetModel:
	var _name: String
	var modules: Array#[HeaderModuleModel]
	
	func _init(name_: String, modules_: Array):
		self._name = name_
		self.modules = modules_

var header_sets: Array#[HeaderSetModel]

func _ready_header():
	var mods: Array = preload("res://resources/header_modules.tres").items.map(func(m): 
		return HeaderModuleModel.new(m.name, m.template, m.signals)
	) as Array[HeaderModuleModel]
	var header_modules: Dictionary
	
	for mod in mods:
		header_modules[mod._name] = mod
		
	var sets: Array = preload("res://resources/header_sets.tres").items.map(func(s):
		return HeaderSetModel.new(s.name, s.modules.map(func(n): return header_modules[n]))
	)
	
	header_sets = sets
	
#endregion
#endregion
	
#region Bank
var bank: float = 1

# Attempt to subtract given amount from bank, returning true
# if successful
func try_debit_bank(amount: float) -> bool:
	if bank >= amount:
		bank -= amount
		bank_change.emit()
		return true
	else:
		return false

func credit_bank(amount: float) -> void:
	bank += amount
	bank_change.emit()
#endregion

#region Facilities
class FacilityModel:
	var id: int
	var _name: String
	var cost: float
	var output: float
	var cost_ratio: float
	var count: int
	var tens_multi: float
	var hnds_multi: float
	
	# Percent of total output this building makes up
	var percent: float = 0
	
	func _init(id_: int, name_: String, cost_: float, output_: float, cost_ratio_: float, tens_multi_: float, hnds_multi_: float, count_: int = 0):
		self.id = id_
		self._name = name_
		self.cost = cost_
		self.output = output_
		self.cost_ratio = cost_ratio_
		self.count = count_
		self.tens_multi = tens_multi_
		self.hnds_multi = hnds_multi_

func register_facility_change(id: int) -> void:
	facility_changed.emit(id)

var facilities: Array[FacilityModel]
#endregion

#region Utils
# Format number in scientific notation if large enough
func fnum(n: float) -> String:
	const fstr = "%.2f"
	if is_inf(n) or is_nan(n):
		return str(n)
	elif abs(n) < 1_000:
		if float(int(n)) == n:
			return str(n)
		else:
			return str(fstr % n)
	else:
		var power = floor(log(abs(n)) / log(10))
		var dec = n / (10 ** power)
		
		# Floating-point math is inherently inexact so this checks
		# for errors
		if dec < 1:
			power -= 1
			dec *= 10
		if dec >= 10:
			power += 1
			dec /= 10
		
		if float(int(dec)) == dec:
			return str(dec, "e", power)
		else:
			return str(fstr % dec, "e", power)
#endregion
