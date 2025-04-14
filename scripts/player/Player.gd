# This makes it a 3D character that moves with physics (the player!)
extends CharacterBody3D

#region Variables
# Where to go when the game ends
const END_SCENE_PATH = "res://end.tscn"
# Camera height stuff
const DEFAULT_CAMERA_HEIGHT: float = 0.1  # Normal eye level
const SUIT_CAMERA_HEIGHT: float = -0.5   # Lower when wearing a suit
var current_camera_height: float = DEFAULT_CAMERA_HEIGHT  # Tracks current height

# Fear, movement, and physics constants (tons of 'em!)
const INCREASE_RATE_NEAR: float = 10.0  # Fear spikes fast when close to scary stuff
const INCREASE_RATE_FAR: float = 5.0    # Slower fear increase when farther
const DECREASE_RATE_COLLIDING: float = 5.0  # Fear drops fast when hitting something
const DECREASE_RATE_NO_COLLISION: float = 3.0  # Slower drop with no collision
const TERMINAL_VELOCITY: float = -40.0  # Max fall speed
const AIR_CONTROL: float = 3.0  # How much you can steer in the air
const FEAR_DEATH_DELAY: float = 4.0  # Seconds before dying of max fear
const SUIT_PICKUP_DISTANCE: float = 3.0  # How close to grab a suit
const SUIT_GROUP: String = "Submarine"  # Group name for suits
const MAX_INVENTORY_SIZE: int = 5  # Max items you can carry
const OXYGEN_CONSUMPTION_RATE: float = 0.2  # How fast oxygen runs out
const OXYGEN_CRITICAL_LEVEL: float = 10.0  # When oxygen gets low
const OXYGEN_LOW_MOVEMENT_PENALTY: float = 0.5  # Slower movement when low on O2
const WATER_DENSITY: float = 1.0  # Water physics stuff
const PLAYER_VOLUME: float = 0.5  # How much space you take up in water
const BUOYANCY_FACTOR: float = 1.0  # How floaty you are
const SWIM_SPEED: float = 2.0  # Normal swim speed
const SWIM_UP_SPEED: float = 3.0  # Speed going up in water
const MIN_VERTICAL_SPEED: float = -0.5  # Slowest downward swim speed
const SWIM_DOWN_SPEED: float = 6.0  # Speed going down in water
const STAMINA_DOWN_COST: float = 2.0  # Stamina cost for swimming down
const MAX_VERTICAL_ANGLE: float = 89.0  # Max camera tilt up/down
const RUN_SPEED_MULTIPLIER: float = 2.0  # How much faster running is
const SENSITIVITY: float = 0.01  # Mouse sensitivity
const GRAVITY: float = -9.8  # Fall speed on land
const WALK_SPEED: float = 3.0  # Normal walk speed
const LOW_STAMINA_SPEED: float = 1.0  # Slow walk when tired
const JUMP_FORCE: float = 3.0  # How high you jump
const JUMP_STAMINA_COST: float = 10.0  # Stamina cost for jumping
const MAX_STAMINA: float = 100.0  # Max stamina
const MAX_H2O: float = 100.0  # Max oxygen
const H2O_DEPLETION_RATE: float = 1.0  # Oxygen drain rate without suit
const H2O_RECOVERY_RATE: float = 30.0  # Oxygen recovery rate out of water
const STAMINA_RECOVERY_RATE: float = 30.0  # Stamina recovery rate
const STAMINA_RUN_DEPLETION_RATE: float = 20.0  # Stamina drain while running
const STAMINA_RECOVERY_DELAY: float = 3.5  # Delay before stamina recovers
const MIN_H2O_THRESHOLD: float = 10.0  # Low oxygen warning point
const INTERACTION_DISTANCE: float = 3.0  # How close to interact with stuff
const LERP_SPEED: float = 5.0  # Smooth transition speed
const RESTART_DELAY: float = 9.0  # Delay before restarting
const DARKEN_MAX_ALPHA: float = 1.0  # How dark the screen gets
const OXYGEN_REPLENISH_RATE: float = 20.0  # Oxygen refill speed near tanks
const OXYGEN_INTERACTION_DISTANCE: float = 3.0  # Distance to refill oxygen
var can_activate_suit = false  # Can you grab a suit?
var target_suit = null  # The suit you’re aiming at

# Inertia and object handling
const ACCELERATION: float = 15.0  # How fast you speed up
const DECELERATION: float = 10.0  # How fast you slow down
var last_suit_position = null  # Last spot a suit was at
@export var throw_force: float = 7.5  # How hard you throw stuff
@export var follow_speed: float = 3.5  # How fast held objects follow you
@export var follow_distance: float = 2.5  # How far held objects float from you
@export var max_distance_from_camera: float = 5.0  # Max distance before dropping
@export var drop_below_player: bool = false  # Drop if object’s below you
@export var ground_ray: RayCast3D  # Ray to check ground
@export var swim_up_speed: float = 10.0  # Faster swim up with suit
@export var climb_speed: float = 7.0  # Speed for climbing (not used yet)
@export var suit_scene: PackedScene = preload("res://scenes/suit.tscn")  # Suit scene

# Camera zoom and fear stuff
var zoom_speed: float = 1.0  # How fast you zoom
var min_distance: float = 1.0  # Closest zoom distance
var max_distance: float = 3.0  # Farthest zoom distance
var is_fear_max: bool = false  # Are you maxed out on fear?
var fear_max_hold_time: float = 5.0  # How long max fear lasts
var fear_max_timer: float = 0.0  # Timer for max fear
var fear_death_timer: float = 0.0  # Timer for dying of fear
var has_suit: bool = false  # Are you wearing a suit?
var inventory: Array = []  # Your inventory list
var selected_item: RigidBody3D = null  # Item you’ve picked from inventory
var selected_item_index: int = -1  # Index of selected item
var stamina: float = MAX_STAMINA  # Current stamina
var h2o: float = MAX_H2O  # Current oxygen

# Money system with animations
var money: int = 100:
	set(value):
		var change = value - money
		if change != 0:  # If money changes...
			show_money_change(change)  # Show the difference
		animate_money_change(money, value)  # Animate the update
		money = value  # Set new money value

# UI and other nodes
@onready var money_l: Label = $CameraPivot/Camera3D/UI/MONEY/Money  # Money display
@onready var money__: Label = $"CameraPivot/Camera3D/UI/MONEY/Money?"  # Money change display
var can_attack: bool = true  # Can you attack?
var is_running: bool = false  # Are you running?
var stamina_recovery_timer: float = 0.0  # Delay for stamina recovery
var can_run: bool = true  # Can you run?
var holding_object_time: float = 0.0  # How long you’ve held something
var is_underwater: bool = false  # Are you underwater?
var resisting_flow: bool = false  # Are you fighting water current?
var restart_timer: float = 0.0  # Timer for restarting
var held_object: RigidBody3D = null  # Object you’re holding
var interaction_cooldown: float = 0.5  # Cooldown between interactions
var last_interaction_time: float = 0.0  # Last time you interacted
var original_fov: float = 70.0  # Default camera field of view
var is_shaking: bool = false  # Is the camera shaking?
var shake_intensity: float = 0.0  # How hard it shakes
var shake_timer: float = 0.0  # How long it shakes
var current_flow: Vector3 = Vector3(1, 0, 0)  # Water current direction
var flow_strength: float = 2.0  # How strong the current is
var jump_charge: float = 0.0  # Charging up a jump (not used yet)
var max_jump_charge: float = 1.0  # Max jump charge
var jump_charge_rate: float = 0.5  # How fast jump charges
var tilt_angle: float = 0.0  # Camera tilt when moving
var max_tilt: float = 3.0  # Max tilt angle
var tilt_speed: float = 8.0  # How fast it tilts
var tilt_recovery: float = 6.0  # How fast tilt recovers
var is_changing_scene: bool = false  # Are we switching scenes?
@onready var Rayscary3D: RayCast3D = $CameraPivot/Camera3D/Rayscary3D  # Ray for fear checks

# Fear system
var fear_level: float = 0.0  # How scared you are (0-100)
var fear_images: Array = [  # Fear UI sprites
	preload("res://utils/img/png_scary/fear_0.png"),    # 0%
	preload("res://utils/img/png_scary/fear_25.png"),   # 25%
	preload("res://utils/img/png_scary/fear_50.png"),   # 50%
	preload("res://utils/img/png_scary/fear_75.png"),   # 75%
	preload("res://utils/img/png_scary/fear_100.png")   # 100%
]
var scary_list: Array = ["fish", "Enemy"]  # Things that scare you

# Materials for highlighting objects
var original_material: Material = null  # Original object material
var highlight_material: Material = preload("res://utils/shader/highlight_material.tres")  # Highlight material
var default_material: StandardMaterial3D = StandardMaterial3D.new()  # Default material

# UI elements
@onready var Menu: TextureRect = $CameraPivot/Camera3D/UI/Menu/Menu  # Interaction menu
@onready var fear_sprite: TextureRect = $CameraPivot/Camera3D/UI/FearSprite  # Fear display
@onready var Pro3: TextureRect = $CameraPivot/Camera3D/UI/Pro3  # UI icon
@onready var Pro2: TextureRect = $CameraPivot/Camera3D/UI/Pro2  # UI icon
@onready var Pro1: TextureRect = $CameraPivot/Camera3D/UI/Pro  # UI icon
@onready var icon2: TextureRect = $CameraPivot/Camera3D/UI/icon2  # UI icon
@onready var icon: TextureRect = $CameraPivot/Camera3D/UI/icon  # UI icon
@onready var AudioManager: Node = $AudioManager  # Sound manager
@onready var AudioPlayer: Node = $AudioManager  # Sound manager
@onready var camera: Camera3D = $CameraPivot/Camera3D  # Player camera
@onready var interact_ray: RayCast3D = $CameraPivot/Camera3D/InteractRay  # Interaction ray
@onready var stamina_bar: TextureProgressBar = $CameraPivot/Camera3D/UI/TextureProgressBar  # Stamina bar
@onready var h2o_bar: TextureProgressBar = $CameraPivot/Camera3D/UI/o2  # Oxygen bar
@onready var label_3d: Label = $"CameraPivot/Camera3D/UI/Menu/Menu?la"  # Interaction label
@onready var darken_screen: ColorRect = $CameraPivot/Camera3D/UI/DarkenScreen  # Fade screen
@onready var NotificationLabel: Label = $CameraPivot/Camera3D/UI/NotificationLabel  # Notification text
@onready var mask: TextureRect = $CameraPivot/Camera3D/UI/mask  # UI mask
@onready var camera_pivot: Node3D = $CameraPivot  # Camera pivot point

var shake_randomizer: RandomNumberGenerator = RandomNumberGenerator.new()  # For camera shake
const SMOOTH_ROTATION_SPEED: float = 5.0  # How smooth camera turns are
var rotation_y: float = 0.0  # Horizontal rotation
var rotation_x: float = 0.0  # Vertical rotation
var target_rotation_y: float = 0.0  # Target horizontal rotation
#endregion

#region Start
# Sets up the player when they spawn
func _ready():
	
	money_l.text = str(money)  # Show starting money
	Menu.visible = false  # Hide interaction menu
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)  # Lock mouse for camera control
	original_fov = camera.fov if camera else 70.0  # Set default camera zoom
	if not camera or not stamina_bar or not h2o_bar or not AudioManager:
		printerr("Warning: Essential nodes are missing!")  # Complain if stuff’s missing
		return
	_update_ui_visibility()  # Show/hide UI based on suit
	stamina_bar.max_value = MAX_STAMINA  # Set stamina bar max
	h2o_bar.max_value = MAX_H2O  # Set oxygen bar max

# Main loop, runs every frame
func _process(delta):
	if is_changing_scene:
		return  # Skip if we’re switching scenes
	# Smoothly adjust camera height based on suit
	if has_suit:
		current_camera_height = lerp(current_camera_height, SUIT_CAMERA_HEIGHT, delta * LERP_SPEED)
	else:
		current_camera_height = lerp(current_camera_height, DEFAULT_CAMERA_HEIGHT, delta * LERP_SPEED)
	camera_pivot.position.y = current_camera_height
	# Suit controls
	if Input.is_action_just_pressed("use_item"):
		activate_suit()
	if Input.is_action_just_pressed("exit_suit") and has_suit:
		exit_suit()
	_handle_rotation(delta)  # Handle camera rotation
	handle_object_interactions(delta)  # Manage picking up/dropping stuff
	update_movement(delta)  # Move the player
	update_stamina(delta)  # Update stamina levels
	update_h2o(delta)  # Update oxygen levels
	update_label()  # Update interaction label
	update_oxygen_tank_interaction(delta)  # Check for oxygen tanks
	if has_suit:
		handle_fear_mechanics(delta)  # Manage fear with suit on
		handle_fear_death(delta)  # Check if fear kills you
		_show_all_ui()  # Show full UI with suit
		handle_water_physics(delta)  # Water physics with suit
	else:
		_hide_all_ui()  # Hide most UI without suit
		handle_water_physics_without_suit(delta)  # Water physics without suit
	apply_camera_shake(delta)  # Add camera shake if needed
	if h2o <= 0 and not is_changing_scene:
		change_scene()  # Die and switch scenes if oxygen runs out

# Smoothly rotate the camera
func _handle_rotation(delta):
	rotation_y = lerp_angle(rotation_y, target_rotation_y, delta * SMOOTH_ROTATION_SPEED)
	rotation.y = rotation_y
	rotation_x = clamp(rotation_x, -MAX_VERTICAL_ANGLE, MAX_VERTICAL_ANGLE)
	camera_pivot.rotation_degrees.x = rotation_x

# Handle mouse and key inputs
func _input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		_handle_mouse_motion(event)  # Rotate camera with mouse
	if event is InputEventKey and event.pressed and Input.is_action_pressed("exit"):
		_toggle_mouse_mode()  # Toggle mouse lock
	if event.is_action_pressed("attack"):
		if AudioManager:
			AudioManager.play_sound("res://voice/player/claw_miss1.mp3")
		attack()  # Attack with held object
	if event is InputEventMouseButton and held_object:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			follow_distance = max(follow_distance - zoom_speed, min_distance)  # Zoom in
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			follow_distance = min(follow_distance + zoom_speed, max_distance)  # Zoom out

# Turn camera based on mouse movement
func _handle_mouse_motion(event: InputEventMouseMotion):
	target_rotation_y -= event.relative.x * SENSITIVITY * 0.1
	rotation_x -= event.relative.y * SENSITIVITY * 5

# Switch between locked and free mouse
func _toggle_mouse_mode():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED)

# Get movement direction from input
func get_input_direction() -> Vector3:
	var i = Vector3(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		0,
		Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward")
	)
	var w = transform.basis.x * i.x + transform.basis.z * i.z
	return w.normalized()

# Switch to end scene when you die
func change_scene():
	if is_changing_scene or not is_instance_valid(self) or not is_inside_tree():
		print("Error: Already changing scene or Player node is invalid!")
		return
	is_changing_scene = true
	darken_screen.visible = true
	var tween = create_tween()
	tween.tween_property(darken_screen, "modulate:a", 1.0, 1.0).set_ease(Tween.EASE_IN)
	await tween.finished
	var tree = get_tree()
	if tree && tree.root:
		print("Changing scene to:", END_SCENE_PATH)
		tree.change_scene_to_file(END_SCENE_PATH)
		set_process(false)
	else:
		print("Error: Unable to access scene tree or root!")
#endregion

#region UI
# Update what UI shows based on suit
func _update_ui_visibility():
	if has_suit:
		_show_all_ui()
	else:
		_hide_all_ui()

# Hide most UI when no suit
func _hide_all_ui():
	stamina_bar.visible = true
	h2o_bar.visible = true
	fear_sprite.visible = false
	mask.visible = false
	Pro3.visible = true
	Pro2.visible = true
	Pro1.visible = true
	icon2.visible = true
	icon.visible = true
	darken_screen.visible = false
	darken_screen.modulate.a = 0.0

# Show full UI with suit
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
#endregion

#region Controller
# Handle picking up and dropping stuff
func handle_object_interactions(delta):
	last_interaction_time += delta
	if Input.is_action_just_pressed("interact") and last_interaction_time >= interaction_cooldown:
		last_interaction_time = 0.0
		if AudioManager:
			AudioManager.play_sound("res://shader/inventory/wpn_select.mp3")
		if held_object:
			drop_held_object()
		else:
			_try_pick_object()
	if Input.is_action_just_pressed("use_item"):
		_try_add_to_inventory()
	if Input.is_action_just_pressed("Q"):
		select_next_inventory_item()
		if AudioManager:
			AudioManager.play_sound("res://shader/inventory/wpn_moveselect.mp3") 
	if Input.is_action_just_pressed("use_item") and selected_item:
		drop_selected_object()
		if AudioManager:
			AudioManager.play_sound("res://shader/inventory/inventory.mp3")
	if held_object:
		follow_player_with_object()
		apply_stamina_penalty_for_holding(delta)
		if stamina <= 0:
			drop_held_object()
	update_label_position()
#endregion

#region Inventory
# Try to pick up an object
func _try_pick_object():
	if interact_ray.is_colliding():
		var collider = interact_ray.get_collider()
		if collider is RigidBody3D and stamina > 10:
			set_held_object(collider)

# Try to add something to inventory
func _try_add_to_inventory():
	if interact_ray.is_colliding():
		var collider = interact_ray.get_collider()
		if collider is RigidBody3D:
			if collider == held_object:
				show_notification("Cannot add held object to inventory! Drop it first.", 2.0)
				return
			if collider in inventory:
				show_notification("Item is already in inventory!", 2.0)
				return
			if inventory.size() < MAX_INVENTORY_SIZE:
				add_to_inventory(collider)

# Add item to inventory
func add_to_inventory(obj: RigidBody3D):
	inventory.append(obj)
	obj.visible = false
	obj.get_parent().remove_child(obj)
	show_notification(obj.name + " added to inventory", 2.0)

# Cycle through inventory items
func select_next_inventory_item() -> void:
	if inventory.is_empty():
		show_notification("Inventory is empty!", 2.0)
		selected_item_index = -1
		selected_item = null
		return
	if selected_item != null:
		selected_item.visible = false
	selected_item_index = (selected_item_index + 1) % inventory.size()
	selected_item = inventory[selected_item_index]
	show_notification("Selected: " + str(selected_item.name), 2.0)

# Drop the selected inventory item
func drop_selected_object() -> void:
	if selected_item == null:
		show_notification("No item selected to drop!", 2.0)
		return
	var original_name = selected_item.name
	selected_item.name = generate_unique_name(original_name)
	selected_item.visible = true
	var container = get_node_or_null("container")
	if container == null:
		container = Node3D.new()
		container.name = "DroppedObjectsContainer"
		get_tree().get_root().add_child(container)
	container.add_child(selected_item)
	selected_item.global_transform.origin = camera.global_transform.origin + camera.global_transform.basis.z * -2.0
	if selected_item is RigidBody3D:
		selected_item.freeze = false
		selected_item.linear_velocity = Vector3.ZERO
		selected_item.angular_velocity = Vector3.ZERO
	set_held_object(selected_item)
	inventory.erase(selected_item)
	selected_item = null
	selected_item_index = -1
	show_notification("Dropped " + original_name, 2.0)

# Make a unique name for dropped items
func generate_unique_name(base_name: String) -> String:
	var unique_name = base_name
	var counter = 1
	var container = get_node_or_null("/root/DroppedObjectsContainer")
	if container != null:
		while container.has_node(unique_name):
			unique_name = base_name
			counter += 1
	return unique_name
#endregion

#region Movement
# Figure out how fast you should move
func determine_character_speed() -> float:
	if is_running and stamina > 0:
		return WALK_SPEED * RUN_SPEED_MULTIPLIER
	elif stamina == 0:
		return LOW_STAMINA_SPEED
	return WALK_SPEED

# Update player movement
func update_movement(delta: float) -> void:
	var input_vector = get_input_direction()
	var target_speed = determine_character_speed()
	var target_velocity = Vector3(input_vector.x * target_speed, velocity.y, input_vector.z * target_speed)

	if is_on_floor() and input_vector.length() > 0 and not is_running and AudioManager:
		if not AudioManager.is_playing("walk_sound"):
			AudioManager.play_sound_player("res://sounds/player/walk.mp3")
	elif AudioManager and AudioManager.is_playing("walk_sound"):
		AudioManager.stop_sound("walk_sound")  #
	if is_on_floor() and is_running and AudioManager:
		if not AudioManager.is_playing("run_sound"):
			AudioManager.play_sound_player("res://sounds/player/sprint.mp3")
	elif AudioManager and AudioManager.is_playing("run_sound"):
		AudioManager.stop_sound("run_sound")
		
	if input_vector.length() > 0:
		velocity.x = lerp(velocity.x, target_velocity.x, ACCELERATION * delta)
		velocity.z = lerp(velocity.z, target_velocity.z, ACCELERATION * delta)
	else:
		velocity.x = lerp(velocity.x, 0.0, DECELERATION * delta)
		velocity.z = lerp(velocity.z, 0.0, DECELERATION * delta)
	if not is_on_floor():
		velocity.x = lerp(velocity.x, target_velocity.x, AIR_CONTROL * delta)
		velocity.z = lerp(velocity.z, target_velocity.z, AIR_CONTROL * delta)
	if can_run and Input.is_action_pressed("run") and stamina > 0 and not is_in_water():
		is_running = true
	else:
		is_running = false
	if is_on_floor():
		handle_character_jump(delta)
	else:
		apply_gravity_force(delta)
	apply_character_turn_tilt(delta)
	move_and_slide()

# Apply gravity when not on ground
func apply_gravity_force(delta: float) -> void:
	if not is_on_floor():
		velocity.y = max(velocity.y + GRAVITY * delta, TERMINAL_VELOCITY)

# Handle jumping
func handle_character_jump(delta: float) -> void:
	if Input.is_action_just_pressed("jump") and stamina >= JUMP_STAMINA_COST:
		velocity.y = JUMP_FORCE
		decrease_stamina(JUMP_STAMINA_COST)

# Tilt camera when turning
func apply_character_turn_tilt(delta: float) -> void:
	var input_direction = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var target_tilt_angle = -input_direction.x * max_tilt
	tilt_angle = lerp(tilt_angle, target_tilt_angle, delta * tilt_speed)
	$CameraPivot.rotation_degrees.z = tilt_angle
#endregion

#region Stamina
# Drain stamina when holding stuff
func apply_stamina_penalty_for_holding(delta):
	var drain_factor = (holding_object_time / 10.0)
	if holding_object_time >= 1.0:
		decrease_stamina(10.0 * drain_factor * delta)

# Update stamina levels
func update_stamina(delta):
	var in_water = is_in_water()
	var moving = get_input_direction().length() > 0
	if can_run and stamina > 0 and Input.is_action_pressed("run") and moving and not in_water:
		decrease_stamina(STAMINA_RUN_DEPLETION_RATE * delta)
		stamina_recovery_timer = STAMINA_RECOVERY_DELAY
		is_running = true
	else:
		is_running = false
		stamina_recovery_timer -= delta
		if stamina_recovery_timer <= 0 and stamina < MAX_STAMINA:
			increase_stamina(STAMINA_RECOVERY_RATE * delta)
			can_run = true
	stamina_bar.value = stamina

# Reduce stamina
func decrease_stamina(amount: float):
	stamina = clamp(stamina - amount, 0, MAX_STAMINA)

# Restore stamina
func increase_stamina(amount: float):
	stamina = clamp(stamina + amount, 0, MAX_STAMINA)
#endregion

#region Water
# Check if the camera is fully submerged underwater
func is_camera_fully_submerged() -> bool:
	if not is_instance_valid(camera_pivot) or not get_tree():
		return false
	var water_areas = get_tree().get_nodes_in_group("water_area")
	for area in water_areas:
		if area is Area3D:
			var camera_pos = camera_pivot.global_transform.origin
			# Assume the Area3D has a CollisionShape3D
			var shape = area.get_node("CollisionShape3D")
			if shape and shape.shape is BoxShape3D:
				var water_top = area.global_transform.origin.y + shape.shape.extents.y
				var water_bottom = area.global_transform.origin.y - shape.shape.extents.y
				# Check if the camera is below the water's top boundary
				if camera_pos.y < water_top and camera_pos.y > water_bottom:
					return true
	return false
# Check if you’re in water
func is_in_water() -> bool:
	if not is_instance_valid(self) or not get_tree():
		return false
	var water_areas = get_tree().get_nodes_in_group("water_area")
	for area in water_areas:
		if area.overlaps_body(self):
			return true
	return false

# Handle water physics with suit
func handle_water_physics(delta: float) -> void:
	if is_in_water():
		is_underwater = true
	
		apply_buoyancy_and_drag_scuba(delta)
		handle_swimming_input_scuba(delta)
	else:
		is_underwater = false
		if velocity.y > 0:
			velocity.y = lerp(velocity.y, 0.0, delta * 5.0)
		velocity.y = lerp(velocity.y, 0.0, delta * 2.0)
	velocity = velocity.limit_length(TERMINAL_VELOCITY * -1)

# Apply buoyancy and drag in water with suit
func apply_buoyancy_and_drag_scuba(delta: float) -> void:
	var buoyancy_force = -GRAVITY * WATER_DENSITY * PLAYER_VOLUME * BUOYANCY_FACTOR
	velocity.y = lerp(velocity.y, buoyancy_force, delta * 2.0)
	var drag = 0.9 if resisting_flow else 0.7
	velocity.x = lerp(velocity.x, 0.0, drag * delta)
	velocity.z = lerp(velocity.z, 0.0, drag * delta)
	velocity.y = clamp(velocity.y, TERMINAL_VELOCITY, SWIM_UP_SPEED)

# Handle swimming controls with suit
func handle_swimming_input_scuba(delta: float) -> void:
	var input_direction = get_input_direction()
	var speed = SWIM_SPEED
	if h2o < OXYGEN_CRITICAL_LEVEL:
		speed *= OXYGEN_LOW_MOVEMENT_PENALTY
	var target_velocity = Vector3(input_direction.x * speed, velocity.y, input_direction.z * speed)
	if input_direction != Vector3.ZERO:
		velocity.x = lerp(velocity.x, target_velocity.x, ACCELERATION * delta * 0.5)
		velocity.z = lerp(velocity.z, target_velocity.z, ACCELERATION * delta * 0.5)
		decrease_stamina(0.5 * delta)
	else:
		velocity.x = lerp(velocity.x, 0.0, DECELERATION * delta * 0.5)
		velocity.z = lerp(velocity.z, 0.0, DECELERATION * delta * 0.5)
	if Input.is_action_pressed("jump") and stamina > 1:
		velocity.y = lerp(velocity.y, SWIM_UP_SPEED, delta * 2.0)
		decrease_stamina(2.0 * delta)
	elif Input.is_action_pressed("crouch") and stamina > 1:
		velocity.y = lerp(velocity.y, -SWIM_DOWN_SPEED, delta * 2.0)
		decrease_stamina(STAMINA_DOWN_COST * delta)
	else:
		if velocity.y < MIN_VERTICAL_SPEED:
			velocity.y = MIN_VERTICAL_SPEED

# Update oxygen levels
func update_h2o(delta: float) -> void:
	if h2o <= 0:
		if not is_changing_scene:
			await get_tree().create_timer(2.0).timeout
			change_scene()
		return
	is_underwater = is_in_water()

	if is_underwater and AudioManager:
		if not AudioManager.is_playing("swim_sound"):
			AudioManager.play_sound_player("res://sounds/player/swim.mp3")
	elif not is_underwater and AudioManager and AudioManager.is_playing("swim_sound"):
		AudioManager.stop_sound("swim_sound")

	# Check various conditions for oxygen consumption/recovery
	if is_camera_fully_submerged() and has_suit:
		# Increased oxygen consumption when the camera is fully submerged
		decrease_h2o(OXYGEN_CONSUMPTION_RATE * 2.0 * delta)
		_handle_underwater_effects(delta)
	elif is_underwater and has_suit:
		# Normal oxygen consumption underwater with a suit
		decrease_h2o(OXYGEN_CONSUMPTION_RATE * delta)
		_handle_underwater_effects(delta)
	elif not is_underwater:
		# Oxygen recovery outside of water
		increase_h2o(H2O_RECOVERY_RATE * delta)
		darken_screen.modulate.a = lerp(darken_screen.modulate.a, 0.0, delta * 2.0)

	update_h2o_bar()

# Effects when low on oxygen
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

# Reduce oxygen
func decrease_h2o(amount: float) -> void:
	h2o = clamp(h2o - amount, 0, MAX_H2O)

# Restore oxygen
func increase_h2o(amount: float) -> void:
	h2o = clamp(h2o + amount, 0, MAX_H2O)

# Update oxygen bar
func update_h2o_bar() -> void:
	h2o_bar.value = h2o

# Check for oxygen tanks nearby
func update_oxygen_tank_interaction(delta: float) -> void:
	if not get_tree():
		return
	for tank in get_tree().get_nodes_in_group("oxygen_source"):
		if tank.global_transform.origin.distance_to(global_transform.origin) <= OXYGEN_INTERACTION_DISTANCE:
			increase_h2o(OXYGEN_REPLENISH_RATE * delta)
			return

# Shake camera when low on oxygen
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

# Water physics without suit
func handle_water_physics_without_suit(delta):
	if is_in_water():

		update_current_flow()
		apply_water_physics(delta)
		decrease_h2o(H2O_DEPLETION_RATE * 3.0 * delta)
		if h2o <= 0:
			change_scene()
	else:
		velocity.y = max(velocity.y + GRAVITY * delta, TERMINAL_VELOCITY)

# Update water current direction
func update_current_flow():
	if global_transform.origin.x > 50:
		current_flow = Vector3(-1, 0, 0)
	elif global_transform.origin.z < -50:
		current_flow = Vector3(0, 0, 1)
	else:
		current_flow = Vector3(1, 0, 0)

# Apply water physics without suit
func apply_water_physics(delta_time):
	var water_gravity = GRAVITY * 0.2
	var water_horizontal_damping = 1.5
	var water_vertical_damping = 1.2
	var swim_up_force = 13.0
	var input_direction = Vector3.ZERO
	if input_direction != Vector3.ZERO:
		input_direction = input_direction.normalized()
		resisting_flow = true
		velocity.x = lerp(velocity.x, input_direction.x * (WALK_SPEED * 0.5), ACCELERATION * delta_time)
		velocity.z = lerp(velocity.z, input_direction.z * (WALK_SPEED * 0.5), ACCELERATION * delta_time)
	else:
		resisting_flow = false
		velocity.x = lerp(velocity.x, 0.0, DECELERATION * delta_time)
		velocity.z = lerp(velocity.z, 0.0, DECELERATION * delta_time)
	if Input.is_action_pressed("jump") and stamina > 1:
		velocity.y += swim_up_force * delta_time
		decrease_stamina(2)
	else:
		velocity.y -= water_gravity * delta_time
	if not resisting_flow:
		velocity += current_flow * flow_strength * delta_time
		decrease_stamina(0.3 * delta_time)
	else:
		velocity += current_flow * flow_strength * 0.5 * delta_time
	velocity.x = lerp(velocity.x, 0.0, water_horizontal_damping * delta_time)
	velocity.z = lerp(velocity.z, 0.0, water_horizontal_damping * delta_time)
	velocity.y = lerp(velocity.y, 0.0, water_vertical_damping * delta_time)
	is_running = false
#endregion

#region Drop Held
# Pick up an object
func set_held_object(body: RigidBody3D):
	if body in inventory:
		show_notification("Cannot pick up item from inventory directly! Drop it first.", 2.0)
		return
	if held_object:
		drop_held_object()
	held_object = body
	if body and body.has_node("MeshInstance3D"):
		var mesh_instance = body.get_node("MeshInstance3D")
		if mesh_instance.get_surface_override_material_count() == 0:
			mesh_instance.set_surface_override_material(0, default_material)
		original_material = mesh_instance.get_surface_override_material(0)
		mesh_instance.set_surface_override_material(0, highlight_material)

# Drop whatever you’re holding
func drop_held_object():
	if held_object and held_object.has_node("MeshInstance3D"):
		var mesh_instance = held_object.get_node("MeshInstance3D")
		if mesh_instance.get_surface_override_material_count() > 0:
			mesh_instance.set_surface_override_material(0, original_material)
	held_object = null
	original_material = null

# Make held object follow you
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

# Update interaction label position
func update_label_position():
	if held_object:
		update_label_for_held_object(held_object)
	else:
		update_label_for_nearby_object()

# Show label for held object
func update_label_for_held_object(object_being_held):
	if not is_instance_valid(object_being_held) or not object_being_held.is_inside_tree():
		held_object = null
		label_3d.visible = false
		Menu.visible = false
		return
	var object_position = object_being_held.global_transform.origin
	var object_height = get_object_height(object_being_held)
	var target_label_position = object_position + Vector3(0, 1, 0)
	Menu.visible = true
	label_3d.text = "Drop " + object_being_held.name
	label_3d.visible = true

# Show label for nearby objects
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
				return
	label_3d.visible = false
	Menu.visible = false

# Get height of an object
func get_object_height(object_to_measure) -> float:
	var shape_node = object_to_measure.get_node_or_null("CollisionShape3D")
	if shape_node and shape_node.shape is BoxShape3D:
		return shape_node.shape.extents.y
	return 0.5
#endregion

#region Submarine
# Update interaction label for suits
func update_label():
	if interact_ray.is_colliding():
		var collider = interact_ray.get_collider()
		if collider != null and collider.is_in_group("Interactable"):
			Menu.visible = true
			label_3d.visible = true
			label_3d.text = collider.name

# Drop the suit
func exit_suit():
	if not has_suit:
		return
	var suit_instance = suit_scene.instantiate()
	if not is_instance_valid(suit_instance):
		printerr("Error: Failed to instantiate suit scene!")
		return
	suit_instance.global_transform.origin = global_transform.origin
	get_tree().current_scene.add_child(suit_instance)
	has_suit = false
	_update_ui_visibility()
	show_notification("Suit removed! Oxygen and stamina are now disabled.", 6.0)
	if AudioManager:
		AudioManager.play_sound("res://sounds/exit.mp3")
	current_camera_height = DEFAULT_CAMERA_HEIGHT
	camera_pivot.position.y = current_camera_height

# Show a notification on screen
func show_notification(text: String, delay: float = 2.0):
	NotificationLabel.text = text
	NotificationLabel.visible = true
	await get_tree().create_timer(delay).timeout
	NotificationLabel.visible = false

# Check for suits every physics frame
func _physics_process(delta):
	interact_ray.force_raycast_update()
	if interact_ray.is_colliding():
		var collider = interact_ray.get_collider()
		if collider != null and collider.is_in_group("suit_items"):
			can_activate_suit = true
			target_suit = collider
		else:
			can_activate_suit = false
			target_suit = null
	else:
		can_activate_suit = false
		target_suit = null

# Put on a suit
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
	else:
		print("Error: No target suit found!")
		
#endregion

#region Fear
# Manage fear levels with suit on
func handle_fear_mechanics(delta: float) -> void:
	if is_fear_max:
		fear_max_timer -= delta
		if fear_max_timer <= 0:
			is_fear_max = false
	else:
		var collider = Rayscary3D.get_collider() if Rayscary3D.is_colliding() else null
		if collider and collider is CharacterBody3D and collider.name in scary_list:
			var distance = global_transform.origin.distance_to(collider.global_transform.origin)
			var rate = INCREASE_RATE_NEAR if distance <= 2.0 else INCREASE_RATE_FAR
			fear_level = clamp(fear_level + rate * delta, 0, 100)
		else:
			var decrease_rate = DECREASE_RATE_COLLIDING if collider else DECREASE_RATE_NO_COLLISION
			fear_level = clamp(fear_level - decrease_rate * delta, 0, 100)
		if fear_level >= 100 and not is_fear_max:
			is_fear_max = true
			fear_max_timer = fear_max_hold_time
	update_fear_sprite()

# Update fear sprite based on level
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

# Check if fear kills you
func handle_fear_death(delta):
	if fear_level >= 100:
		darken_screen.modulate.a = 1
		fear_death_timer += delta
		if fear_death_timer >= FEAR_DEATH_DELAY:
			change_scene()
	else:
		fear_death_timer = 0.0
		darken_screen.modulate.a = lerp(darken_screen.modulate.a, 0.0, delta * 12)
#endregion

#region Attack
# Attack with a spear
func attack():
	if not can_attack or not held_object or not held_object.is_in_group("spear"):
		return
	animate_spear_attack()
	if Rayscary3D.is_colliding():
		var collider = Rayscary3D.get_collider()
		if collider.is_in_group("breakable"):
			collider.take_damage(1)

# Animate spear thrust
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
#endregion

#region Buy
# Animate money changes
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

# Add money to your stash
func add_money(amount: int):
	money += amount
	print("Added ", amount, " coins. New balance: ", money)

# Spend money if you have enough
func subtract_money(amount: int) -> bool:
	if money >= amount:
		money -= amount
		print("Spent ", amount, " coins. Remaining: ", money)
		return true
	print("Insufficient funds! Balance: ", money)
	if AudioManager:
		AudioManager.play_sound("res://sounds/button/wpn_denyselect.mp3")
	return false

# Show money change animation
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
#endregion
