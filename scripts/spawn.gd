extends Node3D

# Blueprints for spawned objects
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

func _ready() -> void:
	# Connect button signals
	for item in buttons:
		var button = buttons[item] as StaticBody3D
		if button:
			button.button_state_changed.connect(_on_button_pressed.bind(item))
		else:
			push_warning("Vending Machine: Button node for %s not found" % item)
	
	if not radar:
		push_warning("Vending Machine: Radar node not found")

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
	player.show_notification("You buy" + " "+ item , 2.0)

func spawn_item(item: String, config: Dictionary) -> void:
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
	container.add_child(instance)
	
	get(config.array).append(instance)
	
	if radar and is_instance_valid(instance):
		radar.highlight_marker(instance)

func delete_last_object() -> void:
	var arrays = [
		{"array": spawned_spanners, "price": ITEM_CONFIG.spanner.price, "name": "spanner"},
		{"array": spawned_guns, "price": ITEM_CONFIG.gun.price, "name": "gun"},
		{"array": spawned_oxygen, "price": ITEM_CONFIG.oxygen.price, "name": "oxygen"}
	]
	
	# Find the array with the most elements
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
			last_item.queue_free()
			if largest_array.price > 0:
				player.add_money(largest_array.price)
			print("Deleted a %s. %s left: %d" % [largest_array.name, largest_array.name.capitalize(), largest_array.array.size()])
	else:
		_play_deny_sound()

func spawn_particles(position: Vector3) -> void:
	if destruction_particles:
		var particles = destruction_particles.instantiate()
		particles.global_transform.origin = position + Vector3(0, -1, 0)
		get_parent().add_child(particles)
		await get_tree().create_timer(0.1, false).timeout

func _play_deny_sound() -> void:
	if player.AudioManager:
		player.AudioManager.play_sound("res://voice/button/wpn_denyselect.mp3")
