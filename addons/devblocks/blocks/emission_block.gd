# Makes this script work in the Godot editor too, not just in-game
@tool
# Builds on ColoredBlock and gives it a custom name
extends ColoredBlock
class_name EmissionBlock

# Lets you set a glow strength in the editor, from 0 (no glow) to 4 (super bright), defaults to 1
@export_range(0.0, 4.0) var emission_energy : float = 1.0 :
	set(value):
		emission_energy = value  # Updates the glow when you tweak it
		_update_mesh()  # Refreshes the block’s look with the new glow

# Runs when the block is ready (in-game or in-editor)
func _ready() -> void:
	super._ready()  # Calls ColoredBlock’s _ready to set up the basics
	# Turns on the glow effect for the block’s material
	$Mesh.get_surface_override_material(0).set("emission_enabled", true)

# Updates the block’s appearance, including color and glow
func _update_mesh() -> void:
	super._update_mesh()  # Runs ColoredBlock’s _update_mesh for texture and color stuff
	# Sets the glow color to match the block’s main color
	$Mesh.get_surface_override_material(0).set("emission", block_color)
	# Sets how strong the glow is based on emission_energy
	$Mesh.get_surface_override_material(0).set("emission_energy", emission_energy)
