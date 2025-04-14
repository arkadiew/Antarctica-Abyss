extends RigidBody3D
class_name BaseBreakable

# Export variables for editor customization
@export var max_hp: int = 3
@export var destruction_particles: PackedScene = preload("res://scenes/partical.tscn")
@export var collision_sound: AudioStream = preload("res://sounds/obj/thud-291047.mp3")
@export var break_sound: AudioStream = preload("res://sounds/obj/wood3.mp3")
@export var impact_volume: float = 0.0
@export var max_sound_distance: float = 20.0

# Internal variables
var hp: int
var audio_player: AudioStreamPlayer3D

func _ready() -> void:
	hp = max_hp
	contact_monitor = true
	max_contacts_reported = 1
	setup_audio()
	
	if body_entered.connect(_on_body_entered) != OK:
		print("ERROR: Failed to connect body_entered signal in ", name)
	else:
		print("Body_entered signal connected successfully for ", name)

func setup_audio() -> void:
	audio_player = AudioStreamPlayer3D.new()
	add_child(audio_player)
	
	if collision_sound:
		audio_player.stream = collision_sound
		audio_player.max_db = 0.0
		audio_player.max_distance = max_sound_distance
		audio_player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
		audio_player.volume_db = impact_volume

func _on_body_entered(body: Node) -> void:
	if audio_player and collision_sound:
		audio_player.play()
		print("Collision with ", body.name, " at ", global_position)
	else:
		print("WARNING: No audio setup for collision in ", name)

func take_damage(amount: int) -> void:
	hp -= amount
	print(name, " took ", amount, " damage. HP left: ", hp)
	if hp <= 0:
		break_object()

func break_object() -> void:
	# Воспроизводим звук разрушения, если он задан
	if audio_player and break_sound:
		audio_player.stream = break_sound
		audio_player.play()
	
	if destruction_particles:
		var particles_instance = destruction_particles.instantiate()
		particles_instance.global_transform = global_transform
		particles_instance.global_transform.origin += Vector3(0, -2, 0)
		get_parent().add_child(particles_instance)
	
	await get_tree().create_timer(0.1).timeout
	_on_destroyed()  # Call virtual method before freeing
	queue_free()

# Virtual function for overriding
func _on_destroyed() -> void:
	pass
