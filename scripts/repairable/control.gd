extends Control

@onready var progress_bar = $ProgressBar
@onready var pipe = $".."
func _ready():
	if pipe:
		pipe.health_changed.connect(_on_health_changed)
		pipe.repair_ui_toggle.connect(_on_repair_ui_toggle)
		visible = false
	if progress_bar:
		progress_bar.value = 50.0 # Тестовое значение
		print("Set progress bar to 50")

func _on_health_changed(new_health: float):
	progress_bar.value = new_health # Обновляем прогресс-бар

func _on_repair_ui_toggle(show: bool):
	visible = show # Показываем или скрываем UI
