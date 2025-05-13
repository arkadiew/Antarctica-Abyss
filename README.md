<h1>Antarctica Abyss</h1>
		A Work-in-Progress Educational Game Project

<p style="background: #e8f0fe; padding: 10px; border-left: 4px solid #1a73e8; margin: 10px 0; border-radius: 4px;"><strong>Note:</strong> This project is a final diploma project for educational purposes. It is under active development, and some features may be incomplete or require fixes.</p>

<h2>Project Overview</h2>
<p><strong>Antarctica-Abyss</strong> is a first-person game combining elements of horror, survival, exploration, and puzzle-solving, developed as a final project for our diploma. Set in an underwater Arctic research base, you play as a scientist tasked with completing daily missions in a mysterious Arctic lake under a tight deadline. Your task completion contributes to a percentage score that determines one of two endings: <strong>Success</strong> (all tasks completed) or <strong>Game Over</strong> (restart required).</p>
<p>The game is a work-in-progress (WIP), built using the <strong>Godot Engine</strong> with 3D assets crafted in <strong>Blender</strong> . It features unique mechanics like sliding, diving, and task-based progression, designed to create an immersive experience.</p>
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
