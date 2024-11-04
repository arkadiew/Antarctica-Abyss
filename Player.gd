extends CharacterBody3D

var restart_timer: float = 0.0
const RESTART_DELAY: float = 9.0  
@onready var darken_screen: ColorRect = $Camera3D/DarkenScreen
const DARKEN_MAX_ALPHA: float = 1
const OXYGEN_REPLENISH_RATE: float = 20.0  
const OXYGEN_INTERACTION_DISTANCE: float = 3.0  

# Constants
const SENSITIVITY: float = 0.01
const GRAVITY: float = -9.8
const WALK_SPEED: float = 5.0
const RUN_SPEED_MULTIPLIER: float = 2.0
const LOW_STAMINA_SPEED: float = 1.0
const JUMP_FORCE: float = 3.0
const JUMP_STAMINA_COST: float = 10.0
const MAX_STAMINA: float = 100.0
const MAX_H20: float = 100.0
const H2O_DEPLETION_RATE: float = 5.0  
const H2O_RECOVERY_RATE: float = 30.0  
const STAMINA_RECOVERY_RATE: float = 30.0
const STAMINA_RUN_DEPLETION_RATE: float = 20.0
const STAMINA_RECOVERY_DELAY: float = 3.5
const FADE_OUT_SPEED: float = 1.0

# Exported Variables
@export var throw_force: float = 7.5
@export var follow_speed: float = 3.5
@export var follow_distance: float = 2.5
@export var max_distance_from_camera: float = 5.0
@export var drop_below_player: bool = false
@export var ground_ray: RayCast3D
@export var swim_up_speed: float = 10.0
@export var climb_speed: float = 7.0

# Variables
var is_underwater: bool = false
var move_vector: Vector3 = Vector3.ZERO
var stamina: float = MAX_STAMINA
var is_running: bool = false
var bar_visible: bool = false
var held_object: RigidBody3D = null
var stamina_recovery_timer: float = 0.0
var can_run: bool = true
var holding_object_time: float = 0.0
var h2o: float = MAX_H20
# Interaction Constants
const INTERACTION_DISTANCE: float = 3.0
const LERP_SPEED: float = 5.0

# Onready Variables
@onready var interact_ray: RayCast3D = $Camera3D/InteractRay
@onready var camera: Camera3D = $Camera3D
@onready var stamina_bar: ProgressBar = $Camera3D/ProgressBar
@onready var label_3d: Label3D = $Camera3D/Label3D
@onready var staminad: Label = $Camera3D/stamina
@onready var h2oLabel: Label = $Camera3D/h2o
@onready var h2o_bar: ProgressBar = $Camera3D/h2o2


# Initialization
func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_initialize_stamina_bar()
	stamina_bar.modulate.a = 0.0  
	staminad.modulate.a = 0.0
	h2o_bar.modulate.a = 0.0  
	h2oLabel.modulate.a = 0.0

# Main Loop
func _process(delta: float) -> void:
	handle_object_interactions(delta)
	update_movement(delta)
	update_stamina(delta)
	update_stamina_bar(delta)
	_handle_water_physics(delta)
	update_h2o(delta) 
	update_oxygen_tank_interaction(delta) 
	
func _initialize_h2o_bar() -> void:
	h2o_bar.max_value = MAX_H20
	h2o_bar.value = h2o
	h2o_bar.modulate.a = 1  

# Stamina Bar Initialization
func _initialize_stamina_bar() -> void:
	stamina_bar.max_value = MAX_STAMINA
	stamina_bar.value = stamina
	stamina_bar.modulate.a = 1

# Player Movement Update
func update_movement(delta: float) -> void:
	move_vector = get_input_direction()
	var current_speed = determine_speed()

	velocity.x = move_vector.x * current_speed
	velocity.z = move_vector.z * current_speed

	if not is_on_floor():
		velocity.y += GRAVITY * delta

	if Input.is_action_just_pressed("jump") and is_on_floor() and stamina >= JUMP_STAMINA_COST:
		velocity.y = JUMP_FORCE
		decrease_stamina(JUMP_STAMINA_COST)

	move_and_slide()

# Determine Movement Speed Based on Conditions
func determine_speed() -> float:
	if is_running and stamina > 0:
		return WALK_SPEED * RUN_SPEED_MULTIPLIER
	elif stamina == 0:
		return LOW_STAMINA_SPEED
	return WALK_SPEED

# Update Stamina Based on Actions
func update_stamina(delta: float) -> void:
	var in_water = is_in_water()
	var is_moving = move_vector.length() > 0

	is_running = can_run and stamina > 0 and Input.is_action_pressed("run") and is_moving and not in_water

	if is_running:
		decrease_stamina(STAMINA_RUN_DEPLETION_RATE * delta)
		stamina_recovery_timer = 0.0
		if stamina <= 0:
			can_run = false
	else:
		stamina_recovery_timer += delta
		if not Input.is_action_pressed("run"):
			if stamina_recovery_timer >= STAMINA_RECOVERY_DELAY:
				increase_stamina(STAMINA_RECOVERY_RATE * delta)
			if stamina > 0:
				can_run = true
	if stamina <= 0 and is_moving:
		stamina_recovery_timer += delta

# Helper Functions to Modify Stamina
func decrease_stamina(amount: float) -> void:
	stamina = clamp(stamina - amount, 0, MAX_STAMINA)

func increase_stamina(amount: float) -> void:
	stamina = clamp(stamina + amount, 0, MAX_STAMINA)

# Get Direction from Input
func get_input_direction() -> Vector3:
	var input_dir = Vector3.ZERO
	if Input.is_action_pressed("move_forward"):
		input_dir.z -= 1
	if Input.is_action_pressed("move_backward"):
		input_dir.z += 1
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("move_right"):
		input_dir.x += 1
	return (transform.basis.z * input_dir.z + transform.basis.x * input_dir.x).normalized()

# Handle Mouse Movement for Camera
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		handle_mouse_motion(event)
	elif event is InputEventKey and event.pressed and Input.is_action_pressed("exit"):
		toggle_mouse_mode()

func handle_mouse_motion(event: InputEventMouseMotion) -> void:
	rotation.y -= event.relative.x * SENSITIVITY
	rotation.x = clamp(rotation.x - event.relative.y * SENSITIVITY, -1.5, 1.5)

func toggle_mouse_mode() -> void:
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

# Update the Stamina Bar based on stamina changes
func update_stamina_bar(delta: float) -> void:
	stamina_bar.value = stamina

	if stamina < MAX_STAMINA and not bar_visible:
		show_stamina_bar(delta)
	elif stamina >= MAX_STAMINA and bar_visible:
		hide_stamina_bar(delta)


func hide_stamina_bar(delta: float) -> void:
	stamina_bar.modulate.a = lerp(stamina_bar.modulate.a, 0.0, delta * 5) 
	staminad.modulate.a = stamina_bar.modulate.a 


	if stamina_bar.modulate.a <= 0.01:
		stamina_bar.modulate.a = 0.0
		staminad.modulate.a = 0.0
		bar_visible = false


func show_stamina_bar(delta: float) -> void:
	stamina_bar.modulate.a = lerp(stamina_bar.modulate.a, 1.0, delta * 5) 
	staminad.modulate.a = stamina_bar.modulate.a 

	if stamina_bar.modulate.a >= 0.99:
		stamina_bar.modulate.a = 1.0
		staminad.modulate.a = 1.0
		bar_visible = true


# Object Interaction Functions
func handle_object_interactions(delta: float) -> void:
	if Input.is_action_just_pressed("interact"):
		if held_object:
			drop_held_object()
			holding_object_time = 0.0
		elif interact_ray.is_colliding():
			var collider = interact_ray.get_collider()
			if collider is RigidBody3D and stamina > 10:
				set_held_object(collider)
				holding_object_time = 0.0
	update_label_position()

	if held_object:
		follow_player_with_object()
		holding_object_time += delta
		var mass = held_object.mass
		var drain_factor = (holding_object_time / 10.0) * mass
		if holding_object_time >= 1.0:
			decrease_stamina(10.0 * drain_factor * delta)
		if stamina <= 0:
			drop_held_object()
			holding_object_time = 0.0

func get_object_height(obj):
	var shape_node = obj.get_node_or_null("CollisionShape3D")
	if shape_node and shape_node.shape is BoxShape3D:
		return shape_node.shape.extents.y
	return 0.5

func update_label_position() -> void:
	if held_object:
		update_label_for_held_object(held_object)
	else:
		update_label_for_nearby_object()

func update_label_for_held_object(object):
	var object_position = object.global_transform.origin
	var object_height = get_object_height(object)
	var target_position = object_position + Vector3(0, object_height + 0.1, 0)
	label_3d.global_transform.origin = label_3d.global_transform.origin.lerp(target_position, LERP_SPEED * get_process_delta_time())
	label_3d.text = "[R] Drop " + object.name
	label_3d.visible = true

func update_label_for_nearby_object():
	if interact_ray.is_colliding():
		var collider = interact_ray.get_collider()
		if collider is RigidBody3D:
			var distance = global_transform.origin.distance_to(collider.global_transform.origin)
			if distance <= INTERACTION_DISTANCE:
				var object_position = collider.global_transform.origin
				var object_height = get_object_height(collider)
				var target_position = object_position + Vector3(0, object_height + 0.1, 0)
				label_3d.global_transform.origin = label_3d.global_transform.origin.lerp(target_position, LERP_SPEED * get_process_delta_time())
				label_3d.text = "[R] Interact with " + collider.name
				label_3d.visible = true
				return
	label_3d.visible = false

func set_held_object(body: RigidBody3D) -> void:
	held_object = body

func drop_held_object() -> void:
	held_object = null

func follow_player_with_object() -> void:
	var target_pos = camera.global_transform.origin + (camera.global_basis * Vector3(0, 0, -follow_distance))
	var object_pos = held_object.global_transform.origin
	held_object.linear_velocity = (target_pos - object_pos) * follow_speed

	if held_object.global_position.distance_to(camera.global_position) > max_distance_from_camera:
		drop_held_object()
	elif drop_below_player and ground_ray.is_colliding() and ground_ray.get_collider() == held_object:
		drop_held_object()

# Water Physics Handling
func _handle_water_physics(delta: float) -> void:
	if is_in_water():
		apply_water_physics(delta)

func is_in_water() -> bool:
	for area in get_tree().get_nodes_in_group("water_area"):
		if area.overlaps_body(self):
			return true
	return false

func apply_water_physics(delta: float) -> void:

	var water_gravity = GRAVITY * 0.2
	var water_drag_horizontal = 1.5
	var water_drag_vertical = 1.2
	var swim_up_force = 13.0
	var is_moving_in_water = false
	var input_dir = Vector3.ZERO

	# Handle movement input
	if Input.is_action_pressed("move_forward"):
		input_dir.z -= 1
	if Input.is_action_pressed("move_backward"):
		input_dir.z += 1
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("move_right"):
		input_dir.x += 1

	# Apply movement direction and speed in water
	if input_dir != Vector3.ZERO:
		is_moving_in_water = true
		input_dir = input_dir.normalized()
		velocity.x = input_dir.x * (WALK_SPEED * 0.5)
		velocity.z = input_dir.z * (WALK_SPEED * 0.5)

	# Handle swimming upward with jump input
	if Input.is_action_pressed("jump") and stamina > 1:
		velocity.y += swim_up_force * delta
		is_moving_in_water = true
		decrease_stamina(0.9)
	else:
		velocity.y -= water_gravity * delta
	# Adjust stamina based on movement in water
	if is_moving_in_water:
		decrease_stamina(0.5 * delta)
	else:
		if not Input.is_action_pressed("jump") and stamina > 0:
			increase_stamina(15.0 * delta)
		else:
			Input.action_release("jump")  # Automatically release the "jump" action


	# Apply water drag to the velocity
	velocity.x = lerp(velocity.x, 0.0, water_drag_horizontal * delta)
	velocity.z = lerp(velocity.z, 0.0, water_drag_horizontal * delta)
	velocity.y = lerp(velocity.y, 0.0, water_drag_vertical * delta)

	# Prevent running in water
	is_running = false
func update_h2o_label_and_bar_visibility(delta: float) -> void:
	if is_underwater and h2o < MAX_H20:
		# Быстрое и плавное появление индикатора H2O
		h2o_bar.modulate.a = lerp(h2o_bar.modulate.a, 1.0, delta * 3)
		h2oLabel.modulate.a = lerp(h2oLabel.modulate.a, 1.0, delta * 3)
	else:
		# Быстрое и плавное исчезновение индикатора H2O
		h2o_bar.modulate.a = lerp(h2o_bar.modulate.a, 0.0, delta * 3)
		h2oLabel.modulate.a = lerp(h2oLabel.modulate.a, 0.0, delta * 3)

	
func update_h2o(delta: float) -> void:
	is_underwater = is_in_water()  # Проверка, находится ли игрок под водой

	if is_underwater:
		decrease_h2o(H2O_DEPLETION_RATE * delta)
		if h2o <= 0:
			# Затемняем экран, если кислород исчерпан
			darken_screen.modulate.a = lerp(darken_screen.modulate.a, DARKEN_MAX_ALPHA, delta * 2)
			restart_timer += delta  # Запускаем таймер на перезапуск
			if restart_timer >= RESTART_DELAY:
				restart_scene()  # Перезапуск сцены после задержки
	else:
		increase_h2o(H2O_RECOVERY_RATE * delta)
		# Постепенно осветляем экран и сбрасываем таймер перезапуска
		darken_screen.modulate.a = lerp(darken_screen.modulate.a, 0.0, delta * 2)
		restart_timer = 0.0  # Сброс таймера перезапуска, если игрок выходит из воды

	update_h2o_bar()  # Обновление H2O-прогресс бара
	update_h2o_label_and_bar_visibility(delta)

func decrease_h2o(amount: float) -> void:
	h2o = clamp(h2o - amount, 0, MAX_H20)

func increase_h2o(amount: float) -> void:
	h2o = clamp(h2o + amount, 0, MAX_H20)
func update_h2o_bar() -> void:
	h2o_bar.value = h2o
	

func update_oxygen_tank_interaction(delta: float) -> void:
	if get_tree() == null:
		return  
	for oxygen_tank in get_tree().get_nodes_in_group("oxygen_source"):
		if oxygen_tank.global_transform.origin.distance_to(global_transform.origin) <= OXYGEN_INTERACTION_DISTANCE:
			increase_h2o(OXYGEN_REPLENISH_RATE * delta)
			return

func restart_scene() -> void:
	get_tree().reload_current_scene()
