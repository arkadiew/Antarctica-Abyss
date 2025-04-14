# This makes it a 3D object that doesn’t move, like a button stuck in place
extends StaticBody3D

# A signal to let other stuff know when the button’s pressed or released (Godot ignores the "unused" warning)

signal button_state_changed(is_pressed: bool)  # Sends out a “hey, the button’s state changed” message

@onready var player = get_node("/root/main/Player")  # The player character in the game

# Grabs the AnimationPlayer node when the button’s ready
@onready var anim = $AnimationPlayer  # For playing press-down or press-up animations

# Keeps track of whether the button’s currently pressed
var is_pressed: bool = false  # Starts off as not pressed (false)

# Finds the player’s raycast (a line that checks what they’re looking at) when the button loads
@onready var interact_ray: RayCast3D = get_tree().get_first_node_in_group("player").get_node("CameraPivot/Camera3D/inbutton")

# Runs every frame to check if the player’s interacting with the button
func _process(delta: float) -> void:
	# If the player’s looking right at this button with their raycast...
	if interact_ray.is_colliding() and interact_ray.get_collider() == self:
		# If they hit the "use_item" key (like E) and the button’s not pressed yet...
		if Input.is_action_just_pressed("use_item") and not is_pressed:
			if player.AudioManager:
				player.AudioManager.play_sound("res://sounds/button/button.mp3")
			anim.play("pressdown")  # Play the animation of the button going down
			is_pressed = true  # Mark it as pressed
			emit_signal("button_state_changed", is_pressed)  # Tell everyone the button’s now pressed
		# If they let go of the "use_item" key and the button’s currently pressed...
		elif Input.is_action_just_released("use_item") and is_pressed:
			anim.play("pressup")  # Play the animation of the button popping back up
			is_pressed = false  # Mark it as not pressed anymore
			emit_signal("button_state_changed", is_pressed)  # Tell everyone the button’s released
