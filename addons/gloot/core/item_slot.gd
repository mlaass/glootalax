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


func _init() -> void:
	_inventory = Inventory.new()
	var item_count_constraint := ItemCountConstraint.new()
	_inventory.add_child(item_count_constraint)
	add_child(_inventory)
	child_entered_tree.connect(_on_child_entered_tree)


func _ready() -> void:
	# Reparent any constraint children to the internal inventory
	for child in get_children():
		if child is InventoryConstraint:
			child.reparent(_inventory)


func _on_child_entered_tree(node: Node) -> void:
	if node is InventoryConstraint:
		# Defer reparent to avoid issues during tree construction
		node.reparent.call_deferred(_inventory)


func _on_item_added(item: ItemStack) -> void:
	item_equipped.emit()


func _on_item_removed(item: ItemStack) -> void:
	cleared.emit(item)


## Equips the given inventory item in the slot. If the slot already contains an item, clear() will be called first.
## Returns false if the clear call fails, the slot can't hold the given item, or already holds the given item. Returns
## true otherwise.
func equip(item: ItemStack) -> bool:
	if !can_hold_item(item):
		return false

	if get_item() != null && !clear():
		return false

	if item.get_inventory() != null:
		item.get_inventory().remove_item(item)

	return _inventory.add_item(item)


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
