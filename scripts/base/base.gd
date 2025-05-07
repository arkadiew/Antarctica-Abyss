extends StaticBody3D

@onready var button_door: StaticBody3D = $Button_door1
@onready var button_door1: StaticBody3D = $Button_door2 
@onready var button_door2: StaticBody3D = $Button_door3
@onready var button_door3: StaticBody3D = $Button_door4
@onready var anim_player = $AnimationPlayer
@onready var collision1: CollisionShape3D = $Door1/StaticBody3D/CollisionShape3D
@onready var collision2: CollisionShape3D = $Door2/StaticBody3D/CollisionShape3D
@onready var no_water_zone: CollisionShape3D = $"../no_water_zone2/CollisionShape3D"

# Track the state of the door animation for button_door3
var door_is_open: bool = false
var door1_is_open: bool = false
var door2_is_open: bool = false
var door3_is_open: bool = false

# This runs when the vending machine first shows up in the game
func _ready():
	# Hook up the buttons so they actually do something when pressed
	if button_door:  
		button_door.connect("button_state_changed", _on_button_button_door) 
	if button_door1: 
		button_door1.connect("button_state_changed", _on_button_button_door1) 
	if button_door2: 
		button_door2.connect("button_state_changed", _on_button_button_door2) 
	if button_door3: 
		button_door3.connect("button_state_changed", _on_button_button_door3) 

# When the cube button gets pressed
func _on_button_button_door(is_pressed: bool):
	if is_pressed:
		if anim_player and anim_player.has_animation("Door2Action"):
			if door_is_open:
				# Play the animation in reverse to close the door
				anim_player.play_backwards("Door2Action")
				collision2.disabled = false
				no_water_zone.disabled = false
				door_is_open = false
			else:
				# Play the animation forward to open the door
				anim_player.play("Door2Action")
				collision2.disabled = true
				no_water_zone.disabled = true
				door_is_open = true
# When the gun button gets pressed
func _on_button_button_door1(is_pressed: bool):
	if is_pressed:
		if anim_player and anim_player.has_animation("Door2Action"):
			if door1_is_open:
				# Play the animation in reverse to close the door
				anim_player.play_backwards("Door2Action")
				collision2.disabled = false
				door1_is_open = false
			else:
				# Play the animation forward to open the door
				anim_player.play("Door2Action")
				collision2.disabled = true
				door1_is_open = true


# When the oxygen button gets pressed
func _on_button_button_door2(is_pressed: bool):
	if is_pressed:
		if anim_player and anim_player.has_animation("Door1Action"):
			if door2_is_open:
				# Play the animation in reverse to close the door
				anim_player.play_backwards("Door1Action")
				collision1.disabled = false
				door2_is_open = false
			else:
				# Play the animation forward to open the door
				anim_player.play("Door1Action")
				collision1.disabled = true
				door2_is_open = true

# When the delete button gets pressed
func _on_button_button_door3(is_pressed: bool):
	if is_pressed:
		if anim_player and anim_player.has_animation("Door1Action"):
			if door3_is_open:
				# Play the animation in reverse to close the door
				anim_player.play_backwards("Door1Action")
				collision1.disabled = false
				door3_is_open = false
			else:
				# Play the animation forward to open the door
				anim_player.play("Door1Action")
				collision1.disabled = true
				door3_is_open = true
