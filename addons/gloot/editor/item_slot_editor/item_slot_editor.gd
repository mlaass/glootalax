@tool
extends Control

const _Undoables = preload("res://addons/gloot/editor/undoables.gd")
const _EditorIcons = preload("res://addons/gloot/editor/common/editor_icons.gd")
const _PropertiesEditor = preload("res://addons/gloot/editor/item_editor/properties_editor.tscn")
const _POPUP_SIZE = Vector2i(800, 300)

var item_slot: ItemSlot:
	set(new_item_slot):
		disconnect_item_slot_signals()
		item_slot = new_item_slot
		%CtrlItemSlot.item_slot = item_slot
		connect_item_slot_signals()

		_refresh()

var _properties_editor: Window


func connect_item_slot_signals():
	if !item_slot:
		return

	item_slot.item_equipped.connect(_refresh)
	item_slot.cleared.connect(_on_item_slot_cleared)


func disconnect_item_slot_signals():
	if !item_slot:
		return

	item_slot.item_equipped.disconnect(_refresh)
	item_slot.cleared.disconnect(_on_item_slot_cleared)


func _on_item_slot_cleared(item: ItemStack) -> void:
	_refresh()


func init(item_slot_: ItemSlot) -> void:
	item_slot = item_slot_


func _refresh() -> void:
	if !is_inside_tree() || item_slot == null:
		return


func _ready() -> void:
	_apply_editor_settings()

	%BtnEdit.icon = _EditorIcons.get_icon("Edit")
	%BtnClear.icon = _EditorIcons.get_icon("Remove")

	%BtnEdit.pressed.connect(_on_btn_edit)
	%BtnClear.pressed.connect(_on_btn_clear)

	%CtrlItemSlot.item_slot = item_slot


func _apply_editor_settings() -> void:
	var control_height: int = ProjectSettings.get_setting("gloot/inspector_control_height")
	custom_minimum_size.y = control_height


func _on_btn_edit() -> void:
	if item_slot.get_item() == null:
		return
	if _properties_editor == null:
		_properties_editor = _PropertiesEditor.instantiate()
		add_child(_properties_editor)
	_properties_editor.item = item_slot.get_item()
	_properties_editor.popup_centered(_POPUP_SIZE)


func _on_btn_clear() -> void:
	if item_slot.get_item() != null:
		_Undoables.undoable_action(item_slot, "Clear slot", func():
			return item_slot.clear()
		)


static func _select_node(node: Node) -> void:
	EditorInterface.get_selection().clear()
	EditorInterface.get_selection().add_node(node)
	EditorInterface.edit_node(node)


func _can_drop_data(at_position: Vector2, data) -> bool:
	if data is Dictionary and data.has("type") and data["type"] == "files":
		for file_path in data["files"]:
			if file_path.ends_with(".tres") or file_path.ends_with(".res"):
				var res = load(file_path)
				if res is ItemType:
					return true
	return false


func _drop_data(at_position: Vector2, data) -> void:
	if data is Dictionary and data.has("type") and data["type"] == "files":
		for file_path in data["files"]:
			if file_path.ends_with(".tres") or file_path.ends_with(".res"):
				var res = load(file_path)
				if res is ItemType:
					var item := ItemStack.new(res)
					_Undoables.undoable_action(item_slot, "Equip item", func():
						return item_slot.equip(item)
					)
					break  # Only equip one item in slot
