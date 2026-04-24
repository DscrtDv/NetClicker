# NetClicker

A network-themed incremental clicker game built in **Godot 4.6**.

You build and manage computer networks to generate bits — the in-game currency. Place nodes, wire them together, unlock topologies, and spend bits on upgrades through the tech tree.

---

## Gameplay Loop

1. **Place clickers** — buy Computers and Switches from the shop and drop them on the grid
2. **Connect them** — draw network connections between nodes to form a subnet
3. **Earn bits** — each active network generates bits per second based on its size and topology
4. **Unlock upgrades** — spend bits in the tech tree to increase network capacity, unlock new node types, and gain passive bonuses

---

## Systems

### Clickers
- **Computer** — the base income node; generates bits when part of a network
- **Switch** — routes traffic between nodes; unlocked via the tech tree
- Clickers are placed via a ghost-preview system and snap to the 2D grid
- Each clicker has a power state (ON/OFF) displayed visually on screen

### Network Engine
- Nodes are grouped into **subnets** automatically based on connection graph
- Each subnet computes its own **bits-per-second** from member nodes
- **Topology bonuses** — ring formations grant an additional BPS bonus
- The main network counter tracks total banked bits; secondary counters appear per subnet on hover

### Connection System
- Enter connection mode from the toolbar to draw links between nodes
- Connections are visualised as coloured overlay lines (colour reflects topology)
- Disconnect mode lets you remove individual links
- Network size is capped by `SignalBus.max_network_size` (expandable via tech tree)

### Tech Tree
- Opens as a floating window from the HUD
- Five techs arranged in a branching grid, connected by visible lines:

| Tech | Effect |
|---|---|
| Network Basics | Foundation upgrade |
| Hard Drives | +2 max network size |
| Switch | Unlocks the Switch in the shop |
| Computer Sockets | Third connection slot per computer |
| Underground Cables | Switches connect across network boundaries |

- Each node shows its **name**, **cost**, and unlock state (locked / available / unlocked)
- Hovering a node shows a tooltip with full description, cost affordability, and bit prerequisite

### HUD
- **Bit counter** — live display of total bits and BPS; expands on hover to show node counts
- **Shop** — purchasable clicker types with scaling prices
- **Terminal** — scrolling event log of game actions
- **Toolbar** — toggle connection mode, disconnect mode, tooltips, and pointer tool
- **Floating window** — reusable panel system used by the tech tree (closeable, ESC-dismissable)

### Camera & Rendering
- Free-roam 2D camera with zoom
- **LOD system** — node detail scales with zoom level to keep the scene readable at any distance
- Selection brackets highlight hovered or selected nodes
- Background grid scales with the world

---

## Project Structure

```
NetClicker/
├── Autoload/           # Singletons: NetworkManager, EventLog, GameColors
├── Clickers/           # Computer and Switch scenes + base Clicker class
├── Main/               # Main scene, main.gd orchestrator, SignalBus autoload
└── UI/
    ├── FloatingWindow/ # Reusable modal window base scene
    ├── HUD/            # Counter, Shop, Terminal, Toolbar, Tooltip, Overlay
    ├── Placement/      # Ghost preview for entity placement
    ├── SelectionBracket/
    └── TechTree/       # TechData, TechRegistry, TechNode button, tree layout
```

---

## Architecture Notes

- **SignalBus** is the sole autoload for game events and shared state (`total_bits`, `unlocked_techs`, signals for purchases, placement, tooltips, etc.)
- **NetworkManager** rebuilds the subnet graph whenever a connection changes and exposes per-network BPS calculations
- **TechRegistry** is a static class (no autoload needed) — call `TechRegistry.get_all()` or `TechRegistry.get_tech(id)` from anywhere
- Tech effects are keyed in `TechData.effect` dictionaries (`max_network_bonus`, `unlock_switch`, `computer_extra_slot`, `switch_cross_network`) and will be applied by a TechManager in a future milestone

---

## Built With

- [Godot Engine 4.6](https://godotengine.org/) — Forward Plus renderer
- GDScript
