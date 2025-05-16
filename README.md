# ❄️ Antarctica Abyss

A Work-in-Progress Educational Game Project

![Godot Engine](https://img.shields.io/badge/Godot%20Engine-4.3-blue.svg)
![Blender](https://img.shields.io/badge/Blender-3.x-orange.svg)
![License](https://img.shields.io/badge/License-Educational-green.svg)
> [!NOTE]  
> This project is a final diploma project for educational purposes. It is under active development, and some features may be incomplete or require fixes.


## 📖 Project Overview

**Antarctica Abyss** is a first-person game blending *horror*, *survival*, *exploration*, and *puzzle-solving*. Set in an underwater Arctic research base, you play as a scientist completing daily missions in a mysterious Arctic lake under a tight deadline. Your task completion contributes to a percentage score determining one of two endings: **Success** (all tasks completed) or **Game Over** (restart required).

Built using the **Godot Engine** with 3D assets crafted in **Blender**, this work-in-progress (WIP) game features unique mechanics like sliding, diving, and task-based progression to create an immersive experience.

---

## 🚀 Installation

### Option 1: Run the Executable
1. **Download the Release**:
   - Visit [Releases](https://github.com/arkadiew/Antarctica-Abyss/releases).
   - Download the latest `.exe` file.
2. **Start the Game**:
   - Double-click the `.exe` file to launch.
   - Enjoy playing!

### Option 2: Set Up Locally
To run and modify the project locally, follow these steps:

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/your-username/Antarctica-Abyss.git
   cd Antarctica-Abyss
   ```

2. **Install Godot Engine**:
   - Download [Godot Engine](https://godotengine.org/) (version 4.3 recommended).
   - Install and ensure it’s accessible in your IDE or system PATH.

3. **Download Additional Assets**:
   - Access extra asset files on [Google Drive – Antarctica Abyss Assets](https://drive.google.com/example-link).
   - Place the downloaded files in the project’s root folder.

4. **Open the Project**:
   - Launch Godot Engine.
   - Click "Import" and select the `project.godot` file in the `Antarctica-Abyss` folder.

5. **Run the Game**:
   - Press `F5` in Godot to play the current build.
   - **Warning**: Some features may be unstable as this is a WIP.

6. **Optional: Modify Assets**:
   - Install [Blender](https://www.blender.org/) (version 3.x or later) to edit 3D assets.
   - Find assets in the `assets/models` directory.
> [!TIP]
> Ensure your system meets Godot’s requirements for smooth performance. Check the [Godot documentation](https://docs.godotengine.org/) for details.

---

## 🎮 Special Mechanics

The game includes unique mechanics to enhance gameplay, though some are still in development:

- **Sliding**: Move quickly across icy surfaces to evade hazards or reach objectives. Triggered on specific terrain types.
- **Diving**: Submerge into the Arctic lake to explore underwater areas. Oxygen management is critical for survival.
- **Task Progression**: Complete daily tasks (e.g., collecting samples, solving puzzles) to increase your completion percentage and unlock endings.
- **Survival Elements**: Manage resources like oxygen and stamina while facing environmental threats.
  
> [!WARNING]  
> Sliding may clip through objects, and diving oxygen mechanics are still being balanced. These will be refined in future updates.

---

## 🗂️ Project Structure

```
Antarctica-Abyss/
├── Animation/          # Animation models
├── sounds/            # Placeholder audio
├── blender/
│   ├── models/        # Blender 3D models
│   └── textures/      # Textures for assets
├── scenes/
│   └── world          # All game-related scenes
├── scripts/
│   └── logic          # Scripts for movement, diving, objects, etc.
├── utils/
│   ├── img/           # Images for GUI
│   └── shader/        # Shaders for project
├── project.godot       # Godot project file
└── README.md          # This file
```

---

## 🎓 Educational Purpose

This project is a final submission for a diploma program, showcasing skills in:

- **Godot Engine** workflows and GDScript.
- **3D asset creation** with Blender.
- **Game mechanics design** (horror, survival, puzzles).
- **Team collaboration** via Git.

As a WIP, we acknowledge bugs and incomplete features, which we aim to address post-submission.
> [!IMPORTANT]  
> This project is for educational purposes only and not intended for commercial use.

---

## 🐛 Known Issues

- **Sliding**: Occasional collision issues on icy surfaces.
- **Diving**: Oxygen HUD not fully implemented.
- **Tasks**: Limited task variety; more will be added.
- **Performance**: Unoptimized assets may cause lag.
> [!TIP]
> Report bugs or suggestions by opening an issue on the [GitHub repository](https://github.com/your-username/Antarctica-Abyss/issues).

---

## 🤝 Contributing

As an educational project, contributions are limited to team members. However, we welcome feedback! Please:

- Open an issue to share suggestions or report bugs.
- Provide detailed descriptions to help us improve.

---

## 📜 Footer

Developed by **Abyssal Team** for Educational Purposes | 2025
