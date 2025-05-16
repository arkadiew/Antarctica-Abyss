extends BaseFish

@export var dash_speed: float = 8.0
@export var detection_radius: float = 5.0
@export var lose_interest_radius: float = 7.0  # Радиус, при котором рыба теряет интерес
@export var chase_persistence_time: float = 3.0  # Время, в течение которого рыба продолжает преследование
@export var dash_interval: float = 1.5

var dash_timer: float = 0.0
var is_chasing: bool = false
var chase_timer: float = 0.0

@onready var player = get_node_or_null("/root/main/Player")

func _ready() -> void:
	super._ready()

func _physics_process(delta: float) -> void:
	dash_timer += delta
	_timer += delta

	if player:
		var distance_to_player = global_position.distance_to(player.global_position)
		

		if distance_to_player <= detection_radius:
			is_chasing = true
			chase_timer = chase_persistence_time
			target_direction = (player.global_position - global_position).normalized()
			if dash_timer >= dash_interval:
				dash_timer = 0.0
				velocity = target_direction * dash_speed
		else:

			if is_chasing:
				if distance_to_player > lose_interest_radius:
					chase_timer -= delta
					if chase_timer <= 0:
						is_chasing = false
						velocity = velocity.lerp(Vector3.ZERO, delta * acceleration_speed)  # Плавное замедление
				else:

					target_direction = (player.global_position - global_position).normalized()


	if not is_chasing and _timer >= rethink_time:
		_timer = 0.0
		target_direction = _get_random_direction()


	if dash_timer > 0.2:
		velocity = velocity.lerp(target_direction * max_speed, delta * acceleration_speed)

	move_and_slide()
	_keep_inside_bounds(delta)
	_face_direction(delta)
	_play_walk_animation()

func _get_random_direction() -> Vector3:
	return Vector3(randf_range(-1.0, 1.0), randf_range(-0.5, 0.5), randf_range(-1.0, 1.0)).normalized()

func _play_walk_animation() -> void:
	var anim_player = find_child("AnimationPlayer", true, false)
	if anim_player and anim_player.has_animation("enemy"):
		if anim_player.current_animation != "enemy":
			anim_player.play("enemy")
