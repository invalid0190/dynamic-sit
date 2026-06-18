# Dynamic Sit System for FiveM

A highly precise, raycast-based "sit-anywhere" system designed for FiveM servers (Qbox/QB-Core/Standalone). This system allows players to interact naturally with the world by detecting surfaces like walls, benches, ledges, and even small objects like trash cans.

## Discord : https://discord.gg/BN34qUeKwY

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

<img width="1545" height="776" alt="image" src="https://github.com/user-attachments/assets/e5740996-cd97-4508-aa7d-30c8a8cc0a0a" />
<img width="1348" height="730" alt="image" src="https://github.com/user-attachments/assets/292771a9-8a38-44d7-a78b-7de44c0e1d60" />
<img width="1351" height="933" alt="image" src="https://github.com/user-attachments/assets/25ab31da-4b0f-4a7e-add7-2a37f2fc9c08" />
<img width="1553" height="923" alt="image" src="https://github.com/user-attachments/assets/69dac5bb-b3ce-4fd3-a742-0d63191e5c30" />
<img width="1792" height="916" alt="image" src="https://github.com/user-attachments/assets/ae58a0df-4cc5-4a89-a4ba-2d511c16b83a" />
<img width="1655" height="935" alt="image" src="https://github.com/user-attachments/assets/73bf0c7f-22f4-49d8-b8ca-a45e8af2b12a" />
<img width="1726" height="950" alt="image" src="https://github.com/user-attachments/assets/e0e1e550-c045-40a1-b8fe-558acbd3dd93" />


---
*Created with focus on immersion and polish.*
