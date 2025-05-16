# This makes it a UI thing (like a menu or screen) in Godot
extends Control

# A constant that points to the main scene file we’ll load
const START_SCENE_PATH = "res://global_menu.tscn"

# Runs when this UI thing shows up
func _ready():
	# Makes the mouse cursor show up (so you can click buttons and stuff)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

# Gets called when a button named "repeat" is pressed (you’d hook this up in the editor)
func _on_repeat_pressed() -> void:
	# Switches the game back to the main scene (like a restart or menu jump)
	get_tree().change_scene_to_file(START_SCENE_PATH)
