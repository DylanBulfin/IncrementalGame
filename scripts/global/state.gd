extends Node

# Signals
signal screen_change(id: int)

signal bank_change
signal facility_changed(id: int)
signal cspeed_change
signal upgrade_changed(id: int)

# Globally-relevant variables
var update_interval_s: float = 0.2

var _bank: float = 1.0e12
var _cspeed: float = 1.0 # Crafting/manufacturing speed

var _header_sets: Array#[HeaderSetModel]
var _screens: Array[String] = preload("res://resources/side_menu_items.tres").items
var _facilities: Array[Models.Facility]

var _upgrade_categories: Array[Models.UpgradeCategory]
var _upgrades: Dictionary#[Models.UpgradeCategory, Array[Models.Upgrade]]
var _all_upgrades: Array[Models.Upgrade]

#region Getters
func bank() -> float: return _bank
func cspeed() -> float: return _cspeed
func header_set(id: int) -> Models.HeaderSet: return _header_sets[id]
func screens() -> Array[String]: return _screens
func facilities() -> Array[Models.Facility]: return _facilities
func upgrade_categories() -> Array: return _upgrades.keys()
func upgrades_by_category(category: Models.UpgradeCategory) -> Array: return _upgrades[category]
#endregion

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_ready_facility()
	_ready_header()
	_ready_upgrades()

# Most global state functions below, mostly separated by category

func change_screen(index: int) -> void:
	screen_change.emit(index)

#region Header
func _ready_header():
	var mods: Array = preload("res://resources/headers/header_modules.tres").items.map(func(m): 
		return Models.HeaderModule.new(m.name, m.template, m.signals)
	)
	var header_modules: Dictionary
	
	for mod in mods:
		header_modules[mod._fname] = mod
		
	var sets: Array = preload("res://resources/headers/header_sets.tres").items.map(func(s):
		return Models.HeaderSet.new(s.name, s.modules.map(func(n): return header_modules[n]))
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
	var facility_resources = preload("res://resources/facilities/facilities.tres").items
	
	# Translate facility resources to live model
	for i in range(len(facility_resources)):
		var resource = facility_resources[i]
		_facilities.append(Models.Facility.new(
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
	
func facility_apply_multiplier(id: int, multi: float) -> void:
	_facilities[id]._output *= multi
	facility_changed.emit(id)
	
#endregion

#region Upgrades
func _ready_upgrades() -> void:
	var upgrade_resources = preload("res://resources/upgrades/upgrades.tres").items
	
	for category in Models.UpgradeCategory.values():
		_upgrades[category] = []
	
	for i in range(len(upgrade_resources)):
		var resource = upgrade_resources[i]
		var category = upgrades_type_to_category(resource.type)
		
		var new_obj = Models.Upgrade.new(
			i, 
			resource.name,
			resource.cost, 
			resource.type,
			resource.multiplier,
			resource.cost_ratio,
			resource.level
		)
		_upgrades[category].append(new_obj)
		_all_upgrades.append(new_obj)

func upgrades_type_to_category(type: Models.UpgradeType) -> Models.UpgradeCategory:
	if type as int <= Models.UpgradeType.AllFacilitiesCost as int:
		return Models.UpgradeCategory.Facility
	else:
		return Models.UpgradeCategory.Crafting

func upgrades_update_state(id: int, level: int, cost: float) -> void:
	var upgrade = _all_upgrades[id]
	var new_levels = level - upgrade._level

	upgrade._level = level
	upgrade._cost = cost
	upgrade_changed.emit(id)
	
	# Actually apply upgrade
	var total_multi = upgrade._multiplier ** new_levels
	
	if upgrade._type as int <= Models.UpgradeType.Facility8 as int:
		facility_apply_multiplier(upgrade._type as int, total_multi)
	else:
		match upgrade._type:
			Models.UpgradeType.CSpeed:
				_cspeed *= total_multi
				cspeed_change.emit()
	
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
