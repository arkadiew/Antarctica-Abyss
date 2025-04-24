extends CanvasLayer  # Скрипт должен быть прикреплён к CanvasLayer или к другому Control-узлу

@export var player: Node3D  # Укажи игрока в инспекторе

func _ready():
	await get_tree().process_frame  # Ждём инициализации размеров
	var icon = $MinimapContainer/PlayerIcon
	var container = $MinimapContainer
	
func _process(_delta):
	if not player:
		return

	var camera = $MinimapContainer/MinimapViewport/MinimapCamera
	var icon = $MinimapContainer/PlayerIcon

	# Центрируем камеру над игроком (по X и Z)
	camera.global_position.x = player.global_position.x
	camera.global_position.z = player.global_position.z

	# Рассчитываем направление взгляда
	var forward = -player.global_transform.basis.z  # Вперёд — минус Z
	var angle = atan2(forward.x, forward.z)

	# Поворачиваем иконку игрока
	icon.rotation = -angle
