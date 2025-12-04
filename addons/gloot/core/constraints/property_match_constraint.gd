@tool
extends InventoryConstraint
class_name PropertyMatchConstraint
## A constraint that limits the inventory to items matching specific property values.
##
## Examples:
##   {"category": "chest_armour", "tier": 2} with match_all=true - both must match
##   {"category": ["weapon", "armor"]} - category must be "weapon" OR "armor"

const _Verify = preload("res://addons/gloot/core/verify.gd")

const _KEY_REQUIRED_PROPERTIES: String = "required_properties"
const _KEY_MATCH_ALL: String = "match_all"

## Dictionary of property_name -> required_value pairs.
## If value is an Array, item property must match ANY value in the array.
## Otherwise, compared using == operator (supports any type).
@export var required_properties: Dictionary = {}:
  set(value):
    required_properties = value
    emit_changed()

## If true (AND), all properties must match. If false (OR), any property match is sufficient.
@export var match_all: bool = true:
  set(value):
    match_all = value
    emit_changed()


func _value_matches(item_value, required_value) -> bool:
  # If required_value is an array, check if item_value matches ANY element
  if required_value is Array:
    return item_value in required_value
  # Otherwise direct comparison
  return item_value == required_value


func _property_matches(item: ItemStack) -> bool:
  if required_properties.is_empty():
    return true

  for property_name in required_properties.keys():
    var required_value = required_properties[property_name]
    var item_value = item.get_property(property_name)
    var matches = _value_matches(item_value, required_value)

    if match_all:
      # AND logic: return false on first mismatch
      if not matches:
        return false
    else:
      # OR logic: return true on first match
      if matches:
        return true

  # AND: all matched, OR: none matched
  return match_all


## Returns the number of times this constraint can receive the given item.
func get_space_for(item: ItemStack) -> int:
  if _property_matches(item):
    return item.get_max_stack_size()
  return 0


## Checks if the constraint can receive the given item.
func has_space_for(item: ItemStack) -> bool:
  return _property_matches(item)


## Serializes the constraint into a `Dictionary`.
func serialize() -> Dictionary:
  var serialized_props: Dictionary = {}
  for key in required_properties.keys():
    serialized_props[key] = {
      "type": typeof(required_properties[key]),
      "value": var_to_str(required_properties[key])
    }
  return {
    _KEY_REQUIRED_PROPERTIES: serialized_props,
    _KEY_MATCH_ALL: match_all
  }


## Loads the constraint data from the given `Dictionary`.
func deserialize(source: Dictionary) -> bool:
  if not _Verify.dict(source, false, _KEY_REQUIRED_PROPERTIES, TYPE_DICTIONARY):
    return false
  if not _Verify.dict(source, false, _KEY_MATCH_ALL, TYPE_BOOL):
    return false

  required_properties.clear()
  if source.has(_KEY_REQUIRED_PROPERTIES):
    for key in source[_KEY_REQUIRED_PROPERTIES].keys():
      var prop_data = source[_KEY_REQUIRED_PROPERTIES][key]
      if prop_data is Dictionary and prop_data.has("value"):
        required_properties[key] = str_to_var(prop_data["value"])

  match_all = source.get(_KEY_MATCH_ALL, true)
  return true
