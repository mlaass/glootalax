# Core Directory Contents

## Directories

| Directory     | Description |
| ------------- | ----------- |
| `constraints` | Constraint implementations (`WeightConstraint`, `GridConstraint` and `ItemCountConstraint`) |

## Files

| File                   | Description |
| ---------------------- | ----------- |
| `item_type.gd`         | `ItemType` resource implementation. Defines item properties as a Godot Resource. |
| `item_stack.gd`        | `ItemStack` implementation. Represents an item stack referencing an ItemType. |
| `inventory.gd`         | `Inventory` implementation. |
| `item_count.gd`        | A helper script for item count arithmetics that support infinity. |
| `item_slot.gd`         | `ItemSlot` implementation. |
| `stack_manager.gd`     | A helper script for managing item stacks. |
| `constraint_manager.gd`| Manages constraints attached to an inventory. |
| `utils.gd`             | Miscellaneous helper utility functions. |
| `verify.gd`            | A helper script for data verification. |
