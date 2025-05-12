<h1>Antarctica Abyss</h1>
		A Work-in-Progress Educational Game Project

<p style="background: #e8f0fe; padding: 10px; border-left: 4px solid #1a73e8; margin: 10px 0; border-radius: 4px;"><strong>Note:</strong> This project is a final diploma project for educational purposes. It is under active development, and some features may be incomplete or require fixes.</p>

<h2>Project Overview</h2>
		<p><strong>Antarctica-Abyss</strong> is a first-person game combining elements of horror, survival, exploration, and puzzle-solving, developed as a final project for our diploma. Set in an underwater Arctic research base, you play as a scientist tasked with completing daily missions in a mysterious Arctic lake under a tight deadline. Your task completion contributes to a percentage score that determines one of two endings: <strong>Success</strong> (all tasks completed) or <strong>Game Over</strong> (restart required).</p>
		<p>The game is a work-in-progress (WIP), built using the <strong>Godot Engine</strong> with 3D assets crafted in <strong>Blender</strong>. It features unique mechanics like sliding, diving, and task-based progression, designed to create an immersive experience.</p>

<h2>Installation</h2>
	<p>To install EXE file, follow these steps:</p>
 	<ol>
			<li><strong>Find release version file</strong>:
				<ul>
			<li>Follow link https://github.com/arkadiew/Antarctica-Abyss/releases</li>
			<li>Dowload latest version EXE file</li>
		</ul>
			</li>
			<li><strong>Start EXE file</strong>:
				<ul>
					<li>Double click on EXE file to start it</li>
					<li>Play game!</li>
				</ul>
			</li>
		</ol>
		<p>To set up and run the project locally, follow these steps:</p>
		<ol>
			<li><strong>Clone the Repository</strong>:
				<pre><code>git clone https://github.com/your-username/Antarctica-Abyss.git cd Antarctica-Abyss</code></pre>
			</li>
			<li><strong>Install Godot Engine</strong>:
				<ul>
					<li>Download <a href="https://godotengine.org/">Godot Engine</a> (version 4.3 recommended).</li>
					<li>Install and ensure it's accessible in your IDE or system PATH.</li>
				</ul>
			</li>
			<li>
    			<strong>Download additional game files</strong>:  
   			 To test the game properly, you need to download extra asset files from Google Drive:  
    					<a href="https://drive.google.com/example-link" target="_blank">Google Drive – Antarctica Abyss Assets</a> 
				After you downloaded files, you need to place them in the root folder to work
			</li>
			<li><strong>Open the Project</strong>:
				<ul>
					<li>Launch Godot Engine.</li>
					<li>Click "Import" and select the <code>project.godot</code> file in the <code>Antarctica-Abyss</code> folder.</li>
				</ul>
			</li>
			<li><strong>Run the Game</strong>:
				<ul>
					<li>Press <code>F5</code> in Godot to play the current build.</li>
					<li>Note: Some features may be unstable as this is a WIP.</li>
				</ul>
			</li>
			<li><strong>Optional: Modify Assets</strong>:
				<ul>
					<li>Install <a href="https://www.blender.org/">Blender</a> (version 3.x or later) to edit 3D assets.</li>
					<li>Find assets in the <code>assets/models</code> directory.</li>
				</ul>
			</li>
		</ol>

<h2>Special Mechanics</h2>
		<p>The game includes unique mechanics to enhance gameplay, though some are still in development:</p>
		<ul>
			<li><strong>Sliding</strong>: Move quickly across icy surfaces to evade hazards or reach objectives. Sliding is triggered on specific terrain types.</li>
			<li><strong>Diving</strong>: Submerge into the Arctic lake to explore underwater areas and complete tasks. Oxygen management is a key survival element.</li>
			<li><strong>Task Progression</strong>: Daily tasks (e.g., collecting samples, solving puzzles) contribute to a completion percentage that determines the ending.</li>
			<li><strong>Survival Elements</strong>: Manage resources like oxygen and stamina while facing environmental threats.</li>
		</ul>
		<div class="note">
			<p><strong>WIP Status</strong>: Sliding may occasionally clip through objects, and diving oxygen mechanics are still being balanced. These will be refined in future updates.</p>
		</div>

<h2>Code Examples</h2>
		<p>Below are snippets from our GDScript code to illustrate key mechanics. These are simplified for clarity and may evolve as development continues.</p>

<h3>Player Movement</h3>
		<p>This script handles basic player movement on icy surfaces:</p>
		<pre><code>
			   
func determine_character_speed() -> float:
	if is_running and stamina > 0:
		return WALK_SPEED * RUN_SPEED_MULTIPLIER
	elif stamina == 0:
		return LOW_STAMINA_SPEED
	return WALK_SPEED

func update_movement(delta: float) -> void:
	var input_vector = get_input_direction()
	var target_speed = determine_character_speed()
	var target_velocity = Vector3(input_vector.x * target_speed, velocity.y, input_vector.z * target_speed)

	if is_on_floor() and input_vector.length() > 0 and not is_running and AudioManager:
		if not AudioManager.is_playing("walk_sound"):
			AudioManager.play_sound_player("res://voice/player/walk.mp3")
	elif AudioManager and AudioManager.is_playing("walk_sound"):
		AudioManager.stop_sound("walk_sound")  #
	if is_on_floor() and is_running and AudioManager:
		if not AudioManager.is_playing("run_sound"):
			AudioManager.play_sound_player("res://voice/player/sprint.mp3")
	elif AudioManager and AudioManager.is_playing("run_sound"):
		AudioManager.stop_sound("run_sound")
		
	if input_vector.length() > 0:
		velocity.x = lerp(velocity.x, target_velocity.x, ACCELERATION * delta)
		velocity.z = lerp(velocity.z, target_velocity.z, ACCELERATION * delta)
	else:
		velocity.x = lerp(velocity.x, 0.0, DECELERATION * delta)
		velocity.z = lerp(velocity.z, 0.0, DECELERATION * delta)
	if not is_on_floor():
		velocity.x = lerp(velocity.x, target_velocity.x, AIR_CONTROL * delta)
		velocity.z = lerp(velocity.z, target_velocity.z, AIR_CONTROL * delta)
	if can_run and Input.is_action_pressed("run") and stamina > 0 and not is_in_water():
		is_running = true
	else:
		is_running = false
	if is_on_floor():
		handle_character_jump(delta)
	else:
		apply_gravity_force(delta)
	apply_character_turn_tilt(delta)
	move_and_slide()

func apply_gravity_force(delta: float) -> void:
	if not is_on_floor():
		velocity.y = max(velocity.y + GRAVITY * delta, TERMINAL_VELOCITY)

func handle_character_jump(delta: float) -> void:
	if Input.is_action_just_pressed("jump") and stamina >= JUMP_STAMINA_COST:
		velocity.y = JUMP_FORCE
		decrease_stamina(JUMP_STAMINA_COST)

func apply_character_turn_tilt(delta: float) -> void:
	var input_direction = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var target_tilt_angle = -input_direction.x * max_tilt
	tilt_angle = lerp(tilt_angle, target_tilt_angle, delta * tilt_speed)
	$CameraPivot.rotation_degrees.z = tilt_angle

func apply_stamina_penalty_for_holding(delta):
	var drain_factor = (holding_object_time / 10.0)
	if holding_object_time >= 1.0:
		decrease_stamina(10.0 * drain_factor * delta)
func update_stamina(delta):
	var in_water = is_in_water()
	var moving = get_input_direction().length() > 0
	if can_run and stamina > 0 and Input.is_action_pressed("run") and moving and not in_water:
		decrease_stamina(STAMINA_RUN_DEPLETION_RATE * delta)
		stamina_recovery_timer = STAMINA_RECOVERY_DELAY
		is_running = true
	else:
		is_running = false
		stamina_recovery_timer -= delta
		if stamina_recovery_timer <= 0 and stamina < MAX_STAMINA:
			increase_stamina(STAMINA_RECOVERY_RATE * delta)
			can_run = true
	stamina_bar.value = stamina


func decrease_stamina(amount: float):
	stamina = clamp(stamina - amount, 0, MAX_STAMINA)


func increase_stamina(amount: float):
	stamina = clamp(stamina + amount, 0, MAX_STAMINA)
</code></pre>

<h3>Diving Mechanic</h3>
		<p>This script manages diving and oxygen levels when underwater:</p>
		<pre><code>

func is_camera_fully_submerged() -> bool:
	if not is_instance_valid(camera_pivot) or not get_tree():
		return false
	var water_areas = get_tree().get_nodes_in_group("water_area")
	for area in water_areas:
		if area is Area3D:
			var camera_pos = camera_pivot.global_transform.origin
			# Assume the Area3D has a CollisionShape3D
			var shape = area.get_node("CollisionShape3D")
			if shape and shape.shape is BoxShape3D:
				var water_top = area.global_transform.origin.y + shape.shape.extents.y
				var water_bottom = area.global_transform.origin.y - shape.shape.extents.y
				# Check if the camera is below the water's top boundary
				if camera_pos.y < water_top and camera_pos.y > water_bottom:
					return true
	return false

func is_in_water() -> bool:
	if not is_instance_valid(self) or not get_tree():
		return false
	var water_areas = get_tree().get_nodes_in_group("water_area")
	for area in water_areas:
		if area.overlaps_body(self):
			return true
	return false


func handle_water_physics(delta: float) -> void:
	if is_in_water():
		is_underwater = true
	
		apply_buoyancy_and_drag_scuba(delta)
		handle_swimming_input_scuba(delta)
	else:
		is_underwater = false
		if velocity.y > 0:
			velocity.y = lerp(velocity.y, 0.0, delta * 5.0)
		velocity.y = lerp(velocity.y, 0.0, delta * 2.0)
	velocity = velocity.limit_length(TERMINAL_VELOCITY * -1)


func apply_buoyancy_and_drag_scuba(delta: float) -> void:
	var buoyancy_force = -GRAVITY * WATER_DENSITY * PLAYER_VOLUME * BUOYANCY_FACTOR
	velocity.y = lerp(velocity.y, buoyancy_force, delta * 2.0)
	var drag = 0.9 if resisting_flow else 0.7
	velocity.x = lerp(velocity.x, 0.0, drag * delta)
	velocity.z = lerp(velocity.z, 0.0, drag * delta)
	velocity.y = clamp(velocity.y, TERMINAL_VELOCITY, SWIM_UP_SPEED)


func handle_swimming_input_scuba(delta: float) -> void:
	var input_direction = get_input_direction()
	var speed = SWIM_SPEED
	if h2o < OXYGEN_CRITICAL_LEVEL:
		speed *= OXYGEN_LOW_MOVEMENT_PENALTY
	var target_velocity = Vector3(input_direction.x * speed, velocity.y, input_direction.z * speed)
	if input_direction != Vector3.ZERO:
		velocity.x = lerp(velocity.x, target_velocity.x, ACCELERATION * delta * 0.5)
		velocity.z = lerp(velocity.z, target_velocity.z, ACCELERATION * delta * 0.5)
		decrease_stamina(0.5 * delta)
	else:
		velocity.x = lerp(velocity.x, 0.0, DECELERATION * delta * 0.5)
		velocity.z = lerp(velocity.z, 0.0, DECELERATION * delta * 0.5)
	if Input.is_action_pressed("jump") and stamina > 1:
		velocity.y = lerp(velocity.y, SWIM_UP_SPEED, delta * 2.0)
		decrease_stamina(2.0 * delta)
	elif Input.is_action_pressed("crouch") and stamina > 1:
		velocity.y = lerp(velocity.y, -SWIM_DOWN_SPEED, delta * 2.0)
		decrease_stamina(STAMINA_DOWN_COST * delta)
	else:
		if velocity.y < MIN_VERTICAL_SPEED:
			velocity.y = MIN_VERTICAL_SPEED


func update_h2o(delta: float) -> void:
	if h2o <= 0:
		if not is_changing_scene:
			await get_tree().create_timer(2.0).timeout
			change_scene()
		return
	is_underwater = is_in_water()

	if is_underwater and AudioManager:
		if not AudioManager.is_playing("swim_sound"):
			AudioManager.play_sound_player("res://voice/player/swim.mp3")
	elif not is_underwater and AudioManager and AudioManager.is_playing("swim_sound"):
		AudioManager.stop_sound("swim_sound")

	# Check various conditions for oxygen consumption/recovery
	if is_camera_fully_submerged() and has_suit:
		# Increased oxygen consumption when the camera is fully submerged
		decrease_h2o(OXYGEN_CONSUMPTION_RATE * 2.0 * delta)
		_handle_underwater_effects(delta)
	elif is_underwater and has_suit:
		# Normal oxygen consumption underwater with a suit
		decrease_h2o(OXYGEN_CONSUMPTION_RATE * delta)
		_handle_underwater_effects(delta)
	elif not is_underwater:
		# Oxygen recovery outside of water
		increase_h2o(H2O_RECOVERY_RATE * delta)
		darken_screen.modulate.a = lerp(darken_screen.modulate.a, 0.0, delta * 2.0)

	update_h2o_bar()


func _handle_underwater_effects(delta: float) -> void:
	if h2o <= MIN_H2O_THRESHOLD and not is_shaking:
		is_shaking = true
		shake_intensity = 0.2
		shake_timer = 2.0
		camera.fov = lerp(camera.fov, original_fov + 10, delta * 5.0)
	elif h2o > MIN_H2O_THRESHOLD and is_shaking:
		is_shaking = false
		shake_intensity = 0.0
		camera.fov = original_fov
	if h2o <= 0:
		darken_screen.modulate.a = lerp(darken_screen.modulate.a, DARKEN_MAX_ALPHA, delta * 2.0)


func decrease_h2o(amount: float) -> void:
	h2o = clamp(h2o - amount, 0, MAX_H2O)


func increase_h2o(amount: float) -> void:
	h2o = clamp(h2o + amount, 0, MAX_H2O)


func update_h2o_bar() -> void:
	h2o_bar.value = h2o

func update_oxygen_tank_interaction(delta: float) -> void:
	if not get_tree():
		return
	for tank in get_tree().get_nodes_in_group("oxygen_source"):
		if tank.global_transform.origin.distance_to(global_transform.origin) <= OXYGEN_INTERACTION_DISTANCE:
			increase_h2o(OXYGEN_REPLENISH_RATE * delta)
			return


func apply_camera_shake(delta: float) -> void:
	if is_shaking:
		var offset = Vector3(
			shake_randomizer.randf_range(-shake_intensity, shake_intensity),
			shake_randomizer.randf_range(-shake_intensity, shake_intensity),
			0
		)
		camera.global_transform.origin += offset * delta
		shake_intensity = lerp(shake_intensity, 0.0, delta * 3.0)
		shake_timer -= delta
		if shake_timer <= 0:
			is_shaking = false
			shake_intensity = 0.0
			camera.fov = original_fov


func handle_water_physics_without_suit(delta):
	if is_in_water():

		update_current_flow()
		apply_water_physics(delta)
		decrease_h2o(H2O_DEPLETION_RATE * 3.0 * delta)
		if h2o <= 0:
			change_scene()
	else:
		velocity.y = max(velocity.y + GRAVITY * delta, TERMINAL_VELOCITY)


func update_current_flow():
	if global_transform.origin.x > 50:
		current_flow = Vector3(-1, 0, 0)
	elif global_transform.origin.z < -50:
		current_flow = Vector3(0, 0, 1)
	else:
		current_flow = Vector3(1, 0, 0)


func apply_water_physics(delta_time):
	var water_gravity = GRAVITY * 0.2
	var water_horizontal_damping = 1.5
	var water_vertical_damping = 1.2
	var swim_up_force = 13.0
	var input_direction = Vector3.ZERO
	if input_direction != Vector3.ZERO:
		input_direction = input_direction.normalized()
		resisting_flow = true
		velocity.x = lerp(velocity.x, input_direction.x * (WALK_SPEED * 0.5), ACCELERATION * delta_time)
		velocity.z = lerp(velocity.z, input_direction.z * (WALK_SPEED * 0.5), ACCELERATION * delta_time)
	else:
		resisting_flow = false
		velocity.x = lerp(velocity.x, 0.0, DECELERATION * delta_time)
		velocity.z = lerp(velocity.z, 0.0, DECELERATION * delta_time)
	if Input.is_action_pressed("jump") and stamina > 1:
		velocity.y += swim_up_force * delta_time
		decrease_stamina(2)
	else:
		velocity.y -= water_gravity * delta_time
	if not resisting_flow:
		velocity += current_flow * flow_strength * delta_time
		decrease_stamina(0.3 * delta_time)
	else:
		velocity += current_flow * flow_strength * 0.5 * delta_time
	velocity.x = lerp(velocity.x, 0.0, water_horizontal_damping * delta_time)
	velocity.z = lerp(velocity.z, 0.0, water_horizontal_damping * delta_time)
	velocity.y = lerp(velocity.y, 0.0, water_vertical_damping * delta_time)
	is_running = false
</code></pre>

<h3>Task System</h3>
		<p>This script tracks task completion and calculates the ending percentage:</p>
		<pre><code>extends Node

var tasks_completed = 0
var total_tasks = 10
var completion_percentage = 0.0

func complete_task():
	tasks_completed += 1
	update_percentage()
	if tasks_completed >= total_tasks:
		trigger_success_ending()

func update_percentage():
	completion_percentage = (tasks_completed / float(total_tasks)) * 100.0
	print("Completion: ", completion_percentage, "%")

func trigger_success_ending():
	print("Success Ending Achieved!")
	# Load success scene (WIP)
</code></pre>
		<div class="note">
			<p><strong>Development Note</strong>: The task system is functional but lacks UI integration. We're working on visual feedback for task progress.</p>
		</div>

<h2>Project Structure</h2>
		<p>The current project structure is as follows:</p>
		<pre><code>Antarctica-Abyss/
├── Animation/          # Animation models
├── sounds/            # Placeholder audio
├── blender/
│   ├── models/        # Blender 3D models
│   └── textures/      # Textures for assets
├── scenes/
│   └── world          # All game-related scenes
├── scripts/
│   └── logic          # Scripts for movement, diving, objects, etc.
├── utils/             # Utils for Antarctica-Abyss
│   ├── img/           # Images for GUI
│   └── shader/        # Shaders for project
├── project.godot       # Godot project file
└── README.html         # This file
</code></pre>

<h2>Educational Purpose</h2>
		<p>This project is our final submission for a diploma program, showcasing our skills in game development, 3D modeling, and programming. We're using it to learn:</p>
		<ul>
			<li>Godot Engine workflows and GDScript.</li>
			<li>3D asset creation with Blender.</li>
			<li>Game mechanics design (horror, survival, puzzles).</li>
			<li>Team collaboration via Git.</li>
		</ul>
		<p>As a WIP, we acknowledge bugs and incomplete features, which we aim to address post-submission.</p>

<h2>Known Issues</h2>
		<ul>
			<li>Sliding: Occasional collision issues on icy surfaces.</li>
			<li>Diving: Oxygen HUD not fully implemented.</li>
			<li>Tasks: Limited task variety; more will be added.</li>
			<li>Performance: Unoptimized assets may cause lag.</li>
		</ul>

<h2>Contributing</h2>
		<p>As this is an educational project, contributions are limited to team members. However, feedback is welcome! Open an issue to share suggestions or report bugs.</p>
	</div>

<footer>
		<p>Developed by  Abyssal Team for Educational Purposes | 2025</p>
</footer>
