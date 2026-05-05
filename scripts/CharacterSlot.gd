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
		# --- キャラクターがいる場合 ---
		name_label.text = str(data.get("name", "EMPTY"))
		cost_label.text = str(data.get("cost", 0))
		button_action.text = "削除"
		
		# コストに応じて下地の色を変える（例）
		var style_box = cost_panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
		var cost_val = int(data.get("cost", 0))
		
		if cost_val >= 30:
			style_box.bg_color = Color.DARK_RED
		else:
			style_box.bg_color = Color("#2a2a2a") # デフォルトの暗い色
		
		cost_panel.add_theme_stylebox_override("panel", style_box)
		
		# アイコン表示（画像パスがある場合）
		# texture_icon.texture = load(data.get("icon", "res://icon.png"))
		
		# 表示状態にする
		cost_label.visible = true
		name_label.visible = true
		icon_texture.visible = true
	else:
		# --- 空欄の場合 ---
		cost_panel.show()
		cost_label.text = "--"
		name_label.text = "empty"
		button_action.text = "追加"
		
		# 不要な表示を隠す
		cost_label.visible = false
		name_label.visible = false
		icon_texture.visible = false
		# texture_icon.texture = null
