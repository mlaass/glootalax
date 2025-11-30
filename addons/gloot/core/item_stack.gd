@tool
@icon("res://addons/gloot/images/icon_item.svg")
extends RefCounted
class_name ItemStack
## Stack-based inventory item class.
##
## Represents an item stack referencing an ItemType resource. Can hold property overrides
## and a stack count. The default stack size is 1.

const _StackManager = preload("res://addons/gloot/core/stack_manager.gd")
const _Verify = preload("res://addons/gloot/core/verify.gd")
const _ItemCount = preload("res://addons/gloot/core/item_count.gd")

signal property_changed(property_name: String)  ## Emitted when a property changes.

## The item type resource this stack is based on.
var item_type: ItemType:
	set(value):
		if value == item_type:
			return
		_disconnect_item_type_signals()
		item_type = value
		_connect_item_type_signals()
		property_changed.emit("item_type")

var _inventory = null  # Will be Inventory type, but can't use class_name here due to circular dependency
var _properties: Dictionary = {}  # Property overrides

const _KEY_ITEM_TYPE: String = "item_type"
const _KEY_PROPERTIES: String = "properties"
const _KEY_TYPE: String = "type"
const _KEY_VALUE: String = "value"
const _KEY_STACK_SIZE: String = "stack_size"
const _KEY_IMAGE: String = "image"
const _KEY_NAME: String = "name"


func _init(item_type_: ItemType = null) -> void:
	item_type = item_type_


func _connect_item_type_signals() -> void:
	if item_type == null:
		return
	if item_type.changed_properties.is_connected(_on_item_type_changed):
		return
	item_type.changed_properties.connect(_on_item_type_changed)


func _disconnect_item_type_signals() -> void:
	if item_type == null:
		return
	if not item_type.changed_properties.is_connected(_on_item_type_changed):
		return
	item_type.changed_properties.disconnect(_on_item_type_changed)


func _on_item_type_changed() -> void:
	property_changed.emit("item_type")


## Returns the inventory this item belongs to, or null.
func get_inventory():
	return _inventory


## Returns a duplicate of this item stack.
func duplicate() -> ItemStack:
	var result := ItemStack.new(item_type)
	result._properties = _properties.duplicate()
	return result


## Checks if the item has the given property.
func has_property(property_name: String) -> bool:
	if _properties.has(property_name):
		return true
	if item_type != null and item_type.has_property(property_name):
		return true
	return false


## Returns the given property value. Checks overrides first, then item_type.
func get_property(property_name: String, default_value = null) -> Variant:
	if _properties.has(property_name):
		var value = _properties[property_name]
		if typeof(value) == TYPE_DICTIONARY or typeof(value) == TYPE_ARRAY:
			return value.duplicate()
		return value

	if item_type != null and item_type.has_property(property_name):
		var value = item_type.get_property(property_name, default_value)
		if typeof(value) == TYPE_DICTIONARY or typeof(value) == TYPE_ARRAY:
			return value.duplicate()
		return value

	return default_value


## Sets the given property value (creates an override).
func set_property(property_name: String, value) -> void:
	if get_property(property_name) == value:
		return

	# If setting to same as item_type value, remove override
	if item_type != null and item_type.has_property(property_name):
		if item_type.get_property(property_name) == value and _properties.has(property_name):
			_properties.erase(property_name)
			property_changed.emit(property_name)
			return

	if value == null:
		if _properties.has(property_name):
			_properties.erase(property_name)
			property_changed.emit(property_name)
	else:
		_properties[property_name] = value
		property_changed.emit(property_name)


## Clears (removes) a property override.
func clear_property(property_name: String) -> void:
	if _properties.has(property_name):
		_properties.erase(property_name)
		property_changed.emit(property_name)


## Returns array of overridden property names.
func get_overridden_properties() -> Array:
	return _properties.keys().duplicate()


## Returns all property names (from item_type + overrides).
func get_properties() -> Array:
	var result: Array = _properties.keys().duplicate()
	if item_type != null:
		for key in item_type.get_property_names():
			if key not in result:
				result.append(key)
	return result


## Checks if the given property is overridden.
func is_property_overridden(property_name: String) -> bool:
	return _properties.has(property_name)


## Resets the item stack (clears overrides, keeps item_type).
func reset() -> void:
	_properties.clear()


## Helper: Returns the texture from item_type or override.
func get_texture() -> Texture2D:
	var tex = get_property("texture")
	if tex is Texture2D:
		return tex
	# Fallback: check for image path (backwards compat)
	var texture_path = get_property(_KEY_IMAGE)
	if texture_path and texture_path is String and texture_path != "" and ResourceLoader.exists(texture_path):
		var loaded = load(texture_path)
		if loaded is Texture2D:
			return loaded
	return null


## Helper: Returns item title (name property or item_type.id).
func get_title() -> String:
	var title = get_property(_KEY_NAME, null)
	if title is String and not title.is_empty():
		return title
	if item_type != null:
		if not item_type.name.is_empty():
			return item_type.name
		return item_type.id
	return ""


## Returns the stack size.
func get_stack_size() -> int:
	return _StackManager.get_item_stack_size(self).count


## Returns the maximum stack size.
func get_max_stack_size() -> int:
	return _StackManager.get_item_max_stack_size(self).count


## Sets the stack size.
func set_stack_size(stack_size: int) -> bool:
	return _StackManager.set_item_stack_size(self, _ItemCount.new(stack_size))


## Sets the maximum stack size.
func set_max_stack_size(max_stack_size: int) -> void:
	_StackManager.set_item_max_stack_size(self, _ItemCount.new(max_stack_size))


## Serializes the item stack to a dictionary.
func serialize() -> Dictionary:
	var result: Dictionary = {}

	if item_type != null:
		if not item_type.resource_path.is_empty():
			result[_KEY_ITEM_TYPE] = item_type.resource_path
		else:
			# Inline item_type (not saved to file) - serialize id
			result[_KEY_ITEM_TYPE] = item_type.id
	else:
		result[_KEY_ITEM_TYPE] = ""

	if not _properties.is_empty():
		result[_KEY_PROPERTIES] = {}
		for property_name in _properties.keys():
			result[_KEY_PROPERTIES][property_name] = _serialize_property(property_name)

	return result


func _serialize_property(property_name: String) -> Dictionary:
	var property_value = _properties[property_name]
	var property_type = typeof(property_value)
	return {
		_KEY_TYPE: property_type,
		_KEY_VALUE: var_to_str(property_value)
	}


## Deserializes item stack from a dictionary.
func deserialize(source: Dictionary) -> bool:
	if not _Verify.dict(source, true, _KEY_ITEM_TYPE, TYPE_STRING):
		return false
	if not _Verify.dict(source, false, _KEY_PROPERTIES, TYPE_DICTIONARY):
		return false

	reset()

	var item_type_path: String = source[_KEY_ITEM_TYPE]
	if not item_type_path.is_empty():
		if item_type_path.begins_with("res://"):
			item_type = load(item_type_path)
		# else: need to look up by id from some registry (not supported in this version)

	if source.has(_KEY_PROPERTIES):
		for key in source[_KEY_PROPERTIES].keys():
			var value = _deserialize_property(source[_KEY_PROPERTIES][key])
			if value != null:
				set_property(key, value)

	return true


func _deserialize_property(data: Dictionary):
	if not data.has(_KEY_VALUE) or not data.has(_KEY_TYPE):
		return null
	var result = str_to_var(data[_KEY_VALUE])
	var expected_type: int = data[_KEY_TYPE]
	var property_type: int = typeof(result)
	if property_type != expected_type:
		push_warning("Property has unexpected type: %s. Expected: %s" % [property_type, expected_type])
		return null
	return result


# Stack operations (delegate to StackManager)
## Merges this stack into the destination stack.
func merge_into(item_dst: ItemStack, split: bool = false) -> bool:
	return _StackManager.merge_stacks(item_dst, self, split)


## Checks if this stack can be merged into the destination.
func can_merge_into(item_dst: ItemStack, split: bool = false) -> bool:
	return _StackManager.can_merge_stacks(item_dst, self, split)


## Checks if this stack is compatible for merging with the destination.
func compatible_with(item_dst: ItemStack) -> bool:
	return _StackManager.stacks_compatible(self, item_dst)


## Returns the free stack space.
func get_free_stack_space() -> int:
	return _StackManager.get_free_stack_space(self).count


## Splits the stack and returns a new stack with the specified size.
func split(new_stack_size: int) -> ItemStack:
	return _StackManager.split_stack(self, _ItemCount.new(new_stack_size))


## Checks if the stack can be split with the given size.
func can_split(new_stack_size: int) -> bool:
	return _StackManager.can_split_stack(self, _ItemCount.new(new_stack_size))


## Swaps two items between inventories. Returns false if swap fails.
static func swap(item1: ItemStack, item2: ItemStack) -> bool:
	if item1 == null or item2 == null or item1 == item2:
		return false

	var inv1 = item1.get_inventory()
	var inv2 = item2.get_inventory()
	if inv1 == null or inv2 == null:
		return false

	if not inv1._constraint_manager._on_pre_item_swap(item1, item2):
		return false
	if inv1 != inv2:
		if not inv2._constraint_manager._on_pre_item_swap(item1, item2):
			return false

	var idx1 = inv1.get_item_index(item1)
	var idx2 = inv2.get_item_index(item2)
	inv1.remove_item(item1)
	inv2.remove_item(item2)

	if not inv2.add_item(item1):
		inv1.add_item(item1)
		inv1.move_item(inv1.get_item_index(item1), idx1)
		inv2.add_item(item2)
		inv2.move_item(inv2.get_item_index(item2), idx2)
		return false
	if not inv1.add_item(item2):
		inv1.add_item(item1)
		inv1.move_item(inv1.get_item_index(item1), idx1)
		inv2.add_item(item2)
		inv2.move_item(inv2.get_item_index(item2), idx2)
		return false

	inv2.move_item(inv2.get_item_index(item1), idx2)
	inv1.move_item(inv1.get_item_index(item2), idx1)

	inv1._constraint_manager._on_post_item_swap(item1, item2)
	if inv1 != inv2:
		inv2._constraint_manager._on_post_item_swap(item1, item2)

	return true
