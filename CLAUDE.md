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

## Socket System

Items can have socket slots defined in their ItemType. Socketed items (gems) are stored as property overrides on the ItemStack.

### Socket Slot Definition

Socket slots are defined in `ItemType.socket_slots` array. Each `SocketSlotDefinition` has:
- `id` - Unique identifier for the slot
- `display_name` - Human-readable name
- `constraints` - Array of InventoryConstraint resources to validate socketed items
- `use_custom_position` - If true, uses absolute positioning instead of auto-layout
- `position` - Position when using custom positioning
- `size_override` - Custom size for the socket visual (Vector2.ZERO for default)

### Pre-socketing Items via `_serialized_format`

To pre-populate items with socketed gems in scenes, use the `_serialized_format` property on Inventory nodes. Add a `_sockets` key to item entries:

```gdscript
_serialized_format = {
    "items": [{
        "item_type": "res://items/socketed_sword.tres",
        "_sockets": {
            "gem_slot_1": {
                "item_type": "res://items/fire_gem.tres"
            },
            "gem_slot_2": {
                "item_type": "res://items/ice_gem.tres",
                "properties": {
                    "power": {"type": 2, "value": "25"}
                }
            }
        }
    }],
    "node_name": "Inventory"
}
```

The `_sockets` dictionary maps slot IDs to serialized ItemStack data. Each socketed item entry follows the same format as regular items:
- `item_type` - Path to the ItemType resource
- `properties` (optional) - Property overrides with `type` (Variant.Type) and `value` (var_to_str format)

### Socket Constraints

Common constraint types for sockets:
- `PropertyMatchConstraint` - Requires specific property values (e.g., `{"socketable": true}`)
- `ItemTypeConstraint` - Restricts to specific ItemType IDs

### Runtime Socket Operations

```gdscript
# Check if item has sockets
item.has_sockets()  # -> bool

# Get socket slot definitions
item.get_socket_slots()  # -> Array[SocketSlotDefinition]

# Socket/unsocket items
item.socket_item(slot_id, gem)  # -> bool
item.unsocket_item(slot_id)  # -> ItemStack or null
item.get_socketed_item(slot_id)  # -> ItemStack or null
```
