<h1>Antarctica-Abyss</h1>
        A Work-in-Progress Educational Game Project

<p style="background: #e8f0fe; padding: 10px; border-left: 4px solid #1a73e8; margin: 10px 0; border-radius: 4px;"><strong>Note:</strong> This project is a final diploma project for educational purposes. It is under active development, and some features may be incomplete or require fixes.</p>

<h2>Project Overview</h2>
        <p><strong>Antarctica-Abyss</strong> is a first-person game combining elements of horror, survival, exploration, and puzzle-solving, developed as a final project for our diploma. Set in an underwater Arctic research base, you play as a scientist tasked with completing daily missions in a mysterious Arctic lake under a tight deadline. Your task completion contributes to a percentage score that determines one of two endings: <strong>Success</strong> (all tasks completed) or <strong>Game Over</strong> (restart required).</p>
        <p>The game is a work-in-progress (WIP), built using the <strong>Godot Engine</strong> with 3D assets crafted in <strong>Blender</strong>. It features unique mechanics like sliding, diving, and task-based progression, designed to create an immersive experience.</p>

<h2>Installation</h2>
        <p>To set up and run the project locally, follow these steps:</p>
        <ol>
            <li><strong>Clone the Repository</strong>:
                <pre><code>git clone https://github.com/your-username/Antarctica-Abyss.git cd Antarctica-Abyss</code></pre>
            </li>
            <li><strong>Install Godot Engine</strong>:
                <ul>
                    <li>Download <a href="https://godotengine.org/">Godot Engine</a> (version 4.x recommended).</li>
                    <li>Install and ensure it's accessible in your IDE or system PATH.</li>
                </ul>
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

<h3>Player Movement with Sliding</h3>
        <p>This script handles basic player movement and sliding on icy surfaces:</p>
        <pre><code>extends CharacterBody3D

var speed = 5.0
var slide_speed = 10.0
var is_sliding = false

func _physics_process(delta):
    var input_dir = Vector3.ZERO
    input_dir.x = Input.get_axis("ui_left", "ui_right")
    input_dir.z = Input.get_axis("ui_up", "ui_down")
    
    # Check if on icy surface (WIP)
    if is_on_ice():
        is_sliding = true
        velocity = input_dir.normalized() * slide_speed
    else:
        is_sliding = false
        velocity = input_dir.normalized() * speed
    
    move_and_slide()

func is_on_ice():
    # Placeholder: Detect icy surface (to be implemented)
    return false
</code></pre>

<h3>Diving Mechanic</h3>
        <p>This script manages diving and oxygen levels when underwater:</p>
        <pre><code>extends Node

var oxygen = 100.0
var max_oxygen = 100.0
var is_diving = false

func _process(delta):
    if is_diving:
        oxygen -= 10.0 * delta  # Deplete oxygen over time
        if oxygen <= 0:
            game_over()
        update_hud()

func start_dive():
    is_diving = true
    # Switch to underwater visuals (WIP)

func end_dive():
    is_diving = false
    oxygen = max_oxygen

func game_over():
    # Trigger game over (WIP)
    print("Oxygen depleted! Game Over")
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
├── assets/
│   ├── models/          # Blender 3D models
│   ├── textures/       # Textures for assets
│   └── sounds/         # Placeholder audio
├── scenes/
│   ├── base/           # Underwater base scenes
│   ├── lake/           # Arctic lake scenes
│   └── player/         # Player character
├── scripts/
│   ├── player.gd       # Movement, sliding, diving
│   ├── tasks.gd        # Task system
│   └── environment.gd  # Environmental effects
├── project.godot        # Godot project file
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
        <p>Developed by [Your Team Name] for Educational Purposes | 2025</p>
</footer>
