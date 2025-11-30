# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

GLoot is a universal inventory system addon for Godot 4.5+. It provides inventory management with support for item stacking, weight/count/grid constraints, and ready-to-use UI controls.

## Running Tests

Tests run automatically when opening the project in Godot (main scene is `tests/gloot_test.tscn`):
```bash
godot --path . tests/gloot_test.tscn
```

## Generating Documentation

Documentation is auto-generated from GDScript docstrings:
```bash
python3 generate_docs.py --godot_bin /path/to/godot
```

## Architecture

### Core Classes (`addons/gloot/core/`)

- **Inventory** - Main container node that holds InventoryItems. Supports signals for item changes and can have constraint child nodes.
- **InventoryItem** - Represents an item stack with properties derived from prototypes. Supports property overrides.
- **ItemSlot** - Single-item container for equipment slots.
- **ProtoTree** - Parses JSON resources defining item prototypes with inheritance support.
- **Prototype** - Individual item prototype with properties (stack_size, max_stack_size, weight, size, etc.).

### Constraints (`addons/gloot/core/constraints/`)

Added as child nodes to Inventory to limit behavior:
- **GridConstraint** - 2D grid with configurable dimensions, uses quad-tree for spatial indexing
- **WeightConstraint** - Capacity limiting based on item weight
- **ItemCountConstraint** - Limits total item count
- **InventoryConstraint** - Base class for custom constraints

### UI Controls (`addons/gloot/ui/`)

- **CtrlInventory** - Displays inventory as ItemList
- **CtrlInventoryGrid** - 2D grid display for GridConstraint inventories
- **CtrlInventoryCapacity** - Progress bar for weight/count constraints
- **CtrlItemSlot** - Visual item slot representation
- **CtrlDraggableInventoryItem** - Drag-and-drop support

### Editor Integration (`addons/gloot/editor/`)

Tool scripts for Godot inspector integration. All editor code runs only in editor mode (`@tool` annotation).

## Key Patterns

- All core classes are marked `@tool` to work in the editor
- Serialization: `serialize()` returns Dictionary, `deserialize(dict)` restores state
- Signals used extensively: `item_added`, `item_removed`, `item_property_changed`, etc.
- Serialization keys use `const _KEY_*` naming convention
- Defaults use `const DEFAULT_*` naming convention
- Internal dependencies loaded via `preload()`

## Prototree JSON Format

Item prototypes defined in JSON with inheritance via `inherits` property:
```json
{
    "base_weapon": { "damage": 1 },
    "sword": { "inherits": "base_weapon", "damage": 10 }
}
```

Special properties: `stack_size`, `max_stack_size`, `weight`, `size` (Vector2i), `rotated` (bool).
