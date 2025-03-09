extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	State.connect("new_popup", _on_new_popup)
	State.connect("screen_change", _on_screen_change)
	%SideMenu.visible = false


func _process(_delta: float) -> void:
	if Input.is_action_pressed("exit"):
		if %SideMenu.visible:
			%SideMenu.visible = false
			%MainContent.visible = true
		if %PopupContainer.visible:
			%PopupContainer.visible = false
			%MainContent.visible = true

func _on_side_menu_button_pressed() -> void:
	%SideMenu.visible = true
	%MainContent.visible = false


func _on_side_menu_item_selected(index: int) -> void:
	%SideMenu.visible = false
	%MainContent.visible = true

	var ev = InputEventAction.new()
	# Set as ui_left, pressed.
	match index:
		0: ev.action = "screen1"
		1: ev.action = "screen2"
		2: ev.action = "screen3"
		3: ev.action = "screen4"
		9: ev.action = "screen10"

	ev.pressed = true
	# Feedback.
	Input.parse_input_event(ev)


func _on_new_popup(title: String, text: String) -> void:
	%PopupTitle.text = title
	%PopupContent.text = text
	%MainContent.visible = false
	%PopupContainer.visible = true


func _on_help_button_pressed() -> void:
	var title: String = State.curr_screen_title()
	var text: String
	match title:
		"Facilities":
			text = "The Facilities menu shows the state of your power generation facilities. There are 8 types of facilities you can buy, and in general the more expensive the facility, the higher the output. When you buy a facility of a certain type, the next facility of that type will cost more."
		"R&D":
			text = "The R&D menu contains various upgrades you can purchase with proceeds from your facilities. The upgrades are separated into categories based on the system they primarily affect."
		"Stock":
			text = "The Stock menu contains your inventory of materials made in the manufacturing screen."
		"Manufacturing":
			text = "The Manufacturing menu allows you to craft recipes to gain materials. These materials are used to craft other materials, and also give bonuses to specific buildings."
		"Settings":
			text = "The Settings menu allows you to Save/Load/Reset your game progress.s"
		_:
			text = "This menu has not yet been implemented"

	State.create_popup(title, text)


func _on_popup_exit_button_pressed() -> void:
	%PopupContainer.visible = false
	%MainContent.visible = true

func _on_screen_change(index: int) -> void:
	# When screen is changed by keybinding while in side menu, want to hide it and switch
	if %SideMenu.visible and not %MainContent.visible:
		%SideMenu.select(index)
		%SideMenu.visible = false
		%MainContent.visible = true
