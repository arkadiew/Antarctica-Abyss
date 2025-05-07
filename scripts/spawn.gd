extends Node3D

# Blueprints for spawned objects
@export var spanner_scene: PackedScene = load("res://scenes/object/spanner.tscn")
@export var gun_scene: PackedScene = load("res://scenes/object/damaging_object.tscn")
@export var oxygen_scene: PackedScene = load("res://scenes/oxygentank/oxygen_tank.tscn")
@export var destruction_particles: PackedScene = load("res://scenes/partical.tscn")

# Player and button nodes
@onready var player = get_node("/root/main/Player")
@onready var button_node: StaticBody3D = $"../Vending_Machine/button"
@onready var delete_button_node: StaticBody3D = $"../Vending_Machine/delete_button"
@onready var gun_button_node: StaticBody3D = $"../Vending_Machine/button_gun"
@onready var oxygen_button_node: StaticBody3D = $"../Vending_Machine/button_oxygen"

# Prices
var cube_price: int = 20
var gun_price: int = 30
var oxygen_price: int = 50

# Lists to track spawned objects
var spawned_cubes: Array = []
var spawned_guns: Array = []
var spawned_oxygen: Array = []

# Reference to the radar (assuming it's at a known path)
@onready var radar = get_node_or_null("/root/main/Radar")

func _ready():
	# Connect button signals
	if button_node:
		button_node.connect("button_state_changed", _on_button_state_changed)
	if delete_button_node:
		delete_button_node.connect("button_state_changed", _on_delete_button_state_changed)
	if gun_button_node:
		gun_button_node.connect("button_state_changed", _on_button_gun_changed)
	if oxygen_button_node:
		oxygen_button_node.connect("button_state_changed", _on_button_oxygen_changed)

	# Warn if radar is not found
	if not radar:
		push_warning("Vending Machine: Radar node not found")

func _on_button_state_changed(is_pressed: bool):
	if is_pressed:
		buy_and_spawn("cube")

func _on_button_gun_changed(is_pressed: bool):
	if is_pressed:
		buy_and_spawn("gun")

func _on_button_oxygen_changed(is_pressed: bool):
	if is_pressed:
		buy_and_spawn("oxygen")

func _on_delete_button_state_changed(is_pressed: bool):
	if is_pressed:
		delete_last_object()

func buy_and_spawn(item: String):
	match item:
		"cube":
			if player.subtract_money(cube_price):
				spawn_cube()
		"gun":
			if player.subtract_money(gun_price):
				spawn_gun()
		"oxygen":
			if player.subtract_money(oxygen_price):
				spawn_oxygen()

func spawn_cube():
	if spanner_scene:
		var container = Node3D.new()
		container.name = "spanner_container_" + str(spawned_cubes.size() + 1)
		add_child(container)
		var cube = spanner_scene.instantiate()
		cube.name = "spanner"
		# Add to minimap group and set icon
		cube.add_to_group("minimap_objects")
		cube.set_meta("minimap_icon", "spanner")
		container.add_child(cube)
		spawned_cubes.append(cube)
		# Highlight on radar
		if radar and is_instance_valid(cube):
			radar.highlight_marker(cube)

func spawn_gun():
	if gun_scene:
		var container = Node3D.new()
		container.name = "gun_container_" + str(spawned_guns.size() + 1)
		add_child(container)
		var gun = gun_scene.instantiate()
		gun.name = "gun"
		# Add to minimap group and set icon
		gun.add_to_group("minimap_objects")
		gun.set_meta("minimap_icon", "harpoon")
		container.add_child(gun)
		spawned_guns.append(gun)
		# Highlight on radar
		if radar and is_instance_valid(gun):
			radar.highlight_marker(gun)

func spawn_oxygen():
	if oxygen_scene:
		var container = Node3D.new()
		container.name = "oxygen_container_" + str(spawned_oxygen.size() + 1)
		add_child(container)
		var oxygen = oxygen_scene.instantiate()
		oxygen.name = "oxygen_tank"
		# Add to minimap group and set icon
		oxygen.add_to_group("minimap_objects")
		oxygen.set_meta("minimap_icon", "oxygen")
		container.add_child(oxygen)
		spawned_oxygen.append(oxygen)
		# Highlight on radar
		if radar and is_instance_valid(oxygen):
			radar.highlight_marker(oxygen)

func delete_last_object():
	if spawned_cubes.size() >= spawned_guns.size() and spawned_cubes.size() >= spawned_oxygen.size():
		delete_last_cube()
	elif spawned_guns.size() >= spawned_cubes.size() and spawned_guns.size() >= spawned_oxygen.size():
		delete_last_gun()
	elif spawned_oxygen.size() >= spawned_cubes.size() and spawned_oxygen.size() >= spawned_guns.size():
		delete_last_oxygen()
	else:
		if player.AudioManager:
			player.AudioManager.play_sound("res://voice/button/wpn_denyselect.mp3")
		print("No objects to delete.")

func delete_last_cube():
	if spawned_cubes.size() > 0:
		var last_cube = spawned_cubes.pop_back()
		if last_cube and is_instance_valid(last_cube):
			partic(last_cube.global_transform.origin)
			last_cube.queue_free()
			if cube_price > 0:
				player.add_money(cube_price)
			print("Deleted a cube. Cubes left:", spawned_cubes.size())
	else:
		if player.AudioManager:
			player.AudioManager.play_sound("res://voice/button/wpn_denyselect.mp3")

func delete_last_gun():
	if spawned_guns.size() > 0:
		var last_gun = spawned_guns.pop_back()
		if last_gun and is_instance_valid(last_gun):
			partic(last_gun.global_transform.origin)
			last_gun.queue_free()
			if gun_price > 0:
				player.add_money(gun_price)
			print("Deleted a gun. Guns left:", spawned_guns.size())
	else:
		if player.AudioManager:
			player.AudioManager.play_sound("res://voice/button/wpn_denyselect.mp3")

func delete_last_oxygen():
	if spawned_oxygen.size() > 0:
		var last_oxygen = spawned_oxygen.pop_back()
		if last_oxygen and is_instance_valid(last_oxygen):
			partic(last_oxygen.global_transform.origin)
			last_oxygen.queue_free()
			if oxygen_price > 0:
				player.add_money(oxygen_price)
			print("Deleted an oxygen tank. Tanks left:", spawned_oxygen.size())
	else:
		if player.AudioManager:
			player.AudioManager.play_sound("res://voice/button/wpn_denyselect.mp3")

func partic(position: Vector3):
	if destruction_particles:
		var particles_instance = destruction_particles.instantiate()
		var shift = Vector3(0, -1, 0)
		particles_instance.global_transform.origin = position + shift
		get_parent().add_child(particles_instance)
	await get_tree().create_timer(0.1).timeout
