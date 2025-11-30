# GLoot v2 to v3 Transition Guide

> **Note:** This guide covers migration from GLoot v2.x to v3.x. GLoot has since introduced ItemType resources and ItemStack (replacing protosets and InventoryItem). See the main README.md for current documentation.

This guide provides an overview of the changes introduced in GLoot version 3.0, and will hopefully enable a smooth transition from version 2.x.

## Protosets (Deprecated in v4+)

> **Note:** Protosets have been replaced with ItemType resources in newer versions. ItemType is a Godot Resource (.tres file) that can be created and edited in the Godot editor.

Protosets underwent significant changes in version 3.0. The essential updates included:

### Resource Type Update

The `ItemProtoset` resource type was removed and protosets were represented as builtin JSON resources.

### JSON Structure

The general JSON structure of a protoset was also changed.

### Protoset Editing

The protoset editor was removed. Editing raw JSON files was the only supported method for creating and managing protosets.

### Item Dimensions

The `width` and `height` properties (integers) were replaced with the `size` property, represented as a Vector2i.

## Inventories

Inventory management has been unified and simplified. Instead of using multiple specialized inventory classes, version 3.0 introduces a single Inventory class which is customizable with constraints:

### Replacements for Deprecated Classes:

* `InventoryStacked`: Use `Inventory` with a `WeightConstraint`.
* `InventoryGrid`: Use `Inventory` with a `GridConstraint`.
* `InventoryGridStacked`: Use `Inventory` with both `GridConstraint` and `WeightConstraint`.

## Inventory Items

> **Note:** `InventoryItem` has been renamed to `ItemStack` in newer versions.

Key updates to inventory item handling:

* Inventory items no longer extend the `Node` class and cannot be created as nodes from the editor.
* Items now extend the `RefCounted` class.
* Items must be created via the inventory editor in the inspector or programmatically.

## Item Slots

The `ItemRefSlot` class has been removed. Its functionality can be replicated by:

* Implementing `_can_drop_data` and `_drop_data` methods for any `Control` node.
* Storing a reference to the dropped item as needed.

## UI Controls

Some UI Control classes have also been unified and simplified:

* `CtrlInventoryStacked` can be represented as a `CtrlInventory` and `CtrlInventoryCapacity`
* `CtrlInventoryGrid` and `CtrlInventoryGridEx` have been consolidated into `CtrlInventoryGrid`
* `CtrlItemSlot` and `CtrlItemSlotEx` have been consolidated into `CtrlItemSlot`

## Additional Information

For additional information:

* Refer to the `README.md` file for more comprehensive documentation.
* Explore the provided examples to better understand the new features and workflows.
