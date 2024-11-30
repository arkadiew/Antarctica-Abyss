extends CharacterBody3D
# Константы
const MAX_INVENTORY_SIZE: int = 5

# Переменные инвентаря
var inventory: Array = []  # Массив для хранения объектов инвентаря
var selected_item_index: int = -1  # Индекс выбранного объекта (-1 - ничего не выбрано)
var selected_object: RigidBody3D = null  # Выбранный объект из инвентаря
# Константы

const RUN_MULTIPLIER: float = 2.0
const SENSITIVITY: float = 0.01
const GRAVITY: float = -9.8
const WALK_SPEED: float = 5.0
const RUN_SPEED_MULTIPLIER: float = 2.0
const LOW_STAMINA_SPEED: float = 1.0
const JUMP_FORCE: float = 3.0
const JUMP_STAMINA_COST: float = 10.0
const MAX_STAMINA: float = 100.0
const MAX_H2O: float = 100.0
const H2O_DEPLETION_RATE: float = 5.0  # Скорость расхода H2O под водой
const H2O_RECOVERY_RATE: float = 30.0  # Скорость восстановления H2O на поверхности
const STAMINA_RECOVERY_RATE: float = 30.0
const STAMINA_RUN_DEPLETION_RATE: float = 20.0
const STAMINA_RECOVERY_DELAY: float = 3.5
const FADE_OUT_SPEED: float = 1.0
const MIN_H2O_THRESHOLD: float = 10.0  # Порог активации эффекта
const INTERACTION_DISTANCE: float = 3.0
const LERP_SPEED: float = 5.0
const RESTART_DELAY: float = 9.0
const DARKEN_MAX_ALPHA: float = 1.0
const OXYGEN_REPLENISH_RATE: float = 20.0
const OXYGEN_INTERACTION_DISTANCE: float = 3.0

# Экспортируемые переменные
@export var throw_force: float = 7.5
@export var follow_speed: float = 3.5
@export var follow_distance: float = 2.5
@export var max_distance_from_camera: float = 5.0
@export var drop_below_player: bool = false
@export var ground_ray: RayCast3D
@export var swim_up_speed: float = 10.0
@export var climb_speed: float = 7.0

# Переменные состояния
var stamina: float = MAX_STAMINA
var h2o: float = MAX_H2O
var move_vector: Vector3 = Vector3.ZERO
var is_running: bool = false
var bar_visible: bool = false
var stamina_recovery_timer: float = 0.0
var can_run: bool = true
var holding_object_time: float = 0.0
var is_underwater: bool = false
var resisting_flow: bool = false
var restart_timer: float = 0.0
var held_object: RigidBody3D = null

# Переменные для дрожания камеры
var original_fov: float = 70.0
var is_shaking: bool = false
var shake_intensity: float = 0.0
var shake_timer: float = 0.0
var shake_randomizer: RandomNumberGenerator = RandomNumberGenerator.new()

# Переменные для течения
var current_flow: Vector3 = Vector3(1, 0, 0)
var flow_strength: float = 2.0

# Onready переменные
@onready var camera: Camera3D = $Camera3D
@onready var interact_ray: RayCast3D = $Camera3D/InteractRay
@onready var stamina_bar: ProgressBar = $Camera3D/ProgressBar
@onready var stamina_label: Label = $Camera3D/stamina
@onready var h2o_bar: ProgressBar = $Camera3D/h2o2
@onready var h2o_label: Label = $Camera3D/h2o
@onready var label_3d: Label3D = $Camera3D/Label3D
@onready var darken_screen: ColorRect = $Camera3D/DarkenScreen

@onready var NotificationLabel: Label =$Camera3D/NotificationLabel


# Инициализация
func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_initialize_bars()
	original_fov = camera.fov

# Инициализация полосок выносливости и H2O
func _initialize_bars() -> void:
	stamina_bar.max_value = MAX_STAMINA
	stamina_bar.value = stamina
	stamina_bar.modulate.a = 0.0
	stamina_label.modulate.a = 0.0

	h2o_bar.max_value = MAX_H2O
	h2o_bar.value = h2o
	h2o_bar.modulate.a = 0.0
	h2o_label.modulate.a = 0.0

# Главный цикл
func _process(delta: float) -> void:
	handle_object_interactions(delta)
	update_movement(delta)
	update_stamina(delta)
	update_stamina_bar(delta)
	handle_water_physics(delta)
	update_h2o(delta)
	update_oxygen_tank_interaction(delta)
	apply_camera_shake(delta)
	apply_drift(delta)

# Обработка взаимодействий с объектами
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
				
	if Input.is_action_just_pressed("use_item"):  # Добавление в инвентарь (E)
		if interact_ray.is_colliding():
			var collider = interact_ray.get_collider()
			if collider is RigidBody3D and not collider in inventory and len(inventory) < MAX_INVENTORY_SIZE:
				add_to_inventory(collider)
	elif Input.is_action_just_pressed("Q"):  # Выбор объекта (цикл по инвентарю)
		select_next_inventory_item()
	elif Input.is_action_just_pressed("interact"):  # Убрать выбранный объект (R)
		if selected_object:
			drop_selected_object()
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

# Обновление позиции метки
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

func get_object_height(obj):
	var shape_node = obj.get_node_or_null("CollisionShape3D")
	if shape_node and shape_node.shape is BoxShape3D:
		return shape_node.shape.extents.y
	return 0.5

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

# Обновление движения игрока
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

# Определение текущей скорости движения
func determine_speed() -> float:
	if is_running and stamina > 0:
		return WALK_SPEED * RUN_SPEED_MULTIPLIER
	elif stamina == 0:
		return LOW_STAMINA_SPEED
	return WALK_SPEED

# Обновление выносливости
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

func decrease_stamina(amount: float) -> void:
	stamina = clamp(stamina - amount, 0, MAX_STAMINA)

func increase_stamina(amount: float) -> void:
	stamina = clamp(stamina + amount, 0, MAX_STAMINA)

# Обновление полоски выносливости
func update_stamina_bar(delta: float) -> void:
	stamina_bar.value = stamina

	if stamina < MAX_STAMINA and not bar_visible:
		show_stamina_bar(delta)
	elif stamina >= MAX_STAMINA and bar_visible:
		hide_stamina_bar(delta)

func show_stamina_bar(delta: float) -> void:
	stamina_bar.modulate.a = lerp(stamina_bar.modulate.a, 1.0, delta * 5)
	stamina_label.modulate.a = stamina_bar.modulate.a

	if stamina_bar.modulate.a >= 0.99:
		stamina_bar.modulate.a = 1.0
		stamina_label.modulate.a = 1.0
		bar_visible = true

func hide_stamina_bar(delta: float) -> void:
	stamina_bar.modulate.a = lerp(stamina_bar.modulate.a, 0.0, delta * 5)
	stamina_label.modulate.a = stamina_bar.modulate.a

	if stamina_bar.modulate.a <= 0.01:
		stamina_bar.modulate.a = 0.0
		stamina_label.modulate.a = 0.0
		bar_visible = false

# Обработка движения мыши для камеры
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

# Получение направления движения из ввода
func get_input_direction() -> Vector3:
	# Собираем вектор ввода на основе нажатых клавиш
	var input_dir = Vector3(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		0,
		Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward")
	)

	# Преобразуем локальные координаты ввода в мировые
	var world_dir = (transform.basis.x * input_dir.x + transform.basis.z * input_dir.z)

	# Нормализуем, чтобы получить единичный вектор
	return world_dir.normalized()

# Обработка физики в воде
func handle_water_physics(delta: float) -> void:
	if is_in_water():
		update_current_flow()
		apply_water_physics(delta)
		apply_drift(delta)

func is_in_water() -> bool:
	for area in get_tree().get_nodes_in_group("water_area"):
		if area.overlaps_body(self):
			return true
	return false

func update_current_flow() -> void:
	# Пример изменения направления течения
	if global_transform.origin.x > 50:
		current_flow = Vector3(-1, 0, 0)  # Течение влево
	elif global_transform.origin.z < -50:
		current_flow = Vector3(0, 0, 1)  # Течение вперед
	else:
		current_flow = Vector3(1, 0, 0)  # Течение вправо

func apply_water_physics(delta: float) -> void:
	var water_gravity = GRAVITY * 0.2
	var water_drag_horizontal = 1.5
	var water_drag_vertical = 1.2
	var swim_up_force = 13.0
	var input_dir = Vector3.ZERO
	var is_moving_in_water = false


	# Если есть движение, игрок сопротивляется течению
	if input_dir != Vector3.ZERO:
		input_dir = input_dir.normalized()
		resisting_flow = true
		velocity.x = input_dir.x * (WALK_SPEED * 0.5)
		velocity.z = input_dir.z * (WALK_SPEED * 0.5)
	else:
		resisting_flow = false

	# Плавание вверх
	if Input.is_action_pressed("jump") and stamina > 1:
		velocity.y += swim_up_force * delta
		is_moving_in_water = true
		decrease_stamina(0.9)
	else:
		velocity.y -= water_gravity * delta

	# Применяем течение, если игрок не сопротивляется
	if not resisting_flow:
		velocity += current_flow * flow_strength * delta
		decrease_stamina(0.3 * delta)
	else:
		velocity += current_flow * flow_strength * 0.5 * delta

	# Применяем водное сопротивление
	velocity.x = lerp(velocity.x, 0.0, water_drag_horizontal * delta)
	velocity.z = lerp(velocity.z, 0.0, water_drag_horizontal * delta)
	velocity.y = lerp(velocity.y, 0.0, water_drag_vertical * delta)

	# Ограничиваем бег в воде
	is_running = false

func apply_drift(delta: float) -> void:
	if not resisting_flow:
		velocity += current_flow * (flow_strength * 0.5) * delta

# Обновление H2O
func update_h2o(delta: float) -> void:
	is_underwater = is_in_water()

	if is_underwater:
		decrease_h2o(H2O_DEPLETION_RATE * delta)

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
	else:
		increase_h2o(H2O_RECOVERY_RATE * delta)
		darken_screen.modulate.a = lerp(darken_screen.modulate.a, 0.0, delta * 2)
		restart_timer = 0.0

	update_h2o_bar()
	update_h2o_label_and_bar_visibility(delta)

func decrease_h2o(amount: float) -> void:
	h2o = clamp(h2o - amount, 0, MAX_H2O)

func increase_h2o(amount: float) -> void:
	h2o = clamp(h2o + amount, 0, MAX_H2O)

func update_h2o_bar() -> void:
	h2o_bar.value = h2o

func update_h2o_label_and_bar_visibility(delta: float) -> void:
	if is_underwater and h2o < MAX_H2O:
		h2o_bar.modulate.a = lerp(h2o_bar.modulate.a, 1.0, delta * 3)
		h2o_label.modulate.a = lerp(h2o_label.modulate.a, 1.0, delta * 3)
	else:
		h2o_bar.modulate.a = lerp(h2o_bar.modulate.a, 0.0, delta * 3)
		h2o_label.modulate.a = lerp(h2o_label.modulate.a, 0.0, delta * 3)

# Обновление взаимодействия с баллоном кислорода
func update_oxygen_tank_interaction(delta: float) -> void:
	if get_tree() == null:
		return
	for oxygen_tank in get_tree().get_nodes_in_group("oxygen_source"):
		if oxygen_tank.global_transform.origin.distance_to(global_transform.origin) <= OXYGEN_INTERACTION_DISTANCE:
			increase_h2o(OXYGEN_REPLENISH_RATE * delta)
			return

func restart_scene() -> void:
	get_tree().reload_current_scene()

# Применение дрожания камеры
func apply_camera_shake(delta: float) -> void:
	if is_shaking:
		var shake_offset = Vector3(
			shake_randomizer.randf_range(-shake_intensity, shake_intensity),
			shake_randomizer.randf_range(-shake_intensity, shake_intensity),
			0
		)
		camera.global_transform.origin += shake_offset * delta

		shake_intensity = lerp(shake_intensity, 0.0, delta * 3)
		shake_timer -= delta

		if shake_timer <= 0:
			is_shaking = false
			shake_intensity = 0.0
			camera.fov = original_fov
			
func add_to_inventory(object: RigidBody3D) -> void:
	inventory.append(object)
	object.visible = false  # Убираем объект из сцены
	NotificationLabel.text = object.name + " added to inventory"
	NotificationLabel.visible = true
func select_next_inventory_item() -> void:
	if len(inventory) == 0:
		return

	selected_item_index += 1
	if selected_item_index >= len(inventory):
		selected_item_index = 0

	if selected_object:
		selected_object.visible = false  # Скрываем предыдущий объект

	selected_object = inventory[selected_item_index]
	selected_object.visible = true  # Показываем выбранный объект

	NotificationLabel.text = "Selected: " + selected_object.name
	NotificationLabel.visible = true
func drop_selected_object() -> void:
	if selected_object:
		inventory.erase(selected_object)
		selected_object.visible = true

		selected_object = null
		selected_item_index = -1
		NotificationLabel.text = "Dropped object"
		NotificationLabel.visible = true
