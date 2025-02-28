extends Node

# Holds the type definitions used elsewhere in the project

#region Headers
class HeaderModule:
	var _fname: String
	var _template: String
	var _signals: Array#[String]
	
	func _init(_fname_: String, _template_: String, _signals_: Array):
		self._fname = _fname_
		self._template = _template_
		self._signals = _signals_
	
	func fname() -> String: return self._fname
	func template() -> String: return self._template
	func signals() -> Array: return self._signals
		
class HeaderSet:
	var _fname: String
	var _modules: Array#[HeaderModule]
	
	func _init(_fname_: String, _modules_: Array):
		self._fname = _fname_
		self._modules = _modules_
	
	func fname() -> String: return self._fname
	func modules() -> Array: return self._modules
#endregion

#region Facilities
class Facility:
	var _id: int
	var _fname: String
	var _cost: float
	var _output: float
	var _cost_ratio: float
	var _count: int
	var _tens_multi: float
	var _hnds_multi: float
	
	var _percent: float = 0

	func _init(_id_: int, _fname_: String, _cost_: float, _output_: float, _cost_ratio_: float, _tens_multi_: float, _hnds_multi_: float, _count_: int = 0):
		self._id = _id_
		self._fname = _fname_
		self._cost = _cost_
		self._output = _output_
		self._cost_ratio = _cost_ratio_
		self._count = _count_
		self._tens_multi = _tens_multi_
		self._hnds_multi = _hnds_multi_
	
	func id() -> int: return self._id
	func fname() -> String: return self._fname
	func cost() -> float: return self._cost
	func output() -> float: return self._output
	func cost_ratio() -> float: return self._cost_ratio
	func count() -> int: return self._count
	func tens_multi() -> float: return self._tens_multi
	func hnds_multi() -> float: return self._hnds_multi
	func percent() -> float: return self._percent
#endregion

#region Upgrades
enum UpgradeType {
	# Manually define them so the int value corresponds to the index
	# in the facilities array. This allows us to avoid handling each
	# facility upgrade individually.
	Facility1 = 0,
	Facility2 = 1,
	Facility3 = 2,
	Facility4 = 3,
	Facility5 = 4,
	Facility6 = 5,
	Facility7 = 6,
	Facility8 = 7,
	
	AllFacilitiesOutput,
	AllFacilitiesCost,
	
	CSpeed,
	COutput,
}

class Upgrade:
	var _id: int
	var _fname: String
	var _cost: float
	var _type: UpgradeType
	var _multiplier: float
	var _cost_ratio: float
	var _level: int

	func _init(_id_: int, _fname_: String, _cost_: float, _type_: UpgradeType, _multiplier_: float, _cost_ratio_: float, _level_: int = 0):
		self._id = _id_
		self._fname = _fname_
		self._cost = _cost_
		self._type = _type_
		self._multiplier = _multiplier_
		self._cost_ratio = _cost_ratio_
		self._level = _level_
	
	func id() -> int: return self._id
	func fname() -> String: return self._fname
	func cost() -> float: return self._cost
	func type() -> UpgradeType: return self._type
	func multiplier() -> float: return self._multiplier
	func cost_ratio() -> float: return self._cost_ratio
	func level() -> int: return self._level
#endregion
