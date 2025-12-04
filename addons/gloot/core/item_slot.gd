@tool
@icon("res://addons/gloot/images/icon_item_slot.svg")
class_name ItemSlot
extends Node
## An item slot that can hold an inventory item.
##
## An item slot that can hold a single inventory item (ItemStack).

signal item_equipped ## Emitted when an item is placed in the slot.
signal cleared(item: ItemStack) ## Emitted when the slot is cleared.

const _Verify = preload("res://addons/gloot/core/verify.gd")
const _KEY_ITEM: String = "item"

var _inventory: Inventory = null:
	set(new_inventory):
		if new_inventory == _inventory:
			return
		_disconnect_inventory_signals()
		_inventory = new_inventory
		_connect_inventory_signals()

var _serialized_format: Dictionary:
	set(new_serialized_format):
		_serialized_format = new_serialized_format


func _get_property_list():
	return [
		{
			"name": "_serialized_format",
			"type": TYPE_DICTIONARY,
			"usage": PROPERTY_USAGE_STORAGE
		},
	]


func _update_serialized_format() -> void:
	if Engine.is_editor_hint():
		_serialized_format = serialize()
		notify_property_list_changed()


func _connect_inventory_signals() -> void:
	if !is_instance_valid(_inventory):
		return
	_inventory.item_added.connect(_on_item_added)
	_inventory.item_removed.connect(_on_item_removed)


func _disconnect_inventory_signals() -> void:
	if !is_instance_valid(_inventory):
		return
	_inventory.item_added.disconnect(_on_item_added)
	_inventory.item_removed.disconnect(_on_item_removed)


## Array of additional constraints to apply to this slot.
## These are added on top of the built-in ItemCountConstraint.
@export var constraints: Array[InventoryConstraint] = []:
	set(value):
		constraints = value
		_apply_constraints()


func _init() -> void:
	_inventory = Inventory.new()
	var item_count_constraint := ItemCountConstraint.new()
	item_count_constraint.constraint_name = "_builtin_item_count"
	_inventory.add_constraint(item_count_constraint)
	add_child(_inventory)


func _ready() -> void:
	_apply_constraints()
	if !_serialized_format.is_empty():
		deserialize(_serialized_format)


func _apply_constraints() -> void:
	if !is_instance_valid(_inventory):
		return
	# Remove all non-builtin constraints
	for constraint in _inventory.get_constraints():
		if !constraint.constraint_name.begins_with("_builtin"):
			_inventory.remove_constraint(constraint)
	# Add the exported constraints
	for constraint in constraints:
		if constraint != null:
			_inventory.add_constraint(constraint)


func _on_item_added(item: ItemStack) -> void:
	_update_serialized_format()
	item_equipped.emit()


func _on_item_removed(item: ItemStack) -> void:
	_update_serialized_format()
	cleared.emit(item)


## Equips the given inventory item in the slot. If the slot already contains an item, clear() will be called first.
## If the item's stack_size exceeds the slot's capacity, only as many items as fit will be taken and the rest
## will remain in the source inventory.
## Returns false if the clear call fails, the slot can't hold any of the item, or already holds the given item.
## Returns true otherwise.
func equip(item: ItemStack) -> bool:
	if item == null:
		return false

	# Clear existing item first (so can_hold_item works correctly with ItemCountConstraint)
	if get_item() != null && !clear():
		return false

	# Check if slot can hold at least one item from the stack
	if !_can_hold_any(item):
		return false

	# Use autosplitmerge to handle partial stack transfers
	return _inventory.add_item_autosplitmerge(item)


## Checks if the slot can hold at least one item from the given stack.
## Used internally for autosplit operations.
func _can_hold_any(item: ItemStack) -> bool:
	if item == null:
		return false
	return _inventory._constraint_manager.get_space_for(item).count > 0


## Clears the item slot. Returns false if there's no item in the slot.
func clear() -> bool:
	if get_item() == null:
		return false

	_inventory.clear()
	return true


## Returns the equipped item or `null` if there's no item in the slot.
func get_item() -> ItemStack:
	if _inventory.get_item_count() == 0:
		return null
	return _inventory.get_items()[0]


## Checks if the slot can hold the given item.
func can_hold_item(item: ItemStack) -> bool:
	if item == null:
		return false
	# Check if the internal inventory's constraints would accept this item
	return _inventory._constraint_manager.has_space_for(item)


## Serializes the item slot into a `Dictionary`.
func serialize() -> Dictionary:
	var result: Dictionary = {}

	if get_item() != null:
		result[_KEY_ITEM] = get_item().serialize()

	return result


## Loads the item slot data from the given `Dictionary`.
func deserialize(source: Dictionary) -> bool:
	if !_Verify.dict(source, false, _KEY_ITEM, [TYPE_DICTIONARY]):
		return false

	clear()

	if source.has(_KEY_ITEM):
		var item := ItemStack.new()
		if !item.deserialize(source[_KEY_ITEM]):
			return false
		equip(item)

	return true
