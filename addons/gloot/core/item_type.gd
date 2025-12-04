@tool
@icon("res://addons/gloot/images/icon_item_type.svg")
class_name ItemType
extends Resource
## Resource-based item type definition.
##
## Defines the base properties for inventory items. Each ItemType is saved as a .tres file
## and can be referenced by ItemStack instances. Properties can be overridden per-stack.

signal changed_properties  ## Emitted when any property changes (for editor updates)

## Unique identifier for this item type (used in serialization)
@export var id: String = "":
  set(value):
    id = value
    emit_changed()
    changed_properties.emit()

## Display name of the item
@export var name: String = "":
  set(value):
    name = value
    emit_changed()
    changed_properties.emit()

## Item texture/icon for UI display
@export var texture: Texture2D:
  set(value):
    texture = value
    emit_changed()
    changed_properties.emit()

## Maximum number of items per stack (default 1 = non-stackable)
@export_range(1, 9999) var max_stack_size: int = 1:
  set(value):
    max_stack_size = value
    emit_changed()
    changed_properties.emit()

## Weight per unit (used by WeightConstraint)
@export var weight: float = 1.0:
  set(value):
    weight = value
    emit_changed()
    changed_properties.emit()

## Grid size in cells (used by GridConstraint)
@export var size: Vector2i = Vector2i(1, 1):
  set(value):
    size = value
    emit_changed()
    changed_properties.emit()

## Custom properties dictionary for game-specific data
@export var custom_properties: Dictionary = {}:
  set(value):
    custom_properties = value
    emit_changed()
    changed_properties.emit()

## Socket slots that can hold other items (gems, attachments, etc.)
@export var socket_slots: Array[SocketSlotDefinition] = []:
  set(value):
    socket_slots = value
    emit_changed()
    changed_properties.emit()

# Built-in property names for validation
# Note: stack_size is NOT included here - it's a per-ItemStack property, not an ItemType property
const BUILTIN_PROPERTIES: Array[String] = ["id", "name", "texture", "image", "max_stack_size", "weight", "size", "socket_slots"]


## Returns the value of the given property, or default if not found.
func get_property(property_name: String, default_value = null) -> Variant:
  match property_name:
    "id": return id
    "name": return name
    "texture", "image": return texture
    "max_stack_size": return max_stack_size
    "weight": return weight
    "size": return size
    "socket_slots": return socket_slots
    _: return custom_properties.get(property_name, default_value)


## Checks if this item type has the given property defined.
func has_property(property_name: String) -> bool:
  if property_name in BUILTIN_PROPERTIES:
    return true
  return custom_properties.has(property_name)


## Returns all property names (built-in + custom).
func get_property_names() -> Array[String]:
  var result: Array[String] = BUILTIN_PROPERTIES.duplicate()
  for key in custom_properties.keys():
    if key not in result:
      result.append(key)
  return result


## Returns all properties as a dictionary.
func get_properties() -> Dictionary:
  var result := {
    "id": id,
    "name": name,
    "texture": texture,
    "max_stack_size": max_stack_size,
    "weight": weight,
    "size": size,
    "socket_slots": socket_slots,
  }
  result.merge(custom_properties)
  return result
