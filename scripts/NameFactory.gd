class_name NameFactory
extends Node

# パターン①用
const NOUNS = [
	"デーモン", "ストーム", "スター", "ドラゴン", "シャドウ", "ブレード", 
	"ソウル", "カオス", "フレイム", "アビス", "アイアン", "ルーン", 
	"ブラッド", "ウィンド", "サンダー", "ナイト", "ヴォイド", "アース", 
	"ミスト", "シルバー"
]
const VERBS = [
	"スレイヤー", "ライダー", "シーカー", "ブレイカー", "ウォーカー", "メーカー", 
	"テイマー", "バスター", "イーター", "ブリンガー", "チェイサー", "キラー", 
	"ガード", "マスター", "リーパー", "ウェイカー", "ストライカー", "ハウンド", 
	"クラッシャー", "ダンサー"
]

# パターン②・③用
const TITLES_PREFIX = [
	"英雄", "破壊王", "竜人", "騎士", "賢者", "守護者", 
	"聖女", "覇王", "亡霊", "魔導士", "処刑人", "放浪者", 
	"神官", "狂戦士", "暗殺者", "預言者", "重装騎士", "辺境伯", 
	"超越者", "道化師"
]
const PROPER_NAMES = [
	"ペルセウス", "グリズワルド", "ミルキウス", "アーサー", "ベオウルフ", 
	"ジークフリート", "バルバロッサ", "イシュタル", "ギルガメッシュ", "ラグナ", 
	"オディール", "カサンドラ", "フェンリル", "ゼノビア", "イカロス", "ガウェイン", 
	"リリス", "ソロモン", "ヴァルキリー", "モルガナ"
]
const TITLES_SUFFIX = [
	"博士", "将軍", "兵長", "王", "卿", "導師", 
	"総督", "大公", "隠者", "監獄長", "司教", "教皇", 
	"隊長", "殿下", "執事", "執行官", "語り部", "管理人", 
	"審判官", "観測者"
]

# パターン④用
const ADJECTIVES = [
	"鋼の", "空を駆ける", "白い手の", "虚無を呼ぶ", "黄金の", "静寂なる", 
	"血に飢えた", "奈落へ誘う", "不滅の", "孤独な", "雷鳴を纏う", "暁の", 
	"昏き", "星を砕く", "名もなき", "燃え盛る", "深淵を知る", "残酷な", 
	"揺るぎなき", "運命を呪う"
]

## ランダムに名前を生成して返します
static func generate_name() -> String:
	var pattern_index = randi() % 4
	var result = ""

	match pattern_index:
		0: # パターン①：名詞 ＋ 動詞
			result = _get_rand(NOUNS) + _get_rand(VERBS)
		
		1: # パターン②：冠詞（称号） ＋ 固有名詞
			result = _get_rand(TITLES_PREFIX) + _get_rand(PROPER_NAMES)
			
		2: # パターン③：固有名詞 ＋ 称号
			result = _get_rand(PROPER_NAMES) + _get_rand(TITLES_SUFFIX)
			
		3: # パターン④：形容詞 ＋ 名詞/固有名詞
			var target = _get_rand(NOUNS) if randi() % 2 == 0 else _get_rand(PROPER_NAMES)
			result = _get_rand(ADJECTIVES) + target

	return result

## 配列からランダムに1つ要素を取得するヘルパー関数
static func _get_rand(list: Array) -> String:
	if list.is_empty():
		return ""
	return list[randi() % list.size()]
