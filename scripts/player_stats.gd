extends Node
## 主角的成长数值:变强界面买到的强化都记在这里(自动加载,跨关卡保留)。
## 四条强化线:攻击伤害 / 血量上限 / 无敌时间 / 弹反范围,
## 都是 4 级、价格 24 / 48 / 96 / 192,越买越强。

signal changed

## 每条线:每级倍率、等级上限、逐级价格。
const UPGRADES := {
	"attack": {"step": 1.5, "max": 4, "costs": [24, 48, 96, 192]},
	"health": {"step": 1.5, "max": 4, "costs": [24, 48, 96, 192]},
	"invuln": {"step": 1.3, "max": 4, "costs": [24, 48, 96, 192]},
	"parry": {"step": 1.3, "max": 4, "costs": [24, 48, 96, 192]},
}

## 每条线已买的等级
var levels := {"attack": 0, "health": 0, "invuln": 0, "parry": 0}


func has_upgrade(key: String) -> bool:
	return UPGRADES.has(key)


func level_of(key: String) -> int:
	return int(levels.get(key, 0))


func max_level_of(key: String) -> int:
	return int((UPGRADES.get(key, {}) as Dictionary).get("max", 0))


func step_of(key: String) -> float:
	return float((UPGRADES.get(key, {}) as Dictionary).get("step", 1.0))


## 当前倍率(1.0 = 未强化),按等级乘法叠加。
func multiplier(key: String) -> float:
	return pow(step_of(key), float(level_of(key)))


## 下一级价格;满级返回 -1。
func next_cost(key: String) -> int:
	var cfg: Dictionary = UPGRADES.get(key, {})
	if cfg.is_empty():
		return -1
	var level := level_of(key)
	var costs: Array = cfg.get("costs", [])
	if level >= int(cfg.get("max", 0)) or level >= costs.size():
		return -1
	return int(costs[level])


## 花 token 买一级;token 不够或已满级返回 false。
func buy(key: String) -> bool:
	var cost := next_cost(key)
	if cost < 0:
		return false
	var tokens := get_node_or_null("/root/Tokens")
	if tokens == null or int(tokens.get("total")) < cost:
		return false
	tokens.call("add", -cost)
	levels[key] = level_of(key) + 1
	changed.emit()
	return true


# ---------------------------------------------------------------- 各条线的倍率

## 主角攻击伤害(拳脚 / 飞刀 / 手雷 / 反弹子弹都走这里)
func hit(base_damage: int) -> int:
	var scale := multiplier("attack")
	if scale == 1.0:
		return base_damage
	return maxi(1, int(round(float(base_damage) * scale)))


## 血量上限倍率
func health_scale() -> float:
	return multiplier("health")


## 受伤后无敌时长倍率
func invuln_scale() -> float:
	return multiplier("invuln")


## 弹反半径倍率
func parry_scale() -> float:
	return multiplier("parry")


## 清空成长(重新开档时用)。
func reset() -> void:
	for key in levels.keys():
		levels[key] = 0
	changed.emit()
