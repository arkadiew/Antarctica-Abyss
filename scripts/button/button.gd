extends StaticBody3D

signal button_state_changed(is_pressed: bool)  # Сигнал изменения состояния кнопки

@onready var player = get_node("/root/main/Player")  # Ссылка на игрока
@onready var anim = $AnimationPlayer  # Анимация кнопки
@onready var interact_ray: RayCast3D = get_tree().get_first_node_in_group("player").get_node("CameraPivot/Camera3D/inbutton")

var is_pressed: bool = false  # Состояние кнопки (нажата или нет)
var button_name: String = "Button"  # Название кнопки по умолчанию

func _ready() -> void:
	# Определяем название кнопки на основе группы
	set_button_name_from_group()

func _process(delta: float) -> void:
	# Проверяем, смотрит ли игрок на кнопку
	if interact_ray.is_colliding() and interact_ray.get_collider() == self:
		# Обновляем текст в интерфейсе игрока
		player.label_3d.text = "Interact with " + button_name
		player.Menu.visible = true
		player.label_3d.visible = true
		
		# Обработка нажатия
		if Input.is_action_just_pressed("player_use_item") and not is_pressed:
			if player.AudioManager:
				player.AudioManager.play_sound("res://sounds/button/button.mp3")
			anim.play("pressdown")
			is_pressed = true
			emit_signal("button_state_changed", is_pressed)
		# Обработка отпускания
		elif Input.is_action_just_released("player_use_item") and is_pressed:
			anim.play("pressup")
			is_pressed = false
			emit_signal("button_state_changed", is_pressed)
	else:
		# Скрываем интерфейс, если игрок не смотрит на кнопку
		if player.label_3d.text.begins_with("Interact with " + button_name):
			player.label_3d.visible = false
			player.Menu.visible = false

# Устанавливаем название кнопки на основе группы
func set_button_name_from_group() -> void:
	var groups = get_groups()  # Получаем все группы, к которым принадлежит кнопка
	if groups.size() > 0:
		# Используем первую группу как основу для имени
		var group_name = groups[0]
		# Преобразуем имя группы в читаемое название (например, "MainRoomButtons" → "Main Room Button")
		button_name = group_name.replace("Buttons", " Button").replace("_", " ")
		# Добавляем уникальный идентификатор, если нужно (например, по позиции или индексу)
		var buttons_in_group = get_tree().get_nodes_in_group(group_name)
		var index = buttons_in_group.find(self) + 1
		if buttons_in_group.size() > 1:
			button_name += " " + str(index)
	else:
		# Если групп нет, используем имя узла или стандартное название
		button_name = name if name != "" else "Button"
