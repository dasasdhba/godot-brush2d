@tool
@icon("icon_param.png")
extends Node2D
class_name BrushParam

@export_category("BrushParam")
@export var enable_border :bool = true
@export var border :Rect2 = Rect2(-16,-16,32,32)
@export var enable_offset :bool = true
@export var offset :Vector2 = Vector2(16,16)
@export_group("Preview")
@export var preview :bool = false
@export var preview_color :Color = Color(1,0.5,1,1)

var brush_param_hint :bool = true

func _ready() ->void:
	if !Engine.is_editor_hint():
		queue_free()

func _draw() ->void:
	if preview:
		var r :Rect2 = border
		r.position -= 2*Vector2.ONE
		r.size += 4*Vector2.ONE
		draw_rect(r,preview_color,false,2)

func _process(_delta) ->void:
	queue_redraw()
