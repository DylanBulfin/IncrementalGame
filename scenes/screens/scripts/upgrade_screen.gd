extends Control

var total_delta: float = 0
var last_update: float = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var entry_scene = preload("res://scenes/components/upgrade_entry.tscn")
	
	for upgrade in State.upgrades():
		var node = entry_scene.instantiate()
		node.base = upgrade
		node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		%UpgradeContainer.add_child(node)
