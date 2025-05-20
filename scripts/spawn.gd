extends Node3D

# Blue_.

@export var spanner_scene: PackedScene = preload("res://scenes/object/spanner.tscn")
@export var gun_scene: PackedScene = preload("res://scenes/object/damaging_object.tscn")
@export var oxygen_scene: PackedScene = preload("res://scenes/oxygentank/oxygen_tank.tscn")
@export var destruction_particles: PackedScene = preload("res://scenes/partical.tscn")

# Player and button nodes
@onready var player = get_node("/root/main/Player")
@onready var radar = get_node_or_null("/root/main/Radar")
@onready var buttons = {
	"spanner": $"../Vending_Machine/Buy_Spanner",
	"gun": $"../Vending_Machine/Buy_Gun",
	"oxygen": $"../Vending_Machine/Buy_Oxygen_Tank",
	"delete": $"../Vending_Machine/Cashback"
}

# Item configurations
const ITEM_CONFIG = {
	"spanner": {"price": 20, "scene": "spanner_scene", "array": "spawned_spanners", "icon": "spanner"},
	"gun": {"price": 30, "scene": "gun_scene", "array": "spawned_guns", "icon": "harpoon"},
	"oxygen": {"price": 50, "scene": "oxygen_scene", "array": "spawned_oxygen", "icon": "oxygen"}
}

# Lists to track spawned objects
var spawned_spanners: Array = []
var spawned_guns: Array = []
var spawned_oxygen: Array = []

const SAVE_PATH = "user://object_save.json"
const SAVE_INTERVAL = 1.0
var time_since_last_save: float = 0.0
var objects_to_save: Dictionary = {} # Tracks objects for saving

func _ready() -> void:
	# Connect button signals
	for item in buttons:
		var button = buttons[item] as StaticBody3D
		if button:
			button.button_state_changed.connect(_on_button_pressed.bind(item))
		else:
			push_warning("Vending Machine: Button node for %s not found" % item)
	
	if not radar:
		push_warning("Vending-machine: Radar node not found")
	
	load_spawned_items()

func _process(delta: float) -> void:
	return
	


func _on_button_pressed(is_pressed: bool, item: String) -> void:
	if not is_pressed:
		return
	if item == "delete":
		delete_last_object()
	else:
		buy_and_spawn(item)

func buy_and_spawn(item: String) -> void:
	var config = ITEM_CONFIG[item]
	if player.subtract_money(config.price):
		spawn_item(item, config)
		player.show_notification("You bought " + item, 2.0)
	else:
		player.show_notification("No money", 2.0)

func spawn_item(item: String, config: Dictionary, position: Vector3 = Vector3.ZERO, rotation: Vector3 = Vector3.ZERO, scale: Vector3 = Vector3.ONE) -> void:
	var scene = get(config.scene) as PackedScene
	if not scene:
		return
	
	var container = Node3D.new()
	container.name = "%s_container_%d" % [item, get(config.array).size() + 1]
	add_child(container)
	
	var instance = scene.instantiate()
	instance.name = item
	instance.add_to_group("minimap_objects")
	instance.set_meta("minimap_icon", config.icon)
	
	# Apply transform
	if position != Vector3.ZERO:
		instance.global_position = position
	if rotation != Vector3.ZERO:
		instance.global_rotation = rotation
	if scale != Vector3.ONE:
		instance.scale = scale
	
	container.add_child(instance)
	
	get(config.array).append(instance)
	
	# Track for saving
	if instance is Node3D:
		objects_to_save[instance] = {
			"type": item,
			"last_transform": instance.global_transform,
			"needs_save": false
		}
	
	if radar and is_instance_valid(instance):
		radar.highlight_marker(instance)

func delete_last_object() -> void:
	var arrays = [
		{"array": spawned_spanners, "price": ITEM_CONFIG.spanner.price, "name": "spanner"},
		{"array": spawned_guns, "price": ITEM_CONFIG.gun.price, "name": "gun"},
		{"array": spawned_oxygen, "price": ITEM_CONFIG.oxygen.price, "name": "oxygen"}
	]
	
	var largest_array = null
	var max_size = -1
	for arr in arrays:
		if arr.array.size() > max_size:
			max_size = arr.array.size()
			largest_array = arr
	
	if largest_array and largest_array.array.size() > 0:
		var last_item = largest_array.array.pop_back()
		if last_item and is_instance_valid(last_item):
			spawn_particles(last_item.global_transform.origin)
			objects_to_save.erase(last_item)
			last_item.queue_free()
			if largest_array.price > 0:
				player.add_money(largest_array.price)
				player.show_notification("Cashback: " + str(largest_array.price), 2.0)
			print("Deleted a %s. %s left: %d" % [largest_array.name, largest_array.name.capitalize(), largest_array.array.size()])
		else:
			player.show_notification("No valid item to delete", 2.0)
			_play_deny_sound()
	else:
		player.show_notification("No items to delete", 2.0)
		_play_deny_sound()
func spawn_particles(position: Vector3) -> void:
	if destruction_particles:
		var particles = destruction_particles.instantiate()
		particles.global_transform.origin = position + Vector3(0, -1, 0)
		get_parent().add_child(particles)
		await get_tree().create_timer(0.1, false).timeout

func _play_deny_sound() -> void:
	if player.AudioManager:
		player.AudioManager.play_sound("res://sounds/button/wpn_denyselect.mp3")

func get_spawned_items_data() -> Array:
	var items_data = []
	for instance in objects_to_save:
		if is_instance_valid(instance):
			var item_data = {
				"type": objects_to_save[instance].type,
				"position": {
					"x": instance.global_position.x,
					"y": instance.global_position.y,
					"z": instance.global_position.z
				},
				"rotation": {
					"x": instance.global_rotation.x,
					"y": instance.global_rotation.y,
					"z": instance.global_rotation.z
				},
				"scale": {
					"x": instance.scale.x,
					"y": instance.scale.y,
					"z": instance.scale.z
				}
			}
			# Store high-precision floats as strings
			for axis in ["position", "rotation", "scale"]:
				for coord in ["x", "y", "z"]:
					item_data[axis][coord] = str(item_data[axis][coord])
			items_data.append(item_data)
			objects_to_save[instance].needs_save = false
	return items_data

func save_spawned_items() -> void:
	var save_data = load_existing_save_data()
	save_data["spawned_items"] = get_spawned_items_data()
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data, "", false))
		file.close()
	else:
		printerr("Error: Could not save spawned items to %s" % SAVE_PATH)

func load_spawned_items() -> void:
	# Clear existing items
	for array_name in ["spawned_spanners", "spawned_guns", "spawned_oxygen"]:
		var array = get(array_name)
		for item in array:
			if is_instance_valid(item):
				item.queue_free()
		array.clear()
	objects_to_save.clear()
	
	var save_data = load_existing_save_data()
	
	if save_data.has("spawned_items"):
		for item_data in save_data["spawned_items"]:
			if item_data.has("type") and item_data.has("position") and item_data.has("rotation") and item_data.has("scale"):
				var item_type = item_data["type"]
				if ITEM_CONFIG.has(item_type):
					var config = ITEM_CONFIG[item_type]
					var position = Vector3(
						float(item_data["position"]["x"]),
						float(item_data["position"]["y"]),
						float(item_data["position"]["z"])
					)
					var rotation = Vector3(
						float(item_data["rotation"]["x"]),
						float(item_data["rotation"]["y"]),
						float(item_data["rotation"]["z"])
					)
					var scale = Vector3(
						float(item_data["scale"]["x"]),
						float(item_data["scale"]["y"]),
						float(item_data["scale"]["z"])
					)
					spawn_item(item_type, config, position, rotation, scale)

func load_existing_save_data() -> Dictionary:
	var save_data = {}
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			var json_string = file.get_as_text()
			file.close()
			var json = JSON.new()
			if json.parse(json_string) == OK:
				save_data = json.data
			else:
				printerr("Error parsing save file: %s" % json.get_error_message())
	return save_data
