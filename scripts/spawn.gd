extends Node3D  # This tells Godot this script is attached to a 3D node, like a vending machine in a 3D game

# These are like "blueprints" for objects we can spawn later. We load them from their scene files.
@export var cube_scene: PackedScene = load("res://scenes/box/cube.tscn")  # Blueprint for a cube
@export var gun_scene: PackedScene = load("res://scenes/object/damaging_object.tscn")  # Blueprint for a gun
@export var oxygen_scene: PackedScene = load("res://scenes/oxygentank/oxygen_tank.tscn")  # Blueprint for an oxygen tank
@export var destruction_particles: PackedScene = load("res://scenes/partical.tscn")  # Blueprint for cool particle effects when stuff gets deleted

# Grabbing the player node so we can mess with their money and stuff
@onready var player = get_node("/root/main/Player")  # Finds the player in the game when the scene loads

# These are the buttons on the vending machine, ready to use once the game starts
@onready var button_node: StaticBody3D = $"../Vending_Machine/button"  # The "buy cube" button
@onready var delete_button_node: StaticBody3D = $"../Vending_Machine/delete_button"  # The "delete last thing" button
@onready var gun_button_node: StaticBody3D = $"../Vending_Machine/button_gun"  # The "buy gun" button
@onready var oxygen_button_node: StaticBody3D = $"../Vending_Machine/button_oxygen"  # The "buy oxygen" button

# Prices for each item - how much the player has to pay
var cube_price: int = 5  # Cubes are cheap, only 5 bucks
var gun_price: int = 30  # Guns cost more, 30 bucks
var oxygen_price: int = 60  # Oxygen is pricey, 60 bucks

# Lists to keep track of all the stuff we’ve spawned
var spawned_cubes: Array = []  # Keeps all the cubes we made
var spawned_guns: Array = []  # Keeps all the guns we made
var spawned_oxygen: Array = []  # Keeps all the oxygen tanks we made

# This runs when the vending machine first shows up in the game
func _ready():
	# Hook up the buttons so they actually do something when pressed
	if button_node:  # If the cube button exists...
		button_node.connect("button_state_changed", _on_button_state_changed)  # Connect it to the cube-buying function
	if delete_button_node:  # If the delete button exists...
		delete_button_node.connect("button_state_changed", _on_delete_button_state_changed)  # Connect it to the delete function
	if gun_button_node:  # If the gun button exists...
		gun_button_node.connect("button_state_changed", _on_button_gun_changed)  # Connect it to the gun-buying function
	if oxygen_button_node:  # If the oxygen button exists...
		oxygen_button_node.connect("button_state_changed", _on_button_oxygen_changed)  # Connect it to the oxygen-buying function

# When the cube button gets pressed
func _on_button_state_changed(is_pressed: bool):
	if is_pressed:  # If someone pushed it...
		buy_and_spawn("cube")  # Try to buy and spawn a cube

# When the gun button gets pressed
func _on_button_gun_changed(is_pressed: bool):
	if is_pressed:  # If someone pushed it...
		buy_and_spawn("gun")  # Try to buy and spawn a gun

# When the oxygen button gets pressed
func _on_button_oxygen_changed(is_pressed: bool):
	if is_pressed:  # If someone pushed it...
		buy_and_spawn("oxygen")  # Try to buy and spawn an oxygen tank

# When the delete button gets pressed
func _on_delete_button_state_changed(is_pressed: bool):
	if is_pressed:  # If someone pushed it...
		delete_last_object()  # Get rid of the last thing we spawned

# This handles buying and spawning whatever item the player wants
func buy_and_spawn(item: String):
	match item:  # Check what they’re trying to buy
		"cube":  # If it’s a cube...
			if player.subtract_money(cube_price):  # Take 5 bucks from the player, and if they have enough...
				spawn_cube()  # Make a cube appear
		"gun":  # If it’s a gun...
			if player.subtract_money(gun_price):  # Take 30 bucks, and if they can pay...
				spawn_gun()  # Make a gun appear
		"oxygen":  # If it’s oxygen...
			if player.subtract_money(oxygen_price):  # Take 60 bucks, and if they’ve got it...
				spawn_oxygen()  # Make an oxygen tank appear

# Makes a new cube pop into the game
func spawn_cube():
	if cube_scene:  # If we’ve got the cube blueprint...
		var container = Node3D.new()  # Make a little holder for the cube
		container.name = "cube_container_" + str(spawned_cubes.size() + 1)  # Give it a unique name like "cube_container_1"
		add_child(container)  # Stick the holder into the vending machine
		var cube = cube_scene.instantiate()  # Build the cube from the blueprint
		cube.name = "Box"  # Call it "Box" so we know what it is
		container.add_child(cube)  # Put the cube in its holder
		spawned_cubes.append(cube)  # Add it to our list of cubes

# Makes a new gun pop into the game
func spawn_gun():
	if gun_scene:  # If we’ve got the gun blueprint...
		var container = Node3D.new()  # Make a holder for the gun
		container.name = "gun_container_" + str(spawned_guns.size() + 1)  # Name it something like "gun_container_1"
		add_child(container)  # Add the holder to the vending machine
		var gun = gun_scene.instantiate()  # Build the gun from the blueprint
		gun.name = "gun"  # Call it "gun"
		container.add_child(gun)  # Put the gun in its holder
		spawned_guns.append(gun)  # Add it to our list of guns

# Makes a new oxygen tank pop into the game
func spawn_oxygen():
	if oxygen_scene:  # If we’ve got the oxygen blueprint...
		var container = Node3D.new()  # Make a holder for the oxygen tank
		container.name = "oxygen_container_" + str(spawned_oxygen.size() + 1)  # Name it like "oxygen_container_1"
		add_child(container)  # Add the holder to the vending machine
		var oxygen = oxygen_scene.instantiate()  # Build the oxygen tank from the blueprint
		oxygen.name = "oxygen_tank"  # Call it "oxygen_tank"
		container.add_child(oxygen)  # Put the tank in its holder
		spawned_oxygen.append(oxygen)  # Add it to our list of oxygen tanks

# Figures out which type of object to delete based on what we have most of
func delete_last_object():
	if spawned_cubes.size() >= spawned_guns.size() and spawned_cubes.size() >= spawned_oxygen.size():  # If we have more cubes (or equal)...
		delete_last_cube()  # Delete a cube
	elif spawned_guns.size() >= spawned_cubes.size() and spawned_guns.size() >= spawned_oxygen.size():  # If we have more guns (or equal)...
		delete_last_gun()  # Delete a gun
	elif spawned_oxygen.size() >= spawned_cubes.size() and spawned_oxygen.size() >= spawned_guns.size():  # If we have more oxygen tanks (or equal)...
		delete_last_oxygen()  # Delete an oxygen tank
	else:  # If there’s nothing to delete...
		if player.AudioManager:
				player.AudioManager.play_sound("res://voice/button/wpn_denyselect.mp3")
		print("No objects to delete.")  # Let us know there’s nothing left

# Deletes the last cube we made
func delete_last_cube():
	if spawned_cubes.size() > 0:  # If there’s at least one cube...
		var last_cube = spawned_cubes.pop_back()  # Grab the last cube from the list
		if last_cube and is_instance_valid(last_cube):  # Make sure it still exists...
			partic(last_cube.global_transform.origin)  # Add some cool particle effects where it was
			last_cube.queue_free()  # Delete the cube
			if cube_price > 0:  # If cubes cost something...
				player.add_money(cube_price)  # Give the player their money back
			print("Deleted a cube. Cubes left:", spawned_cubes.size())  # Tell us how many cubes are left
	else:
		if player.AudioManager:
				player.AudioManager.play_sound("res://voice/button/wpn_denyselect.mp3")

# Deletes the last gun we made
func delete_last_gun():
	if spawned_guns.size() > 0:  # If there’s at least one gun...
		var last_gun = spawned_guns.pop_back()  # Grab the last gun from the list
		if last_gun and is_instance_valid(last_gun):  # Make sure it’s still there...
			partic(last_gun.global_transform.origin)  # Show particle effects where it was
			last_gun.queue_free()  # Delete the gun
			if gun_price > 0:  # If guns cost something...
				player.add_money(gun_price)  # Refund the player
			print("Deleted a gun. Guns left:", spawned_guns.size())  # Tell us how many guns are left
	else:
		if player.AudioManager:
				player.AudioManager.play_sound("res://voice/button/wpn_denyselect.mp3")
# Deletes the last oxygen tank we made
func delete_last_oxygen():
	if spawned_oxygen.size() > 0:  # If there’s at least one oxygen tank...
		var last_oxygen = spawned_oxygen.pop_back()  # Grab the last tank from the list
		if last_oxygen and is_instance_valid(last_oxygen):  # Check it still exists...
			partic(last_oxygen.global_transform.origin)  # Add particle effects where it was
			last_oxygen.queue_free()  # Delete the tank
			if oxygen_price > 0:  # If oxygen costs something...
				player.add_money(oxygen_price)  # Give the money back to the player
			print("Deleted an oxygen tank. Tanks left:", spawned_oxygen.size())  # Tell us how many tanks are left
	else:
		if player.AudioManager:
				player.AudioManager.play_sound("res://voice/button/wpn_denyselect.mp3")
# Makes some fancy particle effects when something gets deleted
func partic(position: Vector3):
	if destruction_particles:  # If we’ve got the particle blueprint...
		var particles_instance = destruction_particles.instantiate()  # Create the particle effect
		var shift = Vector3(0, -1, 0)  # Move it down a bit so it looks right (adjust if needed)
		particles_instance.global_transform.origin = position + shift  # Put it where the object was
		get_parent().add_child(particles_instance)  # Add the particles to the game world
	await get_tree().create_timer(0.1).timeout  # Wait a tiny bit (0.1 seconds) before moving on
