extends Control

func _ready() -> void:
	%FileNameForm.text = State.default_save_name

func _on_save_pressed() -> void:
	if validate_path():
		State.reset_save(get_full_path()) # Returns false if it fails but we don't care
		State.save_game(get_full_path())

func _on_load_pressed() -> void:
	if validate_path(true):
		State.load_game(get_full_path())

func _on_reset_pressed() -> void:
	if validate_path(true):
		State.reset_save(get_full_path())

func get_full_path() -> String:
	return str("user://", %FileNameForm.text)

# must_exist is true, for example, when trying to clear or load a file. This
# is because saving to a non-existent file makes sense but deleting or loading
# one does not
func validate_path(must_exist: bool = false) -> bool:
	var path = %FileNameForm.text
	
	var regex = RegEx.create_from_string("[A-Za-z0-9-_.]+")
	var result = regex.search(path)
	
	if not result or result.get_string() != path or len(path) > 40 \
		or (must_exist and !FileAccess.file_exists(path)):
		State.create_popup(
			"Invalid path",
			str(
				"This path is invalid. Paths must contain only letters, numbers, ",
			 "hyphens, underscores, and periods. They also must be 40 characters ",
			 "or less." ,
			 " The path also must refer to an existing file for loading/resetting" if must_exist else ""
			)
		)
		return false
	else: return true
