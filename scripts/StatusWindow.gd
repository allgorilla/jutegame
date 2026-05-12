extends CanvasLayer
signal closed

# レアリティ画像のパス
const RARITY_PATHS = [
	"res://assets/image/rare_c.png",  # 0: C
	"res://assets/image/rare_uc.png", # 1: UC
	"res://assets/image/rare_r.png",  # 2: R
	"res://assets/image/rare_sr.png"  # 3: SR
]

# ボーナスアイコンのパス 
const BONUS_PATHS = [
	"res://assets/image/bonuses/v.png", # 0: HPボーナス
	"res://assets/image/bonuses/f.png", # 1: 先制ボーナス
	"res://assets/image/bonuses/c.png", # 2: 反撃ボーナス
	"res://assets/image/bonuses/p.png", # 3: 加護ボーナス
	"res://assets/image/bonuses/g.png", # 4: 格上ボーナス
	"res://assets/image/bonuses/r.png", # 5: 回復ボーナス
	"res://assets/image/bonuses/m.png", # 6: マナボーナス
	"res://assets/image/bonuses/a.png", # 7: 復讐ボーナス
]

# ボーナス名からインデックスへの変換用辞書
const BONUS_MAP = {
	"HPボーナス": 0, "先制ボーナス": 1, "反撃ボーナス": 2, "加護ボーナス": 3,
	"格上ボーナス": 4, "回復ボーナス": 5, "マナボーナス": 6, "復讐ボーナス": 7
}

# --- ノード参照 ---
@onready var main_content = $MainContent
@onready var name_label = $MainContent/NameLabel
@onready var cost_label = $MainContent/StatusContainer/CostContainer/CostValue
@onready var power_label = $MainContent/StatusContainer/PowerContainer/PowerValue
@onready var magic_label = $MainContent/StatusContainer/MagicContainer/MagicValue
@onready var rarity_icon = $MainContent/Rarity
@onready var skill_name_label = $MainContent/SkillContainer/SkillName
@onready var skill_text_label = $MainContent/SkillContainer/SkillText
@onready var character_image = $MainContent/Image

# ボーナスアイコン用（@onreadyのパスと変数の定義を修正） 
@onready var bonus_icons = [
	$MainContent/BonusContainer/Panel1/ColorRect,
	$MainContent/BonusContainer/Panel2/ColorRect,
	$MainContent/BonusContainer/Panel3/ColorRect
]

# --- データ保持用 ---
var _temp_data: Dictionary = {}

func _ready():
	$BackgroundButton.pressed.connect(_on_close_requested)

	if not _temp_data.is_empty():
		_update_ui(_temp_data)

	main_content.scale = Vector2.ZERO
	var tween = create_tween()
	tween.tween_property(main_content, "scale", Vector2.ONE, 0.4)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)

func _on_close_requested():
	closed.emit()
	queue_free()

func set_data(data: Dictionary):
	_temp_data = data
	if is_inside_tree():
		_update_ui(data)

## 実際にUIを更新する内部関数
func _update_ui(data: Dictionary):
	name_label.text = data.get("name", "Unknown")
	cost_label.text = str(int(data.get("cost", 0)))
	power_label.text = "%3d" % data.get("power", 0)
	magic_label.text = "%3d" % data.get("magic", 0)

	# --- キャラクター画像の表示処理 ---
	# image_idを取得（デフォルトは"01"）し、パスを組み立てて読み込む
	var img_id = data.get("image_id", "01")
	var img_path = "res://assets/image/units/%s.png" % img_id 
	
	# ファイルが存在するかチェックしてからロード（安全のため）
	if FileAccess.file_exists(img_path):
		character_image.texture = load(img_path)
	else:
		push_warning("画像ファイルが見つかりません: " + img_path)
	
	# レアリティの設定 
	var r_idx = data.get("rarity", 0)
	rarity_icon.texture = load(RARITY_PATHS[r_idx])

	# スキルの設定 
	var s_id = data.get("skill_id", "NONE")
	var skill = SkillFactory.get_skill_data(s_id)
	skill_name_label.text = "[%d] %s" % [skill.cost, skill.name]
	skill_text_label.text = skill.text

	# --- ボーナスアイコンの表示処理 ---
	var bonuses = data.get("bonuses", []) # 生成ロジックで追加した配列を取得
	
	# 全てのアイコンを一旦非表示、またはデフォルト状態にする
	for icon in bonus_icons:
		icon.get_parent().hide() # Panelごと隠す場合

	# 保持しているボーナスの数だけ表示
	for i in range(min(bonuses.size(), bonus_icons.size())):
		var b_name = bonuses[i]
		if BONUS_MAP.has(b_name):
			var b_idx = BONUS_MAP[b_name]
			bonus_icons[i].get_node("TextureRect").texture = load(BONUS_PATHS[b_idx])
			bonus_icons[i].get_parent().show()
			bonus_icons[i].visible = true
