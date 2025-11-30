extends TestSuite

const MINIMAL_ITEM = preload("res://tests/data/item_types/minimal_item.tres")
const ITEM_1X1 = preload("res://tests/data/item_types/item_1x1.tres")
const CHEST_ARMOUR = preload("res://tests/data/item_types/chest_armour.tres")

var slot: ItemSlot
var slot2: ItemSlot
var item: ItemStack
var item2: ItemStack
var inventory: Inventory


func init_suite():
    tests = [
        "test_equip_item",
        "test_add_item_to_inventory",
        "test_equip_item_in_two_slots",
        "test_can_hold_item",
        "test_serialize",
        "test_serialize_json",
        "test_property_match_constraint",
        "test_multiple_constraints",
    ]


func init_test() -> void:
    item = ItemStack.new(MINIMAL_ITEM)
    item2 = ItemStack.new(MINIMAL_ITEM)
    inventory = Inventory.new()
    inventory.add_item(item)
    inventory.add_item(item2)
    slot = ItemSlot.new()
    slot2 = ItemSlot.new()


func cleanup_test() -> void:
    free_inventory(inventory)
    free_slot(slot)
    free_slot(slot2)


func test_equip_item() -> void:
    assert(slot.get_item() == null)
    assert(slot.equip(item))
    assert(slot.get_item() == item)

    assert(slot.equip(item2))
    assert(slot.get_item() == item2)

    slot.clear()
    assert(slot.get_item() == null)


func test_add_item_to_inventory() -> void:
    assert(slot.equip(item))
    assert(inventory.add_item(item))
    assert(slot.get_item() == null)
    assert(slot.equip(item))
    assert(!inventory.has_item(item))


func test_equip_item_in_two_slots() -> void:
    assert(slot.equip(item))
    assert(slot2.equip(item))
    assert(slot.get_item() == null)
    assert(slot2.get_item() == item)


func test_can_hold_item() -> void:
    assert(slot.can_hold_item(item))
    assert(!slot.can_hold_item(null))


func test_serialize() -> void:
    assert(slot.equip(item))
    var expected_item_type := item.item_type
    var expected_properties := item.get_properties()

    var item_slot_data = slot.serialize()
    slot.clear()
    assert(slot.get_item() == null)
    assert(slot.deserialize(item_slot_data))
    assert(slot.get_item().item_type == expected_item_type)
    assert(slot.get_item().get_properties() == expected_properties)


func test_serialize_json() -> void:
    assert(slot.equip(item))
    var expected_item_type := item.item_type
    var expected_properties := item.get_properties()

    var item_slot_data = slot.serialize()

    # To and from JSON serialization
    var json_string: String = JSON.stringify(item_slot_data)
    var test_json_conv: JSON = JSON.new()
    assert(test_json_conv.parse(json_string) == OK)
    item_slot_data = test_json_conv.data

    slot.clear()
    assert(slot.get_item() == null)
    assert(slot.deserialize(item_slot_data))
    assert(slot.get_item().item_type == expected_item_type)
    assert(slot.get_item().get_properties() == expected_properties)


func test_property_match_constraint() -> void:
    # Create a slot with PropertyMatchConstraint that only accepts category: 0
    var constrained_slot := ItemSlot.new()
    var constraint := PropertyMatchConstraint.new()
    constraint.required_properties = {"category": 0}  # Match ITEM_1X1's category
    constrained_slot.add_child(constraint)
    add_child(constrained_slot)

    # Create items
    var matching_item := ItemStack.new(ITEM_1X1)  # Has category: 0
    var non_matching_item := ItemStack.new(MINIMAL_ITEM)  # Has no category property

    # Should accept matching item
    assert(constrained_slot.equip(matching_item))
    assert(constrained_slot.get_item() == matching_item)

    constrained_slot.clear()

    # Should reject non-matching item (missing property)
    assert(!constrained_slot.equip(non_matching_item))
    assert(constrained_slot.get_item() == null)

    constrained_slot.queue_free()


func test_multiple_constraints() -> void:
    # Create a slot with PropertyMatchConstraint
    # (ItemSlot already has a built-in ItemCountConstraint for single item)
    var constrained_slot := ItemSlot.new()

    var constraint1 := PropertyMatchConstraint.new()
    constraint1.required_properties = {"category": 0}  # Match ITEM_1X1
    constrained_slot.add_child(constraint1)

    add_child(constrained_slot)

    var matching_item := ItemStack.new(ITEM_1X1)  # Has category: 0
    var non_matching_item := ItemStack.new(MINIMAL_ITEM)  # No category property

    # Should accept matching item
    assert(constrained_slot.equip(matching_item))
    assert(constrained_slot.get_item() == matching_item)

    constrained_slot.clear()

    # Should reject non-matching item
    assert(!constrained_slot.equip(non_matching_item))
    assert(constrained_slot.get_item() == null)

    constrained_slot.queue_free()
