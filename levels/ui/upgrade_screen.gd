extends Control
## 变强界面:整屏覆盖的强化面板。左上 token 数,右上关闭叉号。
## 只负责显示;开关、暂停与按键由 npc_menu.gd 控制。

signal close_requested

const UI_FONT := preload("res://levels/ui/ui_font.gd")

@onready var _token_hud: Panel = $TokenHud
@onready var _close_button: Button = $CloseButton


func _ready() -> void:
	visible = false
	UI_FONT.apply(self, 16)
	_close_button.pressed.connect(_on_close_pressed)
	_token_hud.call("build", null, null)


## 打开界面(同时刷新一次 token 数)。
func open() -> void:
	_token_hud.call("build", null, null)
	visible = true


func close() -> void:
	visible = false


func _on_close_pressed() -> void:
	close_requested.emit()
