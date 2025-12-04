extends TestSuite

# Test ItemTypes
const FIRE_GEM = preload("res://tests/data/item_types/fire_gem.tres")
const ICE_GEM = preload("res://tests/data/item_types/ice_gem.tres")
const MINIMAL_ITEM = preload("res://tests/data/item_types/minimal_item.tres")

var socketed_sword_type: ItemType
var sword: ItemStack
var gem: ItemStack
var ice_gem: ItemStack


func init_suite():
	tests = [
		"test_has_sockets",
		"test_get_socket_slots",
		"test_get_socket_slot",
		"test_can_socket_item",
		"test_socket_item",
		"test_unsocket_item",
		"test_get_all_socketed_items",
		"test_serialize_with_sockets",
		"test_serialize_json_with_sockets",
		"test_socket_with_constraint",
	]


func init_test() -> void:
	# Create a socketed sword item type programmatically
	socketed_sword_type = ItemType.new()
	socketed_sword_type.id = "socketed_sword"
	socketed_sword_type.name = "Socketed Sword"

	# Create two gem socket slots
	var slot1 := SocketSlotDefinition.new()
	slot1.id = "gem_slot_1"
	slot1.display_name = "Gem Socket 1"
	# Add constraint: requires socketable=true
	var constraint1 := PropertyMatchConstraint.new()
	constraint1.required_properties = {"socketable": true}
	slot1.constraints = [constraint1]

	var slot2 := SocketSlotDefinition.new()
	slot2.id = "gem_slot_2"
	slot2.display_name = "Gem Socket 2"
	var constraint2 := PropertyMatchConstraint.new()
	constraint2.required_properties = {"socketable": true}
	slot2.constraints = [constraint2]

	socketed_sword_type.socket_slots = [slot1, slot2]

	sword = ItemStack.new(socketed_sword_type)
	gem = ItemStack.new(FIRE_GEM)
	ice_gem = ItemStack.new(ICE_GEM)


func cleanup_test() -> void:
	# RefCounted items are automatically freed
	pass


func test_has_sockets() -> void:
	assert(sword.has_sockets())
	var non_socketed := ItemStack.new(MINIMAL_ITEM)
	assert(!non_socketed.has_sockets())


func test_get_socket_slots() -> void:
	var slots := sword.get_socket_slots()
	assert(slots.size() == 2)
	assert(slots[0].id == "gem_slot_1")
	assert(slots[1].id == "gem_slot_2")


func test_get_socket_slot() -> void:
	var slot := sword.get_socket_slot("gem_slot_1")
	assert(slot != null)
	assert(slot.id == "gem_slot_1")

	var invalid_slot := sword.get_socket_slot("nonexistent")
	assert(invalid_slot == null)


func test_can_socket_item() -> void:
	# Should be able to socket gem into empty slot
	assert(sword.can_socket_item("gem_slot_1", gem))

	# Should not socket into nonexistent slot
	assert(!sword.can_socket_item("nonexistent", gem))

	# Should not socket null
	assert(!sword.can_socket_item("gem_slot_1", null))


func test_socket_item() -> void:
	# Socket a gem
	assert(sword.socket_item("gem_slot_1", gem))
	assert(sword.is_socket_filled("gem_slot_1"))
	assert(sword.get_socketed_item("gem_slot_1") == gem)

	# Cannot socket another item into same slot
	assert(!sword.can_socket_item("gem_slot_1", ice_gem))
	assert(!sword.socket_item("gem_slot_1", ice_gem))

	# Can socket into different slot
	assert(sword.socket_item("gem_slot_2", ice_gem))
	assert(sword.get_socketed_item("gem_slot_2") == ice_gem)


func test_unsocket_item() -> void:
	sword.socket_item("gem_slot_1", gem)
	assert(sword.is_socket_filled("gem_slot_1"))

	var removed := sword.unsocket_item("gem_slot_1")
	assert(removed == gem)
	assert(!sword.is_socket_filled("gem_slot_1"))
	assert(sword.get_socketed_item("gem_slot_1") == null)

	# Unsocket from empty slot returns null
	var nothing := sword.unsocket_item("gem_slot_1")
	assert(nothing == null)


func test_get_all_socketed_items() -> void:
	sword.socket_item("gem_slot_1", gem)
	sword.socket_item("gem_slot_2", ice_gem)

	var all_socketed := sword.get_all_socketed_items()
	assert(all_socketed.size() == 2)
	assert(all_socketed["gem_slot_1"] == gem)
	assert(all_socketed["gem_slot_2"] == ice_gem)


func test_serialize_with_sockets() -> void:
	sword.socket_item("gem_slot_1", gem)

	var data := sword.serialize()
	assert(data.has("_sockets"))
	assert(data["_sockets"].has("gem_slot_1"))

	# Deserialize into new item
	var new_sword := ItemStack.new()
	assert(new_sword.deserialize(data))
	assert(new_sword.is_socket_filled("gem_slot_1"))

	var socketed := new_sword.get_socketed_item("gem_slot_1")
	assert(socketed != null)
	assert(socketed.item_type == FIRE_GEM)


func test_serialize_json_with_sockets() -> void:
	sword.socket_item("gem_slot_1", gem)
	sword.socket_item("gem_slot_2", ice_gem)

	var data := sword.serialize()
	var json_string := JSON.stringify(data)

	var json := JSON.new()
	assert(json.parse(json_string) == OK)
	var parsed_data: Dictionary = json.data

	var new_sword := ItemStack.new()
	assert(new_sword.deserialize(parsed_data))
	assert(new_sword.is_socket_filled("gem_slot_1"))
	assert(new_sword.is_socket_filled("gem_slot_2"))


func test_socket_with_constraint() -> void:
	# The gem slot has a PropertyMatchConstraint requiring socketable=true
	# fire_gem has socketable=true, minimal_item does not
	var non_socketable := ItemStack.new(MINIMAL_ITEM)

	# Should accept fire gem (has socketable=true)
	assert(sword.can_socket_item("gem_slot_1", gem))

	# Should reject minimal_item (no socketable property)
	assert(!sword.can_socket_item("gem_slot_1", non_socketable))
