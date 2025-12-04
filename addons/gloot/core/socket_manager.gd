extends RefCounted
class_name SocketManager
## Static helper methods for managing item sockets.
##
## Provides utility functions for socketing, unsocketing, and querying socketed items.
## Follows the same pattern as StackManager.

const _KEY_SOCKETS: String = "_sockets"


## Returns the socket slot definitions from the item's ItemType.
static func get_socket_slots(item: ItemStack) -> Array[SocketSlotDefinition]:
	if item == null or item.item_type == null:
		return []
	return item.item_type.socket_slots


## Returns the socket slot definition for the given slot ID, or null if not found.
static func get_socket_slot(item: ItemStack, slot_id: String) -> SocketSlotDefinition:
	for slot in get_socket_slots(item):
		if slot.id == slot_id:
			return slot
	return null


## Returns the item socketed in the given slot, or null if empty.
static func get_socketed_item(item: ItemStack, slot_id: String) -> ItemStack:
	var sockets := _get_sockets_data(item)
	if not sockets.has(slot_id):
		return null
	return sockets[slot_id] as ItemStack


## Checks if the given gem can be socketed into the specified slot.
static func can_socket_item(item: ItemStack, slot_id: String, gem: ItemStack) -> bool:
	if item == null or gem == null:
		return false

	var slot := get_socket_slot(item, slot_id)
	if slot == null:
		return false

	# Check if slot is already occupied
	if get_socketed_item(item, slot_id) != null:
		return false

	# Check slot constraints
	return slot.can_accept_item(gem)


## Sockets the given item into the specified slot. Returns false if validation fails.
static func socket_item(item: ItemStack, slot_id: String, gem: ItemStack) -> bool:
	if not can_socket_item(item, slot_id, gem):
		return false

	# Remove gem from its current inventory if any
	if gem.get_inventory() != null:
		gem.get_inventory().remove_item(gem)

	var sockets := _get_sockets_data(item)
	sockets[slot_id] = gem
	_set_sockets_data(item, sockets)
	return true


## Removes and returns the socketed item from the specified slot, or null if empty.
static func unsocket_item(item: ItemStack, slot_id: String) -> ItemStack:
	var sockets := _get_sockets_data(item)
	if not sockets.has(slot_id):
		return null

	var gem: ItemStack = sockets[slot_id]
	sockets.erase(slot_id)
	_set_sockets_data(item, sockets)
	return gem


## Returns all socketed items as a dictionary {slot_id: ItemStack}.
static func get_all_socketed_items(item: ItemStack) -> Dictionary:
	return _get_sockets_data(item).duplicate()


## Checks if the item has any socket slots defined.
static func has_sockets(item: ItemStack) -> bool:
	return not get_socket_slots(item).is_empty()


## Checks if a specific socket slot is occupied.
static func is_socket_filled(item: ItemStack, slot_id: String) -> bool:
	return get_socketed_item(item, slot_id) != null


## Serializes the socket contents for the given item.
static func serialize_sockets(item: ItemStack) -> Dictionary:
	var result := {}
	var sockets := _get_sockets_data(item)
	for slot_id in sockets:
		var socketed_item: ItemStack = sockets[slot_id]
		if socketed_item != null:
			result[slot_id] = socketed_item.serialize()
	return result


## Deserializes socket contents into the given item.
static func deserialize_sockets(item: ItemStack, source: Dictionary) -> bool:
	var sockets := {}
	for slot_id in source:
		var socketed_item := ItemStack.new()
		if not socketed_item.deserialize(source[slot_id]):
			return false
		sockets[slot_id] = socketed_item
	_set_sockets_data(item, sockets)
	return true


## Internal: Get the sockets data dictionary from item properties.
static func _get_sockets_data(item: ItemStack) -> Dictionary:
	if item == null:
		return {}
	var sockets = item.get_property(_KEY_SOCKETS, null)
	if sockets == null or not sockets is Dictionary:
		return {}
	return sockets


## Internal: Set the sockets data dictionary in item properties.
static func _set_sockets_data(item: ItemStack, sockets: Dictionary) -> void:
	if item == null:
		return
	if sockets.is_empty():
		item.clear_property(_KEY_SOCKETS)
	else:
		item.set_property(_KEY_SOCKETS, sockets)
