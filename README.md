# GLoot

<p align="center">
  <img src="images/gloot_logo_128x128.png" />
</p>

A universal inventory system for the Godot game engine (version 4.4 and newer).

> NOTE: **Version 3.0 has been merged to `master`** and includes a number of changes that are not backwards-compatible with version 2.x. If you intend to upgrade from version 2 to version 3, there is a short [transition guide](docs/gloot_2_to_3_transition_guide.md) that will hopefully make the process smoother. If you, however, plan to stick to the old version, it can be found on the `v2.x` branch.

## Table of Contents

1. [Features](#features)
    1. [ItemType Resource](#itemtype-resource)
    2. [ItemStack Class](#itemstack-class)
    3. [Inventory Class](#inventory-class)
    4. [Inventory Constraints](#inventory-constraints)
    5. [Item Slots](#item-slots)
    6. [UI Controls](#ui-controls)
2. [Installation](#installation)
3. [Usage](#usage)
4. [Creating Item Types](#creating-item-types)
    1. [Basic ItemType](#basic-itemtype)
    2. [Stack Size Properties](#stack-size-properties)
    3. [Grid Constraint Properties](#grid-constraint-properties)
    4. [Weight Constraint Properties](#weight-constraint-properties)
    5. [Custom Properties](#custom-properties)
5. [Serialization](#serialization)
6. [Documentation](#documentation)
7. [Examples](#examples)

## Features

### ItemType Resource
The [`ItemType`](docs/item_type.md) resource defines common properties for inventory items. ItemTypes are Godot `.tres` resource files that can be created and edited in the Godot editor.

### ItemStack Class
The [`ItemStack`](docs/item_stack.md) class represents an item stack in an inventory. All item stacks reference an `ItemType` resource and have a stack size (default 1). Items can also have custom properties that override or extend the properties from their ItemType.

### Inventory Class
The ![](addons/gloot/images/icon_inventory.svg) [`Inventory`](docs/inventory.md) class represents a basic inventory with basic inventory operations (adding, removing, transferring items etc.) and can be configured by adding various [inventory constraints](#inventory-constraints).

### Inventory Constraints
* ![](addons/gloot/images/icon_grid_constraint.svg) [`GridConstraint`](docs/grid_constraint.md) - Limits the inventory to a 2d grid of a given width and height.
* ![](addons/gloot/images/icon_weight_constraint.svg) [`WeightConstraint`](docs/weight_constraint.md) - Limits the inventory to a given weight capacity (the default unit weight of an item is 1).
* ![](addons/gloot/images/icon_item_count_constraint.svg) [`ItemCountConstraint`](docs/item_count_constraint.md) - Limits the inventory to a given item count.

### Item Slots
The ![](addons/gloot/images/icon_item_slot.svg) [`ItemSlot`](docs/item_slot.md) class represents an item slot that can hold one inventory item.

### UI Controls
User interfaces are usually unique for each project, but it often helps to have some basic UI elements ready for earlier development phases and testing.
The following controls offer some basic interaction with various inventories:
* ![](addons/gloot/images/icon_ctrl_inventory.svg) [`CtrlInventory`](docs/ctrl_inventory.md) - Control node for displaying inventories as an [`ItemList`](https://docs.godotengine.org/en/stable/classes/class_itemlist.html).

    ![](images/screenshots/ss_inventory.png)

* ![](addons/gloot/images/icon_ctrl_capacity.svg) [`CtrlInventoryCapacity`](docs/ctrl_inventory_capacity.md) - Control node for displaying inventory capacity as a progress bar (in case a `WeightConstraint` or an `ItemCountConstraint` is attached to the inventory).

    ![](images/screenshots/ss_capacity.png)

* ![](addons/gloot/images/icon_ctrl_inventory_grid.svg) [`CtrlInventoryGrid`](docs/ctrl_inventory_grid.md) - Control node for displaying inventories with a `GridConstraint` on a 2d grid.

    ![](images/screenshots/ss_inventory_grid.png)

* ![](addons/gloot/images/icon_ctrl_item_slot.svg) [`CtrlItemSlot`](docs/ctrl_item_slot.md) - A control node representing an inventory slot (`ItemSlot`).

    ![](images/screenshots/ss_item_slot.png)

## Installation

1. Create an `addons` directory inside your project directory.
2. Get the plugin from the AssetLib or from GitHub
    * From the AssetLib: Open the AssetLib from the Godot editor and search for "GLoot". Click download and deselect everything except the `addons` directory when importing.

        ![](images/screenshots/ss_install_gloot.png)

    * From GitHub: Run `git clone https://github.com/peter-kish/gloot.git` and copy the contents of the `addons` directory to your projects `addons` directory.
4. Enable the plugin in `Project Settings > Plugins`.

## Usage

1. Create ItemType resources (`.tres` files) that define your item types (see [Creating Item Types](#creating-item-types) below).
2. Create an `Inventory` node in your scene.
3. (*Optional*) Add constraints as child nodes to the previously created inventory node.
4. Add items to the inventory by dragging ItemType resources from the FileSystem dock onto the inventory in the inspector, or from code:
    ```gdscript
    var item_type = preload("res://items/sword.tres")
    inventory.create_and_add_item(item_type)
    ```
5. (*Optional*) Create item slots that will hold various items (for example the currently equipped weapon or armor).
6. Create some UI controls to display the created inventory and its contents.
7. Call `add_item()`, `remove_item()` etc. from your scripts to manipulate inventory nodes. Refer to [the documentation](docs/) for more details about the available properties, methods and signals for each class.

## Creating Item Types

An ItemType is a Godot resource (`.tres` file) that defines the properties all items of that type will share. Each item in an inventory references an ItemType and can optionally override its properties.

### Basic ItemType

To create an ItemType:

1. In the FileSystem dock, right-click and select "New Resource..."
2. Search for and select "ItemType"
3. Save the resource as a `.tres` file (e.g., `sword.tres`)
4. Configure the properties in the inspector:
   - `id` - A unique identifier string for this item type
   - `texture` - The texture/icon for items of this type
   - `properties` - A dictionary of custom properties

Example of a minimal ItemType in `.tres` format:
```
[gd_resource type="Resource" script_class="ItemType" load_steps=2 format=3]

[ext_resource type="Script" path="res://addons/gloot/core/item_type.gd" id="1"]

[resource]
script = ExtResource("1")
id = "minimal_item"
```

### Stack Size Properties

ItemTypes can define stack-related properties:

- `stack_size` - The initial stack size (default: 1)
- `max_stack_size` - The maximum stack size (default: 1)

Example:
```gdscript
# In your ItemType resource:
properties = {
    "stack_size": 12,
    "max_stack_size": 24
}
```

Items with `max_stack_size` greater than 1 can be stacked together. GLoot provides methods like `Inventory.split_stack()` and `Inventory.merge_stacks()` to manipulate stacks.

### Grid Constraint Properties

When using a `GridConstraint`, ItemTypes can define:

- `size` (`Vector2i`) - The width and height of the item. Default is `Vector2i(1, 1)`.
- `rotated` (`bool`) - If `true`, the item is rotated by 90 degrees.
- `positive_rotation` (`bool`) - Whether the item rotates by positive or negative 90 degrees.

These can be set as exported properties on the ItemType or in the `properties` dictionary:
```gdscript
# As exported property:
size = Vector2i(2, 2)

# Or in properties dictionary:
properties = {
    "size": Vector2i(2, 2),
    "rotated": true
}
```

### Weight Constraint Properties

When using a `WeightConstraint`, the `weight` property on an ItemType defines the unit weight of items:

```gdscript
# As exported property:
weight = 5.0

# The total weight of a stack is: weight * stack_size
```

### Custom Properties

ItemTypes can have a `properties` dictionary for any custom data your game needs:

```gdscript
properties = {
    "damage": 25,
    "weapon_type": "melee",
    "description": "A sharp blade.",
    "rarity": "common"
}
```

Access these properties on an ItemStack:
```gdscript
var damage = item.get_property("damage", 0)  # Second arg is default value
var desc = item.get_property("description", "")
```

Individual items can override properties from their ItemType:
```gdscript
# Override a property on a specific item
item.set_property("damage", 30)

# Clear an override to use the ItemType's value again
item.clear_property("damage")
```

## Serialization

All GLoot classes have a `serialize()` and a `deserialize()` method that can be used for serialization. The `serialize()` methods serializes the class into a dictionary, which can be further serialized into JSON, binary or some other format.

Example:
```gdscript
# Serialize the inventory into a JSON string
var inventory: Inventory = get_node("inventory")
var dict: Dictionary = inventory.serialize()
var json: String = JSON.stringify(dict)
```

The `deserialize()` methods receive a dictionary as argument that has been previously generated with `serialize()` and apply the data to the current class instance.

Example:
```gdscript
# Deserialize the inventory from a JSON string
var inventory: Inventory = get_node("inventory")
var res: JSONParseResult = JSON.parse(json)
if res.error == OK:
    var dict = res.result
    inventory.deserialize(dict)
```

Items are serialized with a reference to their ItemType resource path, so make sure your ItemType resources remain at consistent paths.

## Documentation

The documentation can be found [here](docs/).

## Examples

Some example scenes can be found in the [examples](examples/README.md) directory.
