extends Control
## Example scene demonstrating socket UI with confirmation dialogs.

const info_offset: Vector2 = Vector2(20, 0)

# Pending action storage for async confirmation
var _pending_action: Callable = Callable()


func _ready() -> void:
	# Set custom item control scene with socket support
	%CtrlInventoryGrid.custom_item_control_scene = preload(
		"res://addons/gloot/ui/ctrl_inventory_item_with_sockets.tscn")

	# Set confirmation callbacks
	%CtrlInventoryGrid.socket_item_callback = _on_socket_confirm
	%CtrlInventoryGrid.unsocket_item_callback = _on_unsocket_confirm

	# Connect feedback signals
	%CtrlInventoryGrid.item_socketed.connect(_on_item_socketed)
	%CtrlInventoryGrid.item_unsocketed.connect(_on_item_unsocketed)

	# Connect hover info
	%CtrlInventoryGrid.item_mouse_entered.connect(_on_item_mouse_entered)
	%CtrlInventoryGrid.item_mouse_exited.connect(_on_item_mouse_exited)
	%CtrlInventoryGridGems.item_mouse_entered.connect(_on_item_mouse_entered)
	%CtrlInventoryGridGems.item_mouse_exited.connect(_on_item_mouse_exited)

	# Connect dialog confirmation
	%ConfirmDialog.confirmed.connect(_on_dialog_confirmed)
	%ConfirmDialog.canceled.connect(_on_dialog_canceled)


func _on_socket_confirm(parent: ItemStack, slot_id: String, gem: ItemStack) -> bool:
	# Store action to execute on confirmation
	_pending_action = func():
		if parent.socket_item(slot_id, gem):
			%CtrlInventoryGrid.item_socketed.emit(parent, slot_id, gem)

	# Show confirmation dialog
	%ConfirmDialog.dialog_text = "Socket '%s' into '%s'?" % [gem.get_title(), parent.get_title()]
	%ConfirmDialog.popup_centered()
	# Return false to prevent immediate action - we'll do it on dialog confirm
	return false


func _on_unsocket_confirm(parent: ItemStack, slot_id: String, gem: ItemStack) -> bool:
	# Store action to execute on confirmation
	_pending_action = func():
		var removed_gem = parent.unsocket_item(slot_id)
		if removed_gem:
			# Return the gem to the gems inventory
			%InventoryGems.add_item(removed_gem)
			%CtrlInventoryGrid.item_unsocketed.emit(parent, slot_id, removed_gem)

	# Show confirmation dialog
	%ConfirmDialog.dialog_text = "Remove '%s' from '%s'?" % [gem.get_title(), parent.get_title()]
	%ConfirmDialog.popup_centered()
	# Return false to prevent immediate action
	return false


func _on_dialog_confirmed() -> void:
	if _pending_action.is_valid():
		_pending_action.call()
	_pending_action = Callable()


func _on_dialog_canceled() -> void:
	_pending_action = Callable()
	%LblStatus.text = "Action cancelled"


func _on_item_socketed(parent: ItemStack, slot_id: String, gem: ItemStack) -> void:
	print("Socketed: %s -> %s [%s]" % [gem.get_title(), parent.get_title(), slot_id])
	%LblStatus.text = "Socketed %s into %s" % [gem.get_title(), parent.get_title()]


func _on_item_unsocketed(parent: ItemStack, slot_id: String, gem: ItemStack) -> void:
	print("Unsocketed: %s from %s [%s]" % [gem.get_title(), parent.get_title(), slot_id])
	%LblStatus.text = "Removed %s from %s" % [gem.get_title(), parent.get_title()]


func _on_item_mouse_entered(item: ItemStack) -> void:
	%LblInfo.show()
	var text = item.get_title()
	if item.has_sockets():
		var sockets = item.get_socket_slots()
		text += " (%d sockets)" % sockets.size()
		for slot in sockets:
			var socketed = item.get_socketed_item(slot.id)
			if socketed:
				text += "\n  - %s: %s" % [slot.display_name, socketed.get_title()]
			else:
				text += "\n  - %s: (empty)" % slot.display_name
	%LblInfo.text = text


func _on_item_mouse_exited(_item: ItemStack) -> void:
	%LblInfo.hide()


func _input(event: InputEvent) -> void:
	if !(event is InputEventMouseMotion):
		return
	%LblInfo.set_global_position(get_global_mouse_position() + info_offset)
