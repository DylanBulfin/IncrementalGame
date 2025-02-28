extends Node

# Signals
signal bank_change
signal facility_changed(id: int)
signal cspeed_change

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
var _bank: float = 1

func bank() -> float: return _bank

# Attempt to subtract given amount from bank, returning true
# if successful
func try_debit_bank(amount: float) -> bool:
	if _bank >= amount:
		_bank -= amount
		bank_change.emit()
		return true
	else:
		return false

func credit_bank(amount: float) -> void:
	_bank += amount
	bank_change.emit()
#endregion

#region Facilities
class FacilityModel:
	var _id: int
	var _name: String
	var _cost: float
	var _output: float
	var _cost_ratio: float
	var _count: int
	var _tens_multi: float
	var _hnds_multi: float
	
	var _percent: float = 0

	func _init(id: int, fname: String, cost: float, output: float, cost_ratio: float, tens_multi: float, hnds_multi: float, count: int = 0):
		self._id = id
		self._name = fname
		self._cost = cost
		self._output = output
		self._cost_ratio = cost_ratio
		self._count = count
		self._tens_multi = tens_multi
		self._hnds_multi = hnds_multi
	
	func id() -> int: return self._id
	func fname() -> String: return self._name
	func cost() -> float: return self._cost
	func output() -> float: return self._output
	func cost_ratio() -> float: return self._cost_ratio
	func count() -> int: return self._count
	func tens_multi() -> float: return self._tens_multi
	func hnds_multi() -> float: return self._hnds_multi
	func percent() -> float: return self._percent

var facilities: Array[FacilityModel]

func update_facility_state(id: int, count: int, output: float, cost: float) -> void:
	facilities[id]._count = count
	facilities[id]._output = output
	facilities[id]._cost = cost
	facility_changed.emit(id)
	
func update_facility_percent(id: int, percent: float) -> void:
	facilities[id]._percent = percent
	facility_changed.emit(id)
#endregion

#region Manufacturing
var cspeed: float = 1.0

func multiply_cspeed(factor: float) -> void:
	cspeed *= factor
	cspeed_change.emit()
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
