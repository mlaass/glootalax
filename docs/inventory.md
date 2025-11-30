# `Inventory`

Inherits: `Node`

## Description

Basic stack-based inventory class.

Supports basic inventory operations (adding, removing, transferring items etc.). Can contain an unlimited amount of item stacks.

## Methods

### Item Management

* `move_item(from: int, to: int) -> void` - Moves the item at the given index in the inventory to a new index.
* `get_item_index(item: ItemStack) -> int` - Returns the index of the given item in the inventory.
* `get_item_count() -> int` - Returns the number of items in the inventory.
* `get_items() -> Array[ItemStack]` - Returns an array containing all the items in the inventory.
* `has_item(item: ItemStack) -> bool` - Checks if the inventory contains the given item.
* `add_item(item: ItemStack) -> bool` - Adds the given item to the inventory.
* `can_add_item(item: ItemStack) -> bool` - Checks if the given item can be added to the inventory.
* `create_item(item_type: ItemType) -> ItemStack` - Creates an `ItemStack` based on the given `ItemType`.
* `create_and_add_item(item_type: ItemType) -> ItemStack` - Creates an `ItemStack` based on the given `ItemType` and adds it to the inventory. Returns `null` if the item cannot be added.
* `remove_item(item: ItemStack) -> bool` - Removes the given item from the inventory. Returns `false` if the item is not inside the inventory.
* `get_item_with_item_type(item_type: ItemType) -> ItemStack` - Returns the first found item with the given `ItemType`.
* `get_items_with_item_type(item_type: ItemType) -> Array[ItemStack]` - Returns an array of all the items with the given `ItemType`.
* `has_item_with_item_type(item_type: ItemType) -> bool` - Checks if the inventory has an item with the given `ItemType`.
* `get_constraint(script: Script) -> InventoryConstraint` - Returns the inventory constraint of the given type (script). Returns `null` if the inventory has no constraints of that type.
* `reset() -> void` - Removes all items from the inventory.
* `clear() -> void` - Removes all the items from the inventory.
* `serialize() -> Dictionary` - Serializes the inventory into a `Dictionary`.
* `deserialize(source: Dictionary) -> bool` - Loads the inventory data from the given `Dictionary`.

### Stack Operations

* `split_stack(item: ItemStack, new_stack_size: int) -> ItemStack` - Splits the given item stack into two within the inventory. `new_stack_size` defines the size of the new stack, which is added to the inventory. Returns `null` if the split cannot be performed or if the new stack cannot be added to the inventory.
* `merge_stacks(item_dst: ItemStack, item_src: ItemStack, split_source: bool) -> bool` - Merges the `item_src` item stack into the `item_dst` stack which is inside the inventory. If `item_dst` doesn't have enough stack space and `split_source` is set to `true`, `item_src` will be split and only partially merged. Returns `false` if the merge cannot be performed.
* `add_item_automerge(item: ItemStack) -> bool` - Adds the given item to the inventory and merges it with all compatible items. Returns `false` if the item cannot be added.
* `add_item_autosplit(item: ItemStack) -> bool` - Adds the given item to the inventory, splitting it if there is not enough space for the whole stack.
* `add_item_autosplitmerge(item: ItemStack) -> bool` - A combination of `add_item_autosplit` and `add_item_automerge`. Adds the given item stack into the inventory, splitting it up and joining it with available item stacks, as needed.
* `pack_item(item: ItemStack) -> void` - Merges the given item with all compatible items in the same inventory.

## Signals

* `item_added(item)` - Emitted when an item has been added to the inventory.
* `item_removed(item)` - Emitted when an item has been removed from the inventory.
* `item_property_changed(item, property)` - Emitted when a property of an item inside the inventory has been changed.
* `item_moved(item)` - Emitted when an item has moved to a new index.
* `constraint_added(constraint)` - Emitted when a new constraint has been added to the inventory.
* `constraint_removed(constraint)` - Emitted when a constraint has been removed from the inventory.
* `constraint_changed(constraint)` - Emitted when an inventory constraint has changed.

## Example

```gdscript
# Load an ItemType resource
var sword_type: ItemType = preload("res://items/sword.tres")

# Create and add an item
var sword = inventory.create_and_add_item(sword_type)

# Check if we have swords
if inventory.has_item_with_item_type(sword_type):
    var first_sword = inventory.get_item_with_item_type(sword_type)
    print("Found: ", first_sword.get_title())

# Stack operations with stackable items
var arrows_type: ItemType = preload("res://items/arrows.tres")
var arrows = inventory.create_and_add_item(arrows_type)
arrows.set_stack_size(32)

# Split a stack
var split_arrows = inventory.split_stack(arrows, 16)
```
