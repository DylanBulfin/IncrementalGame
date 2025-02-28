extends Resource
class_name HeaderModuleResource

@export var name: String
@export var template: String = "%s"
# Global signal names that should cause an update
@export var signals: Array[String] = []
