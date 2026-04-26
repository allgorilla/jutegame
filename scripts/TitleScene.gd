# TitleScene.gd
extends Control

@onready var continue_button = $VBoxContainer/ContinueButton

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

func _on_new_game_button_pressed():
	# 本来はここで名前入力フォームを出しますが、まずはテスト用に固定名で
	var test_name = "勇者" + str(randi() % 100)
	NetworkManager.request_new_game(test_name)	


func _on_continue_button_pressed() -> void:
	NetworkManager.load_existing_game()
