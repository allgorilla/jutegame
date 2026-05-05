# CharacterSlot.gd
extends Control

# 各コンポーネントへの参照
@onready var button_action = $ColorRect/Button
@onready var cost_label = $ColorRect/CostPanel/Label
@onready var cost_panel = $ColorRect/CostPanel
@onready var icon_texture = $ColorRect/IconPanel/Texture
@onready var icon_panel = $ColorRect/IconPanel
@onready var name_label = $ColorRect/NamePanel/Label
@onready var name_panel = $ColorRect/NamePanel

var slot_used = false
signal action_triggered(index: int) # 追加：インデックスを渡すシグナル
var slot_index: int = -1 # 自分が何番目か保持する変数

func display_character(data):
	# マウスイベントの貫通設定（以前のトラブル防止）
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	cost_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cost_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button_action.mouse_filter = MOUSE_FILTER_PASS

	if data != null:
		slot_used = true;
		name_label.text = str(data.get("name", "不明"))
		cost_label.text = str(int(data.get("cost", 0)))
		button_action.text = "削除"
		
		# 表示状態にする
		cost_label.visible = true
		name_label.visible = true
		icon_texture.visible = true
	else:
		slot_used = false;
		cost_label.visible = false
		name_label.visible = false
		icon_texture.visible = false
		button_action.text = "追加"

func _on_button_pressed():
	# 親（PartyMember）に「自分の番号」を添えて通知する
	action_triggered.emit(slot_index)
