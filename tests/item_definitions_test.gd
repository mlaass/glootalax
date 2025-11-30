extends TestSuite

var inventory: Inventory

const MINIMAL_ITEM = preload("res://tests/data/item_types/minimal_item.tres")


func init_suite() -> void:
    tests = ["test_item_count"]


func init_test() -> void:
    inventory = Inventory.new()
    inventory.create_and_add_item(MINIMAL_ITEM)
    inventory.create_and_add_item(MINIMAL_ITEM)


func cleanup_test() -> void:
    free_inventory(inventory)


func test_item_count() -> void:
    var items = inventory.get_items()
    assert(items.size() == 2)
