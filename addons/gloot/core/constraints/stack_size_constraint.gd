@tool
extends InventoryConstraint
class_name StackSizeConstraint
## A constraint that limits the maximum stack size of items in the inventory.
##
## This constraint limits the total number of individual items (stack_size sum) that can be
## stored in the inventory, regardless of how many ItemStacks they're divided into.

const _Verify = preload("res://addons/gloot/core/verify.gd")

## Default maximum stack size.
const DEFAULT_MAX_STACK_SIZE = 1

const _KEY_MAX_STACK_SIZE: String = "max_stack_size"

## Maximum total stack size allowed in the inventory.
@export var max_stack_size: int = DEFAULT_MAX_STACK_SIZE:
  set(new_max_stack_size):
    if new_max_stack_size < 1:
      new_max_stack_size = 1
    if new_max_stack_size == max_stack_size:
      return
    if get_occupied_space() > new_max_stack_size:
      return
    max_stack_size = new_max_stack_size
    emit_changed()


## Returns the number of items that can still be added to the inventory.
func get_free_space() -> int:
  return max(0, max_stack_size - get_occupied_space())


## Returns the total stack size of all items in the inventory.
func get_occupied_space() -> int:
  if !is_instance_valid(inventory):
    return 0
  var total := 0
  for item in inventory.get_items():
    total += item.get_stack_size()
  return total


## Returns the number of items from the given stack that can be added.
func get_space_for(item: ItemStack) -> int:
  return get_free_space()


## Checks if the constraint can receive the entire item stack.
## Returns true only if there's enough space for all items in the stack.
func has_space_for(item: ItemStack) -> bool:
  return get_space_for(item) >= item.get_stack_size()


## Resets the constraint to default values.
func reset() -> void:
  max_stack_size = DEFAULT_MAX_STACK_SIZE


## Serializes the constraint into a `Dictionary`.
func serialize() -> Dictionary:
  var result := {}
  result[_KEY_MAX_STACK_SIZE] = max_stack_size
  return result


## Loads the constraint data from the given `Dictionary`.
func deserialize(source: Dictionary) -> bool:
  if !_Verify.dict(source, false, _KEY_MAX_STACK_SIZE, [TYPE_INT, TYPE_FLOAT]):
    return false

  reset()
  if source.has(_KEY_MAX_STACK_SIZE):
    max_stack_size = source[_KEY_MAX_STACK_SIZE]

  return true
