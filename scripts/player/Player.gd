# This makes it a 3D character that moves with physics (the player!)
extends CharacterBody3D

#region Variables
# Debug mode for enabling/disabling logs
var debug_mode: bool = true
var log_timer: float = 0.0
var log_interval: float = 20.0  
var logged_events: Dictionary = {}  # Словарь для одноразовых логов
var paused = false
# Where to go when the game ends
const END_SCENE_PATH = "res://global_end.tscn"
# Camera height stuff
const DEFAULT_CAMERA_HEIGHT: float = 0.3  # Normal eye level
const SUIT_CAMERA_HEIGHT: float = -0.5   # Lower when wearing a suit
var current_camera_height: float = DEFAULT_CAMERA_HEIGHT  # Tracks current height
var can_move: bool = true
# Fear, movement, and physics constants
const INCREASE_RATE_NEAR: float = 10.0
const INCREASE_RATE_FAR: float = 5.0
const DECREASE_RATE_COLLIDING: float = 5.0
const DECREASE_RATE_NO_COLLISION: float = 3.0
const TERMINAL_VELOCITY: float = -40.0
const AIR_CONTROL: float = 3.0
const FEAR_DEATH_DELAY: float = 4.0
const SUIT_PICKUP_DISTANCE: float = 3.0
const SUIT_GROUP: String = "Submarine"
const MAX_INVENTORY_SIZE: int = 5
const OXYGEN_CONSUMPTION_RATE: float = 0.2
const OXYGEN_CRITICAL_LEVEL: float = 10.0
const OXYGEN_LOW_MOVEMENT_PENALTY: float = 0.5
const WATER_DENSITY: float = 1.0
const PLAYER_VOLUME: float = 0.5
const BUOYANCY_FACTOR: float = 1.0
const SWIM_SPEED: float = 9.0
const SWIM_UP_SPEED: float = 12.0
const MIN_VERTICAL_SPEED: float = -0.5
const SWIM_DOWN_SPEED: float = 19.0
const STAMINA_DOWN_COST: float = 2.0
const MAX_VERTICAL_ANGLE: float = 89.0
const RUN_SPEED_MULTIPLIER: float = 2.0
const SENSITIVITY: float = 0.01
const GRAVITY: float = -9.8
const WALK_SPEED: float = 3.0
const LOW_STAMINA_SPEED: float = 1.0
const JUMP_FORCE: float = 5.0
const JUMP_STAMINA_COST: float = 10.0
const MAX_STAMINA: float = 200.0
const MAX_O2: float = 100.0
const O2_DEPLETION_RATE: float = 1.0
const O2_RECOVERY_RATE: float = 30.0
const STAMINA_RECOVERY_RATE: float = 30.0
const STAMINA_RUN_DEPLETION_RATE: float = 20.0
const STAMINA_RECOVERY_DELAY: float = 3.5
const MIN_O2_THRESHOLD: float = 10.0
const INTERACTION_DISTANCE: float = 3.0
const LERP_SPEED: float = 5.0
const RESTART_DELAY: float = 9.0
const DARKEN_MAX_ALPHA: float = 1.0
const OXYGEN_REPLENISH_RATE: float = 20.0
const OXYGEN_INTERACTION_DISTANCE: float = 3.0
var can_activate_suit = false
var target_suit = null

# Inertia and object handling
const ACCELERATION: float = 15.0
const DECELERATION: float = 10.0
var last_suit_position = null
@export var throw_force: float = 7.5
@export var follow_speed: float = 3.5
@export var follow_distance: float = 2.5
@export var max_distance_from_camera: float = 5.0
@export var drop_below_player: bool = false
@export var ground_ray: RayCast3D
@export var swim_up_speed: float = 10.0
@export var climb_speed: float = 7.0
@export var suit_scene: PackedScene = preload("res://scenes/suit.tscn")

# Camera zoom and fear stuff
var zoom_speed: float = 1.0
var min_distance: float = 1.0
var max_distance: float = 3.0
var is_fear_max: bool = false
var fear_max_hold_time: float = 5.0
var fear_max_timer: float = 0.0
var fear_death_timer: float = 0.0
var has_suit: bool = false
var inventory: Array = []
var selected_item: RigidBody3D = null
var selected_item_index: int = -1
var stamina: float = MAX_STAMINA
var o2: float = MAX_O2
var repair_amount: float = 10.0
# Money system with animations
var money: int = 100:
	set(value):
		var change = value - money
		if change != 0:
			show_money_change(change)
		animate_money_change(money, value)
		money = value
		if debug_mode:
			log_message("Money updated: " + str(money) + ", Change: " + str(change), true)
@onready var money_l = get_node("CameraPivot/Camera3D/UI/Map/MONEY/Money")
@onready var money__ = get_node("CameraPivot/Camera3D/UI/Map/MONEY/Money?")
# UI and other nodes
var can_attack: bool = true
var is_running: bool = false
var stamina_recovery_timer: float = 0.0
var can_run: bool = true
var holding_object_time: float = 0.0
var is_underwater: bool = false
var resisting_flow: bool = false
var restart_timer: float = 0.0
var held_object: RigidBody3D = null
var interaction_cooldown: float = 0.5
var last_interaction_time: float = 0.0

var is_shaking: bool = false
var shake_intensity: float = 0.0
var shake_timer: float = 0.0
var current_flow: Vector3 = Vector3(1, 0, 0)
var flow_strength: float = 2.0
var jump_charge: float = 0.0
var max_jump_charge: float = 1.0
var jump_charge_rate: float = 0.5
var tilt_angle: float = 0.0
var max_tilt: float = 3.0
var tilt_speed: float = 8.0
var tilt_recovery: float = 6.0
var is_changing_scene: bool = false
@onready var Rayscary3D: RayCast3D = $CameraPivot/Camera3D/Rayscary3D

# Fear system
var fear_level: float = 0.0
var fear_images: Array = [
	preload("res://utils/img/png_scary/fear_0.png"),
	preload("res://utils/img/png_scary/fear_25.png"),
	preload("res://utils/img/png_scary/fear_50.png"),
	preload("res://utils/img/png_scary/fear_75.png"),
	preload("res://utils/img/png_scary/fear_100.png")
]
var scary_list: Array = ["fish", "Enemy"]

# Materials for highlighting objects
var original_material: Material = null
var highlight_material: Material = preload("res://utils/shader/highlight_material.tres")
var default_material: StandardMaterial3D = StandardMaterial3D.new()
@onready var map: Node = $CameraPivot/Camera3D/UI/Map
@onready var statistic: Node = $CameraPivot/Camera3D/UI/Statistic_Info
# UI elements
@onready var Menu: TextureRect = $CameraPivot/Camera3D/UI/Menu/Menu
@onready var fear_sprite: TextureRect = $CameraPivot/Camera3D/UI/FearSprite
@onready var Pro3: TextureRect = $CameraPivot/Camera3D/UI/Pro3
@onready var Pro2: TextureRect = $CameraPivot/Camera3D/UI/Pro2
@onready var Pro1: TextureRect = $CameraPivot/Camera3D/UI/Pro
@onready var icon2: TextureRect = $CameraPivot/Camera3D/UI/icon2
@onready var icon: TextureRect = $CameraPivot/Camera3D/UI/icon
@onready var AudioManager: Node = $AudioManager
@onready var AudioPlayer: Node = $AudioManager
@onready var camera: Camera3D = $CameraPivot/Camera3D
@onready var interact_ray: RayCast3D = $CameraPivot/Camera3D/InteractRay
@onready var stamina_bar: TextureProgressBar = $CameraPivot/Camera3D/UI/TextureProgressBar
@onready var o2_bar: TextureProgressBar = $CameraPivot/Camera3D/UI/o2
@onready var label: Label = $CameraPivot/Camera3D/UI/Menu/Label
@onready var label_3d: Label = $"CameraPivot/Camera3D/UI/Menu/Menu?la"
@onready var darken_screen: ColorRect = $CameraPivot/Camera3D/UI/DarkenScreen
@onready var NotificationLabel: Label = $CameraPivot/Camera3D/UI/NotificationLabel
@onready var mask: TextureRect = $CameraPivot/Camera3D/UI/mask
@onready var camera_pivot: Node3D = $CameraPivot
@onready var menu_exit: Control = $CameraPivot/Camera3D/UI/CanvasLayer/menu
var is_menu_open: bool = false
var shake_randomizer: RandomNumberGenerator = RandomNumberGenerator.new()
const SMOOTH_ROTATION_SPEED: float = 5.0
var rotation_y: float = 0.0
var rotation_x: float = 0.0
var target_rotation_y: float = 0.0
#endregion

# Helper function for debug logging with colored text
func log_message(message: String, is_one_time: bool = false, color: Color = Color.WHITE):
	if debug_mode:
		if is_one_time:
			if logged_events.has(message):
				return
			logged_events[message] = true
		print_rich("[color=" + color.to_html(false) + "]" + message + "[/color]")
	else:
		# Always print debug button messages in green when debug_mode is off
		if message.begins_with("Button pressed"):
			print_rich("[color=" + Color.GREEN.to_html(false) + "]" + message + "[/color]")

#region Start
func _ready():
	menu_exit.visible = false
	log_message("Escape menu initialized and hidden", true)
			
	log_message("Player initializing...", true, Color.RED)
	# Check critical nodes
	if not camera:
		log_message("Error: Camera node is missing!", true)
		return
	if not stamina_bar or not o2_bar:
		log_message("Error: Stamina or O2 bar nodes are missing!", true)
		return
	if not AudioManager:
		log_message("Warning: AudioManager node is missing! Sound effects will not work.", true)
	if not map:
		log_message("Error: Map node is missing!", true)
	if not statistic:
		log_message("Error: Statistic node is missing!", true)
	if not interact_ray:
		log_message("Error: InteractRay node is missing! Interactions will not work.", true)
	
	# Initialize parameters
	current_camera_height = DEFAULT_CAMERA_HEIGHT
	camera.position.y = current_camera_height

	stamina_bar.max_value = MAX_STAMINA
	o2_bar.max_value = MAX_O2
	
	
	# Check constants
	if MAX_STAMINA <= 0 or MAX_O2 <= 0:
		log_message("Error: MAX_STAMINA or MAX_O2 must be positive!", true)
	
	# Initialize map
	if map:
		map.visible = false
		map.modulate.a = 0.0
		map.scale = Vector2(0.8, 0.8)
		map.rotation_degrees = 15.0
		log_message("Map initialized and hidden", true)
	if statistic:
		statistic.visible = false
		log_message("Statistic panel initialized and hidden", true)
	
	# Connect repairable signals
	var repairables = get_tree().get_nodes_in_group("repairable")
	log_message("Found " + str(repairables.size()) + " repairable objects", true)
	for repairable in repairables:
		if repairable.has_signal("money_awarded"):
			repairable.connect("money_awarded", Callable(self, "_on_money_awarded"))
		else:
			log_message("Warning: Repairable node " + repairable.name + " does not have money_awarded signal!", true)
	
	# Initialize UI
	money_l.text = str(money)
	Menu.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_update_ui_visibility()
	log_message("Player initialized successfully. Starting money: " + str(money), true)

func _on_money_awarded(amount: int):
	add_money(amount)
	log_message("Money awarded: " + str(amount), true)

func _process(delta):

	if is_changing_scene:
		log_message("Scene change in progress, skipping process", true)
		return
	# Smoothly adjust camera height
	if has_suit:
		max_tilt = 1.5
		tilt_speed = 4.0
		tilt_recovery = 3.0
		current_camera_height = lerp(current_camera_height, SUIT_CAMERA_HEIGHT, delta * LERP_SPEED)
	else:
		max_tilt = 3.0
		tilt_speed = 8.0
		tilt_recovery = 6.0
		current_camera_height = lerp(current_camera_height, DEFAULT_CAMERA_HEIGHT, delta * LERP_SPEED)
	camera_pivot.position.y = current_camera_height
	log_timer += delta
	if log_timer >= log_interval:
		log_message("Camera height: " + str(current_camera_height))
		log_timer = 0.0
	
	# Suit controls
	if Input.is_action_just_pressed("player_use_item"):
		activate_suit()
	if Input.is_action_just_pressed("player_exit_suit") and has_suit:
		exit_suit()
	_handle_rotation(delta)
	handle_object_interactions(delta)
	update_movement(delta)
	update_stamina(delta)
	update_o2(delta)
	update_label()
	update_oxygen_tank_interaction(delta)
	if has_suit:
		handle_fear_mechanics(delta)
		handle_fear_death(delta)
		_show_all_ui()
		handle_water_physics(delta)
	else:
		_hide_all_ui()
		handle_water_physics_without_suit(delta)
	apply_camera_shake(delta)
	if o2 <= 0 and not is_changing_scene:
		log_message("Oxygen depleted, changing scene", true)
		change_scene()

func _handle_rotation(delta):
	rotation_y = lerp_angle(rotation_y, target_rotation_y, delta * SMOOTH_ROTATION_SPEED)
	rotation.y = rotation_y
	rotation_x = clamp(rotation_x, -MAX_VERTICAL_ANGLE, MAX_VERTICAL_ANGLE)
	camera_pivot.rotation_degrees.x = rotation_x
	log_timer += delta
	if log_timer >= log_interval:
		log_message("Camera rotation: x=" + str(rotation_x) + ", y=" + str(rotation_y))
		log_timer = 0.0

func camera_check():
	if debug_mode == true:
		rotation_x = 90
		rotation_x = 0
		print("Camera X set to 90")
		rotation_y = 90
		rotation_y = 0
		print("Camera Y set to 90")
		print("Camera OK")
	else:
		print("Debug mode off")
		
func escape_menu():
	is_menu_open = !is_menu_open
	menu_exit.visible = is_menu_open
	get_tree().paused = is_menu_open
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE if is_menu_open else Input.MOUSE_MODE_CAPTURED)
	log_message("Escape menu " + ("opened" if is_menu_open else "closed"), true)
		
func _input(event):
	
	if Input.is_action_just_pressed("esc"):
		escape_menu()
		
	if not is_inside_tree() or is_changing_scene:
		log_message("Input blocked: is_changing_scene=" + str(is_changing_scene), true)
		return
	
	
	# Остальная логика для других событий
	if event is InputEventKey and event.pressed:
		if Input.is_action_just_pressed("player_interact"):
			log_message("Button pressed: player_interact (Interact)", false, Color.GREEN)
		if Input.is_action_just_pressed("player_use_item"):
			log_message("Button pressed: player_use_item (Use Item)", false, Color.GREEN)
		if Input.is_action_just_pressed("player_attack"):
			log_message("Button pressed: player_attack (Attack)", false, Color.GREEN)
		if Input.is_action_just_pressed("player_jump"):
			log_message("Button pressed: player_jump (Jump)", false, Color.GREEN)
		if Input.is_action_just_pressed("player_run"):
			log_message("Button pressed: player_run (Run)", false, Color.GREEN)
		if Input.is_action_just_pressed("ui_focus_next"):
			log_message("Button pressed: ui_focus_next (Open Tablet)", false, Color.GREEN)
		if Input.is_action_just_pressed("player_Q"):
			log_message("Button pressed: player_Q (Next Inventory Item)", false, Color.GREEN)
		if Input.is_action_just_pressed("player_exit_suit"):
			log_message("Button pressed: player_exit_suit (Exit Suit)", false, Color.GREEN)

	if event.is_action_pressed("ui_focus_next"):
		log_message("Opening tablet", true)
		open_tablet()
	elif event.is_action_released("ui_focus_next"):
		log_message("Closing tablet", true)
		close_tablet()
	if event.is_action_pressed("player_attack"):
		log_message("Player attack triggered", true)
		if interact_ray.is_colliding():
			var collider = interact_ray.get_collider()
			if collider and collider.has_method("repair"):
				if held_object and held_object.is_in_group("spanner") and can_attack:
					collider.repair(repair_amount)
					animate_spanner_repair()
					log_message("Repairing object " + collider.name + " with spanner", true)
				else:
					show_notification("It can only be fixed with spanner", 2.0)
			elif held_object and held_object.is_in_group("spear") and can_attack:
				if AudioManager:
					AudioManager.play_sound("res://sounds/player/claw_miss1.mp3")
				attack()
				log_message("Attacking with spear", true)
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		_handle_mouse_motion(event)
		log_message("Mouse motion: relative=" + str(event.relative), true)

	if event is InputEventMouseButton and held_object:
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			follow_distance = max(follow_distance - zoom_speed, min_distance)
			log_message("Zoom out, follow_distance=" + str(follow_distance), true)
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			follow_distance = min(follow_distance + zoom_speed, max_distance)
			log_message("Zoom in, follow_distance=" + str(follow_distance), true)

func _handle_mouse_motion(event: InputEventMouseMotion):
	target_rotation_y -= event.relative.x * SENSITIVITY * 0.1
	rotation_x -= event.relative.y * SENSITIVITY * 5

func set_can_move(state: bool) -> void:
	can_move = state
	log_message("Player movement " + ("enabled" if state else "disabled"), true)

func get_input_direction() -> Vector3:
	var i = Vector3(
		Input.get_action_strength("player_move_right") - Input.get_action_strength("player_move_left"),
		0,
		Input.get_action_strength("player_move_backward") - Input.get_action_strength("player_move_forward")
	)
	var w = transform.basis.x * i.x + transform.basis.z * i.z
	return w.normalized()

func change_scene():
	if is_changing_scene or not is_instance_valid(self) or not is_inside_tree():
		log_message("Error: Already changing scene or Player node is invalid!", true)
		return
	is_changing_scene = true
	darken_screen.visible = true
	var tween = create_tween()
	tween.tween_property(darken_screen, "modulate:a", 1.0, 1.0).set_ease(Tween.EASE_IN)
	await tween.finished
	var tree = get_tree()
	if tree && tree.root:
		log_message("Changing scene to: " + END_SCENE_PATH, true)
		tree.change_scene_to_file(END_SCENE_PATH)
		set_process(false)
	else:
		log_message("Error: Unable to access scene tree or root!", true)
#endregion

#region UI
func _update_ui_visibility():
	if has_suit:
		_show_all_ui()
	else:
		_hide_all_ui()

func _hide_all_ui():
	stamina_bar.visible = true
	o2_bar.visible = true
	fear_sprite.visible = false
	mask.visible = false
	Pro3.visible = true
	Pro2.visible = true
	Pro1.visible = true
	icon2.visible = true
	icon.visible = true
	darken_screen.visible = false
	darken_screen.modulate.a = 0.0
	log_message("Hiding UI elements (no suit)", true)

func _show_all_ui():
	stamina_bar.visible = true
	o2_bar.visible = true
	fear_sprite.visible = true
	Pro3.visible = true
	Pro2.visible = true
	Pro1.visible = true
	icon2.visible = true
	mask.visible = true
	icon.visible = true
	NotificationLabel.visible = true
	darken_screen.visible = true
	log_message("Showing all UI elements (suit equipped)", true)
#endregion

#region Controller
func handle_object_interactions(delta):
	last_interaction_time += delta
	if Input.is_action_just_pressed("player_interact") and last_interaction_time >= interaction_cooldown:
		last_interaction_time = 0.0
		if AudioManager:
			AudioManager.play_sound("res://sounds/inventory/wpn_select.mp3")
		if held_object:
			log_message("Dropping object: " + held_object.name, true)
			drop_held_object()
		else:
			log_message("Attempting to pick up object", true)
			_try_pick_object()
	if Input.is_action_just_pressed("player_use_item"):
		log_message("Attempting to add item to inventory", true)
		_try_add_to_inventory()
	if Input.is_action_just_pressed("player_Q"):
		select_next_inventory_item()
		if AudioManager:
			AudioManager.play_sound("res://sounds/inventory/wpn_moveselect.mp3")
		log_message("Selecting next inventory item", true)
	if Input.is_action_just_pressed("player_use_item") and selected_item:
		drop_selected_object()
		if AudioManager:
			AudioManager.play_sound("res://sounds/inventory/inventory.mp3")
		log_message("Dropping selected inventory item", true)
	if held_object:
		follow_player_with_object()
		apply_stamina_penalty_for_holding(delta)
		if stamina <= 0:
			log_message("Stamina depleted, dropping held object", true)
			drop_held_object()
	update_label_position()
#endregion

#region Inventory
func _try_pick_object():
	if interact_ray.is_colliding():
		var collider = interact_ray.get_collider()
		if collider is RigidBody3D and stamina > 10:
			set_held_object(collider)
			log_message("Trying to pick up object: " + collider.name, true)

func _try_add_to_inventory():
	if interact_ray.is_colliding():
		var collider = interact_ray.get_collider()
		if collider is RigidBody3D:
			if collider == held_object:
				show_notification("Cannot add held object to inventory! Drop it first.", 2.0)
				log_message("Cannot add held object to inventory", true)
				return
			if collider in inventory:
				show_notification("Item is already in inventory!", 2.0)
				log_message("Item already in inventory: " + collider.name, true)
				return
			if inventory.size() < MAX_INVENTORY_SIZE:
				add_to_inventory(collider)
				log_message("Adding item to inventory: " + collider.name, true)

func add_to_inventory(obj: RigidBody3D):
	inventory.append(obj)
	obj.visible = false
	if obj.get_parent():
		obj.get_parent().remove_child(obj)
	show_notification(obj.name + " added to inventory", 2.0)
	log_message("Added to inventory: " + obj.name, true)

func select_next_inventory_item() -> void:
	if inventory.is_empty():
		show_notification("Inventory is empty!", 2.0)
		selected_item_index = -1
		selected_item = null
		log_message("Inventory is empty", true)
		return
	if selected_item != null:
		selected_item.visible = false
	selected_item_index = (selected_item_index + 1) % inventory.size()
	selected_item = inventory[selected_item_index]
	show_notification("Selected: " + str(selected_item.name), 2.0)
	log_message("Selected inventory item: " + selected_item.name, true)

func drop_selected_object() -> void:
	if not selected_item or not is_instance_valid(selected_item):
		show_notification("No valid item selected to drop!", 2.0)
		log_message("No valid item selected to drop", true)
		return
	var original_name = selected_item.name
	selected_item.name = generate_unique_name(original_name)
	selected_item.visible = true
	var original_scale = selected_item.scale if selected_item is Node3D else Vector3(1, 1, 1)
	var container = get_node_or_null("/root/DroppedObjectsContainer")
	if not container:
		container = Node3D.new()
		container.name = "DroppedObjectsContainer"
		if get_tree() and get_tree().root:
			get_tree().root.add_child(container)
		else:
			log_message("Error: Cannot create DroppedObjectsContainer!", true)
			return
	container.add_child(selected_item)
	selected_item.global_transform.origin = camera.global_transform.origin + camera.global_transform.basis.z * -2.0 + Vector3(0, 0.5, 0)
	if selected_item is Node3D:
		selected_item.scale = original_scale
	if selected_item is RigidBody3D:
		selected_item.freeze = false
		selected_item.linear_velocity = Vector3.ZERO
		selected_item.angular_velocity = Vector3.ZERO
		selected_item.mass = max(selected_item.mass, 1.0)
	set_held_object(selected_item)
	inventory.erase(selected_item)
	selected_item = null
	selected_item_index = -1
	show_notification("Dropped " + original_name, 2.0)
	log_message("Dropped inventory item: " + original_name, true)

func generate_unique_name(base_name: String) -> String:
	var unique_name = base_name
	var counter = 1
	var container = get_node_or_null("/root/DroppedObjectsContainer")
	if container != null:
		while container.has_node(unique_name):
			unique_name = base_name + "_" + str(counter)
			counter += 1
	return unique_name
#endregion

#region Movement
func determine_character_speed() -> float:
	if is_running and stamina > 0:
		return WALK_SPEED * RUN_SPEED_MULTIPLIER
	elif stamina == 0:
		return LOW_STAMINA_SPEED
	return WALK_SPEED

func update_movement(delta: float) -> void:
	if not can_move or not is_inside_tree():
		log_message("Movement blocked: can_move=" + str(can_move) + ", is_inside_tree=" + str(is_inside_tree()), true)
		return
	log_timer += delta
	var input_vector = get_input_direction()
	var target_speed = determine_character_speed()
	if log_timer >= log_interval:
		log_message("Input vector: " + str(input_vector) + ", Target speed: " + str(target_speed))
		log_timer = 0.0
	if target_speed < 0:
		log_message("Error: Target speed is negative: " + str(target_speed), true)
		target_speed = WALK_SPEED
	var target_velocity = Vector3(input_vector.x * target_speed, velocity.y, input_vector.z * target_speed)
	if is_on_floor() and input_vector.length() > 0 and not is_running and AudioManager:
		if not AudioManager.is_playing("walk_sound"):
			AudioManager.play_sound_player("res://sounds/player/walk.mp3")
			log_message("Playing walk sound", true)
	elif AudioManager and AudioManager.is_playing("walk_sound"):
		AudioManager.stop_sound("walk_sound")
		log_message("Stopped walk sound", true)
	if is_on_floor() and is_running and AudioManager:
		if not AudioManager.is_playing("run_sound"):
			AudioManager.play_sound_player("res://sounds/player/sprint.mp3")
			log_message("Playing run sound", true)
	elif AudioManager and AudioManager.is_playing("run_sound"):
		AudioManager.stop_sound("run_sound")
		log_message("Stopped run sound", true)
	if input_vector.length() > 0:
		velocity.x = lerp(velocity.x, target_velocity.x, ACCELERATION * delta)
		velocity.z = lerp(velocity.z, target_velocity.z, ACCELERATION * delta)
	else:
		velocity.x = lerp(velocity.x, 0.0, DECELERATION * delta)
		velocity.z = lerp(velocity.z, 0.0, DECELERATION * delta)
	if not is_on_floor():
		velocity.x = lerp(velocity.x, target_velocity.x, AIR_CONTROL * delta)
		velocity.z = lerp(velocity.z, target_velocity.z, AIR_CONTROL * delta)
	if can_run and Input.is_action_pressed("player_run") and stamina > 0 and not is_in_water():
		is_running = true
		log_message("Running enabled: stamina=" + str(stamina), true)
	else:
		is_running = false
		if Input.is_action_pressed("player_run"):
			log_message("Running disabled: stamina=" + str(stamina) + ", in_water=" + str(is_in_water()), true)
	if is_on_floor():
		handle_character_jump(delta)
	else:
		apply_gravity_force(delta)
	apply_character_turn_tilt(delta)
	if velocity.length() > abs(TERMINAL_VELOCITY) * 2:
		log_message("Warning: Velocity is too high: " + str(velocity), true)
		velocity = velocity.normalized() * abs(TERMINAL_VELOCITY)
	move_and_slide()
	if log_timer >= log_interval:
		log_message("Current velocity: " + str(velocity))

func apply_gravity_force(delta: float) -> void:
	if not is_on_floor():
		velocity.y = max(velocity.y + GRAVITY * delta, TERMINAL_VELOCITY)
		log_message("Applying gravity, velocity.y=" + str(velocity.y), true)

func handle_character_jump(delta: float) -> void:
	if Input.is_action_just_pressed("player_jump") and stamina >= JUMP_STAMINA_COST:
		velocity.y = JUMP_FORCE
		decrease_stamina(JUMP_STAMINA_COST)
		log_message("Jumping, velocity.y=" + str(velocity.y) + ", stamina=" + str(stamina), true)

func apply_character_turn_tilt(delta: float) -> void:
	var input_direction = Input.get_vector("player_move_left", "player_move_right", "player_move_forward", "player_move_backward")
	var target_tilt_angle = -input_direction.x * max_tilt
	tilt_angle = lerp(tilt_angle, target_tilt_angle, delta * tilt_speed)
	$CameraPivot.rotation_degrees.z = tilt_angle
	log_timer += delta
	if log_timer >= log_interval:
		log_message("Applying tilt, angle=" + str(tilt_angle))
		log_timer = 0.0
#endregion

#region Stamina
func apply_stamina_penalty_for_holding(delta):
	var drain_factor = (holding_object_time / 10.0)
	if holding_object_time >= 1.0:
		decrease_stamina(10.0 * drain_factor * delta)
		log_message("Stamina penalty for holding object, stamina=" + str(stamina), true)

func update_stamina(delta):
	var in_water = is_in_water()
	var moving = get_input_direction().length() > 0
	if can_run and stamina > 0 and Input.is_action_pressed("player_run") and moving and not in_water:
		decrease_stamina(STAMINA_RUN_DEPLETION_RATE * delta)
		stamina_recovery_timer = STAMINA_RECOVERY_DELAY
		is_running = true
		log_message("Running, stamina decreased to: " + str(stamina), true)
	else:
		is_running = false
		stamina_recovery_timer -= delta
		if stamina_recovery_timer <= 0 and stamina < MAX_STAMINA:
			increase_stamina(STAMINA_RECOVERY_RATE * delta)
			can_run = true
			log_message("Recovering stamina, new value: " + str(stamina), true)
	stamina_bar.value = stamina

func decrease_stamina(amount: float):
	stamina = clamp(stamina - amount, 0, MAX_STAMINA)
	log_message("Stamina decreased by " + str(amount) + ", new value: " + str(stamina), true)

func increase_stamina(amount: float):
	stamina = clamp(stamina + amount, 0, MAX_STAMINA)
	log_message("Stamina increased by " + str(amount) + ", new value: " + str(stamina), true)
#endregion

#region Water
func is_in_no_water_effect_zone() -> bool:
	if not is_instance_valid(self) or not get_tree():
		log_message("Cannot check no water effect zone, invalid instance or tree", true)
		return false
	var no_water_zones = get_tree().get_nodes_in_group("no_water_effect_zone")
	for zone in no_water_zones:
		if zone is Area3D and zone.overlaps_body(self):
			log_message("Player in no water effect zone", true)
			return true
	return false

func is_camera_fully_submerged() -> bool:
	if not is_instance_valid(camera_pivot) or not get_tree():
		log_message("Cannot check camera submersion, invalid camera or tree", true)
		return false
	var water_areas = get_tree().get_nodes_in_group("water_area")
	for area in water_areas:
		if area is Area3D:
			var camera_pos = camera_pivot.global_transform.origin
			var shape = area.get_node("CollisionShape3D")
			if shape and shape.shape is BoxShape3D:
				var water_top = area.global_transform.origin.y + shape.shape.extents.y
				var water_bottom = area.global_transform.origin.y - shape.shape.extents.y
				if camera_pos.y < water_top and camera_pos.y > water_bottom:
					log_message("Camera fully submerged", true)
					return true
	return false

func is_in_water() -> bool:
	if is_in_no_water_effect_zone():
		log_message("Player in no water effect zone, not in water", true)
		return false
	if not is_instance_valid(self) or not get_tree():
		log_message("Cannot check water state, invalid instance or tree", true)
		return false
	var water_areas = get_tree().get_nodes_in_group("water_area")
	for area in water_areas:
		if area.overlaps_body(self):
			log_message("Player in water", true)
			return true
	return false

func handle_water_physics(delta: float) -> void:
	if not is_inside_tree() or not get_tree():
		log_message("Error: Cannot handle water physics, not in scene tree", true)
		return
	if is_in_water():
		is_underwater = true
		log_message("Player underwater, applying buoyancy and swimming physics", true)
		apply_buoyancy_and_drag_scuba(delta)
		handle_swimming_input_scuba(delta)
	else:
		is_underwater = false
		velocity.y = lerp(velocity.y, 0.0, delta * 2.0)
		log_message("Player out of water, resetting vertical velocity", true)
	velocity = velocity.limit_length(abs(TERMINAL_VELOCITY))
	log_timer += delta
	if log_timer >= log_interval:
		log_message("Water physics applied, velocity: " + str(velocity))
		log_timer = 0.0

func apply_buoyancy_and_drag_scuba(delta: float) -> void:
	var buoyancy_force = -GRAVITY * WATER_DENSITY * PLAYER_VOLUME * BUOYANCY_FACTOR
	velocity.y = lerp(velocity.y, buoyancy_force, delta * 2.0)
	var drag = 0.9 if resisting_flow else 0.7
	velocity.x = lerp(velocity.x, 0.0, drag * delta)
	velocity.z = lerp(velocity.z, 0.0, drag * delta)
	velocity.y = clamp(velocity.y, TERMINAL_VELOCITY, SWIM_UP_SPEED)
	log_timer += delta
	if log_timer >= log_interval:
		log_message("Applying buoyancy, velocity: " + str(velocity))
		log_timer = 0.0

func handle_swimming_input_scuba(delta: float) -> void:
	var input_direction = get_input_direction()
	var speed = SWIM_SPEED
	if o2 < OXYGEN_CRITICAL_LEVEL:
		speed *= OXYGEN_LOW_MOVEMENT_PENALTY
	var target_velocity = Vector3(input_direction.x * speed, velocity.y, input_direction.z * speed)
	if input_direction != Vector3.ZERO:
		velocity.x = lerp(velocity.x, target_velocity.x, ACCELERATION * delta * 0.5)
		velocity.z = lerp(velocity.z, target_velocity.z, ACCELERATION * delta * 0.5)
		decrease_stamina(0.5 * delta)
	else:
		velocity.x = lerp(velocity.x, 0.0, DECELERATION * delta * 0.5)
		velocity.z = lerp(velocity.z, 0.0, DECELERATION * delta * 0.5)
	if Input.is_action_pressed("player_jump") and stamina > 1:
		velocity.y = lerp(velocity.y, SWIM_UP_SPEED, delta * 2.0)
		decrease_stamina(2.0 * delta)
		log_message("Swimming up, stamina=" + str(stamina), true)
	elif Input.is_action_pressed("player_run") and stamina > 1:
		velocity.y = lerp(velocity.y, -SWIM_DOWN_SPEED, delta * 2.0)
		decrease_stamina(STAMINA_DOWN_COST * delta)
		log_message("Swimming down, stamina=" + str(stamina), true)
	else:
		if velocity.y < MIN_VERTICAL_SPEED:
			velocity.y = MIN_VERTICAL_SPEED
	log_timer += delta
	if log_timer >= log_interval:
		log_message("Swimming input applied, velocity: " + str(velocity))
		log_timer = 0.0

func update_o2(delta: float) -> void:
	if o2 <= 0:
		if not is_changing_scene:
			log_message("Oxygen depleted, waiting 2s before scene change", true)
			await get_tree().create_timer(2.0).timeout
			change_scene()
		return
	is_underwater = is_in_water()
	if is_underwater and AudioManager:
		if not AudioManager.is_playing("swim_sound"):
			AudioManager.play_sound_player("res://sounds/player/swim.mp3")
			log_message("Playing swim sound", true)
	elif not is_underwater and AudioManager and AudioManager.is_playing("swim_sound"):
		AudioManager.stop_sound("swim_sound")
		log_message("Stopped swim sound", true)
	if is_camera_fully_submerged() and has_suit:
		decrease_o2(OXYGEN_CONSUMPTION_RATE * 2.0 * delta)
		_handle_underwater_effects(delta)
		#log_message("Camera submerged, increased O2 consumption, o2=" + str(o2), true)
	elif is_underwater and has_suit:
		decrease_o2(OXYGEN_CONSUMPTION_RATE * delta)
		_handle_underwater_effects(delta)
		#log_message("Underwater, normal O2 consumption, o2=" + str(o2), true)
	elif not is_underwater:
		increase_o2(O2_RECOVERY_RATE * delta)
		darken_screen.modulate.a = lerp(darken_screen.modulate.a, 0.0, delta * 2.0)
		log_message("Out of water, recovering O2, o2=" + str(o2), true)
	update_o2_bar(delta)

func _handle_underwater_effects(delta: float) -> void:
	if o2 <= MIN_O2_THRESHOLD and not is_shaking:
		is_shaking = true
		shake_intensity = 0.2
		shake_timer = 2.0

		log_message("Low oxygen, starting camera shake", true)
	elif o2 > MIN_O2_THRESHOLD and is_shaking:
		is_shaking = false
		shake_intensity = 0.0

		log_message("Oxygen restored, stopping camera shake", true)
	if o2 <= 0:
		darken_screen.modulate.a = lerp(darken_screen.modulate.a, DARKEN_MAX_ALPHA, delta * 2.0)
		log_message("Zero oxygen, darkening screen", true)

func decrease_o2(amount: float) -> void:
	o2 = clamp(o2 - amount, 0, MAX_O2)
	log_message("O2 decreased by " + str(amount) + ", new value: " + str(o2), true)

func increase_o2(amount: float) -> void:
	o2 = clamp(o2 + amount, 0, MAX_O2)
	#log_message("O2 increased by " + str(amount) + ", new value: " + str(o2), true)

func update_o2_bar(delta: float) -> void:
	o2_bar.value = o2
	log_timer += delta
	if log_timer >= log_interval:
		log_message("O2 bar updated: " + str(o2))
		log_timer = 0.0

func update_oxygen_tank_interaction(delta: float) -> void:
	if not get_tree():
		log_message("Cannot check oxygen tanks, no scene tree", true)
		return
	for tank in get_tree().get_nodes_in_group("oxygen_source"):
		if tank.global_transform.origin.distance_to(global_transform.origin) <= OXYGEN_INTERACTION_DISTANCE:
			increase_o2(OXYGEN_REPLENISH_RATE * delta)
			log_message("Near oxygen tank, replenishing O2", true)
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
	
			log_message("Camera shake stopped", true)
		log_timer += delta
		if log_timer >= log_interval:
			log_message("Applying camera shake, intensity=" + str(shake_intensity))
			log_timer = 0.0

func handle_water_physics_without_suit(delta):
	if is_in_water():
		update_current_flow()
		apply_water_physics(delta)
		decrease_o2(O2_DEPLETION_RATE * 3.0 * delta)
		if o2 <= 0:
			log_message("Oxygen depleted without suit, changing scene", true)
			change_scene()
		log_message("In water without suit, O2=" + str(o2), true)
	else:
		velocity.y = max(velocity.y + GRAVITY * delta, TERMINAL_VELOCITY)
		log_message("Out of water without suit, applying gravity", true)

func update_current_flow():
	if global_transform.origin.x > 50:
		current_flow = Vector3(-1, 0, 0)
	elif global_transform.origin.z < -50:
		current_flow = Vector3(0, 0, 1)
	else:
		current_flow = Vector3(1, 0, 0)
	log_message("Updated water flow: " + str(current_flow), true)

func apply_water_physics(delta: float):
	var water_gravity = GRAVITY * 0.2
	var water_horizontal_damping = 1.5
	var water_vertical_damping = 1.2
	var swim_up_force = 13.0
	var input_direction = get_input_direction()
	if input_direction != Vector3.ZERO:
		input_direction = input_direction.normalized()
		resisting_flow = true
		velocity.x = lerp(velocity.x, input_direction.x * (WALK_SPEED * 0.5), ACCELERATION * delta)
		velocity.z = lerp(velocity.z, input_direction.z * (WALK_SPEED * 0.5), ACCELERATION * delta)
		log_message("Resisting water flow, velocity: " + str(velocity), true)
	else:
		resisting_flow = false
		velocity.x = lerp(velocity.x, 0.0, DECELERATION * delta)
		velocity.z = lerp(velocity.z, 0.0, DECELERATION * delta)
		log_message("Not resisting water flow", true)
	if Input.is_action_pressed("player_jump") and stamina > 1:
		velocity.y += swim_up_force * delta
		decrease_stamina(2)
		log_message("Swimming up without suit, stamina=" + str(stamina), true)
	else:
		velocity.y -= water_gravity * delta
	if not resisting_flow:
		velocity += current_flow * flow_strength * delta
		decrease_stamina(0.3 * delta)
	else:
		velocity += current_flow * flow_strength * 0.5 * delta
	velocity.x = lerp(velocity.x, 0.0, water_horizontal_damping * delta)
	velocity.z = lerp(velocity.z, 0.0, water_horizontal_damping * delta)
	velocity.y = lerp(velocity.y, 0.0, water_vertical_damping * delta)
	is_running = false
	log_timer += delta
	if log_timer >= log_interval:
		log_message("Water physics without suit applied, velocity: " + str(velocity))
		log_timer = 0.0
#endregion

#region Drop Held
func set_held_object(body: RigidBody3D):
	if not body or not is_instance_valid(body) or body in inventory:
		log_message("Error: Cannot pick up invalid or inventory item: " + (body.name if body else "null"), true)
		show_notification("Cannot pick up invalid or inventory item!", 2.0)
		return
	if held_object:
		drop_held_object()
	held_object = body
	log_message("Picked up object: " + body.name, true)
	if body.has_node("MeshInstance3D"):
		var mesh_instance = body.get_node("MeshInstance3D")
		if mesh_instance.get_surface_override_material_count() == 0:
			mesh_instance.set_surface_override_material(0, default_material)
		original_material = mesh_instance.get_surface_override_material(0)
		mesh_instance.set_surface_override_material(0, highlight_material)
		log_message("Applied highlight material to " + body.name, true)
	else:
		log_message("Warning: Held object " + body.name + " has no MeshInstance3D!", true)

func drop_held_object():
	if not held_object or not is_instance_valid(held_object):
		held_object = null
		log_message("No valid object to drop", true)
		return
	log_message("Dropping object: " + held_object.name, true)
	if held_object.has_node("MeshInstance3D"):
		var mesh_instance = held_object.get_node("MeshInstance3D")
		if mesh_instance.get_surface_override_material_count() > 0:
			mesh_instance.set_surface_override_material(0, original_material)
			log_message("Restored original material for " + held_object.name, true)
	held_object = null
	original_material = null

func follow_player_with_object():
	if not held_object or not is_instance_valid(held_object) or not held_object.is_inside_tree():
		held_object = null
		log_message("Held object invalid or not in scene, dropping", true)
		return
	var tp = camera.global_transform.origin + camera.global_basis * Vector3(0, 0, -follow_distance)
	var op = held_object.global_transform.origin
	held_object.linear_velocity = (tp - op) * follow_speed
	log_timer += 1
	if log_timer >= log_interval:
		log_message("Held object " + held_object.name + " following player at distance: " + str(follow_distance))
		log_timer = 0.0
	if held_object.global_position.distance_to(camera.global_position) > max_distance_from_camera:
		log_message("Object too far, dropping: " + held_object.name, true)
		drop_held_object()
	elif drop_below_player and ground_ray.is_colliding() and ground_ray.get_collider() == held_object:
		log_message("Object below player, dropping: " + held_object.name, true)
		drop_held_object()

func update_label_position():
	if held_object:
		update_label_for_held_object(held_object)
	else:
		update_label_for_nearby_object()

func update_label_for_held_object(object_being_held):
	if not is_instance_valid(object_being_held) or not object_being_held.is_inside_tree():
		held_object = null
		label_3d.visible = false
		Menu.visible = false
		log_message("Invalid held object, hiding label", true)
		return
	var object_position = object_being_held.global_transform.origin
	var object_height = get_object_height(object_being_held)
	var target_label_position = object_position + Vector3(0, 1, 0)
	Menu.visible = true
	label_3d.text = "Drop " + object_being_held.name
	label_3d.visible = true
	log_message("Showing label for held object: " + object_being_held.name, true)

func update_label_for_nearby_object():
	if interact_ray.is_colliding():
		var collider = interact_ray.get_collider()
		if collider and collider is RigidBody3D and collider.is_inside_tree():
			var distance_to_collider = global_transform.origin.distance_to(collider.global_transform.origin)
			if distance_to_collider <= INTERACTION_DISTANCE:
				var collider_position = collider.global_transform.origin
				var collider_height = get_object_height(collider)
				var target_label_position = collider_position + Vector3(0, 1, 0)
				Menu.visible = true
				label_3d.text = "Interact with " + collider.name
				label_3d.visible = true
				log_message("Showing label for nearby object: " + collider.name, true)
				return
	label_3d.visible = false
	Menu.visible = false
	log_message("No nearby objects, hiding label", true)

func get_object_height(object_to_measure) -> float:
	var shape_node = object_to_measure.get_node_or_null("CollisionShape3D")
	if shape_node and shape_node.shape is BoxShape3D:
		return shape_node.shape.extents.y
	log_message("Using default object height for " + object_to_measure.name, true)
	return 0.5
#endregion

#region Submarine
func update_label():
	if interact_ray.is_colliding():
		var collider = interact_ray.get_collider()
		if collider != null and collider.is_in_group("Interactable"):
			Menu.visible = true
			label_3d.visible = true
			label_3d.text = collider.name
			log_message("Showing interactable label: " + collider.name, true)

func exit_suit():
	if not has_suit:
		log_message("Cannot exit suit, no suit equipped", true)
		return
	var suit_instance = suit_scene.instantiate()
	if not is_instance_valid(suit_instance):
		log_message("Error: Failed to instantiate suit scene!", true)
		return
	suit_instance.global_transform.origin = global_transform.origin
	get_tree().current_scene.add_child(suit_instance)
	has_suit = false
	_update_ui_visibility()
	show_notification("Suit removed! Oxygen and stamina are now disabled.", 6.0)
	if AudioManager:
		AudioManager.play_sound("res://sounds/exit.mp3")
	current_camera_height = DEFAULT_CAMERA_HEIGHT
	camera.position.y = current_camera_height
	log_message("Suit exited, UI updated", true)

func show_notification(text: String, delay: float = 2.0):
	if not NotificationLabel or not is_instance_valid(NotificationLabel):
		log_message("Error: NotificationLabel is missing!", true)
		return
	if NotificationLabel.visible:
		log_message("Notification queued, waiting 0.5s", true)
		await get_tree().create_timer(0.5).timeout
	NotificationLabel.text = text
	NotificationLabel.visible = true
	log_message("Showing notification: " + text + " for " + str(delay) + " seconds", true)
	await get_tree().create_timer(delay).timeout
	if is_instance_valid(NotificationLabel):
		NotificationLabel.visible = false
		log_message("Notification hidden: " + text, true)

func _physics_process(delta):
	interact_ray.force_raycast_update()
	if interact_ray.is_colliding():
		var collider = interact_ray.get_collider()
		if collider != null and collider.is_in_group("suit_items"):
			can_activate_suit = true
			target_suit = collider
			log_message("Can activate suit, target: " + collider.name, true)
		else:
			can_activate_suit = false
			target_suit = null
			log_message("No suit in range", true)
	else:
		can_activate_suit = false
		target_suit = null
		log_message("No suit detected", true)

func activate_suit():
	if target_suit != null:
		last_suit_position = target_suit.global_transform.origin
		if last_suit_position != null:
			global_transform.origin = last_suit_position
		has_suit = true
		target_suit.queue_free()
		_update_ui_visibility()
		show_notification("Suit activated! Oxygen and stamina are now available.", 2.0)
		if AudioManager:
			AudioManager.play_sound("res://sounds/voice.mp3")
		current_camera_height = SUIT_CAMERA_HEIGHT
		camera_pivot.position.y = current_camera_height
		can_activate_suit = false
		target_suit = null
		log_message("Suit activated, UI updated", true)
	else:
		log_message("Failed to activate suit, no target", true)
#endregion

#region Fear
func handle_fear_mechanics(delta: float) -> void:
	if not Rayscary3D or not is_instance_valid(Rayscary3D):
		log_message("Error: Rayscary3D is missing!", true)
		return
	if is_fear_max:
		fear_max_timer -= delta
		if fear_max_timer <= 0:
			is_fear_max = false
			log_message("Fear max timer expired, resetting", true)
	else:
		var collider = Rayscary3D.get_collider() if Rayscary3D.is_colliding() else null
		if collider and is_instance_valid(collider) and collider is CharacterBody3D and collider.name in scary_list:
			var distance = global_transform.origin.distance_to(collider.global_transform.origin)
			var rate = INCREASE_RATE_NEAR if distance <= 2.0 else INCREASE_RATE_FAR
			fear_level = clamp(fear_level + rate * delta, 0, 100)
			log_message("Increasing fear near " + collider.name + ", fear_level=" + str(fear_level), true)
		else:
			var decrease_rate = DECREASE_RATE_COLLIDING if collider else DECREASE_RATE_NO_COLLISION
			fear_level = clamp(fear_level - decrease_rate * delta, 0, 100)
			log_message("Decreasing fear, fear_level=" + str(fear_level), true)
		if fear_level < 0 or fear_level > 100:
			log_message("Error: Fear level out of bounds: " + str(fear_level), true)
			fear_level = clamp(fear_level, 0, 100)
	update_fear_sprite()

func update_fear_sprite():
	if fear_level < 25:
		fear_sprite.texture = fear_images[0]
	elif fear_level < 50:
		fear_sprite.texture = fear_images[1]
	elif fear_level < 75:
		fear_sprite.texture = fear_images[2]
	elif fear_level < 100:
		fear_sprite.texture = fear_images[3]
	else:
		fear_sprite.texture = fear_images[4]
	log_timer += 1
	if log_timer >= log_interval:
		log_message("Fear sprite updated, fear_level=" + str(fear_level))
		log_timer = 0.0

func handle_fear_death(delta):
	if fear_level >= 100:
		darken_screen.modulate.a = 1
		fear_death_timer += delta
		if fear_death_timer >= FEAR_DEATH_DELAY:
			log_message("Max fear reached, changing scene", true)
			change_scene()
		log_message("Fear death timer: " + str(fear_death_timer), true)
	else:
		fear_death_timer = 0.0
		darken_screen.modulate.a = lerp(darken_screen.modulate.a, 0.0, delta * 12)
		log_message("Fear death timer reset, screen darkening: " + str(darken_screen.modulate.a), true)
#endregion

#region Attack
func animate_spanner_repair():
	if not held_object:
		log_message("Cannot animate repair, no held object", true)
		return
	var tween = create_tween()
	var start_position = held_object.position
	var start_rotation = held_object.rotation
	var direction = -transform.basis.z.normalized()
	var end_position = start_position + direction * 0.5
	var twist_rotation = start_rotation + Vector3(0, 0, deg_to_rad(45))
	tween.tween_property(held_object, "position", end_position, 0.15).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(held_object, "rotation", twist_rotation, 0.15).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(held_object, "position", start_position, 0.15).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(held_object, "rotation", start_rotation, 0.15).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	tween.play()
	log_message("Animating spanner repair", true)

func attack():
	if not can_attack or not held_object or not held_object.is_in_group("spear"):
		log_message("Cannot attack, invalid conditions", true)
		return
	animate_spear_attack()
	if Rayscary3D.is_colliding():
		var collider = Rayscary3D.get_collider()
		if collider.is_in_group("breakable"):
			collider.take_damage(1)
			log_message("Damaging breakable object: " + collider.name, true)

func animate_spear_attack():
	if not held_object:
		log_message("Cannot animate spear attack, no held object", true)
		return
	var tween = create_tween()
	var start_position = held_object.position
	var direction = -transform.basis.z.normalized()
	var end_position = start_position + direction * 2.0
	tween.tween_property(held_object, "position", end_position, 0.2).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(held_object, "position", start_position, 0.2).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	tween.play()
	log_message("Animating spear attack", true)
#endregion

#region Buy
func animate_money_change(start_value: int, end_value: int):
	var tween = create_tween()
	tween.tween_method(
		func(value): money_l.text = str(value),
		start_value,
		end_value,
		0.5
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	if money__.text != "":
		await get_tree().create_timer(1.0).timeout
		money__.text = ""
	log_message("Animating money change from " + str(start_value) + " to " + str(end_value), true)

func add_money(amount: int):
	money += amount
	log_message("Added " + str(amount) + " coins. New balance: " + str(money), true)

func subtract_money(amount: int) -> bool:
	if money >= amount:
		money -= amount
		log_message("Spent " + str(amount) + " coins. Remaining: " + str(money), true)
		return true
	log_message("Insufficient funds! Balance: " + str(money), true)
	if AudioManager:
		AudioManager.play_sound("res://sounds/button/wpn_denyselect.mp3")
	return false

func show_money_change(change: int):
	money__.text = "%+d" % change
	var target_position = money__.position
	var initial_position = money__.position
	if change > 0:
		target_position.y -= 30
	else:
		target_position.y += 30
	var tween = create_tween()
	tween.tween_property(money__, "position", target_position, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_property(money__, "modulate", Color(1, 1, 1, 0), 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	await tween.finished
	money__.text = ""
	money__.modulate = Color(1, 1, 1, 1)
	money__.position = initial_position
	log_message("Showing money change: " + str(change), true)
#endregion

#region Tablet
func open_tablet():
	if not map or not is_instance_valid(map):
		log_message("Error: Map node is not found!", true)
		return
	map.visible = true
	map.modulate.a = 0.0
	map.scale = Vector2(0.8, 0.8)
	map.rotation_degrees = 15.0
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(map, "modulate:a", 1.0, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(map, "scale", Vector2(1.0, 1.0), 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(map, "rotation_degrees", 0.0, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	log_message("Tablet opened, starting animation", true)

func close_tablet():
	if not map or not is_instance_valid(map):
		log_message("Error: Map node is not found!", true)
		return
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(map, "modulate:a", 0.0, 0.3).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(map, "scale", Vector2(0.8, 0.8), 0.3).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	tween.tween_property(map, "rotation_degrees", -15.0, 0.3).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tween.tween_callback(func(): map.visible = false)
	log_message("Tablet closed, animation started", true)

func open_info_tablet():
	if not statistic or not is_instance_valid(statistic):
		log_message("Error: Statistic node is not found!", true)
		return
	statistic.visible = true
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(statistic, "modulate:a", 1.0, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(statistic, "scale", Vector2(1.0, 1.0), 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(statistic, "rotation_degrees", 0.0, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	log_message("Statistic tablet opened, starting animation", true)

func close_info_tablet():
	if not statistic or not is_instance_valid(statistic):
		log_message("Error: Statistic node is not found!", true)
		return
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(statistic, "modulate:a", 0.0, 0.3).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(statistic, "scale", Vector2(0.8, 0.8), 0.3).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	tween.tween_property(statistic, "rotation_degrees", -15.0, 0.3).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tween.tween_callback(func(): statistic.visible = false)
	log_message("Statistic tablet closed, animation started", true)
#endregion
