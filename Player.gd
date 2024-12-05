extends CharacterBody3D
# Константы
const MAX_INVENTORY_SIZE: int = 5
var global_delta: float = 0.0
const OXYGEN_CONSUMPTION_RATE: float = 0.5   # Расход кислорода (H2O) в секунду
const OXYGEN_CRITICAL_LEVEL: float = 10.0    # Критический уровень кислорода
const OXYGEN_LOW_MOVEMENT_PENALTY: float = 0.5 # Замедление при низком запасе кислорода
var is_scuba_mode: bool = true  # Флаг, что игрок в акваланге
# Новые константы для режима акваланга и плавания
const WATER_DENSITY: float = 1.0        # Плотность воды (можно подбирать)
const PLAYER_VOLUME: float = 0.5        # Условный объём игрока
const BUOYANCY_FACTOR: float = 1.0       # Коэффициент плавучести
const SWIM_SPEED: float = 2.0            # Базовая скорость плавания в воде
const SWIM_UP_SPEED: float = 3.0         # Скорость всплытия при зажатии прыжка
const MIN_VERTICAL_SPEED: float = -0.5   # Минимальное опускание без действий
const SWIM_DOWN_SPEED: float = 3.0  # Скорость погружения при нажатии Ctrl
const STAMINA_DOWN_COST: float = 2.0 # Расход выносливости при активном погружении

# Переменные инвентаря
var inventory: Array = []
var selected_item: RigidBody3D = null
var selected_item_index: int = -1
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
var interaction_cooldown: float = 0.5
var last_interaction_time: float = 0.0
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
	global_delta = delta
	handle_object_interactions(delta)
	update_movement(delta)
	update_stamina(delta)
	update_stamina_bar(delta)
	handle_water_physics(delta)
	update_h2o(delta)
	update_oxygen_tank_interaction(delta)
	apply_camera_shake(delta)

	apply_inertia(delta)  # Применение скольжения
	handle_jump(delta)    # Обработка прыжков

# Обработка взаимодействий с объектами
func handle_object_interactions(delta: float) -> void:
	last_interaction_time += delta
	if Input.is_action_just_pressed("interact") and last_interaction_time >= interaction_cooldown:
		last_interaction_time = 0.0
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
		if selected_item:
			drop_selected_object()
	update_label_position()
	

	if held_object and held_object is RigidBody3D:
		follow_player_with_object()
		holding_object_time += delta
		var mass = held_object.mass
		var drain_factor = (holding_object_time / 10.0) * mass
		if holding_object_time >= 1.0:
			decrease_stamina(10.0 * drain_factor * delta)
		if stamina <= 0:
			drop_held_object()
			holding_object_time = 0.0
	else:
		drop_held_object()

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
		if collider and collider is RigidBody3D:
			if not collider.is_inside_tree():
				return  # Избегаем работы с объектом, не находящимся в дереве сцены

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

func update_movement(delta: float) -> void:
	move_vector = get_input_direction()
	
	# Плавное ускорение и замедление
	var target_speed = determine_speed() * move_vector.length()
	var current_speed = velocity.length()
	var speed_difference = target_speed - current_speed
	var acceleration = 20.0 if speed_difference > 0 else 10.0  # Ускорение и торможение
	var adjusted_speed = current_speed + sign(speed_difference) * min(abs(speed_difference), acceleration * delta)
	
	# Направление движения
	if move_vector.length() > 0:
		move_vector = move_vector.normalized() * adjusted_speed
	else:
		move_vector *= max(0, current_speed - 10.0 * delta)  # Замедление при отсутствии ввода

	velocity.x = move_vector.x
	velocity.z = move_vector.z

	# Управление в воздухе
	if not is_on_floor():
		velocity.x = lerp(velocity.x, move_vector.x, delta * 2.0)
		velocity.z = lerp(velocity.z, move_vector.z, delta * 2.0)
		velocity.y += GRAVITY * delta
	else:
		# Прыжок
		if Input.is_action_just_pressed("jump") and stamina >= JUMP_STAMINA_COST:
			velocity.y = JUMP_FORCE
			decrease_stamina(JUMP_STAMINA_COST)

	# Убедитесь, что мы вызываем метод без переназначения
	move_and_slide()

var jump_charge: float = 0.0
var max_jump_charge: float = 1.0
var jump_charge_rate: float = 0.5

func handle_jump(delta: float) -> void:
	if Input.is_action_pressed("jump") and is_on_floor():
		jump_charge = clamp(jump_charge + jump_charge_rate * delta, 0, max_jump_charge)
	elif Input.is_action_just_released("jump") and jump_charge > 0.0:
		velocity.y = JUMP_FORCE + jump_charge * JUMP_FORCE
		jump_charge = 0.0
		decrease_stamina(JUMP_STAMINA_COST)
func apply_inertia(delta: float) -> void:
	if move_vector.length() == 0.0:
		velocity.x = lerp(velocity.x,0.0, delta * 5.0)
		velocity.z = lerp(velocity.z, 0.0, delta * 5.0)
var elapsed_time: float = 0.0

func determine_speed() -> float:
	# Рассчёт фактора уменьшения скорости 
	# Допустим, каждые 10 секунд скорость уменьшается на 1%
	# через 100 секунд скорость уменьшится на 10%
	var reduction_factor = 1.0 - (elapsed_time / 10.0) * 0.01
	if reduction_factor < 0.5:
		reduction_factor = 0.5 # Минимальная скорость 50% от исходной

	var effective_walk_speed = WALK_SPEED * reduction_factor

	if is_running and stamina > 0:
		return effective_walk_speed * RUN_SPEED_MULTIPLIER
	elif stamina == 0:
		return LOW_STAMINA_SPEED * reduction_factor
	return effective_walk_speed



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
				increase_stamina(STAMINA_RECOVERY_RATE * delta * (1 - stamina / MAX_STAMINA))
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
	var sensitivity_factor = 0.1
	rotation.y -= event.relative.x * SENSITIVITY * sensitivity_factor
	rotation.x = clamp(rotation.x - event.relative.y * SENSITIVITY * sensitivity_factor, -1.5, 1.5)

	# Используем сохранённое значение delta
	global_transform.basis = global_transform.basis.slerp(Basis().rotated(Vector3(1, 0, 0), rotation.x).rotated(Vector3(0, 1, 0), rotation.y), global_delta * 5.0)

	

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
func is_in_water() -> bool:
	for area in get_tree().get_nodes_in_group("water_area"):
		if area.overlaps_body(self):
			return true
	return false

# Обработка физики под водой
func handle_water_physics(delta: float) -> void:
	if is_in_water():
		apply_buoyancy_and_drag_scuba(delta)
		handle_swimming_input_scuba(delta)
	else:
		# Если не в воде - просто гравитация
		if velocity.y < 0:
			velocity.y += GRAVITY * delta

func apply_buoyancy_and_drag_scuba(delta: float) -> void:
	# При акваланге плавучесть можно оставить стабильной, чтобы игрок не тонул резко
	var buoyant_force = -GRAVITY * WATER_DENSITY * PLAYER_VOLUME * BUOYANCY_FACTOR
	velocity.y = lerp(velocity.y, buoyant_force, delta * 2.0)

	# Сопротивление: под водой движение более плавное, но не столь «тяжёлое», как без акваланга
	var drag_horizontal = 1.0
	var drag_vertical = 0.7
	velocity.x = lerp(velocity.x, 0.0, drag_horizontal * delta)
	velocity.z = lerp(velocity.z, 0.0, drag_horizontal * delta)
	velocity.y = lerp(velocity.y, 0.0, drag_vertical * delta * 0.5)


func handle_swimming_input_scuba(delta: float) -> void:
	var input_dir = get_input_direction()
	var current_swim_speed = SWIM_SPEED
	# Если кислород низкий, уменьшаем максимальную скорость
	if h2o < OXYGEN_CRITICAL_LEVEL:
		current_swim_speed *= OXYGEN_LOW_MOVEMENT_PENALTY

	if input_dir != Vector3.ZERO:
		input_dir = input_dir.normalized()
		velocity.x = lerp(velocity.x, input_dir.x * current_swim_speed, delta * 2.0)
		velocity.z = lerp(velocity.z, input_dir.z * current_swim_speed, delta * 2.0)

		# Расходуем выносливость только при активном движении
		decrease_stamina(0.5 * delta)
	else:
		# Если нет ввода, скорость замедляется до нуля (см. drag)
		velocity.x = lerp(velocity.x, 0.0, delta * 1.5)
		velocity.z = lerp(velocity.z, 0.0, delta * 1.5)

	# Всплытие при нажатии прыжка — чуть быстрее, но расходует больше выносливости
	if Input.is_action_pressed("jump") and stamina > 1:
		velocity.y = lerp(velocity.y, SWIM_UP_SPEED, delta * 2.0)
		decrease_stamina(2 * delta)
	elif Input.is_action_pressed("crouch") and stamina > 1:
		velocity.y = lerp(velocity.y, -SWIM_DOWN_SPEED, delta * 2.0)
		decrease_stamina(STAMINA_DOWN_COST * delta)
	else:
		# Без всплытия — медленное опускание, но фактически компенсируется плавучестью
		if velocity.y < MIN_VERTICAL_SPEED:
			velocity.y = MIN_VERTICAL_SPEED
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
			
# Управление инвентарем
func add_to_inventory(object: RigidBody3D) -> void:
	if inventory.size() >= MAX_INVENTORY_SIZE:
		show_notification("Inventory is full!", 2.0)
		return
	if object == held_object:
		drop_held_object()  # Убираем из рук перед добавлением
	inventory.append(object)
	object.visible = false
	object.get_parent().remove_child(object)
	show_notification(object.name + " added to inventory", 2.0)

func select_next_inventory_item() -> void:
	if inventory.size() == 0:
		show_notification("Inventory is empty!", 2.0)
		return

	if selected_item:
		selected_item.visible = false

	selected_item_index = (selected_item_index + 1) % inventory.size()
	selected_item = inventory[selected_item_index]
	show_notification("Selected: " + selected_item.name, 2.0)

func drop_selected_object() -> void:
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

# Уведомления
func show_notification(text: String, delay: float = 2.0) -> void:
	NotificationLabel.text = text
	NotificationLabel.visible = true
	await get_tree().create_timer(delay).timeout
	NotificationLabel.visible = false
