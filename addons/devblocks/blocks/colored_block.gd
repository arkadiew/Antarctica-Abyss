# Makes this script work in the Godot editor too, not just in-game
@tool
# Builds on the BasicBlock class and gives it a custom name
extends BasicBlock
class_name ColoredBlock

# Lets you pick a color in the editor, starts as white
@export var block_color : Color = Color.WHITE :
	set(value):
		block_color = value  # Updates the color when you pick a new one
		_update_mesh()  # Refreshes the block’s look with the new color

# Updates the block’s appearance, including the new color
func _update_mesh() -> void:
	super._update_mesh()  # Runs the BasicBlock’s _update_mesh first to handle textures
	# If the mesh has a material...
	if $Mesh.get_surface_override_material(0):
		# Slaps the chosen color onto the material
		$Mesh.get_surface_override_material(0).set("albedo_color", block_color)
