# Dynamic Sit System for FiveM

A highly precise, raycast-based "sit-anywhere" system designed for FiveM servers (Qbox/QB-Core/Standalone). This system allows players to interact naturally with the world by detecting surfaces like walls, benches, ledges, and even small objects like trash cans.

## 🚀 Features

- **Dynamic Surface Detection**: Uses multi-height vertical sweeps and thick capsule scanning to find the perfect sitting spot.
- **Wall & Ledge Sitting**: Snap perfectly to the edge of walls or balconies with legs hanging down naturally.
- **Smart Leaning**: Automatically detects high walls and hedges to trigger a leaning animation instead of sitting.
- **Small Object Support**: Special logic to sit exactly on top of thin objects like trash cans, chairs, and posts.
- **Edge-Standing Fallback**: If you've climbed a high wall, you can sit on the edge directly from your standing position.
- **Multiplayer Synchronized**: All animations and positions are synced across all players on the server.
- **Safety Measures**: Prevents character burial or clipping by enforcing ground-safety checks and position locking.
- **Debugging Tools**: Integrated visual debug system (lines and markers) to see exactly where the script is looking.

## 🎮 Usage

- `/sit`: Automatically detects a surface in front of you (or under you if on a ledge) and sits.
- `/stand`: Exit the sitting/leaning position. Standard movement keys (WASD) will also automatically trigger a stand-up.

## 🛠️ Configuration

### `config.lua`
Adjust height thresholds and offsets for different styles:
- `Ledge`: Low heights (curbs, steps).
- `Bench`: Knee-to-waist heights (walls, benches).
- `Lean`: Chest-high or taller surfaces.

### `props.lua`
Define model-specific overrides for custom props to ensure pixel-perfect alignment.

## 📦 Installation

1. Copy the `dynamic-sit` folder into your resources directory.
2. Add `ensure dynamic-sit` to your `server.cfg`.
3. (Optional) Set `Config.Debug = true` in `config.lua` to visualize the detection during setup.

## 📝 Requirements

- Standalone (Works with Qbox, QB-Core, ESX, etc.)
- No dependencies.

---
*Created with focus on immersion and polish.*
