@tool
extends InventoryConstraint
class_name ItemTypeConstraint
## A constraint that limits the inventory to specific item types.
##
## Only items whose ItemType is in the allowed_types array can be added to the inventory.
## If allowed_types is empty, all item types are allowed.

const _Verify = preload("res://addons/gloot/core/verify.gd")

const _KEY_ALLOWED_TYPES: String = "allowed_types"

## List of allowed ItemType resources. If empty, all types are allowed.
@export var allowed_types: Array[ItemType] = []:
	set(value):
		allowed_types = value
		emit_changed()


func _item_type_allowed(item: ItemStack) -> bool:
	if allowed_types.is_empty():
		return true
	return item.item_type in allowed_types


## Returns the number of times this constraint can receive the given item.
func get_space_for(item: ItemStack) -> int:
	if _item_type_allowed(item):
		return item.get_max_stack_size()
	return 0


## Checks if the constraint can receive the given item.
func has_space_for(item: ItemStack) -> bool:
	return _item_type_allowed(item)


## Serializes the constraint into a `Dictionary`.
func serialize() -> Dictionary:
	var paths: Array[String] = []
	for item_type in allowed_types:
		if item_type != null and not item_type.resource_path.is_empty():
			paths.append(item_type.resource_path)
	return { _KEY_ALLOWED_TYPES: paths }


## Loads the constraint data from the given `Dictionary`.
func deserialize(source: Dictionary) -> bool:
	if not _Verify.dict(source, false, _KEY_ALLOWED_TYPES, TYPE_ARRAY):
		return false
	allowed_types.clear()
	if source.has(_KEY_ALLOWED_TYPES):
		for path in source[_KEY_ALLOWED_TYPES]:
			if path is String and ResourceLoader.exists(path):
				var item_type = load(path)
				if item_type is ItemType:
					allowed_types.append(item_type)
	return true
