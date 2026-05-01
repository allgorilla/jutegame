extends CanvasLayer
signal closed

const RARITY_PATHS = [
	"res://assets/image/rare_c.png",  # 0: C (Common)
	"res://assets/image/rare_uc.png", # 1: UC (Uncommon)
	"res://assets/image/rare_r.png",  # 2: R (Rare)
	"res://assets/image/rare_sr.png"  # 3: SR (Super Rare)
]

# --- ノード参照 ---
@onready var main_content = $MainContent
@onready var name_label = $MainContent/NameLabel
@onready var cost_label = $MainContent/StatusContainer/CostContainer/CostValue
@onready var power_label = $MainContent/StatusContainer/PowerContainer/PowerValue
@onready var magic_label = $MainContent/StatusContainer/MagicContainer/MagicValue
@onready var rarity_icon = $MainContent/Rarity
@onready var skill_name_label = $MainContent/SkillContainer/SkillName
@onready var skill_text_label = $MainContent/SkillContainer/SkillText

# --- データ保持用 ---
var _temp_data: Dictionary = {}

func _ready():
	# 背景ボタンの接続
	$BackgroundButton.pressed.connect(_on_close_requested)

	# データの反映（_ready のタイミングで UI に流し込む）
	if not _temp_data.is_empty():
		_update_ui(_temp_data)

	# アニメーション処理
	main_content.scale = Vector2.ZERO
	var tween = create_tween()
	tween.tween_property(main_content, "scale", Vector2.ONE, 0.4)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)

func _on_close_requested():
	closed.emit()
	queue_free()

## 外部から呼ばれるデータ設定用関数
func set_data(data: Dictionary):
	_temp_data = data
	# すでに準備ができている（再設定などの）場合は即座に反映
	if is_inside_tree():
		_update_ui(data)

## 実際にUIを更新する内部関数
func _update_ui(data: Dictionary):
	name_label.text = data.get("name", "Unknown")
	cost_label.text = str(data.get("cost", 0))

	power_label.text = "%3d" % data.get("power", 0)
	magic_label.text = "%3d" % data.get("magic", 0)

	# (あらかじめ用意したレアリティ画像リストから、data.rarity をキーに取得)
	var r_idx = data.get("rarity", 0)
	rarity_icon.texture = load(RARITY_PATHS[r_idx])

	var s_id = data.get("skill_id", "NONE")
	var skill = SkillFactory.get_skill_data(s_id)
	skill_name_label.text = "[%d] %s" % [skill.cost, skill.name]
	skill_text_label.text = skill.text
