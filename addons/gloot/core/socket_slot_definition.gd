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

@export_group("Visual Override")
## Override size for this socket (Vector2.ZERO = use default from control).
## Values are in pixels relative to original texture size.
@export var size_override: Vector2 = Vector2.ZERO:
	set(value):
		size_override = value
		emit_changed()

## When true, use 'position' as absolute position. When false, use auto-layout.
@export var use_custom_position: bool = false:
	set(value):
		use_custom_position = value
		emit_changed()

## Absolute position on item (only used when use_custom_position is true).
## Values are in pixels relative to original texture size.
@export var position: Vector2 = Vector2.ZERO:
	set(value):
		position = value
		emit_changed()

## Custom scene for this socket slot (null = use default from control).
## Scene should extend CtrlSocketSlot or implement compatible interface.
@export var custom_scene: PackedScene = null:
	set(value):
		custom_scene = value
		emit_changed()


## Checks if the given item can be inserted into this socket slot.
func can_accept_item(item: ItemStack) -> bool:
	if item == null:
		return false
	for constraint in constraints:
		if constraint != null and not constraint.has_space_for(item):
			return false
	return true
