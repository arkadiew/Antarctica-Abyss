# This makes it a tool script, so it runs in the Godot editor too, not just in-game
@tool
# Tells Godot this is a StaticBody3D (a 3D object that doesn’t move) with a custom name
extends StaticBody3D
class_name BasicBlock

# A signal we can send out when the block’s position/rotation/scale changes
signal transform_changed

# Where all the texture files live
const _base_texture_folder = "res://addons/devblocks/textures/"

# A list of color options for the block
enum DEVBLOCK_COLOR_GROUP {DARK, GREEN, LIGHT, ORANGE, PURPLE, RED}
# Matches the color options to folder names where textures are stored
const _devblock_color_to_foldername := [
	"dark",    # DARK = 0
	"green",   # GREEN = 1
	"light",   # LIGHT = 2
	"orange",  # ORANGE = 3
	"purple",  # PURPLE = 4
	"red"      # RED = 5
]

# Lets you pick a color group in the editor, defaults to DARK
@export var block_color_group : DEVBLOCK_COLOR_GROUP = DEVBLOCK_COLOR_GROUP.DARK :
	set(value):
		block_color_group = value  # Updates the color when you pick a new one
		_update_mesh()  # Refreshes the block’s look with the new color

# A big list of styles you can slap on the block
enum DEVBLOCK_STYLE {
	DEFAULT,          # Plain and simple
	CROSS,            # X marks the spot
	CONTRAST,         # High contrast vibes
	DIAGONAL,         # Slash across it
	DIAGONAL_FADED,   # Faded diagonal
	GROUPED_CROSS,    # Crosses in a group
	GROUPED_CHECKERS, # Checkerboard in groups
	CHECKERS,         # Classic checkerboard
	CROSS_CHECKERS,   # Cross + checkers combo
	STAIRS,           # Looks like steps
	DOOR,             # Door texture
	WINDOW,           # Window texture
	INFO              # Info sign texture
}

# Lets you pick a style in the editor, defaults to DEFAULT
@export var block_style : DEVBLOCK_STYLE = DEVBLOCK_STYLE.DEFAULT :
	set(value):
		block_style = value  # Updates the style when you change it
		_update_mesh()  # Refreshes the block’s look with the new style

# Grabs the MeshInstance3D node (the actual 3D shape) when the block loads
@onready var _mesh : MeshInstance3D = $Mesh

# Runs when the block is ready (in-game or in-editor)
func _ready():
	# Sets up the block’s material by copying a base material file
	_mesh.set_surface_override_material(0, load("res://addons/devblocks/blocks/block_material.tres").duplicate(true))
	_update_mesh()  # Loads the right texture based on color and style
	_update_uvs()   # Fixes the texture alignment based on size
	_mesh.set_notify_local_transform(true)  # Makes sure we know when the block moves or scales
	# Hooks up the transform_changed signal to call _update_uvs when stuff changes
	transform_changed.connect(Callable(self, "_update_uvs"))

# Catches notifications from Godot, like when the block’s transform changes
func _notification(what : int):
	if what == NOTIFICATION_TRANSFORM_CHANGED:  # If it’s a transform change...
		transform_changed.emit()  # Send out the signal to update stuff

# Updates the block’s texture based on the color and style
func _update_mesh() -> void:
	if not _mesh:  # If there’s no mesh yet, bail out
		return
	var mat := _mesh.get_surface_override_material(0)  # Grab the material
	if not mat:  # If there’s no material, bail out
		return
	
	# Turns the style number into a texture name (like "texture_01" or "texture_13")
	var texture_i : int = block_style + 1  # +1 because styles start at 0, textures at 1
	var texture_i_str : String = ("0" if texture_i < 10 else "") + str(texture_i)  # Adds a "0" for single digits
	var texture_name := "texture_" + texture_i_str  # Builds the texture file name
	# Picks the right color folder from the list
	var texture_folder : String = _devblock_color_to_foldername[block_color_group]
	# Puts together the full path to the texture file
	var full_texture_path := _base_texture_folder + texture_folder + "/" + texture_name + ".png"
	var texture : Resource = load(full_texture_path)  # Loads the texture
	if not (texture is Texture):  # If it didn’t load right, skip it
		return
	
	# Slaps the loaded texture onto the block’s material
	_mesh.get_surface_override_material(0).set("albedo_texture", texture as Texture)

# Tweaks the texture’s UVs (how it stretches over the block) based on the block’s size
func _update_uvs() -> void:
	var mat = _mesh.get_surface_override_material(0)  # Grab the material
	var offset := Vector3()  # Starts with no offset
	# Loops through X, Y, Z to adjust the texture based on scale
	for i in range(3):
		# Checks if the scale is close to 1 or 2 (for texture alignment)
		var different_offset := fmod(scale[i], 2.0) >= 0.99  # True if scale is near 1, 3, etc.
		var different_offset2 := fmod(scale[i], 1.0) >= 0.49  # True if scale is near 0.5, 1.5, etc.
		# Sets a little offset to make the texture fit nicely
		offset[i] = (0.5 if different_offset else 1) - (0.25 if different_offset2 else 0.0)
	mat.set("uv1_scale", scale)  # Scales the texture to match the block’s size
	mat.set("uv1_offset", offset)  # Shifts the texture so it lines up right
