@tool
extends Node2D

const ITEM_2X2 = preload("res://tests/data/item_types/item_2x2.tres")

func _ready():
    %CtrlInventoryItem.item = ItemStack.new(ITEM_2X2)
