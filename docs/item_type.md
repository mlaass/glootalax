# `ItemType`

Inherits: `Resource`

## Description

Resource-based item type definition.

Defines the base properties for inventory items. Each `ItemType` is saved as a `.tres` file and can be referenced by `ItemStack` instances. Properties can be overridden per-stack.

## Creating ItemType Resources

1. In the FileSystem dock, right-click and select "New Resource..."
2. Search for and select "ItemType"
3. Save the resource as a `.tres` file
4. Configure the properties in the inspector

## Properties

* `id: String` - Unique identifier for this item type (used in serialization and display).
* `name: String` - Display name of the item.
* `texture: Texture2D` - Item texture/icon for UI display.
* `max_stack_size: int` - Maximum number of items per stack (default 1 = non-stackable).
* `weight: float` - Weight per unit (used by `WeightConstraint`). Default is 1.0.
* `size: Vector2i` - Grid size in cells (used by `GridConstraint`). Default is `Vector2i(1, 1)`.
* `custom_properties: Dictionary` - Custom properties dictionary for game-specific data.

## Methods

* `get_property(property_name: String, default_value: Variant) -> Variant` - Returns the value of the given property, or `default_value` if not found.
* `has_property(property_name: String) -> bool` - Checks if this item type has the given property defined.
* `get_property_names() -> Array[String]` - Returns all property names (built-in + custom).
* `get_properties() -> Dictionary` - Returns all properties as a dictionary.

## Signals

* `changed_properties` - Emitted when any property changes (for editor updates).

## Built-in Properties

The following property names are built-in and have dedicated exported fields:

* `id` - The item type identifier
* `name` - Display name
* `texture` / `image` - Item texture (both names map to the same property)
* `max_stack_size` - Maximum stack size
* `weight` - Unit weight
* `size` - Grid size
* `stack_size` - Current stack size (only meaningful on ItemStack)

## Example

```gdscript
# Load an ItemType resource
var sword_type: ItemType = preload("res://items/sword.tres")

# Access properties
print(sword_type.id)  # "sword"
print(sword_type.name)  # "Iron Sword"
print(sword_type.weight)  # 5.0

# Access custom properties
var damage = sword_type.get_property("damage", 10)
```
