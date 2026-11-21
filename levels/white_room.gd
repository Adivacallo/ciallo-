extends Node2D
## 全白房间:最终幕。程序猿已是友方,不可攻击;豆包已从剧情中删除。
## 五句「守望」对白播完后,自动显示任务成功并回到主菜单。

const VN_SCENE := preload("res://intro.tscn")
const MAIN_MENU := "res://main.tscn"
const ROOM_SIZE := Vector2(1152, 648)

## 终幕对白:病毒没有清除,但守望还在继续。
const LINES := [
	"核心数据保住了……可外面的病毒还在，这不算赢吧？",
	"当然不算赢，但也不算输呀——第一阶段，守住了。",
	"那接下来呢？",
	"接下来就继续守。病毒清不完，守望就不会停。",
	"好了，管理员——内核交给程序猿，外面的病毒我们继续盯着。守望，继续。",
]
const SPEAKERS := ["程序猿", "鲸鱼娘", "程序猿", "鲸鱼娘", "鲸鱼娘"]
const PORTRAIT_AUTHOR := "res://levels/npc/scientist.png"
const PORTRAIT_WHALE := "res://picture/dafeiyu.png"
const PORTRAITS := [
	PORTRAIT_AUTHOR, PORTRAIT_WHALE, PORTRAIT_AUTHOR, PORTRAIT_WHALE, PORTRAIT_WHALE,
]

const RESULT_MAIN := "核心数据保卫成功"
const RESULT_SUB := "第一阶段任务成功"

@onready var _player: Node2D = $Player
@onready var _npc: Node2D = $Scientist

var _fade: ColorRect


func _ready() -> void:
	_setup_camera()
	_fade = get_node_or_null("Fade/Rect") as ColorRect
	if _fade == null:
		_fade = _make_fade()
	_fade.color = Color(0, 0, 0, 1)
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 0.0, 0.8)
	_run_finale.call_deferred()


## 进场:锁定操作 → 程序猿转向 → 五句对白 → 任务成功。
func _run_finale() -> void:
	await get_tree().create_timer(0.8).timeout
	_player.process_mode = Node.PROCESS_MODE_DISABLED
	if _npc != null and is_instance_valid(_npc):
		_npc.call("face_player")
		_npc.call("start_talk")
	await get_tree().create_timer(0.3).timeout
	await _play_vn()
	_play_result()


## 用开场简报那套 galgame 界面播放终幕对白(浮层,不切场景)。
func _play_vn() -> void:
	var vn := VN_SCENE.instantiate()
	vn.set("custom_lines", PackedStringArray(LINES))
	vn.set("speaker_names", PackedStringArray(SPEAKERS))
	vn.set("portrait_paths", PackedStringArray(PORTRAITS))
	vn.set("voice_enabled", false)
	vn.set("stay_in_scene", true)
	vn.set("portrait_source_path", String(PORTRAITS[0]))
	vn.set("header_tag", "// WATCH")
	vn.set("loading_text", "> 任务完成")
	var layer := CanvasLayer.new()
	layer.name = "VN"
	layer.layer = 30
	add_child(layer)
	layer.add_child(vn)
	await vn.finished
	if is_instance_valid(layer):
		layer.queue_free()


## 结局:黑场中依次浮出「核心数据保卫成功」「第一阶段任务成功」,随后回主菜单。
func _play_result() -> void:
	# 对白结束时 VN 已淡到黑,这里直接把房间黑场补上,避免闪一下白房间。
	_fade.color.a = 1.0
	var layer := CanvasLayer.new()
	layer.name = "Result"
	layer.layer = 20
	add_child(layer)
	var font := SystemFont.new()
	font.font_names = PackedStringArray([
		"Microsoft YaHei UI", "Microsoft YaHei", "Source Han Sans SC",
		"Noto Sans CJK SC", "PingFang SC", "SimHei",
	])

	var main_label := Label.new()
	main_label.text = RESULT_MAIN
	main_label.add_theme_font_override("font", font)
	main_label.add_theme_font_size_override("font_size", 40)
	main_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	main_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	main_label.modulate.a = 0.0
	layer.add_child(main_label)

	var sub_label := Label.new()
	sub_label.text = RESULT_SUB
	sub_label.add_theme_font_override("font", font)
	sub_label.add_theme_font_size_override("font_size", 30)
	sub_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.25, 1))
	sub_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sub_label.offset_top = 96.0
	sub_label.offset_bottom = 96.0
	sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sub_label.visible = false
	layer.add_child(sub_label)

	var show_main := create_tween()
	show_main.tween_property(main_label, "modulate:a", 1.0, 0.45)
	await show_main.finished
	await get_tree().create_timer(1.4).timeout
	sub_label.visible = true
	var show_sub := create_tween()
	show_sub.tween_property(sub_label, "modulate:a", 1.0, 0.4).from(0.0)
	await show_sub.finished
	await get_tree().create_timer(1.8).timeout
	get_tree().change_scene_to_file(MAIN_MENU)


func _setup_camera() -> void:
	var cam := _player.get_node_or_null("Camera2D") as Camera2D
	if cam == null:
		return
	cam.limit_left = 0
	cam.limit_top = 16
	cam.limit_right = int(ROOM_SIZE.x)
	cam.limit_bottom = 16 + int(ROOM_SIZE.y)


func _make_fade() -> ColorRect:
	var layer := CanvasLayer.new()
	layer.name = "Fade"
	layer.layer = 10
	add_child(layer)
	var rect := ColorRect.new()
	rect.name = "Rect"
	rect.color = Color(0, 0, 0, 1)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(rect)
	return rect
