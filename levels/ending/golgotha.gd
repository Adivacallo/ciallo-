extends Control
## 结局过渡场景:黑场直接进入火雨房间。
## 原先的孤石方碑 + 字幕演出已整段跳过,相关文本与代码已删除。

const NEXT_SCENE := "res://levels/fire_room.tscn"

@onready var _fade: ColorRect = $Fade


func _ready() -> void:
	_fade.color.a = 1.0
	await get_tree().create_timer(0.3).timeout
	get_tree().change_scene_to_file(NEXT_SCENE)
