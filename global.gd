# This makes it a UI thing (like a main menu screen)
extends Control

# Grabs the Continue button when the menu loads
@onready var continue_button =$menu/Continue

# Where the save file lives and the game scene we’ll jump to
const SAVE_PATH = "user://player_save.json"  # Path for saving player progress
const GAME_SCENE_PATH = "res://Main.tscn"  # Path to the main game scene

# Runs when the menu first shows up
func _ready():
	$Creadits.visible = false
	$Setting.visible = false
	# Show the Continue button only if there’s a save file
	continue_button.visible = FileAccess.file_exists(SAVE_PATH)
	# Make the mouse cursor visible for clicking buttons
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

# Called when the "New Game" button is pressed
func _on_new_game_pressed() -> void:
	# If there’s an old save file, delete it to start fresh
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	# Jump to the main game scene
	get_tree().change_scene_to_file(GAME_SCENE_PATH)

# Called when the "Exit" button is pressed
func _on_exit_pressed() -> void:
	# Shut down the game completely
	get_tree().quit()

# Called when the "Continue" button is pressed
func _on_continue_pressed() -> void:
	# Load the main game scene (save file will be checked there)
	get_tree().change_scene_to_file(GAME_SCENE_PATH)


func _on_frame_pressed() -> void:
	$Creadits.visible = !$Creadits.visible


func _on_setting_pressed() -> void:
	$Setting.visible = !$Setting.visible
