extends StaticBody3D

@onready var player = get_node("/root/main/Player")
@onready var camera = player.get_node("CameraPivot/Camera3D")
@onready var interact_ray = player.get_node("CameraPivot/Camera3D/InteractRay")
@export var repair_particles: PackedScene = preload("res://scenes/partical.tscn") # For repair effects

var health: float = randf_range(20.0, 35.0)
var max_health: float = 100.0
var is_repairable: bool = true
var has_awarded_money: bool = false
var contributor_id: String

@onready var broken_model: Node3D = $BrokenPipe
@onready var damaged_model: Node3D = $DamagedPipe
@onready var repaired_model: Node3D = $RepairedPipe

const BROKEN_THRESHOLD: float = 30.0
const DAMAGED_THRESHOLD: float = 70.0

signal health_changed(new_health)
signal repair_ui_toggle(show: bool)
signal money_awarded(amount: int)

func _ready():
	contributor_id = get_path()
	var details = {"max_health": max_health}
	TaskManager.register_task("pipe_repair", "Repair Pipe", max_health, contributor_id, details)
	update_health()
	emit_signal("health_changed", health)
	TaskManager.update_task_progress("pipe_repair", contributor_id, health)
	print("Pipe initialized: ID=", contributor_id, ", Health=", health, ", Max Health=", max_health)

func _process(_delta):
	var should_show_ui = false
	if interact_ray.is_colliding():
		var collider = interact_ray.get_collider()
		if collider == self and is_repairable:
			should_show_ui = true
	
	if should_show_ui != $Control.visible:
		emit_signal("repair_ui_toggle", should_show_ui)

func repair(amount: float):
	if is_repairable:
		# Spawn repair particles
		if repair_particles:
			var particles_instance = repair_particles.instantiate()
			# Assuming the GPUParticles3D is a child named "Particles"
			var particles_node = particles_instance.get_node("CPUParticles3D") as CPUParticles3D
			if particles_node:
				particles_instance.global_position = global_position + Vector3(0, 0.5, 0)
				particles_node.emitting = true
				get_parent().add_child(particles_instance)
				await get_tree().create_timer(particles_node.lifetime).timeout
				particles_instance.queue_free()
			else:
				print("Error: Could not find CPUParticles3D node named 'Particles' in repair_particles scene")
	
		health = min(health + amount, max_health)
		# Rest of the function remains the same
		update_health()
		emit_signal("health_changed", health)
		TaskManager.update_task_progress("pipe_repair", contributor_id, health)
		print("Pipe repaired: ID=", contributor_id, ", New Health=", health)
		
		if health >= max_health:
			is_repairable = false
			emit_signal("repair_ui_toggle", false)
			if not has_awarded_money:
				player.add_money(35)
				has_awarded_money = true
				emit_signal("money_awarded", 35)
			player.show_notification("Pipe repaired successfully!", 2)
			print("Pipe fully repaired: ID=", contributor_id)

func update_health():
	update_model()

func update_model():
	broken_model.visible = health <= BROKEN_THRESHOLD
	damaged_model.visible = health > BROKEN_THRESHOLD and health <= DAMAGED_THRESHOLD
	repaired_model.visible = health > DAMAGED_THRESHOLD
