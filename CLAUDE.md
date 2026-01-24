# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**mofuel** is a Godot 4.5 mobile game project featuring a 3D dice roller with physics simulation.

## Development Commands

```bash
# Open project in Godot editor
godot --editor --path .

# Run the project
godot --path .

# Run with specific scene
godot --path . res://dice.tscn

# Export for mobile (requires export templates configured)
godot --headless --export-debug "Android" ./build/mofuel.apk
```

## Architecture

### Entry Point
- **Main Scene:** `dice.tscn` - A RigidBody3D node with attached dice mesh and collision shape
- **Main Script:** `dice.gd` - Handles input and physics-based dice rolling

### Scene Structure
```
Dice (RigidBody3D) ← dice.gd
├── dice (MeshInstance3D from dice.glb)
└── CollisionShape3D (BoxShape3D 2x2x2)
```

### Input System
- Uses Godot's built-in "ui_accept" action (Space/Enter on desktop, tap on mobile)
- Pattern: `_input(event)` → `_roll()` function triggers physics simulation

### Physics Configuration
- Gravity scale: 2.0 (enhanced for snappy dice feel)
- Initial freeze: true (prevents movement until rolled)
- Roll applies random rotation via `Basis` transforms and impulse via `apply_impulse()`

## Godot 4.5 Conventions

- **GDScript style:** Use snake_case for functions/variables, PascalCase for classes
- **Scene files:** `.tscn` (text-based scene format)
- **Resources:** `.tres` (text-based resource format)
- **3D assets:** GLB format (binary glTF 2.0)
- **Rendering:** Mobile renderer configured (`project.godot` → `renderer/rendering_method="mobile"`)

## Asset Import

GLB models are imported with:
- LOD generation enabled
- Shadow meshes enabled
- Light baking enabled
- Materials kept inline (not extracted)
