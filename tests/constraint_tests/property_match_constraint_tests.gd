extends TestSuite

var inventory: Inventory
var item_chest: ItemStack
var item_minimal: ItemStack
var property_constraint: PropertyMatchConstraint

const CHEST_ARMOUR = preload("res://tests/data/item_types/chest_armour.tres")
const MINIMAL_ITEM = preload("res://tests/data/item_types/minimal_item.tres")


func init_suite():
	tests = [
		"test_init",
		"test_empty_required_properties",
		"test_single_property_match",
		"test_single_property_no_match",
		"test_missing_property",
		"test_multiple_properties_and",
		"test_multiple_properties_or",
		"test_array_value_match",
		"test_array_value_no_match",
		"test_add_item",
		"test_serialize",
		"test_serialize_json",
	]


func init_test() -> void:
	item_chest = create_item(CHEST_ARMOUR)
	item_minimal = create_item(MINIMAL_ITEM)
	inventory = create_inventory()
	property_constraint = PropertyMatchConstraint.new()
	inventory.add_child(property_constraint)


func cleanup_test() -> void:
	free_inventory(inventory)


func test_init() -> void:
	assert(property_constraint.inventory == inventory)
	assert(property_constraint.required_properties.is_empty())
	assert(property_constraint.match_all == true)


func test_empty_required_properties() -> void:
	# Empty required_properties means all items are allowed
	assert(property_constraint.has_space_for(item_chest))
	assert(property_constraint.has_space_for(item_minimal))
	assert(property_constraint.get_space_for(item_chest) > 0)


func test_single_property_match() -> void:
	property_constraint.required_properties = {"category": "chest_armour"}
	assert(property_constraint.has_space_for(item_chest))
	assert(property_constraint.get_space_for(item_chest) > 0)


func test_single_property_no_match() -> void:
	property_constraint.required_properties = {"category": "weapon"}
	assert(!property_constraint.has_space_for(item_chest))
	assert(property_constraint.get_space_for(item_chest) == 0)


func test_missing_property() -> void:
	property_constraint.required_properties = {"category": "chest_armour"}
	# minimal_item doesn't have "category" property
	assert(!property_constraint.has_space_for(item_minimal))
	assert(property_constraint.get_space_for(item_minimal) == 0)


func test_multiple_properties_and() -> void:
	# Add a tier property to chest item for this test
	item_chest.set_property("tier", 2)

	# AND mode (default): both must match
	property_constraint.required_properties = {"category": "chest_armour", "tier": 2}
	property_constraint.match_all = true
	assert(property_constraint.has_space_for(item_chest))

	# Change tier - now should fail
	property_constraint.required_properties = {"category": "chest_armour", "tier": 3}
	assert(!property_constraint.has_space_for(item_chest))


func test_multiple_properties_or() -> void:
	# Add a tier property to chest item for this test
	item_chest.set_property("tier", 2)

	# OR mode: any property match is sufficient
	property_constraint.required_properties = {"category": "weapon", "tier": 2}
	property_constraint.match_all = false
	# category doesn't match, but tier does
	assert(property_constraint.has_space_for(item_chest))

	# Neither matches
	property_constraint.required_properties = {"category": "weapon", "tier": 5}
	assert(!property_constraint.has_space_for(item_chest))


func test_array_value_match() -> void:
	# Array value: item property must match ANY element
	property_constraint.required_properties = {"category": ["weapon", "chest_armour", "helmet"]}
	assert(property_constraint.has_space_for(item_chest))


func test_array_value_no_match() -> void:
	property_constraint.required_properties = {"category": ["weapon", "helmet", "boots"]}
	assert(!property_constraint.has_space_for(item_chest))


func test_add_item() -> void:
	property_constraint.required_properties = {"category": "chest_armour"}
	assert(inventory.add_item(item_chest))
	assert(!inventory.add_item(item_minimal))
	assert(inventory.has_item(item_chest))
	assert(!inventory.has_item(item_minimal))


func test_serialize() -> void:
	property_constraint.required_properties = {"category": "chest_armour", "tier": 2}
	property_constraint.match_all = false
	var constraint_data = property_constraint.serialize()

	var new_constraint = PropertyMatchConstraint.new()
	assert(new_constraint.deserialize(constraint_data))
	assert(new_constraint.required_properties.has("category"))
	assert(new_constraint.required_properties["category"] == "chest_armour")
	assert(new_constraint.required_properties.has("tier"))
	assert(new_constraint.required_properties["tier"] == 2)
	assert(new_constraint.match_all == false)
	new_constraint.free()


func test_serialize_json() -> void:
	property_constraint.required_properties = {"category": ["weapon", "armor"]}
	property_constraint.match_all = true
	var constraint_data = property_constraint.serialize()

	# To and from JSON serialization
	var json_string: String = JSON.stringify(constraint_data)
	var test_json_conv: JSON = JSON.new()
	assert(test_json_conv.parse(json_string) == OK)
	constraint_data = test_json_conv.data

	var new_constraint = PropertyMatchConstraint.new()
	assert(new_constraint.deserialize(constraint_data))
	assert(new_constraint.required_properties.has("category"))
	assert(new_constraint.required_properties["category"] is Array)
	assert("weapon" in new_constraint.required_properties["category"])
	assert("armor" in new_constraint.required_properties["category"])
	assert(new_constraint.match_all == true)
	new_constraint.free()
