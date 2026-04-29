# MessageManager.gd
extends Node

enum MsgState { READING, WAIT_TAP, IDLE }
var current_state = MsgState.IDLE
var _current_tween: Tween

# 現在のシーンで使用するUIを保持する変数
var _current_label: Control
var _current_guide: Control

# 1. 最初にUIを覚えさせる関数
func setup_ui(label: Control, guide: Control = null):
	_current_label = label
	_current_guide = guide

# 2. 引数を大幅に減らした表示関数
func display_text(txt: String, use_guide: bool = true) -> void:
	var speed = 0.05
	
	if _current_tween:
		_current_tween.kill()
	
	# --- 修正ポイント ---
	# 引数の設定に関わらず、保持しているガイドがあれば「まず隠す」
	if _current_guide:
		_current_guide.hide()
	
	current_state = MsgState.READING
	
	# テキスト設定処理
	if _current_label is RichTextLabel or _current_label is Label:
		_current_label.text = txt
		_current_label.visible_ratio = 0
	
	var duration = txt.length() * speed
	var tween = _current_label.create_tween()
	tween.tween_property(_current_label, "visible_ratio", 1.0, duration)
	
	await tween.finished
	current_state = MsgState.WAIT_TAP
	
	# --- 修正ポイント ---
	# 表示が終わった後、「今回ガイドを表示する設定」の場合のみ表示する
	if use_guide and _current_guide:
		_current_guide.show()
		start_next_animation(_current_guide)

func start_next_animation(target: CanvasItem):
	if _current_tween:
		_current_tween.kill()
	
	_current_tween = target.create_tween().set_loops()
	target.modulate.a = 1.0
	_current_tween.tween_property(target, "modulate:a", 0.3, 0.6).set_trans(Tween.TRANS_SINE)
	_current_tween.tween_property(target, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_SINE)
