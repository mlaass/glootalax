# `GridConstraint`

Inherits: `InventoryConstraint`

## Description

A constraint that limits the inventory to a 2d grid of a given size.

The constraint implements a grid-based inventory of a configurable size.

## Properties

* `size: Vector2i` - The size of the 2d grid.
* `insertion_priority: int` - Insertion priority. Defines whether items will be stacked horizontally-first or vertically-first when inserted into the 2d grid.

## Methods

### Item Position & Size

* `get_item_position(item: ItemStack) -> Vector2i` - Returns the position of the given item on the 2d grid.
* `set_item_position(item: ItemStack, new_position: Vector2i) -> bool` - Sets the position of the given item on the 2d grid.
* `set_item_position_unsafe(item: ItemStack, new_position: Vector2i) -> void` - Sets the position of the given item on the 2d grid without any validity checks (somewhat faster than `set_item_position`).
* `get_item_size(item: ItemStack) -> Vector2i` - Returns the size of the given item (i.e. the `size` property).
* `set_item_size(item: ItemStack, new_size: Vector2i) -> bool` - Sets the size of the given item (i.e. the `size` property).
* `get_item_rect(item: ItemStack) -> Rect2i` - Returns a rectangle constructed from the position and size of the given item.
* `set_item_rect(item: ItemStack, new_rect: Rect2i) -> bool` - Sets the position and size of the given item based on the given rectangle. Returns `false` if the new position and size cannot be applied to the item.

### Item Rotation

* `is_item_rotated(item: ItemStack) -> bool` - Checks whether the given item is rotated (i.e. whether the `rotated` property is set).
* `is_item_rotation_positive(item: ItemStack) -> bool` - Checks whether the given item has positive rotation.
* `set_item_rotation(item: ItemStack, rotated: bool) -> bool` - Sets the rotation of the given item (i.e. the `rotated` property).
* `rotate_item(item: ItemStack) -> bool` - Rotates the given item (i.e. toggles the `rotated` property).
* `set_item_rotation_direction(item: ItemStack, positive: bool) -> void` - Sets the rotation direction of the given item (positive or negative, i.e. sets the `positive_rotation` property).
* `can_rotate_item(item: ItemStack) -> bool` - Checks if the given item can be rotated.

### Adding & Finding Items

* `add_item_at(item: ItemStack, position: Vector2i) -> bool` - Adds the given item to the inventory and sets its position.
* `create_and_add_item_at(item_type: ItemType, position: Vector2i) -> ItemStack` - Creates and adds the given item to the inventory and sets its position.
* `get_item_at(position: Vector2i) -> ItemStack` - Returns the item at the given grid position. Returns `null` if no item can be found at that position.
* `get_items_under(rect: Rect2i) -> Array[ItemStack]` - Returns an array of items under the given rectangle.

### Moving Items

* `move_item_to(item: ItemStack, position: Vector2i) -> bool` - Moves the given item to a new position. Returns `false` if the item cannot be moved.
* `move_item_to_free_spot(item: ItemStack) -> bool` - Moves the given item to a free spot. Returns `false` if no free spot can be found.

### Space Management

* `rect_free(rect: Rect2i, exception: ItemStack) -> bool` - Checks if the given rectangle is free (i.e. no items can be found under it). The `exception` item will be disregarded during the check, if set.
* `find_free_place(item: ItemStack, exception: ItemStack) -> Dictionary` - Finds a place for the given item. The `exception` item will be disregarded during the search, if set. Returns a dictionary containing two fields: `success` and `position`. `success` will be set to `false` if no free place can be found and to `true` otherwise. If `success` is `true` the `position` field contains the resulting coordinates.
* `find_free_space(item_size: Vector2i, occupied_rects: Array[Rect2i]) -> Dictionary` - Finds a place for the given item size with regard to the given occupied rectangles. Returns a dictionary containing two fields: `success` and `position`.
* `get_space_for(item: ItemStack) -> int` - Returns the number of times this constraint can receive the given item.
* `has_space_for(item: ItemStack) -> bool` - Checks if the constraint can receive the given item.
* `sort() -> bool` - Sorts the inventory based on item size.

### Serialization

* `reset() -> void` - Resets the constraint, i.e. sets its size to default (`Vector2i(10, 10)`).
* `serialize() -> Dictionary` - Serializes the constraint into a `Dictionary`.
* `deserialize(source: Dictionary) -> bool` - Loads the constraint data from the given `Dictionary`.
