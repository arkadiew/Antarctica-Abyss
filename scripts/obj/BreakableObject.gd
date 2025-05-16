extends BaseBreakable

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
	# Add custom destruction logic here if needed
