# CharacterSelector.gd
extends CanvasLayer

signal character_selected(char_id: String)
signal cancelled

const CHARACTER_SLOT_SCENE = preload("res://scenes/CharacterSlot.tscn")

@onready var v_box = $MainContent/ScrollContainer/VBoxContainer
@onready var cost_label = $MainContent/CostArea/CostLabel

var current_party_ids = [] # 現在の暫定パーティID一覧
var remaining_cost = 0      # あとどれだけコストを使えるか

func setup(party_ids: Array, max_cost: int, current_total_cost: int):
	current_party_ids = party_ids
	remaining_cost = max_cost - current_total_cost;
	cost_label.text = str(current_total_cost)+"/"+str(max_cost)
	_render_list()

func _render_list():
	for child in v_box.get_children():
		child.queue_free()
	
	var inn_list = Global.player_data.get("inn_list", [])
	
	for id_raw in inn_list:
		var id = str(int(id_raw))
		
		# 1. 重複チェック：既にパーティにいるなら表示しない
		if id in current_party_ids:
			continue
			
		var data = Global.world_list.get(str(int(id)))
		if not data:
			continue
			
		# 2. スロットの生成
		var slot = CHARACTER_SLOT_SCENE.instantiate()
		v_box.add_child(slot)
		
		# スロットのセットアップ
		slot.display_character(data)
		slot.button_action.text = "追加"
		
		# 3. コストチェック：コストオーバーならボタンを無効化
		var char_cost = int(data.get("cost", 0))
		if char_cost > remaining_cost:
			slot.button_action.disabled = true
			slot.button_action.modulate = Color.DARK_GRAY
		
		# ボタンが押されたらIDを添えてシグナルを発行
		slot.button_action.pressed.connect(func(): 
			character_selected.emit(id)
			queue_free()
		)

func _on_cancel_button_pressed():
	cancelled.emit()
	queue_free()
