extends BaseFish

# Runs when the fish spawns
func _ready() -> void:
	super._ready()  # Call the base class _ready()

# Override physics process to add animation
func _physics_process(delta: float) -> void:
	super._physics_process(delta)  # Call the base class physics process
	_play_swim_animation()

# Play the swimming animation if available
func _play_swim_animation() -> void:
	var anim_player = find_child("AnimationPlayer", true, false)
	if anim_player and anim_player.has_animation("Fish"):
		if anim_player.current_animation != "Fish":
			anim_player.play("Fish")
