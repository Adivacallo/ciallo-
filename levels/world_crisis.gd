extends Node
## 进入第一个房间 1 秒后:黑屏闪动几下,随后把背景换成废墟城市。
## 只在首次进入时演出;之后回到第一房间直接保持城市背景。

const NEW_BG := "res://picture/city_ruins_bg.png"
const FLICKER_TIMES := 4
## 记录本次运行是否已经播过(死亡后回第一房间不再重播,主菜单新开一局会重置)。
const META_KEY := "world_crisis_played"


func _ready() -> void:
	if bool(Engine.get_meta(META_KEY, false)):
		_apply_background()
		queue_free()
		return
	Engine.set_meta(META_KEY, true)
	_run.call_deferred()


func _run() -> void:
	await get_tree().create_timer(1.0).timeout
	var layer := CanvasLayer.new()
	layer.name = "CrisisFlash"
	layer.layer = 90
	add_child(layer)
	var flash := ColorRect.new()
	flash.color = Color(0, 0, 0, 0)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(flash)

	# 黑屏闪动几下
	for i in FLICKER_TIMES:
		flash.color.a = 0.9
		await get_tree().create_timer(0.06).timeout
		flash.color.a = 0.0
		await get_tree().create_timer(0.08).timeout

	# 最后一闪压满黑,在黑屏里换背景再淡出
	flash.color.a = 1.0
	await get_tree().create_timer(0.14).timeout
	_apply_background()
	var tw := create_tween()
	tw.tween_property(flash, "color:a", 0.0, 0.45)
	await tw.finished
	layer.queue_free()


func _apply_background() -> void:
	var root := get_parent()
	if root == null:
		return
	var backdrop := root.get_node_or_null("Background/Backdrop") as TextureRect
	if backdrop == null:
		return
	var tex := _load_texture(NEW_BG)
	if tex == null:
		return
	backdrop.texture = tex
	backdrop.modulate = Color(1, 1, 1, 1)


func _load_texture(path: String) -> Texture2D:
	var tex: Texture2D = null
	if ResourceLoader.exists(path):
		tex = load(path) as Texture2D
	if tex != null:
		return tex
	var img := Image.new()
	if img.load(path) == OK:
		return ImageTexture.create_from_image(img)
	return null
