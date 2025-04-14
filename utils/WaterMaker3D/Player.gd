extends CharacterBody3D

#region variables

const INCREASE_RATE_NEAR: float = 10.0   
const INCREASE_RATE_FAR: float = 5.0    
const DECREASE_RATE_COLLIDING: float = 5.0
const DECREASE_RATE_NO_COLLISION: float = 3.0
const TERMINAL_VELOCITY = -40.0
const AIR_CONTROL = 3.0 
const FEAR_DEATH_DELAY = 4.0  
const SUIT_PICKUP_DISTANCE = 3.0
const SUIT_GROUP = "suit_items"
const MAX_INVENTORY_SIZE = 5
const OXYGEN_CONSUMPTION_RATE = 0.2
const OXYGEN_CRITICAL_LEVEL = 10.0
const OXYGEN_LOW_MOVEMENT_PENALTY = 0.5
const WATER_DENSITY = 1.0
const PLAYER_VOLUME = 0.5
const BUOYANCY_FACTOR = 1.0
const SWIM_SPEED = 2.0
const SWIM_UP_SPEED = 3.0
const MIN_VERTICAL_SPEED = -0.5
const SWIM_DOWN_SPEED = 6.0
const STAMINA_DOWN_COST = 2.0
const MAX_VERTICAL_ANGLE = 89.0
const RUN_SPEED_MULTIPLIER = 2.0  
const SENSITIVITY = 0.01
const GRAVITY = -9.8
const WALK_SPEED = 5.0
const LOW_STAMINA_SPEED = 1.0
const JUMP_FORCE = 3.0
const JUMP_STAMINA_COST = 10.0
const MAX_STAMINA = 100.0
const MAX_H2O = 100.0
const H2O_DEPLETION_RATE = 1.0
const H2O_RECOVERY_RATE = 30.0
const STAMINA_RECOVERY_RATE = 30.0
const STAMINA_RUN_DEPLETION_RATE = 20.0
const STAMINA_RECOVERY_DELAY = 3.5
const MIN_H2O_THRESHOLD = 10.0
const INTERACTION_DISTANCE = 3.0
const LERP_SPEED = 5.0
const RESTART_DELAY = 9.0
const DARKEN_MAX_ALPHA = 1.0
const OXYGEN_REPLENISH_RATE = 20.0
const OXYGEN_INTERACTION_DISTANCE = 3.0
var zoom_speed: float = 1.0  
var min_distance: float = 1.0  
var max_distance: float = 3.0  

@export var throw_force = 7.5
@export var follow_speed = 3.5
@export var follow_distance = 2.5
@export var max_distance_from_camera = 5.0
@export var drop_below_player = false
@export var ground_ray: RayCast3D
@export var swim_up_speed = 10.0
@export var climb_speed = 7.0

var is_fear_max: bool = false
var fear_max_hold_time: float = 5.0  
var fear_max_timer: float = 0.0
var fear_death_timer = 0.0
var has_suit = false
var inventory = []
var selected_item: RigidBody3D = null
var selected_item_index = -1
var stamina = MAX_STAMINA
var h2o = MAX_H2O
var money: int = 100  
var can_attack = true
var is_running = false
var stamina_recovery_timer = 0.0
var can_run = true
var holding_object_time = 0.0
var is_underwater = false
var resisting_flow = false
var restart_timer = 0.0
var held_object: RigidBody3D = null
var interaction_cooldown = 0.5
var last_interaction_time = 0.0
var original_fov = 70.0
var is_shaking = false
var shake_intensity = 0.0
var shake_timer = 0.0
var current_flow = Vector3(1, 0, 0)
var flow_strength = 2.0
var jump_charge = 0.0
var max_jump_charge = 1.0
var jump_charge_rate = 0.5
var tilt_angle = 0.0  
var max_tilt = 3.0  
var tilt_speed = 8.0  
var tilt_recovery = 6.0  

@onready var Rayscary3D: RayCast3D = $CameraPivot/Camera3D/Rayscary3D
var fear_level = 0.0
var fear_images = [
	preload("res://utils/png_scary/fear_0.png"),    # 0%
	preload("res://utils/png_scary/fear_25.png"),   # 25%
	preload("res://utils/png_scary/fear_50.png"),   # 50%
	preload("res://utils/png_scary/fear_75.png"),   # 75%
	preload("res://utils/png_scary/fear_100.png")   # 100%
]
var scary_list = ["fish", "Enemy"]

@export var suit_scene: PackedScene = preload("res://TSCN/suit.tscn")
var original_material: Material = null
var highlight_material: Material = preload("res://utils/highlight_material.tres")
var default_material = StandardMaterial3D.new()
@onready var fear_sprite: TextureRect = $CameraPivot/Camera3D/UI/FearSprite
@onready var Pro3: TextureRect = $CameraPivot/Camera3D/UI/Pro3
@onready var Pro2: TextureRect = $CameraPivot/Camera3D/UI/Pro2
@onready var Pro1: TextureRect = $CameraPivot/Camera3D/UI/Pro
@onready var icon2: TextureRect = $CameraPivot/Camera3D/UI/icon2
@onready var icon: TextureRect = $CameraPivot/Camera3D/UI/icon
@onready var AudioManager: Node = $AudioManager
@onready var camera: Camera3D = $CameraPivot/Camera3D
@onready var interact_ray: RayCast3D = $CameraPivot/Camera3D/InteractRay
@onready var stamina_bar: TextureProgressBar = $CameraPivot/Camera3D/UI/TextureProgressBar
@onready var h2o_bar: TextureProgressBar = $CameraPivot/Camera3D/UI/o2
@onready var label_3d: Label3D = $CameraPivot/Camera3D/Label3D
@onready var darken_screen: ColorRect = $CameraPivot/Camera3D/UI/DarkenScreen
@onready var NotificationLabel: Label = $CameraPivot/Camera3D/UI/NotificationLabel
@onready var mask: TextureRect = $CameraPivot/Camera3D/UI/mask
@onready var camera_pivot: Node3D = $CameraPivot

var shake_randomizer = RandomNumberGenerator.new()
const SMOOTH_ROTATION_SPEED = 5.0

var rotation_y = 0.0
var rotation_x = 0.0
var target_rotation_y = 0.0
#endregion

#region start

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	original_fov = camera.fov
	if has_suit:
		stamina_bar.visible = true
		h2o_bar.visible = true
		stamina_bar.modulate.a = 1.0
		h2o_bar.modulate.a = 1.0
	else:
		stamina_bar.visible = false
		h2o_bar.visible = false

func _process(delta):
	if Input.is_action_just_pressed("exit_suit") and has_suit:
		exit_suit()
	_handle_rotation(delta)
	if has_suit:
		_process_with_suit(delta)
	else:
		_process_without_suit(delta)

func _handle_rotation(delta):
	rotation_y = lerp_angle(rotation_y, target_rotation_y, delta * SMOOTH_ROTATION_SPEED)
	rotation.y = rotation_y
	rotation_x = clamp(rotation_x, -MAX_VERTICAL_ANGLE, MAX_VERTICAL_ANGLE)
	camera_pivot.rotation_degrees.x = rotation_x

func _process_without_suit(delta):
	handle_object_interactions(delta)
	update_movement(delta)
	update_h2o(delta)
	update_stamina(delta)
	apply_camera_shake(delta)
	check_suit_pickup()
	_hide_all_ui()
	handle_water_physics_without_suit(delta)
	if h2o <= 0:
		restart_scene()

func _process_with_suit(delta):
	handle_object_interactions(delta)
	update_movement(delta)
	update_stamina(delta)
	update_h2o(delta)
	update_oxygen_tank_interaction(delta)
	handle_water_physics(delta)
	_initialize_bars()
	handle_fear_mechanics(delta)
	handle_fear_death(delta)
	_show_all_ui()
	
func _input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		_handle_mouse_motion(event)
	if event is InputEventKey and event.pressed and Input.is_action_pressed("exit"):
		_toggle_mouse_mode()
	if event.is_action_pressed("attack"):
		attack()
	if event is InputEventMouseButton and held_object:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			follow_distance = max(follow_distance - zoom_speed, min_distance)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			follow_distance = min(follow_distance + zoom_speed, max_distance)
			
func _handle_mouse_motion(event: InputEventMouseMotion):
	target_rotation_y -= event.relative.x * SENSITIVITY * 0.1
	rotation_x -= event.relative.y * SENSITIVITY * 5

func _toggle_mouse_mode():
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		
func get_input_direction() -> Vector3:
	var i = Vector3(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		0,
		Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward")
	)
	var w = transform.basis.x * i.x + transform.basis.z * i.z
	return w.normalized()	
	
func restart_scene():
	if get_tree() == null:
		print("Error: Scene tree is null. Cannot restart scene.")
		return
	show_notification("H2O Depleted! Restarting...", 2.0)
	get_tree().reload_current_scene()
	
#endregion

#region ui

func _hide_all_ui():
	stamina_bar.visible = false
	h2o_bar.visible = false
	label_3d.visible = false
	fear_sprite.visible = false
	mask.visible = false
	Pro3.visible = false
	Pro2.visible = false
	Pro1.visible = false
	icon2.visible = false
	icon.visible = false
	NotificationLabel.visible = false
	darken_screen.visible = false
	darken_screen.modulate.a = 0.0

func _show_all_ui():
	stamina_bar.visible = true
	h2o_bar.visible = true
	fear_sprite.visible = true
	Pro3.visible = true
	Pro2.visible = true
	Pro1.visible = true
	icon2.visible = true
	mask.visible = true
	icon.visible = true
	NotificationLabel.visible = true
	darken_screen.visible = true
	
func _initialize_bars():
	stamina_bar.max_value = MAX_STAMINA
	stamina_bar.value = stamina
	stamina_bar.modulate.a = 1.0  

	h2o_bar.max_value = MAX_H2O
	h2o_bar.value = h2o
	h2o_bar.modulate.a = 1.0  

	stamina_bar.visible = true
	h2o_bar.visible = true
	
#endregion

#region controler

func handle_object_interactions(delta):
	last_interaction_time += delta
	if Input.is_action_just_pressed("interact") and last_interaction_time >= interaction_cooldown:
		last_interaction_time = 0.0
		if held_object:
			drop_held_object()
			holding_object_time = 0.0
		else:
			_try_pick_object()
	if Input.is_action_just_pressed("use_item"):
		_try_add_to_inventory()
	if Input.is_action_just_pressed("Q"):
		select_next_inventory_item()
	if Input.is_action_just_pressed("interact"):
		if selected_item:
			drop_selected_object()
	update_label_position()
	if held_object and held_object is RigidBody3D:
		follow_player_with_object()
		holding_object_time += delta
		apply_stamina_penalty_for_holding(delta)
		if stamina <= 0:
			drop_held_object()
			holding_object_time = 0.0
	else:
		drop_held_object()
		
#endregion

#region inv

func _try_pick_object():
	if interact_ray.is_colliding():
		var collider = interact_ray.get_collider()
		if collider is RigidBody3D and stamina > 10:
			set_held_object(collider)
			holding_object_time = 0.0

func _try_add_to_inventory():
	if not has_suit:
		show_notification("Inventory not available without suit!", 2.0)
		return
	if interact_ray.is_colliding():
		var collider = interact_ray.get_collider()
		if collider is RigidBody3D and not collider in inventory and len(inventory) < MAX_INVENTORY_SIZE:
			add_to_inventory(collider)

func add_to_inventory(obj: RigidBody3D):
	if inventory.size() >= MAX_INVENTORY_SIZE:
		show_notification("Inventory is full!", 2.0)
		return
	if obj == held_object:
		drop_held_object()
	inventory.append(obj)
	obj.visible = false
	obj.get_parent().remove_child(obj)
	show_notification(obj.name + " added to inventory", 2.0)

func select_next_inventory_item():
	if not has_suit:
		show_notification("Inventory not available without suit!", 2.0)
		return
	if inventory.size() == 0:
		show_notification("Inventory is empty!", 2.0)
		return
	if selected_item:
		selected_item.visible = false
	selected_item_index = (selected_item_index + 1) % inventory.size()
	selected_item = inventory[selected_item_index]
	show_notification("Selected: " + selected_item.name, 2.0)

func drop_selected_object():
	if not has_suit:
		show_notification("Inventory not available without suit!", 2.0)
		return
	if not selected_item:
		show_notification("No item to drop!", 2.0)
		return
	selected_item.visible = true
	get_tree().get_root().add_child(selected_item)
	selected_item.global_transform.origin = camera.global_transform.origin + camera.global_transform.basis.z * -2.0
	if selected_item is RigidBody3D:
		selected_item.freeze = false
		selected_item.linear_velocity = Vector3.ZERO
		selected_item.angular_velocity = Vector3.ZERO
	set_held_object(selected_item)
	inventory.erase(selected_item)
	selected_item = null
	selected_item_index = -1
	show_notification("Dropped object", 2.0)
			
#endregion

#region movement
	
# Determines the character's speed based on running state and stamina
func determine_character_speed() -> float:
	if is_running and stamina > 0:
		return WALK_SPEED * RUN_SPEED_MULTIPLIER
	elif stamina == 0:
		return LOW_STAMINA_SPEED
	return WALK_SPEED

# Updates the character's movement every frame
func update_movement(delta: float) -> void:
	var movement_vector = get_input_direction()
	var target_speed = calculate_target_movement_speed(movement_vector)
	target_speed = apply_running_speed_modifier(target_speed)
	var current_speed = velocity.length()
	var adjusted_speed = adjust_movement_speed(current_speed, target_speed, delta)
	
	# Добавляем скольжение при остановке с учетом скорости бега
	if movement_vector.length() > 0:
		movement_vector = movement_vector.normalized() * adjusted_speed
	else:
		# Динамический коэффициент трения, зависящий от скорости
		var base_friction = 15.0
		# Уменьшаем трение при высокой скорости для большего скольжения во время бега
		var speed_factor = clamp(current_speed / (WALK_SPEED * RUN_SPEED_MULTIPLIER), 0.0, 1.0)
		var slide_friction = base_friction * (1.0 - speed_factor * 0.5)  # Уменьшаем трение до 50% при максимальной скорости
		var current_horizontal_speed = Vector2(velocity.x, velocity.z).length()
		var new_speed = max(0, current_horizontal_speed - slide_friction * delta)
		if current_horizontal_speed > 0:
			var slide_direction = Vector2(velocity.x, velocity.z).normalized()
			movement_vector = Vector3(slide_direction.x, 0, slide_direction.y) * new_speed
	
	update_character_velocity(movement_vector, delta)
	apply_character_turn_tilt(delta)

	if is_on_floor():
		handle_character_jump(delta)

	apply_gravity_force(delta)
	move_and_slide()

# Calculates the target speed based on movement input
func calculate_target_movement_speed(movement_vector: Vector3) -> float:
	return determine_character_speed() * movement_vector.length()

# Adjusts the current speed towards the target speed
func adjust_movement_speed(current_speed: float, target_speed: float, delta: float) -> float:
	var speed_difference = target_speed - current_speed
	var acceleration = 20.0 if speed_difference > 0 else 10.0
	return current_speed + sign(speed_difference) * min(abs(speed_difference), acceleration * delta)

# Applies a speed multiplier when running
func apply_running_speed_modifier(target_speed: float) -> float:
	if can_run and Input.is_action_pressed("run") and stamina > 0:
		return target_speed * RUN_SPEED_MULTIPLIER
	return target_speed

# Updates the character's velocity based on movement input
func update_character_velocity(movement_vector: Vector3, delta: float) -> void:
	velocity.x = movement_vector.x
	velocity.z = movement_vector.z
	if not is_on_floor():
		velocity.x = lerp(velocity.x, movement_vector.x, delta * AIR_CONTROL)
		velocity.z = lerp(velocity.z, movement_vector.z, delta * AIR_CONTROL)

# Applies gravity to the character when not on the floor
func apply_gravity_force(delta: float) -> void:
	if not is_on_floor():
		velocity.y = max(velocity.y + GRAVITY * delta, TERMINAL_VELOCITY)

# Handles the character's jump action
func handle_character_jump(delta: float) -> void:
	if Input.is_action_just_pressed("jump") and stamina >= JUMP_STAMINA_COST:
		velocity.y = JUMP_FORCE
		decrease_stamina(JUMP_STAMINA_COST)

# Applies a camera tilt effect based on turning input
func apply_character_turn_tilt(delta: float) -> void:
	var input_direction = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var target_tilt_angle = -input_direction.x * max_tilt
	tilt_angle = lerp(tilt_angle, target_tilt_angle, delta * tilt_speed)
	$CameraPivot.rotation_degrees.z = tilt_angle
	
#endregion

#region stamina


func apply_stamina_penalty_for_holding(delta):
	#var mass = held_object.mass * mass
	var drain_factor = (holding_object_time / 10.0) 
	if holding_object_time >= 1.0:
		decrease_stamina(10.0 * drain_factor * delta)
		
func update_stamina(delta):
	var in_water = is_in_water()
	var mv = get_input_direction()
	var moving = mv.length() > 0
	if can_run and stamina > 0 and Input.is_action_pressed("run") and moving and not in_water:
		decrease_stamina(STAMINA_RUN_DEPLETION_RATE * delta)
		stamina_recovery_timer = 0.0
		if stamina <= 0:
			can_run = false
	else:
		stamina_recovery_timer += delta
		if stamina_recovery_timer >= STAMINA_RECOVERY_DELAY:
			var rate = STAMINA_RECOVERY_RATE * delta * (1 - stamina / MAX_STAMINA)
			increase_stamina(rate)
			if stamina > 0:
				can_run = true
	if stamina <= 0 and moving:
		decrease_stamina(STAMINA_RUN_DEPLETION_RATE * delta * 0.5)

func decrease_stamina(amount: float):
	stamina = clamp(stamina - amount, 0, MAX_STAMINA)

func increase_stamina(amount: float):
	stamina = clamp(stamina + amount, 0, MAX_STAMINA)
	
#endregion

#region water

func is_in_water() -> bool:
	if not is_instance_valid(self) or not get_tree():
		return false
	var water_areas = get_tree().get_nodes_in_group("water_area")
	var result = false
	for area in water_areas:
		if area.overlaps_body(self):
			result = true
			break
	print("Is in water: ", result, " | Position: ", global_transform.origin)
	return result

func handle_water_physics(delta: float) -> void:
	if is_in_water():
		apply_buoyancy_and_drag_scuba(delta)
		handle_swimming_input_scuba(delta)
	else:
	# When exiting water, dampen upward velocity to prevent "flying"
		if velocity.y > 0:
			velocity.y = lerp(velocity.y, 0.0, delta * 5.0)  # Smoothly reduce upward speed
	# Apply gravity unless in a suit with special behavior
		if not has_suit:  # Assuming you add this check
			velocity.y -= GRAVITY * delta
		else:
			# Suit behavior: no falling when not in water
			velocity.y = lerp(velocity.y, 0.0, delta * 2.0)  # Hover or slow descent

	velocity = velocity.limit_length(50.0)

func apply_buoyancy_and_drag_scuba(delta: float) -> void:
	var buoyancy_force = -GRAVITY * WATER_DENSITY * PLAYER_VOLUME * BUOYANCY_FACTOR
	velocity.y = lerp(velocity.y, buoyancy_force, delta * 2.0)

	var drag_horizontal = 1.0
	var drag_vertical = 0.7
	velocity.x = lerp(velocity.x, 0.0, drag_horizontal * delta)
	velocity.z = lerp(velocity.z, 0.0, drag_horizontal * delta)
	velocity.y = lerp(velocity.y, 0.0, drag_vertical * delta * 0.5)

func handle_swimming_input_scuba(delta: float) -> void:
	var input_direction = get_input_direction()
	var speed = SWIM_SPEED
	
	if h2o < OXYGEN_CRITICAL_LEVEL:
		speed *= OXYGEN_LOW_MOVEMENT_PENALTY
	
	if input_direction != Vector3.ZERO:
		input_direction = input_direction.normalized()
		velocity.x = lerp(velocity.x, input_direction.x * speed, delta * 2.0)
		velocity.z = lerp(velocity.z, input_direction.z * speed, delta * 2.0)
		decrease_stamina(0.5 * delta)
	else:
		velocity.x = lerp(velocity.x, 0.0, delta * 1.5)
		velocity.z = lerp(velocity.z, 0.0, delta * 1.5)
	
	if Input.is_action_pressed("jump") and stamina > 1:
		velocity.y = lerp(velocity.y, SWIM_UP_SPEED, delta * 2.0)
		decrease_stamina(2.0 * delta)
	elif Input.is_action_pressed("crouch") and stamina > 1:
		velocity.y = lerp(velocity.y, -SWIM_DOWN_SPEED, delta * 2.0)
		decrease_stamina(STAMINA_DOWN_COST * delta)
	else:
		if velocity.y < MIN_VERTICAL_SPEED:
			velocity.y = MIN_VERTICAL_SPEED

func update_h2o(delta: float) -> void:
	is_underwater = is_in_water()
	if is_underwater:
		decrease_h2o(H2O_DEPLETION_RATE * delta)
		_handle_underwater_effects(delta)
	else:
		increase_h2o(H2O_RECOVERY_RATE * delta)
		darken_screen.modulate.a = lerp(darken_screen.modulate.a, 0.0, delta * 2.0)
		restart_timer = 0.0
	update_h2o_bar()

func _handle_underwater_effects(delta: float) -> void:
	if h2o <= MIN_H2O_THRESHOLD and not is_shaking:
		is_shaking = true
		shake_intensity = 0.2
		shake_timer = 2.0
		camera.fov = lerp(camera.fov, original_fov + 10, delta * 5.0)
	elif h2o > MIN_H2O_THRESHOLD and is_shaking:
		is_shaking = false
		shake_intensity = 0.0
		camera.fov = original_fov
	
	if h2o <= 0:
		darken_screen.modulate.a = lerp(darken_screen.modulate.a, DARKEN_MAX_ALPHA, delta * 2.0)
		restart_timer += delta
		if restart_timer >= RESTART_DELAY:
			show_notification("H2O Depleted! Restarting...", 2.0)
			restart_scene()

func decrease_h2o(amount: float) -> void:
	h2o = clamp(h2o - amount, 0, MAX_H2O)

func increase_h2o(amount: float) -> void:
	h2o = clamp(h2o + amount, 0, MAX_H2O)

func update_h2o_bar() -> void:
	h2o_bar.value = h2o

func update_oxygen_tank_interaction(delta: float) -> void:
	if not is_instance_valid(self) or not get_tree():
		return
	for tank in get_tree().get_nodes_in_group("oxygen_source"):
		if tank.global_transform.origin.distance_to(global_transform.origin) <= OXYGEN_INTERACTION_DISTANCE:
			increase_h2o(OXYGEN_REPLENISH_RATE * delta)
			return

func apply_camera_shake(delta: float) -> void:
	if is_shaking:
		var offset = Vector3(
			shake_randomizer.randf_range(-shake_intensity, shake_intensity),
			shake_randomizer.randf_range(-shake_intensity, shake_intensity),
			0
		)
		camera.global_transform.origin += offset * delta
		shake_intensity = lerp(shake_intensity, 0.0, delta * 3.0)
		shake_timer -= delta
		if shake_timer <= 0:
			is_shaking = false
			shake_intensity = 0.0
			camera.fov = original_fov
			
#endregion

#region dropheld

func set_held_object(body: RigidBody3D):
	held_object = body
	if body and body.has_node("MeshInstance3D"):
		var mesh_instance = body.get_node("MeshInstance3D")
		if mesh_instance.get_surface_override_material_count() == 0:
			@warning_ignore("confusable_local_usage")
			mesh_instance.set_surface_override_material(0, original_material)
		@warning_ignore("shadowed_variable", "unused_variable")
		var original_material = mesh_instance.get_surface_override_material(0)
		mesh_instance.set_surface_override_material(0, highlight_material)

func drop_held_object():
	if held_object and held_object.has_node("MeshInstance3D"):
		var mesh_instance = held_object.get_node("MeshInstance3D")
		if mesh_instance.get_surface_override_material_count() > 0:
			mesh_instance.set_surface_override_material(0, original_material)
	held_object = null
	original_material = null

func follow_player_with_object():
	if not is_instance_valid(held_object) or not held_object.is_inside_tree():
		held_object = null
		return
	
	var tp = camera.global_transform.origin + camera.global_basis * Vector3(0, 0, -follow_distance)
	var op = held_object.global_transform.origin
	held_object.linear_velocity = (tp - op) * follow_speed
	
	if held_object.global_position.distance_to(camera.global_position) > max_distance_from_camera:
		drop_held_object()
	elif drop_below_player and ground_ray.is_colliding() and ground_ray.get_collider() == held_object:
		drop_held_object()

func update_label_position():
	if held_object:
		update_label_for_held_object(held_object)
	else:
		update_label_for_nearby_object()

func update_label_for_held_object(obj):
	if not is_instance_valid(obj) or not obj.is_inside_tree():
		held_object = null
		label_3d.visible = false
		return
	
	var pos = obj.global_transform.origin
	var h = get_object_height(obj)
	var tp = pos + Vector3(0, h + 0.1, 0)
	label_3d.global_transform.origin = label_3d.global_transform.origin.lerp(tp, LERP_SPEED * get_process_delta_time())
	label_3d.text = "[R] Drop " + obj.name
	label_3d.visible = true

func update_label_for_nearby_object():
	if interact_ray.is_colliding():
		var c = interact_ray.get_collider()
		if c and c is RigidBody3D and c.is_inside_tree():
			var d = global_transform.origin.distance_to(c.global_transform.origin)
			if d <= INTERACTION_DISTANCE:
				var pos = c.global_transform.origin
				var h = get_object_height(c)
				var tp = pos + Vector3(0, h + 0.1, 0)
				label_3d.global_transform.origin = label_3d.global_transform.origin.lerp(
					tp, LERP_SPEED * get_process_delta_time()
				)
				label_3d.text = "[R] Interact with " + c.name
				label_3d.visible = true
				return
	label_3d.visible = false

func get_object_height(obj) -> float:
	var sn = obj.get_node_or_null("CollisionShape3D")
	if sn and sn.shape is BoxShape3D:
		return sn.shape.extents.y
	return 0.5
	
#endregion

#region suit

func exit_suit():
	if not has_suit:
		return  
	var suit_instance = suit_scene.instantiate()
	if not is_instance_valid(suit_instance):
		print("Error: Failed to instantiate suit scene!")
		return
	suit_instance.global_transform.origin = global_transform.origin
	get_tree().current_scene.add_child(suit_instance)
	has_suit = false
	if is_instance_valid(stamina_bar) and is_instance_valid(h2o_bar):
		stamina_bar.modulate.a = 0.0
		h2o_bar.modulate.a = 0.0
		stamina_bar.visible = false
		h2o_bar.visible = false
	else:
		print("Error: UI bars not found!")
	show_notification("Suit removed! Oxygen and stamina are now disabled.", 6.0)
	var sound_path = "res://voice/exit.mp3"  
	if is_instance_valid(AudioManager):
		AudioManager.play_sound(sound_path)
	else:
		print("AudioManager not found!")
		
func show_notification(text: String, delay: float = 2.0):
	NotificationLabel.text = text
	NotificationLabel.visible = true
	await get_tree().create_timer(delay).timeout
	NotificationLabel.visible = false


func check_suit_pickup():
	if interact_ray.is_colliding():
		var c = interact_ray.get_collider()
		if c and c.is_in_group(SUIT_GROUP):
			var d = global_transform.origin.distance_to(c.global_transform.origin)
			if d <= SUIT_PICKUP_DISTANCE:
				activate_suit(c)
				label_3d.text = c.name
				label_3d.visible = true
			else:
				label_3d.visible = false
		else:
			label_3d.visible = false

func activate_suit(suit: Node):
	has_suit = true
	suit.queue_free()
	show_notification("Suit activated! Oxygen and stamina are now available.", 6.0)
	stamina_bar.modulate.a = 1.0
	h2o_bar.modulate.a = 1.0
	stamina_bar.visible = true
	h2o_bar.visible = true
	var sound_path = "res://voice/voice.mp3"
	if AudioManager:
		AudioManager.play_sound(sound_path)
	else:
		print("AudioManager not found!")

func handle_water_physics_without_suit(delta):
	if is_in_water():
		update_current_flow()
		apply_water_physics(delta)
		var accelerated = H2O_DEPLETION_RATE * 3.0
		decrease_h2o(accelerated * delta)
		if h2o <= 0:
			restart_scene()

func update_current_flow():
	if global_transform.origin.x > 50:
		current_flow = Vector3(-1, 0, 0)
	elif global_transform.origin.z < -50:
		current_flow = Vector3(0, 0, 1)
	else:
		current_flow = Vector3(1, 0, 0)

func apply_water_physics(delta):
	var wg = GRAVITY * 0.2
	var wh = 1.5
	var wv = 1.2
	var suf = 13.0
	var id = Vector3.ZERO
	@warning_ignore("unused_variable")
	var imw = false
	if id != Vector3.ZERO:
		id = id.normalized()
		resisting_flow = true
		velocity.x = id.x * (WALK_SPEED * 0.5)
		velocity.z = id.z * (WALK_SPEED * 0.5)
	else:
		resisting_flow = false
	if Input.is_action_pressed("jump") and stamina > 1:
		velocity.y += suf * delta
		imw = true
		decrease_stamina(2)
	else:
		velocity.y -= wg * delta
	if not resisting_flow:
		velocity += current_flow * flow_strength * delta
		decrease_stamina(0.3 * delta)
	else:
		velocity += current_flow * flow_strength * 0.5 * delta
	velocity.x = lerp(velocity.x, 0.0, wh * delta)
	velocity.z = lerp(velocity.z, 0.0, wh * delta)
	velocity.y = lerp(velocity.y, 0.0, wv * delta)
	is_running = false
func handle_fear_mechanics(delta: float) -> void:
	if is_fear_max:
		fear_max_timer -= delta
		print("Fear max mode active. Timer: ", fear_max_timer)
		if fear_max_timer <= 0:
			is_fear_max = false  # Позволяем уровень страха снова уменьшаться
			print("Fear max mode deactivated.")
	else:
		if Rayscary3D.is_colliding():
			var collider = Rayscary3D.get_collider()
			print("Collider detected: ", collider.name)
			if collider is CharacterBody3D and collider.name in scary_list:
				# Найдём игрока через группу
				var player = get_tree().get_nodes_in_group("players")[0]  # Предполагается, что игрок в группе "players"
				
				if player:
					var distance = player.global_transform.origin.distance_to(collider.global_transform.origin)
					print("Distance to collider: ", distance)
					if distance <= 2.0:
						# Если объект находится в пределах 2 метров от игрока – увеличиваем страх быстрее
						fear_level = clamp(fear_level + INCREASE_RATE_NEAR * delta, 0, 100)
						print("Increased fear (near): ", fear_level)
					else:
						fear_level = clamp(fear_level + INCREASE_RATE_FAR * delta, 0, 100)
						print("Increased fear (far): ", fear_level)
				else:
					print("Player not found in group!")
			else:
				fear_level = clamp(fear_level - DECREASE_RATE_COLLIDING * delta, 0, 100)
				print("Decreased fear (non-scary collider): ", fear_level)
		else:
			fear_level = clamp(fear_level - DECREASE_RATE_NO_COLLISION * delta, 0, 100)
			print("No collision - decreased fear: ", fear_level)
		

		if fear_level >= 100 and not is_fear_max:
			is_fear_max = true
			fear_max_timer = fear_max_hold_time  
			print("Fear level reached 100. Entering fear max mode.")

	update_fear_sprite()




func update_fear_sprite():
	if fear_level < 25:
		fear_sprite.texture = fear_images[0]  # 0%
	elif fear_level < 50:
		fear_sprite.texture = fear_images[1]  # 25%
	elif fear_level < 75:
		fear_sprite.texture = fear_images[2]  # 50%
	elif fear_level < 100:
		fear_sprite.texture = fear_images[3]  # 75%
	else:
		fear_sprite.texture = fear_images[4]  # 100%

func handle_fear_death(delta):
	if fear_level >= 100:
		
		darken_screen.modulate.a = 1
		fear_death_timer += delta
		if fear_death_timer >= FEAR_DEATH_DELAY:
			restart_scene()
	else:
		fear_death_timer = 0.0
		darken_screen.modulate.a = lerp(darken_screen.modulate.a, 0.0, delta * 12) 
#endregion

#region attack
	
func attack():
	if not can_attack:
		return
	if held_object and held_object.is_in_group("spear"):
		check_for_breakable_objects()
		animate_spear_attack()
		print("Атака палкой!")
	else:
		print("Невозможно атаковать без палки.")
func animate_spear_attack():
	if not held_object:
		return
	var tween = create_tween()
	var start_position = held_object.position
	var direction = -transform.basis.z.normalized()
	var end_position = start_position + direction * 2.0
	tween.tween_property(held_object, "position", end_position, 0.2).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(held_object, "position", start_position, 0.2).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	tween.play()
	
func check_for_breakable_objects():
	if Rayscary3D.is_colliding():  
		var collider = Rayscary3D.get_collider()
		if collider and collider.is_in_group("breakable"):  
			collider.take_damage(1) 
#endregion

#region buy

func add_money(amount: int):
	money += amount
	print("Добавлено", amount, "монет. Новый баланс:", money)

func subtract_money(amount: int) -> bool:
	if money >= amount:
		money -= amount
		print("Потрачено", amount, "монет. Остаток:", money)
		return true  
	else:
		print("Недостаточно денег! Баланс:", money)
		return false 
#endregion
