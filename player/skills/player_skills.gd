extends Node2D
## 主角的主动技能(挂在 Player 下作为子节点,不动玩家主脚本):
##   U = 回复:立刻恢复 80% 血量
##   I = 混沌爆炎:2 秒内朝面向散射 20 发火焰弹,每发 80 伤害
## 能不能按取决于 PlayerStats 里的「解锁 + 装配」状态。

const FIREBALL := preload("res://player/skills/chaos_fireball.tscn")

const HEAL_PERCENT := 0.8
const HEAL_COOLDOWN := 25.0
const BLAZE_DAMAGE := 80
const BLAZE_SHOTS := 20
const BLAZE_DURATION := 2.0
const BLAZE_COOLDOWN := 30.0
## 散射角度:以面向为中心左右各摊开这么多弧度
const BLAZE_SPREAD := 0.5
## 每发再随机抖一点角度
const BLAZE_JITTER := 0.06

var _heal_cd := 0.0
var _blaze_cd := 0.0
var _blazing := false


func _physics_process(delta: float) -> void:
	_heal_cd = maxf(0.0, _heal_cd - delta)
	_blaze_cd = maxf(0.0, _blaze_cd - delta)
	var player := get_parent() as Node2D
	if player == null:
		return
	if bool(player.get("_won")) or bool(player.get("_walk_in_active")):
		return
	if int(player.get("health")) <= 0:
		return
	if Input.is_action_just_pressed("skill_1"):
		_cast_slot(0, player)
	if Input.is_action_just_pressed("skill_2"):
		_cast_slot(1, player)


## 释放某个框(0 = 框一 / U,1 = 框二 / I)里装的技能。
func _cast_slot(index: int, player: Node2D) -> void:
	var key := PlayerStats.slot_skill(index)
	if key == "":
		return
	match key:
		"heal":
			_cast_heal(player)
		"blaze":
			_cast_blaze(player)
		_:
			pass


# ---------------------------------------------------------------- 回复(U)

## 立刻回复 80% 血量;血量满了就不浪费冷却。
func _cast_heal(player: Node2D) -> void:
	if _heal_cd > 0.0:
		return
	var max_hp := int(player.get("max_health"))
	var hp := int(player.get("health"))
	if hp >= max_hp:
		return
	_heal_cd = HEAL_COOLDOWN
	var amount := int(round(float(max_hp) * HEAL_PERCENT))
	var target := mini(max_hp, hp + amount)
	player.set("health", target)
	player.emit_signal("health_changed", target, max_hp)
	_pop_text(player.global_position + Vector2(0.0, -118.0),
		"+%d HP" % (target - hp), Color(0.55, 1.0, 0.72), 26)


# ---------------------------------------------------------------- 混沌爆炎(I)

## 2 秒内朝面向散射 20 发火焰弹。
func _cast_blaze(player: Node2D) -> void:
	if _blaze_cd > 0.0 or _blazing:
		return
	var host := player.get_parent()
	if host == null:
		return
	_blaze_cd = BLAZE_COOLDOWN
	_blazing = true
	var facing := 1.0 if float(player.get("_facing")) >= 0.0 else -1.0
	var gap := BLAZE_DURATION / float(BLAZE_SHOTS)
	for i in BLAZE_SHOTS:
		if not is_inside_tree() or not is_instance_valid(player):
			break
		var t := float(i) / float(maxi(1, BLAZE_SHOTS - 1))
		var angle := lerpf(-BLAZE_SPREAD * 0.5, BLAZE_SPREAD * 0.5, t) \
			+ randf_range(-BLAZE_JITTER, BLAZE_JITTER)
		var dir := Vector2(facing, 0.0).rotated(angle)
		var ball := FIREBALL.instantiate()
		host.add_child(ball)
		ball.global_position = player.global_position + Vector2(facing * 34.0, -58.0)
		ball.call("setup", dir, BLAZE_DAMAGE)
		await get_tree().create_timer(gap).timeout
	_blazing = false


# ---------------------------------------------------------------- 飘字

func _pop_text(pos: Vector2, text: String, color: Color, size: int) -> void:
	var host := get_tree().current_scene
	if host == null:
		host = get_parent()
	if host == null:
		return
	var label := Label.new()
	label.text = text
	label.z_index = 30
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("outline_size", 6)
	host.add_child(label)
	label.global_position = pos
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(label, "global_position:y", pos.y - 54.0, 0.9)
	tw.tween_property(label, "modulate:a", 0.0, 0.5).set_delay(0.4)
	tw.chain().tween_callback(label.queue_free)
