extends GPUParticles3D  # Или Particles, если используете Particles

func _ready():
	# Ждем завершения времени жизни частиц
	await get_tree().create_timer(lifetime).timeout
	# Удаляем узел с частицами
	queue_free()
