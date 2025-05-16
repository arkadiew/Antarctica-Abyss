extends RigidBody3D
class_name BaseBreakable

# Export variables for editor customization
@export var hardness: float = 1.5  # Base break time in seconds (like Minecraft stone)
@export var max_hp: int = 10  # Health points for durability
@export var strength: float = 1.0  # Damage multiplier (lower = more resistant)
@export var impact_damage_threshold: float = 5.0  # Minimum impulse for impact damage
@export var impact_damage_multiplier: float = 0.5  # Scales impulse to damage
@export var destruction_particles: PackedScene  # Particle scene for breaking
@export var collision_sound: AudioStream  # Sound for collisions
@export var break_sound: AudioStream  # Sound for breaking
@export var impact_volume: float = 0.0  # Volume for collision sound
@export var max_sound_distance: float = 20.0  # Max distance for sound
@export var break_stages: Array[Texture2D] = []  # Textures for crack animation

# Internal variables
var hp: int
var audio_player: AudioStreamPlayer3D
var break_progress: float = 0.0  # Breaking progress (0.0 to 1.0)
var is_breaking: bool = false  # Is the player manually breaking
var break_timer: float = 0.0  # Time spent breaking
var sprite: Sprite3D  # For crack animation

func _ready() -> void:
	hp = max_hp
	contact_monitor = true
	max_contacts_reported = 1
	setup_audio()
	setup_visuals()
	
	# Connect body_entered signal (Godot 4.3 compatible)
	body_entered.connect(_on_body_entered)

func setup_audio() -> void:
	audio_player = AudioStreamPlayer3D.new()
	add_child(audio_player)
	audio_player.bus = "SFX"  # Ensure SFX bus exists in project settings
	if collision_sound:
		audio_player.stream = collision_sound
		audio_player.max_distance = max_sound_distance
		audio_player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
		audio_player.volume_db = impact_volume

func setup_visuals() -> void:
	sprite = Sprite3D.new()
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.no_depth_test = true  # Avoid z-fighting
	sprite.position = Vector3(0, 0, 0.01)  # Slight offset
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD  # For transparent textures
	if break_stages.size() > 0:
		sprite.texture = break_stages[0]
	add_child(sprite)

func _physics_process(delta: float) -> void:
	if is_breaking:
		break_timer += delta
		var break_time = hardness * strength
		break_progress = break_timer / break_time
		update_break_visuals()
		
		if break_progress >= 1.0:
			take_damage(max_hp)  # Break the object
			is_breaking = false
			break_timer = 0.0
			break_progress = 0.0

func _on_body_entered(body: Node) -> void:
	if audio_player and collision_sound:
		audio_player.play()
	
	# Estimate impulse based on relative velocity
	var impulse: float = linear_velocity.length()
	if body is RigidBody3D:
		impulse += body.linear_velocity.length()
	
	if impulse > impact_damage_threshold:
		var damage = int((impulse - impact_damage_threshold) * impact_damage_multiplier)
		if damage > 0:
			take_damage(damage)
	
	print("Collision with ", body.name, " at ", global_position, " with estimated impulse ", impulse)


func update_break_visuals() -> void:
	if break_stages.size() == 0:
		return
	
	var stage_count = break_stages.size()
	var stage = int(break_progress * stage_count)
	stage = min(stage, stage_count - 1)
	sprite.texture = break_stages[stage]
	sprite.visible = break_progress > 0

func take_damage(amount: int) -> void:
	var modified_damage = int(amount * strength)
	hp -= modified_damage
	print(name, " took ", modified_damage, " damage (original: ", amount, ", strength: ", strength, "). HP left: ", hp)
	if hp <= 0:
		break_object()

func break_object() -> void:
	if audio_player and break_sound:
		audio_player.stream = break_sound
		audio_player.play()
	
	if destruction_particles:
		var particles_instance = destruction_particles.instantiate()
		get_tree().current_scene.add_child(particles_instance)
		particles_instance.global_position = global_position
		if particles_instance is GPUParticles3D:
			particles_instance.emitting = true
	
	await get_tree().create_timer(0.1).timeout
	_on_destroyed()
	queue_free()

# Virtual function for child classes to override
func _on_destroyed() -> void:
	pass
