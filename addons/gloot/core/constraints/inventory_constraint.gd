@tool
extends Resource
class_name InventoryConstraint
## Base inventory constraint class.
##
## Base inventory constraint class which implements some basic constraint functionality and defines methods that can be
## overridden.

## Note: Uses inherited Resource.changed signal for state change notifications.

## Constraint name for serialization and identification.
@export var constraint_name: String = ""

## Reference to an inventory that this constraint belongs to.
var inventory: Inventory = null:
	set(new_inventory):
		if new_inventory == inventory:
			return
		var old_inventory = inventory
		inventory = new_inventory
		if old_inventory != null:
			_on_inventory_unset(old_inventory)
		if new_inventory != null:
			_on_inventory_set()


## Returns the number of times this constraint can receive the given item.
func get_space_for(item: ItemStack) -> int:
	return 0


## Checks if the constraint can receive the given item.
func has_space_for(item: ItemStack) -> bool:
	return false


## Serializes the constraint into a `Dictionary`.
func serialize() -> Dictionary:
	return {}


## Loads the constraint data from the given `Dictionary`.
func deserialize(source: Dictionary) -> bool:
	return true


## Called when constraint inventory is set/changed.
func _on_inventory_set() -> void:
	pass


## Called when constraint is removed from an inventory.
func _on_inventory_unset(old_inventory: Inventory) -> void:
	pass


## Called when an item is added to the inventory.
func _on_item_added(item: ItemStack) -> void:
	pass


## Called when an item is removed from the inventory.
func _on_item_removed(item: ItemStack) -> void:
	pass


## Called when an item property has changed.
func _on_item_property_changed(item: ItemStack, property: String) -> void:
	pass


## Called before the two given items are swapped.
func _on_pre_item_swap(item1: ItemStack, item2: ItemStack) -> bool:
	return true


## Called after the two given items have been swapped.
func _on_post_item_swap(item1: ItemStack, item2: ItemStack) -> void:
	pass
