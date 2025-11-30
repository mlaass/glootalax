# `ItemSlot`

Inherits: `Node`

## Description

An item slot that can hold an inventory item.

Used to represent equipment slots, quick slots, or any single-item container.

## Methods

* `equip(item: ItemStack) -> bool` - Equips the given inventory item in the slot. If the slot already contains an item, `clear()` will be called first. Returns `false` if the clear call fails, the slot can't hold the given item, or already holds the given item. Returns `true` otherwise.
* `clear() -> bool` - Clears the item slot. Returns `false` if there's no item in the slot.
* `get_item() -> ItemStack` - Returns the equipped item or `null` if there's no item in the slot.
* `can_hold_item(item: ItemStack) -> bool` - Checks if the slot can hold the given item.
* `serialize() -> Dictionary` - Serializes the item slot into a `Dictionary`.
* `deserialize(source: Dictionary) -> bool` - Loads the item slot data from the given `Dictionary`.

## Signals

* `item_equipped()` - Emitted when an item is placed in the slot.
* `cleared()` - Emitted when the slot is cleared.

## Constraints

`ItemSlot` supports constraints just like `Inventory`. Add any `InventoryConstraint` node as a child of the `ItemSlot` and it will be applied to filter which items can be equipped.

By default, `ItemSlot` includes a built-in `ItemCountConstraint` that ensures only one item can be equipped at a time.

### Example with PropertyMatchConstraint

To create an equipment slot that only accepts chest armor:

```
ItemSlot
  └── PropertyMatchConstraint (required_properties = {"category": "chest_armour"})
```

## Example

```gdscript
# Equip an item from inventory
var weapon = inventory.get_item_with_type(sword_type)
if weapon != null and weapon_slot.can_hold_item(weapon):
    weapon_slot.equip(weapon)

# Check equipped item
var equipped = weapon_slot.get_item()
if equipped != null:
    print("Equipped: ", equipped.get_title())

# Unequip
weapon_slot.clear()
```
