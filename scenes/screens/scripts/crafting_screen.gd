extends Control


var is_active: bool
var curr_recipe#: Models.CraftingRecipe
var tween#: Tween

# Whenever we have creation faster than 4/second or so, it's easier to just calculate
# crafting output in bulk
var is_fast: bool

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var entry_scene = preload("res://scenes/components/recipe_entry.tscn")
	
	for rec in State.recipes():
		var node = entry_scene.instantiate()
		node.base = rec
		%RecipeContainer.add_child(node)
	
	State.connect("recipe_change", _on_recipe_change)
	%StopButton.connect("pressed", _on_stop_pressed)
	
func _process(delta: float) -> void:
	if is_active and is_fast:
		var rec_per_s = State.cspeed() / curr_recipe.time_cost_s()
		var total_output = delta * rec_per_s * State.coutput()
		
		if State.manufacturing_try_debit(curr_recipe.material_costs(), curr_recipe.bank_cost(), delta * rec_per_s):
			State.manufacturing_credit_materials(curr_recipe.output(), total_output)

func _on_stop_pressed() -> void:
	cancel_recipe()

func _on_recipe_change(recipe: Models.Recipe) -> void:
	# Assume that any new recipe is not fast
	is_fast = false
	
	if recipe == curr_recipe:
		# Pressed the same recipe that's active, deactivate it instead
		cancel_recipe()
		return
		
	var rec_time = recipe.time_cost_s() / State.cspeed()
	
	if is_active:
		# Disable the current recipe and refund resources
		cancel_recipe()
		
	if rec_time >= State.fast_craft_cutoff_s:
		# If time is high enough we can just use tweeners and callbacks
		init_tween(rec_time)
		%CraftingProgressLabel.text = str("Crafting: ", State.material_name(recipe.output()))
	# If time is less than this we will calculate the output in the process function
	else:
		is_fast = true
		%CraftingProgress.value = 100
		%CraftingProgressLabel.text = str(
			"Crafting: ",
			State.material_name(recipe.output()),
			"\n",
			State.fnum(1 / rec_time),
			" recipes per second")

	is_active = true
	curr_recipe = recipe
	
	State.manufacturing_try_debit(curr_recipe.material_costs(), curr_recipe.bank_cost())

func init_tween(time: float) -> void:
	%CraftingProgress.value = 0 # Just in case
	tween = get_tree().create_tween()
	tween.tween_property(%CraftingProgress, "value", 100.0, time)
	tween.tween_callback(process_recipe_completion)
	
func kill_tween() -> void:
	if tween != null:
		tween.kill()
		tween = null
	%CraftingProgress.value = 0

func cancel_recipe() -> void:
	if is_fast:
		# Just need to set to inactive, as resources are taken out at the 
		# same time as they are added
		is_fast = false
	else:
		# Disable the current recipe and refund resources
		if curr_recipe != null:
			State.bank_credit(curr_recipe.bank_cost())
			for mc in curr_recipe.material_costs():
				State.manufacturing_credit_materials(mc.material(), mc.count())
			kill_tween()
		
	is_active = false
	curr_recipe = null
	%CraftingProgress.value = 0
	%CraftingProgressLabel.text = "Crafting: Nothing"
	

func process_recipe_completion():
	State.manufacturing_credit_materials(curr_recipe.output(), State.coutput())

	kill_tween()
	
	if State.manufacturing_try_debit(curr_recipe.material_costs(), curr_recipe.bank_cost()):
		init_tween(curr_recipe.time_cost_s() / State.cspeed())
