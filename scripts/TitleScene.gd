# TitleScene.gd
extends Control

@onready var continue_button = $VBoxContainer/ContinueButton
@onready var name_panel = $NameRegistrationPanel
@onready var name_input = $NameRegistrationPanel/VBoxContainer/NameLineEdit

const SAVE_PATH = "user://save_data.json"

func _ready():
	# 起動時にセーブファイルの有無を確認
	if FileAccess.file_exists(SAVE_PATH):
		continue_button.disabled = false
		continue_button.text = "CONTINUE"
	else:
		# ファイルがなければCONTINUEを押せなくする
		continue_button.disabled = true
		continue_button.text = "---"

# 1. NEW GAMEボタンが押されたらパネルを出す
func _on_new_game_button_pressed():
	name_panel.show()
	name_input.grab_focus() # すぐに入力できる状態にする

# 2. キャンセルが押されたら閉じる
func _on_cancel_button_pressed():
	name_panel.hide()

# 3. 決定ボタンが押されたら通信開始！
func _on_confirm_button_pressed():
	var player_name = name_input.text.strip_edges()
	
	if player_name == "":
		print("名前を入力してください")
		return
		
	# ① Factoryで純粋なデータを作成
	var new_data = PlayerFactory.create_initial_data(player_name)
	
	# ② Global（ワークメモリ）に同期
	Global.sync_player_data(new_data)
	
	name_panel.hide()
	get_tree().change_scene_to_file("res://scenes/MainMap.tscn")

func _on_continue_button_pressed() -> void:
	NetworkManager.load_existing_game()
