extends BaseFish

# Additional export variables for enemy behavior
@export var dash_speed: float = 8.0
@export var detection_radius: float = 90.0
@export var chase_persistence_time: float = 3.0
@export var dash_interval: float = 1.5

# Internal variables
var dash_timer: float = 0.0
var is_chasing: bool = false
var chase_timer: float = 0.0
var player: Node3D = null

# Runs when the enemy spawns
func _ready() -> void:
	super._ready()  # Call the base class _ready()
	player = get_tree().get_root().find_child("player", true, false)  # Find the player

# Override physics process to add chasing and dashing
func _physics_process(delta: float) -> void:
	dash_timer += delta
	_timer += delta
	
	if player:
		var distance_to_player = global_transform.origin.distance_to(player.global_transform.origin)
		if distance_to_player <= detection_radius:
			is_chasing = true
			chase_timer = chase_persistence_time
			target_direction = (player.global_transform.origin - global_transform.origin).normalized()
			if dash_timer >= dash_interval:
				dash_timer = 0.0
				velocity = target_direction * dash_speed
		else:
			if is_chasing:
				chase_timer -= delta
				if chase_timer <= 0:
					is_chasing = false
					target_direction = _get_random_direction()
	
	if not is_chasing and _timer >= rethink_time:
		_timer = 0.0
		target_direction = _get_random_direction()
	
	if dash_timer > 0.2:  # Smooth movement after dash
		velocity = velocity.lerp(target_direction * max_speed, delta * acceleration_speed)
	
	move_and_slide()
	_keep_inside_bounds(delta)
	_face_direction(delta)
	_play_walk_animation()

# Override random direction to limit vertical movement
func _get_random_direction() -> Vector3:
	return Vector3(randf_range(-1.0, 1.0), randf_range(-0.5, 0.5), randf_range(-1.0, 1.0)).normalized()

# Play the walking animation if available
func _play_walk_animation() -> void:
	var anim_player = find_child("AnimationPlayer", true, false)
	if anim_player and anim_player.has_animation("enemy"):
		if anim_player.current_animation != "enemy":
			anim_player.play("enemy")
