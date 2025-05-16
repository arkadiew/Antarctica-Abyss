extends RigidBody3D

var collected_items = []
var item_counters = {"Stone": 0, "Curiosity": 0}

@export var collision_sound: AudioStream = preload("res://sounds/obj/thud-291047.mp3")

@onready var detection_area = $Area3D


var audio_player: AudioStreamPlayer3D
@export var impact_volume: float = -10.0
@export var max_sound_distance: float = 20.0

func _ready():
	setup_audio()
	if detection_area:
		detection_area.connect("body_entered", _on_body_entered)


func setup_audio() -> void:
	audio_player = AudioStreamPlayer3D.new()
	add_child(audio_player)
	if collision_sound:
		audio_player.stream = collision_sound
		audio_player.max_db = 0.0
		audio_player.max_distance = max_sound_distance
		audio_player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
		audio_player.volume_db = impact_volume
	else:
		print("Error: No collision sound assigned!")

# Relevant excerpt
func _on_body_entered(body):
	if audio_player and collision_sound:
		audio_player.volume_db = impact_volume
		audio_player.play()
	else:
		print("Error: Audio player or collision sound not set up!")
	
	if body and is_instance_valid(body) and body.is_in_group("collectable"):
		var item_name = body.name
		if "Stone" in item_name:
			item_counters["Stone"] += 1
		elif "Curiosity" in item_name:
			item_counters["Curiosity"] += 1
		body.queue_free()
		collected_items.append(item_name)
		print("Collected items: ", collected_items)
		TaskManager.update_button_task_items("button_task", item_counters)


func get_collected_items():
	return collected_items

func get_item_counters():
	return item_counters

func register_success():
	print("Success registered in framework")

func register_failure():
	print("Failure registered in framework")

func register_half_success():
	print("Half registered in framework")
