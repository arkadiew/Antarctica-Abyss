extends CharacterBody3D

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
const RUN_MULTIPLIER = 2.0
const SENSITIVITY = 0.01
const GRAVITY = -9.8
const WALK_SPEED = 5.0
const RUN_SPEED_MULTIPLIER = 2.0
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
const FADE_OUT_SPEED = 1.0
const MIN_H2O_THRESHOLD = 10.0
const INTERACTION_DISTANCE = 3.0
const LERP_SPEED = 5.0
const RESTART_DELAY = 9.0
const DARKEN_MAX_ALPHA = 1.0
const OXYGEN_REPLENISH_RATE = 20.0
const OXYGEN_INTERACTION_DISTANCE = 3.0

@export var throw_force = 7.5
@export var follow_speed = 3.5
@export var follow_distance = 2.5
@export var max_distance_from_camera = 5.0
@export var drop_below_player = false
@export var ground_ray: RayCast3D
@export var swim_up_speed = 10.0
@export var climb_speed = 7.0

var has_suit = false
var global_delta = 0.0
var is_scuba_mode = true
var inventory = []
var selected_item: RigidBody3D = null
var selected_item_index = -1
var stamina = MAX_STAMINA
var h2o = MAX_H2O
var move_vector = Vector3.ZERO
var is_running = false
var bar_visible = false
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
var elapsed_time = 0.0
var jump_charge = 0.0
var max_jump_charge = 1.0
var jump_charge_rate = 0.5
# ---------------------
# Переменные для "шкалы страха"
# ---------------------
@onready var Rayscary3D: RayCast3D = $CameraPivot/Camera3D/Rayscary3D
var fear_level = 0.0
# Подставьте ваши реальные пути к иконкам:
var fear_images = [
	preload("res://utils/png_scary/fear_0.png"),    # 0%
	preload("res://utils/png_scary/fear_25.png"),   # 25%
	preload("res://utils/png_scary/fear_50.png"),   # 50%
	preload("res://utils/png_scary/fear_75.png"),   # 75%
	preload("res://utils/png_scary/fear_100.png")   # 100%
]
# Список «страшных» объектов (по имени):
var scary_list = ["fish", "shark", "barracuda"]

@onready var fear_sprite: Sprite2D = $CameraPivot/Camera3D/UI/FearSprite

@onready var AudioManager: Node = $AudioManager
@onready var camera: Camera3D = $CameraPivot/Camera3D
@onready var interact_ray: RayCast3D = $CameraPivot/Camera3D/InteractRay
@onready var stamina_bar: TextureProgressBar = $CameraPivot/Camera3D/UI/TextureProgressBar
@onready var stamina_label: Label = $CameraPivot/Camera3D/UI/stamina
@onready var h2o_bar: ProgressBar = $CameraPivot/Camera3D/UI/h2o2
@onready var h2o_label: Label = $CameraPivot/Camera3D/UI/h2o
@onready var label_3d: Label3D = $CameraPivot/Camera3D/Label3D
@onready var darken_screen: ColorRect = $CameraPivot/Camera3D/UI/DarkenScreen
@onready var NotificationLabel: Label = $CameraPivot/Camera3D/UI/NotificationLabel
@onready var camera_pivot: Node3D = $CameraPivot
var shake_randomizer = RandomNumberGenerator.new()
const SMOOTH_ROTATION_SPEED = 5.0

var rotation_y = 0.0
var rotation_x = 0.0
var target_rotation_y = 0.0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_initialize_bars()

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
	rotation_y = lerp_angle(rotation_y, target_rotation_y, delta * SMOOTH_ROTATION_SPEED)
	rotation.y = rotation_y
	rotation_x = clamp(rotation_x, -MAX_VERTICAL_ANGLE, MAX_VERTICAL_ANGLE)
	camera_pivot.rotation_degrees.x = rotation_x
	global_delta = delta
	if has_suit:
		_process_with_suit(delta)
		if not stamina_bar.visible or stamina_bar.modulate.a < 1.0:
			stamina_bar.visible = true
			stamina_bar.modulate.a = 1.0
		if not h2o_bar.visible or h2o_bar.modulate.a < 1.0:
			h2o_bar.visible = true
			h2o_bar.modulate.a = 1.0
	else:
		_process_without_suit(delta)

func _process_without_suit(delta):
	handle_object_interactions(delta)
	update_movement(delta)
	update_h2o(delta)
	update_stamina(delta)
	apply_camera_shake(delta)
	apply_inertia(delta)
	check_suit_pickup()
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

func apply_stamina_penalty_for_holding(delta):
	var mass = held_object.mass
	var drain_factor = (holding_object_time / 10.0) * mass
	if holding_object_time >= 1.0:
		decrease_stamina(10.0 * drain_factor * delta)

func update_movement(delta):
	var mv = get_input_direction()
	var ts = calculate_target_speed(mv)
	ts = apply_run_speed(ts)
	var cs = velocity.length()
	var adj = adjust_speed(cs, ts, delta)
	mv = mv.normalized() * adj if mv.length() > 0 else mv * max(0, cs - 10.0 * delta)
	update_velocity(mv, delta)
	if is_on_floor():
		handle_jump(delta)
	apply_gravity(delta)
	move_and_slide()

func calculate_target_speed(mv: Vector3):
	return determine_speed() * mv.length()

func adjust_speed(cs, ts, delta):
	var diff = ts - cs
	var accel = 20.0 if diff > 0 else 10.0
	return cs + sign(diff) * min(abs(diff), accel * delta)

func apply_run_speed(ts):
	if can_run and Input.is_action_pressed("run") and stamina > 0:
		return ts * RUN_SPEED_MULTIPLIER
	return ts

func update_velocity(mv, delta):
	velocity.x = mv.x
	velocity.z = mv.z
	if not is_on_floor():
		velocity.x = lerp(velocity.x, mv.x, delta * 2.0)
		velocity.z = lerp(velocity.z, mv.z, delta * 2.0)

func apply_gravity(delta):
	if not is_on_floor():
		velocity.y += GRAVITY * delta

func handle_jump(delta):
	if Input.is_action_just_pressed("jump") and stamina >= JUMP_STAMINA_COST:
		velocity.y = JUMP_FORCE
		decrease_stamina(JUMP_STAMINA_COST)

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

func decrease_stamina(amount):
	stamina = clamp(stamina - amount, 0, MAX_STAMINA)

func increase_stamina(amount):
	stamina = clamp(stamina + amount, 0, MAX_STAMINA)

func handle_water_physics(delta):
	if is_in_water():
		apply_buoyancy_and_drag_scuba(delta)
		handle_swimming_input_scuba(delta)
	else:
		if velocity.y < 0:
			velocity.y += GRAVITY * delta

func apply_buoyancy_and_drag_scuba(delta):
	var bf = -GRAVITY * WATER_DENSITY * PLAYER_VOLUME * BUOYANCY_FACTOR
	velocity.y = lerp(velocity.y, bf, delta * 2.0)
	var dh = 1.0
	var dv = 0.7
	velocity.x = lerp(velocity.x, 0.0, dh * delta)
	velocity.z = lerp(velocity.z, 0.0, dh * delta)
	velocity.y = lerp(velocity.y, 0.0, dv * delta * 0.5)

func handle_swimming_input_scuba(delta):
	var id = get_input_direction()
	var spd = SWIM_SPEED
	if h2o < OXYGEN_CRITICAL_LEVEL:
		spd *= OXYGEN_LOW_MOVEMENT_PENALTY
	if id != Vector3.ZERO:
		id = id.normalized()
		velocity.x = lerp(velocity.x, id.x * spd, delta * 2.0)
		velocity.z = lerp(velocity.z, id.z * spd, delta * 2.0)
		decrease_stamina(0.5 * delta)
	else:
		velocity.x = lerp(velocity.x, 0.0, delta * 1.5)
		velocity.z = lerp(velocity.z, 0.0, delta * 1.5)
	if Input.is_action_pressed("jump") and stamina > 1:
		velocity.y = lerp(velocity.y, SWIM_UP_SPEED, delta * 2.0)
		decrease_stamina(2 * delta)
	elif Input.is_action_pressed("crouch") and stamina > 1:
		velocity.y = lerp(velocity.y, -SWIM_DOWN_SPEED, delta * 2.0)
		decrease_stamina(STAMINA_DOWN_COST * delta)
	else:
		if velocity.y < MIN_VERTICAL_SPEED:
			velocity.y = MIN_VERTICAL_SPEED

func update_h2o(delta):
	is_underwater = is_in_water()
	if is_underwater:
		decrease_h2o(H2O_DEPLETION_RATE * delta)
		_handle_underwater_effects(delta)
	else:
		increase_h2o(H2O_RECOVERY_RATE * delta)
		darken_screen.modulate.a = lerp(darken_screen.modulate.a, 0.0, delta * 2)
		restart_timer = 0.0
	update_h2o_bar()

func _handle_underwater_effects(delta):
	if h2o <= MIN_H2O_THRESHOLD and not is_shaking:
		is_shaking = true
		shake_intensity = 0.2
		shake_timer = 2.0
		camera.fov = lerp(camera.fov, original_fov + 10, delta * 5)
	elif h2o > MIN_H2O_THRESHOLD and is_shaking:
		is_shaking = false
		shake_intensity = 0.0
		camera.fov = original_fov
	if h2o <= 0:
		darken_screen.modulate.a = lerp(darken_screen.modulate.a, DARKEN_MAX_ALPHA, delta * 2)
		restart_timer += delta
		if restart_timer >= RESTART_DELAY:
			restart_scene()

func decrease_h2o(amount):
	h2o = clamp(h2o - amount, 0, MAX_H2O)

func increase_h2o(amount):
	h2o = clamp(h2o + amount, 0, MAX_H2O)

func update_h2o_bar():
	h2o_bar.value = h2o

func update_oxygen_tank_interaction(delta):
	if not is_instance_valid(self) or not get_tree():
		return
	for tank in get_tree().get_nodes_in_group("oxygen_source"):
		if tank.global_transform.origin.distance_to(global_transform.origin) <= OXYGEN_INTERACTION_DISTANCE:
			increase_h2o(OXYGEN_REPLENISH_RATE * delta)
			return

func apply_camera_shake(delta):
	if is_shaking:
		var off = Vector3(
			shake_randomizer.randf_range(-shake_intensity, shake_intensity),
			shake_randomizer.randf_range(-shake_intensity, shake_intensity),
			0
		)
		camera.global_transform.origin += off * delta
		shake_intensity = lerp(shake_intensity, 0.0, delta * 3)
		shake_timer -= delta
		if shake_timer <= 0:
			is_shaking = false
			shake_intensity = 0.0
			camera.fov = original_fov

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

func _initialize_bars():
	stamina_bar.max_value = MAX_STAMINA
	stamina_bar.value = stamina
	stamina_bar.modulate.a = 0.0
	stamina_label.modulate.a = 0.0
	h2o_bar.max_value = MAX_H2O
	h2o_bar.value = h2o
	h2o_bar.modulate.a = 0.0
	h2o_label.modulate.a = 0.0
	stamina_bar.visible = false
	h2o_bar.visible = false
	bar_visible = false

func get_input_direction() -> Vector3:
	var i = Vector3(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		0,
		Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward")
	)
	var w = transform.basis.x * i.x + transform.basis.z * i.z
	return w.normalized()

func is_in_water() -> bool:
	if not is_instance_valid(self) or not get_tree():
		return false
	for area in get_tree().get_nodes_in_group("water_area"):
		if area.overlaps_body(self):
			return true
	return false

func determine_speed():
	var rf = 1.0 - (elapsed_time / 10.0) * 0.01
	if rf < 0.5:
		rf = 0.5
	var eff = WALK_SPEED * rf
	if is_running and stamina > 0:
		return eff * RUN_SPEED_MULTIPLIER
	elif stamina == 0:
		return LOW_STAMINA_SPEED * rf
	return eff

func apply_inertia(delta):
	if move_vector.length() == 0.0:
		velocity.x = lerp(velocity.x, 0.0, delta * 5.0)
		velocity.z = lerp(velocity.z, 0.0, delta * 5.0)

func set_held_object(body: RigidBody3D):
	held_object = body

func drop_held_object():
	held_object = null

func follow_player_with_object():
	var tp = camera.global_transform.origin + camera.global_basis * Vector3(0,0,-follow_distance)
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

func get_object_height(obj):
	var sn = obj.get_node_or_null("CollisionShape3D")
	if sn and sn.shape is BoxShape3D:
		return sn.shape.extents.y
	return 0.5

func restart_scene():
	if get_tree() == null:
		print("Error: Scene tree is null. Cannot restart scene.")
		return
	show_notification("H2O Depleted! Restarting...", 2.0)
	get_tree().reload_current_scene()

func show_notification(text, delay = 2.0):
	NotificationLabel.text = text
	NotificationLabel.visible = true
	await get_tree().create_timer(delay).timeout
	NotificationLabel.visible = false

func _input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		_handle_mouse_motion(event)
	if event is InputEventKey and event.pressed and Input.is_action_pressed("exit"):
		_toggle_mouse_mode()

func _handle_mouse_motion(event: InputEventMouseMotion):
	target_rotation_y -= event.relative.x * SENSITIVITY * 0.1
	rotation_x -= event.relative.y * SENSITIVITY * 5

func _toggle_mouse_mode():
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

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
	stamina_label.modulate.a = 1.0
	h2o_bar.modulate.a = 1.0
	h2o_label.modulate.a = 1.0
	stamina_bar.visible = true
	h2o_bar.visible = true
	bar_visible = true
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
# ------------------------------------------------------------------------------
# Новая функция и вспомогательные методы для обработки «уровня страха»
func handle_fear_mechanics(delta):
	if Rayscary3D.is_colliding():
		var collider = Rayscary3D.get_collider()
		if collider is CharacterBody3D and collider.name in scary_list:
			# Повышаем страх более плавно, например на 10 вместо 40
			fear_level = clamp(fear_level + 10.0 * delta, 0, 100)
		else:
			# Понижаем страх медленнее, например на 5 вместо 20
			fear_level = clamp(fear_level - 5.0 * delta, 0, 100)
	else:
		# Если луч никуда не попал, плавно снижаем ещё медленнее, к примеру 3
		fear_level = clamp(fear_level - 3.0 * delta, 0, 100)

	update_fear_sprite()


func update_fear_sprite():
	# Выбираем текстуру на основе текущего fear_level
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

	# При желании можно показывать/скрывать спрайт:
	if fear_level <= 0:
		fear_sprite.visible = false
	else:
		fear_sprite.visible = true
