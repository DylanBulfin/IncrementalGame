extends Node

var side_menu_visible = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	%SideMenu.visible = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _on_side_menu_button_pressed() -> void:
	side_menu_visible = not side_menu_visible
	%SideMenu.visible = side_menu_visible
	%MainContent.visible = not side_menu_visible


func _on_side_menu_item_selected(index: int) -> void:
	%SideMenu.visible = false
	%MainContent.visible = true
	side_menu_visible = false
	
	State.change_screen(index)
