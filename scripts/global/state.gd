extends Node

# Signals
signal bank_change
signal facility_changed(id: int)
signal cspeed_change

# Globally-relevant variables
var update_interval_s: float = 0.2

var _bank: float = 1.0
var _cspeed: float = 1.0 # Crafting/manufacturing speed

var _header_sets: Array#[HeaderSetModel]
var _screens: Array[String] = preload("res://resources/side_menu_items.tres").items
var _facilities: Array[Models.FacilityModel]

#region Getters
func bank() -> float: return _bank
func cspeed() -> float: return _cspeed
func header_set(id: int) -> Models.HeaderSetModel: return _header_sets[id]
func screens() -> Array[String]: return _screens
func facilities() -> Array[Models.FacilityModel]: return _facilities
#endregion

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_ready_facility()
	_ready_header()

# Most global state functions below, separated by category

#region Header
func _ready_header():
	var mods: Array = preload("res://resources/header_modules.tres").items.map(func(m): 
		return Models.HeaderModuleModel.new(m.name, m.template, m.signals)
	)
	var header_modules: Dictionary
	
	for mod in mods:
		header_modules[mod._fname] = mod
		
	var sets: Array = preload("res://resources/header_sets.tres").items.map(func(s):
		return Models.HeaderSetModel.new(s.name, s.modules.map(func(n): return header_modules[n]))
	)
	
	_header_sets = sets
#endregion
	
#region Bank
# Attempt to subtract given amount from bank, returning true
# if successful
func bank_try_debit(amount: float) -> bool:
	if bank_can_afford(amount):
		_bank -= amount
		bank_change.emit()
		return true
	else:
		return false

func bank_can_afford(amount: float) -> bool: 
	return _bank >= amount

func bank_credit(amount: float) -> void:
	_bank += amount
	bank_change.emit()
#endregion

#region Facilities
func _ready_facility() -> void:
	var facility_resources = preload("res://resources/facilities.tres").items
	
	# Translate facility resources to live model
	for i in range(len(facility_resources)):
		var resource = facility_resources[i]
		_facilities.append(Models.FacilityModel.new(
			i, 
			resource.name, 
			resource.base_cost, 
			resource.base_output, 
			resource.cost_ratio, 
			resource.tens_multiplier, 
			resource.hundreds_multiplier
			)
		)

func facility_update_state(id: int, count: int, output: float, cost: float) -> void:
	_facilities[id]._count = count
	_facilities[id]._output = output
	_facilities[id]._cost = cost
	facility_changed.emit(id)
	
func facility_update_percent(id: int, percent: float) -> void:
	_facilities[id]._percent = percent
	facility_changed.emit(id)
#endregion

#region Manufacturing
func manufacturing_multiply_speed(factor: float) -> void:
	_cspeed *= factor
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
