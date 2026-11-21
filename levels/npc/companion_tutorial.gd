extends Node2D
## 鲸鱼娘第一次跟随时弹出的教学提示:交互可升级 / 更换技能。
## 点「确认」后不再出现(静态标记,跨场景重载也有效)。

const TIP_TEXT := "你可以通过与鲸鱼娘交互来升级和更换技能，让自己变强。"
const FONT_NAMES := [
	"Microsoft YaHei UI", "Microsoft YaHei", "Source Han Sans SC",
	"Noto Sans CJK SC", "PingFang SC", "SimHei",
]

## 点过确认后为 true。
static var _dismissed: bool = false

var _companion: Node
var _was_following := false
var _visible := false
var _layer: CanvasLayer


func _ready() -> void:
	# 菜单打开时游戏会暂停,这里也要继续跑才能自动收掉提示。
	process_mode = Node.PROCESS_MODE_ALWAYS
	_companion = get_parent()
	if _companion != null and _companion.has_method("is_following"):
		_was_following = bool(_companion.call("is_following"))
	set_process(not _dismissed)


func _process(_delta: float) -> void:
	if _dismissed or _companion == null or not is_instance_valid(_companion):
		return
	# 提示显示期间:F 打开交互菜单就自动关掉。
	if _visible:
		if _menu_is_open():
			_dismiss()
		return
	if not _companion.has_method("is_following"):
		return
	var following := bool(_companion.call("is_following"))
	if following and not _was_following:
		_show_tip()
	_was_following = following


## 交互菜单是同伴的直接子节点,打开时 is_open() 为 true。
func _menu_is_open() -> bool:
	if _companion == null or not is_instance_valid(_companion):
		return false
	for child in _companion.get_children():
		if child.has_method("is_open") and bool(child.call("is_open")):
			return true
	return false


func _show_tip() -> void:
	if _dismissed or _visible:
		return
	_visible = true
	_layer = CanvasLayer.new()
	_layer.name = "Tutorial"
	_layer.layer = 60
	_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_layer)

	var root := Control.new()
	root.name = "Root"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(root)

	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.035, 0.06, 0.94)
	style.border_color = Color(0.35, 0.9, 1.0, 0.8)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 24.0
	style.content_margin_right = 24.0
	style.content_margin_top = 16.0
	style.content_margin_bottom = 14.0
	panel.add_theme_stylebox_override("panel", style)
	root.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	panel.offset_left = -400.0
	panel.offset_right = 400.0
	panel.offset_top = -180.0
	panel.offset_bottom = -38.0

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)

	var text := Label.new()
	text.text = TIP_TEXT
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_theme_font_override("font", _make_font(false))
	text.add_theme_font_size_override("font_size", 19)
	text.add_theme_color_override("font_color", Color(0.9, 0.96, 1, 1))
	box.add_child(text)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END
	box.add_child(row)

	var confirm := Button.new()
	confirm.text = "确认"
	confirm.custom_minimum_size = Vector2(132, 42)
	confirm.focus_mode = Control.FOCUS_NONE
	confirm.add_theme_font_override("font", _make_font(true))
	confirm.add_theme_font_size_override("font_size", 18)
	confirm.add_theme_color_override("font_color", Color(0.86, 0.98, 1, 1))
	confirm.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))
	confirm.add_theme_color_override("font_pressed_color", Color(1, 1, 1, 1))
	confirm.add_theme_stylebox_override("normal", _make_button_box(Color(0.06, 0.12, 0.18, 1)))
	confirm.add_theme_stylebox_override("hover", _make_button_box(Color(0.10, 0.28, 0.36, 1)))
	confirm.add_theme_stylebox_override("pressed", _make_button_box(Color(0.14, 0.38, 0.46, 1)))
	confirm.pressed.connect(_dismiss)
	row.add_child(confirm)

	root.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(root, "modulate:a", 1.0, 0.25)


func _make_font(bold: bool) -> SystemFont:
	var font := SystemFont.new()
	font.font_names = PackedStringArray(FONT_NAMES)
	font.font_weight = 700 if bold else 400
	return font


func _make_button_box(color: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = Color(0.35, 0.9, 1.0, 0.75)
	box.set_border_width_all(1)
	box.set_corner_radius_all(6)
	box.content_margin_left = 20.0
	box.content_margin_right = 20.0
	box.content_margin_top = 8.0
	box.content_margin_bottom = 8.0
	return box


func _dismiss() -> void:
	_dismissed = true
	_visible = false
	if _layer != null and is_instance_valid(_layer):
		_layer.queue_free()
	_layer = null
