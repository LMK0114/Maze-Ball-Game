#  Maze Ball Game
A 2.5D maze game created using Processing 4, with live physics effects like gravity, collision detection, friction, and math methods for movement. Players tilt a board to move a ball through a maze, dodging holes and trying to reach the finish line.
## Overview
This Maze Game is a puzzle game that uses physics, created in Processing 4. In this game, you control a ball on a slanted board. It follows basic physics rules, like how things move and interact, without using any outside physics programs. Your goal is to guide the ball from the starting point to the finish area by tilting the board in two directions, while steering clear of walls and holes.
## Features
* Real-time Physics Simulation
  * Gravity projection onto tilted plane with trigonometric calculations
  * Symplectic (semi-implicit) Euler integration for stable motion
  * Explicit Euler integration available for comparison
  * Real-time acceleration calculation based on board tilt angles
* Tilt Control System
  * Keyboard-controlled board tilting along X and Z axes
  * Tilt angles clamped to ±30° for realistic gameplay
  * Smooth board rotation using Processing's 3D transformations
* Collision Detection & Response
  * Circle vs. Axis-Aligned Bounding Box (AABB) collision detection
  * Impulse-based contact resolution with restitution coefficient (e)
  * Tangential friction impulse implementation with friction coefficient (μ)
  * Position correction to prevent penetration
  * Boundary constraints with elastic collisions
* Complex Maze Structure
* Adjustable Physics Parameters
  * Live-adjustable restitution coefficient (e: 0-1) using keys 1/2
  * Live-adjustable friction coefficient (μ: 0-1) using keys 3/4
## Technologies Used
* Processing 4
* P3D renderer
* Vector Mathematics
* Collision Detection AABB
* File I/O
## Gameplay Mechanics
### Physics Simulation
* The ball's acceleration is determined by the board's tilt angles:
  * Tilting forward/backward (angleX) creates acceleration along Y-axis
  * Tilting left/right (angleZ) creates acceleration along X-axis
  * Gravity (g = 9.81 m/s²) projects onto the tilted plane using sine functions
* Collision Response
  * Calculate closest point on wall AABB to ball center
  * Compute collision normal vector
### Enemy System
* Demon boss continuously chases the player
* Fire laser attacks with warning indicators
* Stunning effects when hit by lasers
## Control
| Key | Action |
|-----|--------|
| ↑ / W | Tilt board forward |
| ↓ / S | Tilt board backward |
| ← / A | Tilt board left |
| → / D | Tilt board right |
| 1 | Increase restitution (bounciness) |
| 2 | Decrease restitution |
| 3 | Increase friction |
| 4 | Decrease friction |
| R | Reset ball to start position |
| BACKSPACE | Reset entire game |

## Project Structure

```bash
├── MazeGame.pde
├── highscores.txt
└── README.md
```

## Installation
1. Download Processing 4 from processing.org.
2. Drag the .pde file onto the Processing window.
3. Click the Run button (play icon) in the toolbar.
## Screenshots
### Gameplay
<img width="1919" height="1078" alt="image" src="https://github.com/user-attachments/assets/22bed9b1-0ee4-4682-9803-b44494ce4dd6" />
### GameWin
<img width="1918" height="1079" alt="image" src="https://github.com/user-attachments/assets/88c2f48a-ca8a-4a6a-9d3a-317e072a0b28" />


## Authors
* LAM MING KANG
## License
This project is developed for educational purposes.
