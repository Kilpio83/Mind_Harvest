## MH_TextboxLayer — Mind Harvest dialogue panel.
##
## Extends the default VN textbox with a single override:
## the Anchor is shifted so the panel spans from ~28 % to the right edge
## of the viewport (bottom-right half-screen layout).
##
## All colour / font settings are applied via the Dialogic style overrides
## (see mind_harvest_style.tres), not here.
@tool
extends "res://addons/dialogic/Modules/DefaultLayoutParts/Layer_VN_Textbox/vn_textbox_layer.gd"


func _apply_export_overrides() -> void:
	await super._apply_export_overrides()
	_apply_mh_position()


func _apply_mh_position() -> void:
	if not is_inside_tree():
		return

	var anchor: Control = get_node_or_null("Anchor")
	if anchor == null:
		return

	var vp_w: float = get_viewport().get_visible_rect().size.x

	# The panel should span from 28 % to the right edge.
	# Centre of that span = (0.28 + 1.0) / 2 = 0.64 of the viewport width.
	# We position the Anchor at that horizontal centre and set the panel
	# width to 0.72 × viewport_width so it extends ±36 % from the centre,
	# landing exactly at 28 % on the left and 100 % on the right.
	anchor.anchor_left  = 0.64
	anchor.anchor_right = 0.64

	var sizer: Control = get_node_or_null("Anchor/AnimationParent/Sizer")
	if sizer == null:
		return

	box_size.x = vp_w * 0.72
	sizer.size     = box_size
	sizer.position = box_size * Vector2(-0.5, -1.0) + Vector2(0.0, float(-box_margin_bottom))
