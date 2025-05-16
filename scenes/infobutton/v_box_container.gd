extends VBoxContainer

var action_descriptions = {
	"player_move_forward": {"name": "Forward", "hint": "Move forward"},
	"player_move_backward": {"name": "Backward", "hint": "Move backward"},
	"player_move_left": {"name": "Left", "hint": "Move left"},
	"player_move_right": {"name": "Right", "hint": "Move right"},
	"player_jump": {"name": "Jump", "hint": "Jump over obstacles"},
	"player_attack": {"name": "Attack/Repairable", "hint": "Attack enemies"},
	"player_Q": {"name": "Inventory", "hint": "Select item"},
	"player_use_item": {"name": "Use", "hint": "Use item"},
	"player_interact": {"name": "Interact", "hint": "With objects"},
	"player_exit": {"name": "Exit", "hint": "Exit menu"},
	"player_exit_suit": {"name": "Remove Suit", "hint": "Remove suit"}
}

func _ready():
	update_control_info()

func update_control_info():
	# Clear existing children except DefaultButton
	for child in get_children():
		if child.name != "DefaultButton":
			child.queue_free()
	
	# Add header
	var header = Label.new()
	header.text = "Controls:"
	header.add_theme_font_size_override("font_size", 24)
	add_child(header)
	
	var actions = InputMap.get_actions()
	var actions_added = false
	
	# Iterate through actions
	for action in actions:
		if not action.begins_with("player_"):
			continue
		
		var hbox = HBoxContainer.new()
		var action_label = Label.new()
		var events = InputMap.action_get_events(action)
		var key_name = ""
		
		# Check input events for key or mouse
		for event in events:
			if event is InputEventKey:
				key_name = event.as_text().split(" ")[0]
				break
			elif event is InputEventMouseButton:
				if event.button_index == 1:
					key_name = "Mouse Left"
				elif event.button_index == 2:
					key_name = "Mouse Right"
				else:
					key_name = "Mouse " + str(event.button_index)
				break
		
		# Get action description or default
		var desc = action_descriptions.get(action, {
			"name": action.trim_prefix("player_").capitalize(), 
			"hint": ""
		})
		var text = "%s - %s" % [key_name if key_name else "Not assigned", desc["name"]]
		action_label.text = text
		
		hbox.add_child(action_label)
		add_child(hbox)
		actions_added = true
	
	# Display message if no actions found
	if not actions_added:
		var no_actions = Label.new()
		no_actions.text = "No actions found."
		add_child(no_actions)
