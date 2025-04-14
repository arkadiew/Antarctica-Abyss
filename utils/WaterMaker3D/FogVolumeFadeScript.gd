# This makes it a fog effect in 3D space (like a misty cloud)
extends FogVolume

# How far away the fog starts fading out from the camera (you can tweak this in the editor)
@export var fade_distance := 1

# Runs every frame to update the fog’s fade effect
func _process(_delta):
	# Grab the 3D camera that’s currently looking at the scene (if there is one)
	var cam = get_viewport().get_camera_3d() if get_viewport() else null
	if cam:  # If we’ve got a camera...
		# Get the direction the camera’s facing (z-axis), flipped and scaled a bit
		var fade_plane_normal = cam.global_transform.basis.z * -0.6
		# Figure out where the fade plane starts (a bit in front of the camera)
		var fade_plane_pos = cam.global_transform.origin + cam.global_transform.basis.z * -fade_distance
		# Calculate the distance for the fade plane (math stuff for the shader)
		var fade_plane_distance = fade_plane_pos.dot(fade_plane_normal)
		# Pack it into a Vector4 for the shader (x, y, z, and distance)
		var fade_plane = Vector4(fade_plane_normal.x, fade_plane_normal.y, fade_plane_normal.z, fade_plane_distance)
		# Send that info to the fog’s material shader to control the fade
		self.material.set_shader_parameter("fade_plane", fade_plane)
