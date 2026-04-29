# MessageManager.gd
extends Node

enum MsgState { READING, WAIT_TAP, IDLE }
var current_state = MsgState.IDLE

# アニメーションを保持する変数（新しいアニメが始まったら古い方を止めるため）
var _current_tween: Tween

func display_text(label: Control, txt: String, speed: float = 0.05) -> void:
	# 以前のアニメーション（点滅など）が動いていたら止める
	if _current_tween:
		_current_tween.kill()
	
	current_state = MsgState.READING
	
	# テキスト設定
	if label is RichTextLabel or label is Label:
		label.text = txt
	
	label.visible_ratio = 0
	
	var duration = txt.length() * speed
	var tween = label.create_tween()
	tween.tween_property(label, "visible_ratio", 1.0, duration)
	
	await tween.finished
	current_state = MsgState.WAIT_TAP

# NEXTガイド（矢印など）を点滅させる共通関数
func start_next_animation(target: CanvasItem):
	# 既存のアニメがあれば止める
	if _current_tween:
		_current_tween.kill()
		
	_current_tween = target.create_tween().set_loops()
	
	target.modulate.a = 1.0
	_current_tween.tween_property(target, "modulate:a", 0.3, 0.6).set_trans(Tween.TRANS_SINE)
	_current_tween.tween_property(target, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_SINE)
