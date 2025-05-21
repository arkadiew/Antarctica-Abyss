extends BaseBreakable
@export var spanner_scene: PackedScene = preload("res://scenes/object/spanner.tscn")
@export var gun_scene: PackedScene = preload("res://scenes/object/damaging_object.tscn")
@export var oxygen_scene: PackedScene = preload("res://scenes/oxygentank/oxygen_tank.tscn")

# Additional export variable specific to this class
@export var bounce_force: float = 2.0

func _ready() -> void:
	super._ready()  # Call parent _ready()
	print("Initialized breakable object: ", name)

func _on_body_entered(body: Node) -> void:
	super._on_body_entered(body)  # Call parent collision logic
	# Add bounce effect
	if body is RigidBody3D:
		var direction = (body.global_position - global_position).normalized()
		apply_central_impulse(direction * bounce_force)
		print("Bounced off ", body.name)

func _on_destroyed() -> void:
	print(name, " has been destroyed!")
	# Array of possible items to spawn
	var possible_items: Array[PackedScene] = [spanner_scene, gun_scene, oxygen_scene]
	# Randomly select an item
	var selected_item: PackedScene = possible_items[randi() % possible_items.size()]
	# Instance the selected item
	var item_instance = selected_item.instantiate()
	# Add to the scene tree
	get_tree().current_scene.add_child(item_instance)
	# Set position with slight random offset
	item_instance.global_position = global_position + Vector3(
		randf_range(-0.5, 0.5),
		randf_range(0.0, 0.5),
		randf_range(-0.5, 0.5)
	)
