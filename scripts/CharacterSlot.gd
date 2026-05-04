# CharacterSlot.gd
extends Control

# 枠線を表示して存在を確認する
func _ready():
	var debug_rect = ColorRect.new()
	debug_rect.color = Color(1, 0, 0, 0.5) # 半透明の赤
	debug_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(debug_rect)
