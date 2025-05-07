extends Area3D

@export var conveyor_speed: float = 5.0
@export var direction: Vector3 = Vector3(-1, 0, 0)
@export var target_group: String = "conveyor_objects"
@export var conveyor_sound: AudioStream = preload("res://sounds/button/9ca76c68f28d1ae.mp3")  # Add your sound file path

@onready var button_lenta: StaticBody3D = $"../Button_lenta"
@onready var anim_player = $"../Lenta/lenta_/AnimationPlayer"
@onready var audio_player = $AudioStreamPlayer3D  # Add this node in the scene

var is_conveyor_active: bool = false

func _ready():
	# Validate required nodes
	if not has_node("CollisionShape3D"):
		push_error("Area3D requires a CollisionShape3D node!")
		return
	
	if not button_lenta:
		push_error("Button_lenta not found!")
		return
	
	if not anim_player:
		push_error("AnimationPlayer not found!")
		return
	
	# Setup audio player
	if not audio_player:
		audio_player = AudioStreamPlayer3D.new()
		add_child(audio_player)
		audio_player.stream = conveyor_sound
		audio_player.bus = "SFX"  # Use appropriate audio bus
	
	# Enable monitoring
	monitoring = true
	monitorable = true
	
	# Connect button signal
	button_lenta.connect("button_state_changed", _on_button_button_lenta)

func _on_button_button_lenta(is_pressed: bool):
	if is_pressed:  # Toggle on button press
		is_conveyor_active = not is_conveyor_active
		
		if is_conveyor_active:
			# Start conveyor
			if anim_player and anim_player.has_animation("lennta"):
				anim_player.play("lennta")
			if audio_player and conveyor_sound:
				audio_player.play()
		else:
			# Stop conveyor
			if anim_player:
				anim_player.stop()
			if audio_player:
				audio_player.stop()

func _physics_process(delta):
	if not is_conveyor_active:
		return
	
	var bodies = get_overlapping_bodies()
	
	# Debug output every second
	if Engine.get_frames_drawn() % 60 == 0:
		if bodies.size() == 0:
			print("No bodies in Area3D")
	
	# Move objects on conveyor
	for body in bodies:
		if body.is_in_group(target_group):
			var move_vector = direction.normalized() * conveyor_speed * delta
			
			if body is RigidBody3D:
				body.linear_velocity = move_vector / delta
			elif body is Node3D:
				body.global_transform.origin += move_vector
