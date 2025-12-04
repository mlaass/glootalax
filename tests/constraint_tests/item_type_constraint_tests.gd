extends TestSuite

var inventory: Inventory
var item: ItemStack
var item2: ItemStack
var item_type_constraint: ItemTypeConstraint

const MINIMAL_ITEM = preload("res://tests/data/item_types/minimal_item.tres")
const MINIMAL_ITEM_2 = preload("res://tests/data/item_types/minimal_item_2.tres")
const ITEM1 = preload("res://tests/data/item_types/item1.tres")


func init_suite():
	tests = [
		"test_init",
		"test_empty_allowed_types",
		"test_allowed_types",
		"test_rejected_types",
		"test_add_item",
		"test_serialize",
		"test_serialize_json",
	]


func init_test() -> void:
	item = create_item(MINIMAL_ITEM)
	item2 = create_item(MINIMAL_ITEM_2)
	inventory = create_inventory()
	item_type_constraint = ItemTypeConstraint.new()
	inventory.add_constraint(item_type_constraint)


func cleanup_test() -> void:
	free_inventory(inventory)


func test_init() -> void:
	assert(item_type_constraint.inventory == inventory)
	assert(item_type_constraint.allowed_types.is_empty())


func test_empty_allowed_types() -> void:
	# Empty allowed_types means all types are allowed
	assert(item_type_constraint.has_space_for(item))
	assert(item_type_constraint.has_space_for(item2))
	assert(item_type_constraint.get_space_for(item) > 0)


func test_allowed_types() -> void:
	item_type_constraint.allowed_types = [MINIMAL_ITEM]
	assert(item_type_constraint.has_space_for(item))
	assert(item_type_constraint.get_space_for(item) > 0)


func test_rejected_types() -> void:
	item_type_constraint.allowed_types = [MINIMAL_ITEM]
	assert(!item_type_constraint.has_space_for(item2))
	assert(item_type_constraint.get_space_for(item2) == 0)


func test_add_item() -> void:
	item_type_constraint.allowed_types = [MINIMAL_ITEM]
	assert(inventory.add_item(item))
	assert(!inventory.add_item(item2))
	assert(inventory.has_item(item))
	assert(!inventory.has_item(item2))


func test_serialize() -> void:
	item_type_constraint.allowed_types = [MINIMAL_ITEM, ITEM1]
	var constraint_data = item_type_constraint.serialize()

	var new_constraint = ItemTypeConstraint.new()
	assert(new_constraint.deserialize(constraint_data))
	assert(new_constraint.allowed_types.size() == 2)
	assert(MINIMAL_ITEM in new_constraint.allowed_types)
	assert(ITEM1 in new_constraint.allowed_types)
	# RefCounted objects are automatically freed


func test_serialize_json() -> void:
	item_type_constraint.allowed_types = [MINIMAL_ITEM]
	var constraint_data = item_type_constraint.serialize()

	# To and from JSON serialization
	var json_string: String = JSON.stringify(constraint_data)
	var test_json_conv: JSON = JSON.new()
	assert(test_json_conv.parse(json_string) == OK)
	constraint_data = test_json_conv.data

	var new_constraint = ItemTypeConstraint.new()
	assert(new_constraint.deserialize(constraint_data))
	assert(new_constraint.allowed_types.size() == 1)
	assert(MINIMAL_ITEM in new_constraint.allowed_types)
	# RefCounted objects are automatically freed
