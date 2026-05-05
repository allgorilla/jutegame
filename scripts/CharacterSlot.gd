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
var slot_index: int = -1 # 自分が何番目か保持する変数
var character_id = null

const STATUS_WINDOW_SCENE = preload("res://scenes/StatusWindow.tscn")

signal action_triggered(index: int) # 追加：インデックスを渡すシグナル


func display_character(data):
	# マウスイベントの貫通設定（以前のトラブル防止）
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	cost_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cost_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	name_label.mouse_filter = Control.MOUSE_FILTER_PASS
	button_action.mouse_filter = MOUSE_FILTER_PASS

	if data != null:
		slot_used = true;
		character_id = str(int(data.get("my_id", "")))
		name_label.text = str(data.get("name", "不明"))
		cost_label.text = str(int(data.get("cost", 0)))
		button_action.text = "削除"
		
		# --- リーダー（プレイヤーID）の保護処理 ---
		# 例: Global.player_data["my_id"] と一致する場合はボタンを無効化する
		if character_id == str(Global.player_data.get("my_id", "")):
			button_action.disabled = true
			button_action.modulate = Color(1, 1, 1, 0.5) # 半透明にして「押せない感」を出す
		else:
			button_action.disabled = false
			button_action.modulate = Color.WHITE

		# 表示状態にする
		cost_label.visible = true
		name_label.visible = true
		icon_texture.visible = true
	else:
		slot_used = false;
		character_id = null
		cost_label.visible = false
		name_label.visible = false
		icon_texture.visible = false
		button_action.text = "追加"

func _on_button_pressed():
	# 親（PartyMember）に「自分の番号」を添えて通知する
	action_triggered.emit(slot_index)

# 名前パネルの gui_input イベント
func _on_name_panel_gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if slot_used and character_id:
			_show_status_window()

func _show_status_window():
	# 1. character_id を元に、Global.world_list から詳細データを取得する
	# (注意: display_character で str(data.get("my_id", "")) を代入しているため、型は一致します)
	var data = Global.world_list.get(character_id)
	
	if not data:
		print("エラー: ID ", character_id, " のデータが world_list に見つかりません")
		return

	# 2. ステータス画面をインスタンス化
	var status_ui = STATUS_WINDOW_SCENE.instantiate()
	
	# 3. ルートに追加して最前面に表示する
	get_tree().root.add_child(status_ui)
	
	# 4. 取得した辞書データをセットする[cite: 3, 4]
	status_ui.set_data(data)
