extends BaseFish

func _ready() -> void:
	super._ready()

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	_play_swim_animation()

func _play_swim_animation() -> void:
	var anim_player = find_child("AnimationPlayer", true, false)
	if anim_player and anim_player.has_animation("Fish"):
		if get_tree().paused:
			anim_player.stop()  # Останавливаем анимацию при паузе сцены
		else:
			if anim_player.current_animation != "Fish":
				anim_player.play("Fish")
