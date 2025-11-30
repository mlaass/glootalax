# `ItemStack`

Inherits: `RefCounted`

## Description

Stack-based inventory item class.

Represents an item stack referencing an `ItemType` resource. Can hold property overrides and a stack count. The default stack size is 1.

## Properties

* `item_type: ItemType` - The item type resource this stack is based on.

## Methods

### Core Methods

* `duplicate() -> ItemStack` - Returns a duplicate of this item stack.
* `get_inventory() -> Inventory` - Returns the `Inventory` this item belongs to, or `null` if not inside an inventory.
* `reset() -> void` - Resets the item stack (clears property overrides, keeps `item_type`).

### Property Methods

* `has_property(property_name: String) -> bool` - Checks if the item has the given property (from overrides or `item_type`).
* `get_property(property_name: String, default_value: Variant) -> Variant` - Returns the given property value. Checks overrides first, then `item_type`.
* `set_property(property_name: String, value: Variant) -> void` - Sets the given property value (creates an override).
* `clear_property(property_name: String) -> void` - Clears (removes) a property override.
* `get_overridden_properties() -> Array` - Returns an array of overridden property names.
* `get_properties() -> Array` - Returns all property names (from `item_type` + overrides).
* `is_property_overridden(property_name: String) -> bool` - Checks if the given property is overridden.

### Helper Methods

* `get_texture() -> Texture2D` - Returns the texture from `item_type` or override.
* `get_title() -> String` - Returns item title (`name` property, or `item_type.name`, or `item_type.id`).

### Stack Methods

* `get_stack_size() -> int` - Returns the stack size.
* `get_max_stack_size() -> int` - Returns the maximum stack size.
* `set_stack_size(stack_size: int) -> bool` - Sets the stack size.
* `set_max_stack_size(max_stack_size: int) -> void` - Sets the maximum stack size.
* `get_free_stack_space() -> int` - Returns the free stack space (`max_stack_size - stack_size`).
* `merge_into(item_dst: ItemStack, split: bool) -> bool` - Merges this stack into `item_dst`. If `split` is `true` and `item_dst` doesn't have enough space, the stack will be partially merged. Returns `false` if merge fails.
* `can_merge_into(item_dst: ItemStack, split: bool) -> bool` - Checks if this stack can be merged into `item_dst`.
* `compatible_with(item_dst: ItemStack) -> bool` - Checks if this stack is compatible for merging with `item_dst`.
* `split(new_stack_size: int) -> ItemStack` - Splits the stack and returns a new stack with the specified size. Returns `null` if split fails.
* `can_split(new_stack_size: int) -> bool` - Checks if the stack can be split with the given size.

### Serialization Methods

* `serialize() -> Dictionary` - Serializes the item stack to a dictionary.
* `deserialize(source: Dictionary) -> bool` - Deserializes item stack from a dictionary.

### Static Methods

* `swap(item1: ItemStack, item2: ItemStack) -> bool` - Swaps two items between inventories. Returns `false` if swap fails.

## Signals

* `property_changed(property_name: String)` - Emitted when a property changes.

## Example

```gdscript
# Create an item stack
var sword_type: ItemType = preload("res://items/sword.tres")
var sword = ItemStack.new(sword_type)

# Access properties (from item_type)
print(sword.get_title())  # "Iron Sword"
print(sword.get_property("damage", 0))  # 10

# Override a property
sword.set_property("damage", 15)
print(sword.get_property("damage", 0))  # 15
print(sword.is_property_overridden("damage"))  # true

# Clear override (reverts to item_type value)
sword.clear_property("damage")
print(sword.get_property("damage", 0))  # 10

# Stack operations
var arrows_type: ItemType = preload("res://items/arrows.tres")  # max_stack_size = 64
var arrows = ItemStack.new(arrows_type)
arrows.set_stack_size(32)
print(arrows.get_stack_size())  # 32
print(arrows.get_free_stack_space())  # 32

# Split a stack
var split_arrows = arrows.split(16)  # arrows now has 16, split_arrows has 16
```
