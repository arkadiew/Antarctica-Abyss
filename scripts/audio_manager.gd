extends Node

# Audio manager script to handle all sound effects
@export var default_volume: float = -10.0  # Default volume in dB
@onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer
var current_sound: String = ""  # Track the currently playing sound
@onready var player: AudioStreamPlayer = $WalkPlayer


# Plays a sound effect
func play_sound(sound_path: String, volume_db: float = default_volume) -> void:
	if audio_player.is_playing():
		audio_player.stop()
	
	# Dynamically load the sound file
	var sound_stream = ResourceLoader.load(sound_path)
	if sound_stream and sound_stream is AudioStream:  # Ensure it's a valid AudioStream
		audio_player.stream = sound_stream
		audio_player.volume_db = volume_db
		audio_player.play()
	else:
		print("Failed to load sound: ", sound_path)
		
# Play a sound file with a specified volume
func play_sound_player(sound_path: String, volume_db: float = default_volume) -> void:
	if player.is_playing():
		player.stop()

	# Dynamically load the sound file
	var sound_stream = ResourceLoader.load(sound_path)
	if sound_stream and sound_stream is AudioStream:  # Ensure it's a valid AudioStream
		player.stream = sound_stream
		player.volume_db = volume_db
		player.play()
		# Update the current sound based on the path
		if sound_path.ends_with("walk.mp3"):
			current_sound = "walk_sound"
		elif sound_path.ends_with("sprint.mp3"):
			current_sound = "run_sound"
		elif sound_path.ends_with("swim.mp3"):
			current_sound = "swim_sound"
	else:
		print("Failed to load sound: ", sound_path)

# Stop a specific sound
func stop_sound(sound_name: String) -> void:
	if current_sound == sound_name and player.is_playing():
		player.stop()
		current_sound = ""

# Check if a specific sound is playing
func is_playing(sound_name: String) -> bool:
	return player.is_playing() and current_sound == sound_name
