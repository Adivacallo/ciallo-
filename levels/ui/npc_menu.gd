extends CanvasLayer
## 蓝色精灵的交互菜单:按 F 后在她右边弹出「1：我要变强 / 2：离开」,
## 选 1 打开整屏的变强界面;选 2 / ESC 关闭。菜单打开时暂停游戏。

signal closed(used_upgrade: bool)

const UI_FONT := preload("res://levels/ui/ui_font.gd")
## 选项框相对精灵位置的偏移(屏幕像素,放在她右侧)
const OPTION_OFFSET := Vector2(48.0, -112.0)

@onready var _root: Control = $Root
@onready var _options: PanelContainer = $Root/Options
@onready var _screen: Control = $Root/UpgradeScreen

var _npc: Node2D
var _opened := false
var _used_upgrade := false
var _paused_by_us := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	UI_FONT.apply(_root, 16)
	visible = false
	_options.visible = false
	_screen.visible = false
	_screen.connect("close_requested", _on_screen_close)
	set_process(false)


func is_open() -> bool:
	return _opened


func open(npc: Node2D) -> void:
	if _opened:
		return
	_npc = npc
	_opened = true
	_used_upgrade = false
	visible = true
	_options.visible = true
	_screen.visible = false
	_pause_game()
	_refresh_position()
	set_process(true)


func close() -> void:
	if not _opened:
		return
	var used := _used_upgrade
	_opened = false
	_used_upgrade = false
	visible = false
	_options.visible = false
	_screen.visible = false
	set_process(false)
	_resume_game()
	closed.emit(used)


func _show_upgrade() -> void:
	_used_upgrade = true
	_options.visible = false
	_screen.call("open")


func _exit_tree() -> void:
	# 场景被卸载时别把游戏留在暂停里。
	_resume_game()


func _on_screen_close() -> void:
	close()


func _input(event: InputEvent) -> void:
	if not _opened or not (event is InputEventKey):
		return
	var key := event as InputEventKey
	if not key.pressed or key.echo:
		return
	var code := key.physical_keycode if key.physical_keycode != 0 else key.keycode
	if code == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		close()
		return
	if _screen.visible:
		return
	if code == KEY_1 or code == KEY_KP_1:
		get_viewport().set_input_as_handled()
		_show_upgrade()
	elif code == KEY_2 or code == KEY_KP_2:
		get_viewport().set_input_as_handled()
		close()


func _process(_delta: float) -> void:
	if _opened and _options.visible:
		_refresh_position()


## 把选项框放精灵右边(屏幕坐标),并夹在屏幕内。
func _refresh_position() -> void:
	if not is_instance_valid(_npc):
		return
	var vp := get_viewport().get_visible_rect().size
	var anchor: Vector2 = get_viewport().get_canvas_transform() * _npc.global_position
	# 布局还没算完时 size 是 0,退回最小尺寸,免得夹取算错。
	var size := _options.size
	if size.x <= 0.0 or size.y <= 0.0:
		size = _options.get_combined_minimum_size()
	var target := anchor + OPTION_OFFSET
	target.x = clampf(target.x, 12.0, maxf(12.0, vp.x - size.x - 12.0))
	target.y = clampf(target.y, 12.0, maxf(12.0, vp.y - size.y - 12.0))
	_options.position = target


func _pause_game() -> void:
	if get_tree().paused:
		return
	get_tree().paused = true
	_paused_by_us = true


func _resume_game() -> void:
	if not _paused_by_us:
		return
	_paused_by_us = false
	get_tree().paused = false
