class_name BattleCalc
extends Node

# 戦闘力の差に基づくダメージ率テーブル 
const DAMAGE_TABLE = [
	120, 110, 100, 91, 82, 74, 66, 59, 52, 46,  # 差 20 ～ 11
	40, 35, 30, 26, 22, 19, 16, 14, 12, 11,     # 差 10 ～ 01
	10,                                         # 差 00
	9, 8, 7, 6, 5, 4, 3, 2, 1, 1                # 差 -01 ～ -10
]

## 通常攻撃の最終ダメージを計算する
static func get_attack_damage(power_diff: int, is_defending: bool = false, extra_dmg_bonus: int = 0) -> int:
	# 1. テーブルから基本ダメージ率を取得 
	var table_index = 20 - power_diff
	table_index = clampi(table_index, 0, DAMAGE_TABLE.size() - 1)
	var damage = float(DAMAGE_TABLE[table_index])
	
	# 2. 格上ボーナス補正（自分より戦闘力が高い敵への追加ダメージ） 
	# ※ power_diffがマイナス（敵の方が強い）の場合のみ適用
	if power_diff < 0:
		damage += extra_dmg_bonus * 5.0 # 1つにつき5%加算 
	
	# 3. 防御状態の補正（ダメージ50%） 
	if is_defending:
		damage *= 0.5
		
	return int(round(damage))
