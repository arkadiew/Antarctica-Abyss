extends TextureRect
@onready var fullscreen_checkbox: CheckBox = $"Setting=/CheckBox"
@onready var fov_slider: HSlider = $"Setting=/fov_slider"
@onready var player = get_node_or_null("/root/main/Player")
@onready var sound_slider: HSlider = $"Setting=/sound_slider2"
func _ready() -> void:
	sound_slider.value = 100
	sound_slider.value_changed.connect(_on_sound_slider_2_value_changed)
	fullscreen_checkbox.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	fullscreen_checkbox.toggled.connect(_on_check_box_toggled)
	if player and player.camera:  
		fov_slider.value = player.camera.fov  
		fov_slider.value_changed.connect(_on_fov_slider_value_changed)
	else:
		push_error("Player or Camera node not found!")

func _on_fov_slider_value_changed(value: float) -> void:
	if player and player.camera:  
		player.camera.fov = value
		if player.debug_mode:
			player.log_message("FOV updated to: " + str(value), true)
	else:
		push_error("Cannot update FOV: Player or Camera is null.")

func _on_check_box_toggled(toggled_on: bool) -> void:
	# Переключаем режим окна
	if toggled_on:  # Use toggled_on instead of button_pressed
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	#if player.debug_mode:
		#player.log_message("Fullscreen mode: " + str(toggled_on), true)  # Use toggled_on


func _on_sound_slider_2_value_changed(value: float) -> void:
	var volume_db = linear_to_db(value / 100.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), volume_db)
	#if player.debug_mode:
		#player.log_message("SFX volume updated to: " + str(value), true)
func linear_to_db(linear: float) -> float:
	if linear <= 0:
		return -80.0  # Минимальная громкость (тишина)
	return 20.0 * log(linear) / log(10.0)
