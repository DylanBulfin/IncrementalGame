extends Control

var total_delta: float = 0
var last_update: float = 0

var categories: Array = State.upgrade_categories()
var curr_category_name: String = State.upgrade_categories()[0]

var group: ButtonGroup = ButtonGroup.new()

var upgrade_nodes: Dictionary = {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	group.connect("pressed", _on_pressed)
	
	var entry_scene = preload("res://scenes/components/upgrade_entry.tscn")
	
	for category_name in State.upgrade_categories():
		# Create and register button for this category
		var button = Button.new()
		button.text = category_name
		button.toggle_mode = true
		button.button_group = group
		
		%CategoryButtonsContainer.add_child(button)
		
		var cat_upgrade_nodes: Array = []

		var category = Models.UpgradeCategory[category_name]		
		for upgrade in State.upgrades_by_category(category):
			var node = entry_scene.instantiate()
			node.base = upgrade
			node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			
			cat_upgrade_nodes.append(node)
		
		upgrade_nodes[category_name] = cat_upgrade_nodes
		
	# Initialize the UpgradeContainer
	for node in upgrade_nodes[curr_category_name]:
		%UpgradeContainer.add_child(node)

func _on_pressed(button: BaseButton) -> void:
	var category = button.text
	
	for child in %UpgradeContainer.get_children():
		%UpgradeContainer.remove_child(child)
	for node in upgrade_nodes[category]:
		%UpgradeContainer.add_child(node)
