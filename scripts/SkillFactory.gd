# SkillFactory.gd
class_name SkillFactory

# コモン用：低級スキル
const SKILLS_C = {
	"NONE": { "name": "なし", "cost": 0, "text": "" },
	"ENHANCE": { "name": "エンハンス", "cost": 4, "text": "自身の戦闘力が5増加する。" },
	"FRONT_MARCH": { "name": "進撃の号令", "cost": 5, "text": "味方前列の戦闘力を3増加させる。" },
	"MAGIC_BOLT": { "name": "マジックボルト", "cost": 5, "text": "敵一人に魔力ダメージを与える。" },
	"WEAKNESS": { "name": "ウィークネス", "cost": 5, "text": "戦闘力を4弱体化させる。" },
	"LIGHT_HEAL": { "name": "ライトヒール", "cost": 2, "text": "味方一人のHPを50%回復する。" },
}

# アンコモン以上用：全スキル（必要に応じてレアリティごとに細分化も可能）
const SKILLS_UC = {
	"NONE": { "name": "なし", "cost": 0, "text": "" },
	# --- 自己強化・特殊 ---
	"OVER_BOOST": { "name": "オーバーブースト", "cost": 6, "text": "自身の戦闘力が10増加する。" },
	"IRON_WILL": { "name": "不動の境地", "cost": 2, "text": "自身の戦闘力が3増加する（効果時間：長）。" },
	"SAGE_CHEST": { "name": "賢者の鼓舞", "cost": 4, "text": "自身の戦闘力が4、魔力が5増加する。" },
	"LIFE_ENERGY": { "name": "活命の気", "cost": 3, "text": "自身の戦闘力が3増加し、HPを50%回復する。" },
	"CELESTIAL_FAVOR": { "name": "天恵の福音", "cost": 4, "text": "自身の戦闘力が3増加し、HPを30%超過回復する。" },
	"DIVINE_PROTECTION": { "name": "アテナの加護", "cost": 4, "text": "自身の戦闘力が3増加し、加護ボーナスを1つ得る。" },
	"QUICK_STANCE": { "name": "神速の構え", "cost": 4, "text": "自身の戦闘力が3増加し、先制ボーナスを1つ得る。" },
	"THORN_SHIELD": { "name": "荊棘の盾", "cost": 4, "text": "自身の戦闘力が3増加し、反撃ボーナスを1つ得る。" },
	"UNDYING_SOUL": { "name": "不屈の魂", "cost": 4, "text": "自身の戦闘力が3増加し、復活ボーナスを1つ得る。" },
	"LIFE_SURGE": { "name": "生命の奔流", "cost": 4, "text": "自身の戦闘力が3増加し、再生ボーナスを1つ得る。" },
	"COUNTER_ATTACK": { "name": "反転攻勢", "cost": 4, "text": "自身の戦闘力が3増加する。デバフがある場合、解除してさら戦闘力を4増加させる。" },
	"BERSERK": { "name": "狂戦士", "cost": 4, "text": "自身の戦闘力が10増加する。発動時にHPの50%を失う。" },
	"LAST_STAND": { "name": "玉砕", "cost": 4, "text": "自身の戦闘力が10増加する。効果終了時にHPを全て失う。" },
	"MANA_REMNANT": { "name": "魔力の残滓", "cost": 3, "text": "自身の戦闘力が3増加する。効果終了時にマナを1得る。" },
	"DESPERATE_LINE": { "name": "背水の陣", "cost": 4, "text": "自身の戦闘力が3増加する。HP50%以下なら追加で戦闘力が5増加する。" },
	"PERFECT_STANCE": { "name": "盤石の構え", "cost": 4, "text": "自身の戦闘力が3増加する。HP80%以上なら追加で戦闘力が4増加する。" },

	# --- 味方前列支援 ---
	"FRONT_TRIUMPH": { "name": "凱歌の鬨", "cost": 6, "text": "味方前列の戦闘力を5増加させる。" },
	"FRONT_FORTRESS": { "name": "不退転の陣", "cost": 6, "text": "味方前列の戦闘力を3増加させる（効果時間：長）。" },
	"FRONT_TACTICS": { "name": "戦術詠唱", "cost": 6, "text": "味方前列の戦闘力を4、魔力を5増加させる。" },
	"FRONT_RELIEF": { "name": "救護の陣", "cost": 5, "text": "味方前列の戦闘力を3増加させ、HPを50%回復させる。" },
	"FRONT_SANCTUARY": { "name": "聖域の守り", "cost": 6, "text": "味方前列の戦闘力を3増加させ、HPを30%超過回復させる。" },
	"FRONT_VEIL": { "name": "神の帳", "cost": 5, "text": "味方前列の戦闘力を3増加させ、加護ボーナスを1つ得る。" },
	"FRONT_HASTE": { "name": "疾風の陣形", "cost": 5, "text": "味方前列の戦闘力を3増加させ、先制ボーナスを1つ得る。" },
	"FRONT_RETALIATE": { "name": "報復の壁", "cost": 5, "text": "味方前列の戦闘力を3増加させ、反撃ボーナスを1つ得る。" },
	"FRONT_PHOENIX": { "name": "不死鳥の加護", "cost": 5, "text": "味方前列の戦闘力を3増加させ、復活ボーナスを1つ得る。" },
	"FRONT_RIPPLE": { "name": "祈りの波紋", "cost": 5, "text": "味方前列の戦闘力を3増加させ、再生ボーナスを1つ得る。" },
	"FRONT_PURGE": { "name": "軍勢の浄化", "cost": 5, "text": "味方前列の戦闘力を3増加させる。デバフを解除し追加で戦闘力が4増加する。" },
	"FRONT_SACRIFICE": { "name": "捨身の突撃", "cost": 6, "text": "味方前列の戦闘力を10増加させる。発動時にHPの50%を失う。" },
	"FRONT_REST": { "name": "戦士の休息", "cost": 5, "text": "味方前列の戦闘力を3増加させる。終了時にマナを1ずつ得る。" },
	"FRONT_RAT_BITE": { "name": "窮鼠の牙", "cost": 6, "text": "味方前列の戦闘力を3増加させる。HP50%以下なら追加で5増加する。" },
	"FRONT_LION_PRIDE": { "name": "獅子の威風", "cost": 6, "text": "味方前列の戦闘力を3増加させる。HP80%以上なら追加で4増加する。" },

	# --- 魔力攻撃 ---
	"GRAVITY_PRESS": { "name": "グラビティプレス", "cost": 5, "text": "敵一員に魔力ダメージを与える（HPの30%ダメージ保証）。" },
	"MIND_BREAK": { "name": "マインドブレイク", "cost": 5, "text": "敵一員に魔力ダメージを与え、魔力を5低下させる。" },
	"ABSOLUTE_ZERO": { "name": "アブソリュート・ゼロ", "cost": 5, "text": "敵一員に魔力ダメージを与え、そのターンの行動権を失わせる。" },
	"FORCE_QUAKE": { "name": "フォースクエイク", "cost": 6, "text": "敵前列に魔力ダメージを与える（HPの30%ダメージ保証）。" },
	"SILENCE_FIELD": { "name": "サイレンス・フィールド", "cost": 6, "text": "敵前列に魔力ダメージを与え、魔力を5低下させる。" },
	"COLD_PRISON": { "name": "コールドプリズン", "cost": 6, "text": "敵前列に魔力ダメージを与え、そのターンの行動権を失わせる。" },
	"CATASTROPHE": { "name": "カタストロフ", "cost": 7, "text": "敵全体に魔力ダメージを与える（HPの30%ダメージ保証）。" },
	"MANA_DRAIN": { "name": "マナ・ドレイン", "cost": 7, "text": "敵全体に魔力ダメージを与え、魔力を5低下させる。" },
	"TIME_FREEZE": { "name": "タイム・フリーズ", "cost": 7, "text": "敵全体に魔力ダメージを与え、そのターンの行動権を失わせる。" },
	"TRIDENT_SHOT": { "name": "トライデント・ショット", "cost": 6, "text": "戦闘力が高い敵3人に魔力ダメージを与える。" },
	"LUMINOUS_PURGE": { "name": "ルミナスパージ", "cost": 6, "text": "HP50%以上の敵全員に魔力ダメージを与える。" },
	"JUDGE_INT": { "name": "知の裁定", "cost": 6, "text": "自分より魔力の低い敵全員に魔力ダメージを与える。" },
	"CHASE_LIGHT": { "name": "チェイスライト", "cost": 6, "text": "自分より後に行動する敵全員に魔力ダメージを与える。" },
	"THUNDER_AMBUSH": { "name": "迎撃の雷光", "cost": 6, "text": "そのターン攻撃に参加している敵全員に魔力ダメージを与える。" },
	"WEAKNESS_SHOT": { "name": "ウィークネス", "cost": 5, "text": "敵一人に魔力ダメージを与え、戦闘力を5弱体化させる。" },
	"CURSE_CHAIN": { "name": "呪縛の連鎖", "cost": 5, "text": "敵一人に魔力ダメージを与え、バフを解除する。" },

	# --- 弱体化・妨害・回復・解除 ---
	"SLOW": { "name": "スロウ", "cost": 4, "text": "敵一人の戦闘力を5弱体化させる。" },
	"CURSE": { "name": "カース", "cost": 5, "text": "敵一人の戦闘力を10弱体化させる。" },
	"REGENERATE": { "name": "リジェネレート", "cost": 3, "text": "自身のHPを50%回復する。" },
	"SAINT_DOMAIN": { "name": "聖者の領域", "cost": 4, "text": "味方前列のデバフを解除する。" }
}

# IDからスキルデータを取得する（全テーブルを検索）
static func get_skill_data(skill_id: String) -> Dictionary:
	if SKILLS_C.has(skill_id):
		return SKILLS_C[skill_id]
	if SKILLS_UC.has(skill_id):
		return SKILLS_UC[skill_id]
	return SKILLS_C["NONE"]

## レアリティ値（int）に基づいてランダムにIDを返す
## 0:C, 1:UC, 2:R, 3:SR
static func get_random_skill_id(rarity_idx: int) -> String:
	var target_table: Dictionary
	
	match rarity_idx:
		0: # Common
			target_table = SKILLS_C
		1, 2, 3: # UC, R, SR (現在は共通でUCテーブルを参照)
			target_table = SKILLS_UC
		_:
			target_table = SKILLS_C
	
	var ids = target_table.keys()
	
	# C(0)の場合は「なし(NONE)」を含めて抽選
	# UC(1)以上の場合は「なし」を除外して必ずスキルを付与する設計例
	if rarity_idx >= 1:
		var skill_ids = []
		for id in ids:
			if id != "NONE":
				skill_ids.append(id)
		return skill_ids[randi() % skill_ids.size()]
	
	return ids[randi() % ids.size()]
