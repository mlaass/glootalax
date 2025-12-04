@tool
extends Resource
class_name SocketSlotDefinition
## Defines a socket slot that can hold another item.
##
## Socket slots are defined on ItemType resources and specify what items can be inserted.
## Each slot has an ID for identification and optional constraints to filter valid items.

## Unique identifier for this socket slot.
@export var id: String = ""

## Display name for UI purposes.
@export var display_name: String = ""

## Constraints that filter which items can be inserted into this socket.
## All constraints must pass for an item to be accepted (AND logic).
@export var constraints: Array[InventoryConstraint] = []


## Checks if the given item can be inserted into this socket slot.
func can_accept_item(item: ItemStack) -> bool:
	if item == null:
		return false
	for constraint in constraints:
		if constraint != null and not constraint.has_space_for(item):
			return false
	return true
