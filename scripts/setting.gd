extends TextureRect

@onready var fullscreen_checkbox: CheckBox = $"Panel/Setting=/CheckBox"
@onready var fov_slider: HSlider = $"Panel/Setting=/fov_slider"
@onready var player = get_node_or_null("/root/main/Player")
@onready var sound_slider: HSlider = $"Panel/Setting=/sound_slider2"

const SFX_BUS_NAME: String = "SFX"
const MIN_DB: float = -60.0  # More reasonable minimum volume
const FULLSCREEN_SWITCH_DELAY: float = 0.1

func _ready() -> void:
	# Initialize sound slider
	sound_slider.value = 100
	sound_slider.value_changed.connect(_on_sound_slider_value_changed)
	
	# Initialize fullscreen checkbox
	var is_fullscreen: bool = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	fullscreen_checkbox.button_pressed = is_fullscreen
	fullscreen_checkbox.toggled.connect(_on_fullscreen_toggled)
	
	# Initialize FOV slider
	if _is_player_valid():
		fov_slider.value = player.camera.fov
		fov_slider.value_changed.connect(_on_fov_slider_value_changed)
	else:
		push_warning("Player or Camera node not found. FOV controls disabled.")

func _is_player_valid() -> bool:
	return player != null and player.camera != null

func _on_fov_slider_value_changed(value: float) -> void:
	if not _is_player_valid():
		push_warning("Cannot update FOV: Player or Camera is null.")
		return
	
	player.camera.fov = value
	if player.debug_mode:
		player.log_message("FOV updated to: %.1f" % value)

func _on_fullscreen_toggled(toggled_on: bool) -> void:
	# Disable UI elements during transition
	_set_ui_interaction(false)
	
	# Switch window mode
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if toggled_on 
		else DisplayServer.WINDOW_MODE_WINDOWED
	)
	
	# Wait for transition to complete
	await get_tree().create_timer(FULLSCREEN_SWITCH_DELAY, false).timeout
	
	# Re-enable UI elements
	_set_ui_interaction(true)
	
	if _is_player_valid() and player.debug_mode:
		player.log_message("Fullscreen mode: %s" % toggled_on)

func _on_sound_slider_value_changed(value: float) -> void:
	var volume_db: float = linear_to_db(value / 100.0)
	var bus_index: int = AudioServer.get_bus_index(SFX_BUS_NAME)
	
	if bus_index == -1:
		push_warning("SFX audio bus not found!")
		return
	
	AudioServer.set_bus_volume_db(bus_index, volume_db)
	
	if _is_player_valid() and player.debug_mode:
		player.log_message("SFX volume: %.1f%%" % value)

func _set_ui_interaction(enabled: bool) -> void:
	fov_slider.editable = enabled
	sound_slider.editable = enabled
	fullscreen_checkbox.disabled = not enabled

# Improved linear to decibel conversion
func linear_to_db(linear: float) -> float:
	linear = clampf(linear, 0.0, 1.0)
	if linear < 0.001:  # Avoid log(0) and provide smooth cutoff
		return MIN_DB
	return lerp(MIN_DB, 0.0, linear)
