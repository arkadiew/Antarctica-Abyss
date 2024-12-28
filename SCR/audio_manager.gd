extends Node

# Audio manager script to handle all sound effects
@export var default_volume: float = -10.0  # Default volume in dB
@onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer

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
