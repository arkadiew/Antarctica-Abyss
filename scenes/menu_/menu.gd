extends Control
const GAME_SCENE_PATH = "res://global_menu.tscn"
@onready var menu = get_node_or_null("/root/main/Player/CameraPivot/Camera3D/UI/CanvasLayer/menu")
func resume():
	get_tree().paused = false

func pause ():
	get_tree().paused = true


# Runs when this UI thing shows up
func _ready():
	$Creadits.visible = false
	$yesornot.visible = false
	$Setting.visible = false
	# Makes the mouse cursor show up (so you can click buttons and stuff)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	process_mode = Node.PROCESS_MODE_ALWAYS

func _on_continue_pressed() -> void:
	menu.visible = false
	resume()
	

func _on_exit_pressed() -> void:
	#get_tree().quit()
	$yesornot.visible = true

func _on_no_pressed() -> void:
	$yesornot.visible = false

func _on_yes_pressed() -> void:
	get_tree().change_scene_to_file(GAME_SCENE_PATH)


func _on_frame_pressed() -> void:
	$Creadits.visible = !$Creadits.visible


func _on_setting_pressed() -> void:
	$Setting.visible = !$Setting.visible
