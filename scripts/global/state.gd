extends Node

# Signals
signal screen_change(id: int)
signal new_popup(title: String, text: String)

signal bank_change
signal facility_changed(id: int)
signal cspeed_change
signal coutput_change
signal upgrade_changed(id: int)
signal inventory_change  # May want to add id arg later?
signal recipe_change(recipe: Models.Recipe)

# Globally-relevant variables
var update_interval_s: float = 0.2
var fast_craft_cutoff_s: float = 0.25
var default_save_name: String = "savegame.save"

var _curr_screen: int = 0

var _buy_quant: Models.BuyQuant = Models.BuyQuant.OneX

var _bank: float = 1.0
var _cspeed: float = 1.0  # Crafting/manufacturing speed
var _coutput: float = 1.0  # Crafting/manufacturing output multi

var _header_sets: Array  #[HeaderSetModel]
var _screens: Array[String] = preload("res://resources/side_menu_items.tres").items
var _facilities: Array[Models.Facility]

var _upgrades: Dictionary  #[Models.UpgradeCategory, Array[Models.Upgrade]]
var _all_upgrades: Array[Models.Upgrade]

var _inventory: Array[Models.InventoryItem]
var _inventory_map: Dictionary  #[Models.CraftingMaterial, Models.InventoryItem]
var _recipes: Array  #[Models.Recipe]


#region Getters
func bank() -> float:
	return _bank


func cspeed() -> float:
	return _cspeed


func coutput() -> float:
	return _coutput


func header_set(id: int) -> Models.HeaderSet:
	return _header_sets[id]


func curr_screen_title() -> String:
	return _screens[_curr_screen]


func buy_quant() -> Models.BuyQuant:
	return _buy_quant


func screens() -> Array[String]:
	return _screens


func facilities() -> Array[Models.Facility]:
	return _facilities


func upgrade_categories() -> Array:
	return Models.UpgradeCategory.keys()


func upgrades_by_category(category: Models.UpgradeCategory) -> Array:
	return _upgrades[category]


func inventory() -> Array:
	return _inventory


func material_name(cm: Models.CraftingMaterial) -> String:
	return _inventory_map[cm].material_name()


func material_count(cm: Models.CraftingMaterial) -> float:
	return _inventory_map[cm].count()


func recipes() -> Array:
	return _recipes


#endregion


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_ready_facility()
	_ready_header()
	_ready_upgrades()
	_ready_manufacturing()
	
	if FileAccess.file_exists(get_user_path()):
		load_game()
	
	# Don't use default quit behavior, override it so I can save on exit
	get_tree().set_auto_accept_quit(false)

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		# Desktop/web 
		save_game()
		get_tree().quit()
	elif what == NOTIFICATION_APPLICATION_PAUSED:
		save_game()

# Most global state functions below, mostly separated by category


func change_screen(index: int) -> void:
	_curr_screen = index

	screen_change.emit(index)


func create_popup(title: String, text: String) -> void:
	new_popup.emit(title, text)


func increment_buy_quant() -> void:
	match _buy_quant:
		Models.BuyQuant.OneX: _buy_quant = Models.BuyQuant.TenX
		Models.BuyQuant.TenX: _buy_quant = Models.BuyQuant.HundX
		Models.BuyQuant.HundX: _buy_quant = Models.BuyQuant.OneX


func buy_count() -> int:
	match State.buy_quant():
		Models.BuyQuant.OneX: return 1
		Models.BuyQuant.TenX: return 10
		Models.BuyQuant.HundX: return 100
		_: return 1

func get_total_cost(cost_1: float, cost_ratio: float) -> float:
	return cost_1 * ((cost_ratio ** buy_count()) - 1) / (cost_ratio - 1)


#region Header
func _ready_header():
	var mods: Array = preload("res://resources/headers/header_modules.tres").items.map(
		func(m): return Models.HeaderModule.new(m.name, m.template, m.signals)
	)
	var header_modules: Dictionary

	for mod in mods:
		header_modules[mod._fname] = mod

	var sets: Array = preload("res://resources/headers/header_sets.tres").items.map(
		func(s):
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
		_facilities.append(
			Models.Facility.new(
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


func facility_set_material_multiplier(id: int, multi: float) -> void:
	_facilities[id]._material_multi = multi


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
	match type:
		Models.UpgradeType.Facility1, Models.UpgradeType.Facility2, Models.UpgradeType.Facility3, Models.UpgradeType.Facility4, Models.UpgradeType.Facility5, Models.UpgradeType.Facility6, Models.UpgradeType.Facility7, Models.UpgradeType.Facility8, Models.UpgradeType.AllFacilitiesOutput, Models.UpgradeType.AllFacilitiesCost:
			return Models.UpgradeCategory.Facility

		Models.UpgradeType.CSpeed, Models.UpgradeType.COutput:
			return Models.UpgradeCategory.Crafting

	push_error()
	return Models.UpgradeCategory.Facility


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
func _ready_manufacturing() -> void:
	# Having both allows easier handling of diverse use cases
	_inventory = []
	_inventory_map = {}
	# Loops through variant names of this enum
	for cn in Models.CraftingMaterial.keys():
		var cm = Models.CraftingMaterial[cn]
		var ii = Models.InventoryItem.new(cm as Models.CraftingMaterial, cn, 0)
		_inventory.push_back(ii)
		_inventory_map[cm as Models.CraftingMaterial] = ii

	# Parse recipes as well
	for rec in preload("res://resources/manufacturing/recipes.tres").items:
		_recipes.push_back(
			Models.Recipe.new(
				rec.bank_cost,
				rec.material_costs.map(
					func(mc): return Models.MaterialCost.new(mc.material, mc.count)
				),
				rec.time_cost_s,
				rec.output,
			)
		)


func manufacturing_can_afford_materials(materials: Array, n_times: float = 1) -> bool:
	return (
		materials
		. map(func(m): return _inventory_map[m.material()].count() >= m.count() * n_times)
		. reduce(func(a, m): return a and m, true)
	)


func manufacturing_try_debit(materials: Array, bank_cost: float, n_times: float = 1) -> bool:
	if (
		manufacturing_can_afford_materials(materials, n_times)
		and bank_try_debit(bank_cost * n_times)
	):
		for mc in materials:
			_inventory_map[mc.material()]._count -= mc.count() * n_times
		inventory_change.emit()
		return true
	else:
		return false


func manufacturing_credit_materials(material: Models.CraftingMaterial, count: float) -> void:
	_inventory_map[material]._count += count
	inventory_change.emit()


func manufacturing_multiply_speed(factor: float) -> void:
	_cspeed *= factor
	cspeed_change.emit()


func manufacturing_multiply_output(factor: float) -> void:
	_coutput *= factor
	coutput_change.emit()


func manufacturing_activate_recipe(recipe: Models.Recipe) -> void:
	recipe_change.emit(recipe)


#endregion


#region Utils
# Format number in scientific notation if large enough
func fnum(n: float) -> String:
	const fstr = "%.2f"
	if is_inf(n) or is_nan(n):
		return str(n)
	elif abs(n) < 1_000:
		if float(int(n)) == n:
			return str(n as int)
		else:
			return str(fstr % n)
	else:
		var power: float = floor(log(abs(n)) / log(10))
		var dec: float = n / (10 ** power)
		
		var dec_fstr = fstr % dec

		# Floating-point math is inherently inexact so this checks
		# for errors
		if dec_fstr[0] == '0':
			# Indicates dec is 0.99999999 or something
			power -= 1
			dec *= 10
		if len(dec_fstr) == 5:
			# This indicates dec is 10.00 
			power += 1
			dec /= 10
		
		# Reassign since dec may have changed
		dec_fstr = fstr % dec
		
		# Gets part of string after decimal
		if dec_fstr.substr(2) == "00":
			# Looks better to show as int
			return str(dec_fstr[0], "e", power as int)
		else:
			return str(dec_fstr, "e", power as int)

func get_user_path(path: String = default_save_name) -> String:
	return str("user://", path)

func save_game(path: String = get_user_path()):
	var save_dict := {
		"bank": _bank,
		"cspeed": _cspeed,
		"coutput": _coutput,
		
		"facilities": _facilities.map(func(e): return e.to_dict()),
		"inventory": _inventory.map(func(e): return e.to_dict()),
		"upgrades": _all_upgrades.map(func(e): return e.to_dict())
	}
	
	var save_file = FileAccess.open(path, FileAccess.WRITE)

	# JSON provides a static method to serialized JSON string.
	var json_string = JSON.stringify(save_dict)

	# Store the save dictionary as a new line in the save file.
	save_file.store_line(json_string)
	save_file.flush()

func load_game(path: String = get_user_path()):
	var save_file = FileAccess.open(path, FileAccess.READ)
	
	var save_dict: Dictionary = JSON.parse_string(save_file.get_line())
	
	if save_dict.has("bank"): _bank = save_dict["bank"]
	if save_dict.has("cspeed"): _cspeed = save_dict["cspeed"]
	if save_dict.has("coutput"): _coutput = save_dict["coutput"]

	if save_dict.has("facilities"):
		var dicts: Array = save_dict["facilities"]
		
		if len(dicts) == len(_facilities):
			for i in range(len(dicts)):
				_facilities[i].update_from_dict(dicts[i])

	if save_dict.has("inventory"):
		var dicts: Array = save_dict["inventory"]
		
		if len(dicts) == len(_inventory):
			for i in range(len(dicts)):
				_inventory[i].update_from_dict(dicts[i])

	if save_dict.has("upgrades"):
		var dicts: Array = save_dict["upgrades"]
		
		if len(dicts) == len(_all_upgrades):
			for i in range(len(dicts)):
				_all_upgrades[i].update_from_dict(dicts[i])

# Returns true if file existed
func reset_save(path: String = get_user_path()) -> bool:
	return DirAccess.remove_absolute(path) == OK

#endregion
