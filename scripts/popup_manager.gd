extends Node

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	State.connect("new_popup", _on_new_popup)
	%SideMenu.visible = false

func _on_side_menu_button_pressed() -> void:
	%SideMenu.visible = true
	%MainContent.visible = false


func _on_side_menu_item_selected(index: int) -> void:
	%SideMenu.visible = false
	%MainContent.visible = true
	
	State.change_screen(index)

func _on_new_popup(title: String, text: String) -> void:
	%PopupTitle.text = title
	%PopupContent.text = text
	%MainContent.visible = false
	%PopupContainer.visible = true

func _on_help_button_pressed() -> void:
	State.create_popup("Testing", "Testing2")

func _on_popup_exit_button_pressed() -> void:
	%PopupContainer.visible = false
	%MainContent.visible = true
