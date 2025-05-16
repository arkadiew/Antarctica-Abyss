extends StaticBody3D

@onready var buttons = {
	"door": $Button_door1,
	"door1": $Button_door2,
	"door2": $Button_door3,
	"door3": $Button_door4
}
@onready var anim_player = $AnimationPlayer
@onready var collision1 = $Door1/StaticBody3D/CollisionShape3D
@onready var collision2 = $Door2/StaticBody3D/CollisionShape3D
@onready var no_water_zone = $"../no_water_zone/CollisionShape3D"
@onready var player = get_node_or_null("/root/main/Player")

var door_states = {
	"door": false,
	"door1": false,
	"door2": false,
	"door3": false
}

func _ready():
	# Connect button signals
	for key in buttons:
		if buttons[key]:
			buttons[key].connect("button_state_changed", Callable(self, "_on_button_pressed").bind(key))

func _on_button_pressed(is_pressed: bool, button_key: String):
	if not is_pressed or not anim_player:
		return

	var is_door2 = button_key in ["door", "door1"]
	var animation = "Door2Action" if is_door2 else "Door1Action"
	var collision = collision2 if is_door2 else collision1
	var state = door_states[button_key]

	if anim_player.has_animation(animation):
		if state:
			anim_player.play_backwards(animation)
			collision.disabled = false
			if button_key == "door":
				no_water_zone.disabled = false
			player.log_message("Closed door", true, Color.CORAL)
		else:
			anim_player.play(animation)
			collision.disabled = true
			if button_key == "door":
				no_water_zone.disabled = true
			player.log_message("Opened door", true, Color.CORAL)
		door_states[button_key] = not state
