extends StaticBody3D

# These are shortcuts to grab nodes when the scene loads, so we don’t have to search for them later
@onready var detection_area = $Area3D  # Grabs the Area3D node to detect stuff nearby
@onready var button_node: StaticBody3D = $button  # Grabs the button node we’ll interact with
@onready var framework = get_node("/root/main/framework")  # Links to some main framework thing in the game
@onready var player = get_node("/root/main/Player")  # Links to the player so we can mess with their stuff

# A little dictionary to keep track of how many items we need
var item_counters = {
	"Stone": 0,  # Number of stones needed (starts at 0, we’ll set it later)
	"Curiosity": 0  # Number of curiosities needed (same deal)
}

# This flag keeps track of whether the button’s been used already
var is_button_used = false  # Starts as false since no one’s touched it yet

# Runs when the object first shows up in the game
func _ready():
	# Sets random goals for how many stones and curiosities we need (between 3 and 8)
	item_counters = {
		"Stone": randi_range(3, 8),  # Picks a random number of stones
		"Curiosity": randi_range(3, 8)  # Picks a random number of curiosities
	}
	update_label_text()  # Updates the text on screen to show the goals

	# If we’ve got a button, hook it up so we know when it’s pressed
	if button_node:
		button_node.connect("button_state_changed", _on_button_state_changed)  # Listens for button presses

# Updates the text on screen to show how many items we need and if the player’s got enough
func update_label_text(player_items: Dictionary = {}):
	# Start with "✗" (a cross) to show the player hasn’t met the goals yet
	var stone_status = "✗"  # Cross for stones by default
	var curiosity_status = "✗"  # Cross for curiosities by default

	# If we’ve got the player’s items, check if they’ve collected enough
	if player_items.has("Stone") and player_items.has("Curiosity"):
		if player_items["Stone"] >= item_counters["Stone"]:
			stone_status = "✓"  # Switch to a checkmark if they’ve got enough stones
		if player_items["Curiosity"] >= item_counters["Curiosity"]:
			curiosity_status = "✓"  # Same deal for curiosities

	# Update the text on screen with the goals and checkmarks/crosses
	$SubViewport/Control/Label.text = "Stones: %d %s\nCuriosities: %d %s" % [
		item_counters["Stone"], stone_status,  # Shows stone goal and status
		item_counters["Curiosity"], curiosity_status  # Shows curiosity goal and status
	]

# Gets called whenever the button’s state changes (like when it’s pressed)
func _on_button_state_changed(is_pressed: bool):
	if is_pressed:  # Only care if the button’s actually pressed
		# If the button’s already been used, let the player know and stop here
		if is_button_used:
		
			if player.AudioManager:
					player.AudioManager.play_sound("res://sounds/button/wpn_denyselect.mp3")
			player.show_notification("Button already used successfully!")  # Pops up a message
			return  # Bails out early

		# Check for anything in the detection area (like the player)
		for body in detection_area.get_overlapping_bodies():
			if body and body.has_method("get_item_counters"):  # If it’s something with items (like the player)
				var player_items = body.get_item_counters()  # Grab the player’s items
				print("Player collected: ", player_items)  # Just for debugging, shows what they’ve got

				# Update the screen with the player’s current progress
				update_label_text(player_items)

				# Check if they’ve got exactly the right amount of stuff
				var has_exact_items = check_exact_items(player_items)
				if has_exact_items:
					player.add_money(50)  # Give them 50 bucks for nailing it
					if framework and framework.has_method("register_success"):
						framework.register_success()  # Tell the game they crushed it
					is_button_used = true  # Mark the button as done
					player.show_notification("Task completed successfully! Button disabled.")  # Victory message
				else:
					# If not perfect, check if they’ve got at least half the stuff right
					var has_half_items = check_half_items(player_items)
					if has_half_items:
						player.add_money(35)  # Give them 35 bucks for a decent effort
						if framework and framework.has_method("register_half_success"):
							framework.register_half_success()  # Tell the game they did okay
						is_button_used = true  # Button’s done now
						player.show_notification("Task partially completed! Button disabled.")  # Partial win message
					else:
						if player.AudioManager:
								player.AudioManager.play_sound("res://sounds/button/wpn_denyselect.mp3")
						# If they didn’t even get half, they gotta try again
						player.show_notification("Not enough items collected! Try again.")  # Fail message
						if framework and framework.has_method("register_failure"):
							framework.register_failure()  # Tell the game they flopped

# Checks if the player has exactly the right number of items
func check_exact_items(player_items: Dictionary) -> bool:
	# If the player’s missing either item type, they’re out of luck
	if not player_items.has("Stone") or not player_items.has("Curiosity"):
		return false  # Nope, they don’t have everything
	
	# Compare what they’ve got to what we need
	var stones_match = player_items["Stone"] == item_counters["Stone"]  # Exact stone match?
	var curiosities_match = player_items["Curiosity"] == item_counters["Curiosity"]  # Exact curiosity match?
	
	return stones_match and curiosities_match  # True only if both match perfectly

# Checks if the player has at least one of the item types exactly right
func check_half_items(player_items: Dictionary) -> bool:
	# If they’re missing either item type, no dice
	if not player_items.has("Stone") or not player_items.has("Curiosity"):
		return false  # Nope, missing stuff
	
	# See if they nailed at least one of the goals
	var stones_match = player_items["Stone"] == item_counters["Stone"]  # Got the stones right?
	var curiosities_match = player_items["Curiosity"] == item_counters["Curiosity"]  # Got the curiosities right?
	
	return stones_match or curiosities_match  # True if they got at least one perfect
