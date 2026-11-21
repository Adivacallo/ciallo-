extends Node2D
## 全黑房间:纯黑背景与看不见的地面,主角站在黑暗里。

const ROOM_SIZE := Vector2(1152, 648)
const NEXT_SCENE := "res://levels/white_room.tscn"
const EXIT_X := 1050.0
## 黑场里鲸鱼娘的一句通讯。
const COMMS_TEXT := "[center][color=#8fe9ff]鲸鱼娘[/color]：程序猿他来救场了，赶紧在前面把核心数据交给他[/center]"

@onready var _player: Node2D = $Player

var _fade: ColorRect
var _leaving := false


func _ready() -> void:
	_setup_camera()
	_fade = get_node_or_null("Fade/Rect") as ColorRect
	if _fade == null:
		_fade = _make_fade()
	_fade.color = Color(0, 0, 0, 1)
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 0.0, 0.9)
	_show_comms.call_deferred()


## 在纯黑里浮出一句通讯字幕,不挡移动。
func _show_comms() -> void:
	await get_tree().create_timer(1.1).timeout
	var layer := CanvasLayer.new()
	layer.name = "Comms"
	layer.layer = 20
	add_child(layer)
	var font := SystemFont.new()
	font.font_names = PackedStringArray([
		"Microsoft YaHei UI", "Microsoft YaHei", "Source Han Sans SC",
		"Noto Sans CJK SC", "PingFang SC", "SimHei",
	])
	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	label.text = COMMS_TEXT
	label.fit_content = true
	label.scroll_active = false
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("normal_font", font)
	label.add_theme_font_size_override("normal_font_size", 22)
	label.add_theme_color_override("default_color", Color(0.92, 0.96, 1, 1))
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("outline_size", 6)
	label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	label.offset_top = -118.0
	label.offset_bottom = -54.0
	label.modulate.a = 0.0
	layer.add_child(label)
	var tw := create_tween()
	tw.tween_property(label, "modulate:a", 1.0, 0.5)
	tw.tween_interval(4.5)
	tw.tween_property(label, "modulate:a", 0.0, 0.6)
	tw.tween_callback(layer.queue_free)


func _setup_camera() -> void:
	var cam := _player.get_node_or_null("Camera2D") as Camera2D
	if cam == null:
		return
	cam.limit_left = 0
	cam.limit_top = 16
	cam.limit_right = int(ROOM_SIZE.x)
	cam.limit_bottom = 16 + int(ROOM_SIZE.y)


## 走到房间最右侧就进入下一个(全白)房间。
func _process(_delta: float) -> void:
	if _leaving or _player == null:
		return
	if _player.global_position.x > EXIT_X:
		_go_next()


func _go_next() -> void:
	if _leaving:
		return
	_leaving = true
	if _fade != null:
		var tw := create_tween()
		tw.tween_property(_fade, "color:a", 1.0, 0.6)
		await tw.finished
	get_tree().change_scene_to_file(NEXT_SCENE)


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
