extends Button
## Compact owned-card entry; native hover popup uses the full card view.
var host: Control
var card_id: String

func _make_custom_tooltip(_for_text: String) -> Object:
 if not is_instance_valid(host): return null
 var preview: Button = host.card_view(card_id, func(): pass)
 preview.name = "OwnedCardTooltip"
 preview.theme = host.theme
 preview.custom_minimum_size = Vector2(300, 340)
 preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
 preview.tooltip_text = ""
 return preview
