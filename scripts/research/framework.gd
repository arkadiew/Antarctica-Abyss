# This makes it a 3D object that can move with physics (like a rolling box)
extends RigidBody3D

# Keeps track of stuff it picks up
var collected_items = []  # List of item names it’s collected
var item_counters = {"Stone": 0, "Curiosity": 0}  # Counts stones and curiosities

@export var collision_sound: AudioStream = preload("res://sounds/obj/thud-291047.mp3")

# Grabs nodes when the object loads
@onready var detection_area = $Area3D  # Area to detect nearby items
@onready var counter_label = $SubViewport/Control/Label  # Label to show counts
@onready var animation_player =  $frameworkv2/AnimationPlayer # For playing animations

var audio_player: AudioStreamPlayer3D
@export var impact_volume: float = -10.0  # Default to audible volume (adjust in Inspector if needed)
@export var max_sound_distance: float = 20.0

# Runs when the object first shows up
func _ready():
	setup_audio()
	# Hook up the detection area to notice when stuff enters it
	if detection_area:
		detection_area.connect("body_entered", _on_body_entered)
	# Warn if there’s no animation player (just in case)
	if not animation_player:
		print("Warning: AnimationPlayer node not found!")
	# Show the starting counts on the label
	update_counter_label()

func setup_audio() -> void:
	audio_player = AudioStreamPlayer3D.new()
	add_child(audio_player)
	
	if collision_sound:
		audio_player.stream = collision_sound
		audio_player.max_db = 0.0  # Maximum volume cap
		audio_player.max_distance = max_sound_distance
		audio_player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
		audio_player.volume_db = impact_volume  # Set initial volume
	else:
		print("Error: No collision sound assigned!")

# Called when something enters the detection area
func _on_body_entered(body):
	if audio_player and collision_sound:
		audio_player.volume_db = impact_volume  # Ensure volume is applied
		audio_player.play()
	else:
		print("Error: Audio player or collision sound not set up!")
	
	# Check if it’s a valid collectable thing
	if body and is_instance_valid(body) and body.is_in_group("collectable"):
		var item_name = body.name  # Grab the item’s name
		# Add to the right counter based on the name
		if "Stone" in item_name:
			item_counters["Stone"] += 1
		elif "Curiosity" in item_name:
			item_counters["Curiosity"] += 1
		# Get rid of the item (it’s collected now!)
		body.queue_free()
		# Add it to the collected list
		collected_items.append(item_name)
		# Show what’s been collected in the console
		print("Collected items: ", collected_items)
		# Play a little pickup animation
		play_collect_animation()
		# Update the label with the new counts
		update_counter_label()

# Plays an animation when something’s collected
func play_collect_animation():
	if animation_player and animation_player.has_animation("openframework"):
		animation_player.play("openframework")  # Play it!
	else:
		print("Error: AnimationPlayer or 'openframework' animation not set up!")

# Updates the label to show how many items we’ve got
func update_counter_label():
	if counter_label:
		counter_label.text = "Stones: %d\nCuriosities: %d" % [item_counters["Stone"], item_counters["Curiosity"]]

# Lets other stuff see the full list of collected items
func get_collected_items():
	return collected_items

# Lets other stuff see the counts of stones and curiosities
func get_item_counters():
	return item_counters

# Just prints a message for when something succeeds (like a task)
func register_success():
	print("Success registered in framework")

# Prints a message for when something fails
func register_failure():
	print("Failure registered in framework")

# Prints a message for a half-success (like partial completion)
func register_half_success():
	print("Half registered in framework")
