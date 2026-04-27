# IconButton.gd
extends TextureButton

# エディタから個別に調整できるように変数化しておく
@export var click_offset := Vector2(2, 2)
@export var hover_modulate := Color(1.2, 1.2, 1.2)

func _ready():
	# 自身（self）のシグナルに自分自身を接続する
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_button_down():
	position += click_offset

func _on_button_up():
	position -= click_offset

func _on_mouse_entered():
	self_modulate = hover_modulate

func _on_mouse_exited():
	self_modulate = Color(1, 1, 1)
