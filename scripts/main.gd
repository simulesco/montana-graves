extends Control

var hero := Vector2(480, 490)
var destination := Vector2(480, 490)
var verb := "Esamina"
var message := "Tharros, 1936. Il mistero comincia."
var inventory: Array[String] = []
var spots := [
	{"name": "Stele", "area": Rect2(790, 355, 100, 120), "detail": "Una stele incisa. Sembra mancare un pezzo."},
	{"name": "Anfora", "area": Rect2(280, 470, 80, 80), "detail": "Un'anfora spezzata tra le rovine."},
	{"name": "Portico", "area": Rect2(75, 260, 275, 180), "detail": "Colonne di un antico edificio, trasformato nei secoli."}
]
const VERBS := ["Cammina", "Esamina", "Prendi", "Usa", "Parla"]

func _process(delta: float) -> void:
	hero = hero.move_toward(destination, 200.0 * delta)
	queue_redraw()

func _draw() -> void:
	var w := size.x
	var h := size.y
	draw_rect(Rect2(0, 0, w, h), Color("#d6ad77"))
	draw_rect(Rect2(0, 0, w, 295), Color("#89c5df"))
	draw_rect(Rect2(0, 245, w, 92), Color("#3583a3"))
	draw_circle(Vector2(w * 0.82, 105), 53, Color("#ffdfa0"))
	for x in [110, 205, 300]:
		draw_rect(Rect2(x, 275, 24, 170), Color("#a28260"))
		draw_rect(Rect2(x - 8, 262, 40, 17), Color("#c6a37a"))
	draw_rect(Rect2(75, 252, 270, 15), Color("#b78b61"))
	draw_rect(Rect2(805, 367, 75, 108), Color("#98775b"))
	for i in range(4):
		draw_line(Vector2(820, 390 + i * 18), Vector2(864, 390 + i * 18), Color("#544738"), 3)
	draw_circle(Vector2(320, 515), 28, Color("#a95f3c"))
	draw_rect(Rect2(306, 479, 28, 17), Color("#a95f3c"))
	draw_line(hero + Vector2(-8, -19), hero + Vector2(-13, 0), Color("#34313a"), 7)
	draw_line(hero + Vector2(8, -19), hero + Vector2(13, 0), Color("#34313a"), 7)
	draw_rect(Rect2(hero.x - 15, hero.y - 65, 30, 46), Color("#765437"))
	draw_circle(hero + Vector2(0, -78), 14, Color("#e2ad82"))
	draw_rect(Rect2(hero.x - 23, hero.y - 94, 46, 7), Color("#48362a"))
	draw_rect(Rect2(hero.x - 14, hero.y - 102, 28, 11), Color("#48362a"))
	draw_rect(Rect2(0, h - 145, w, 145), Color("#282735"))
	draw_string(ThemeDB.fallback_font, Vector2(22, h - 112), message, HORIZONTAL_ALIGNMENT_LEFT, int(w - 44), 21, Color("#ffe6bc"))
	for i in range(VERBS.size()):
		var tint := Color("#ffd078") if VERBS[i] == verb else Color("#e0ddd6")
		draw_string(ThemeDB.fallback_font, Vector2(25 + i * 145, h - 77), VERBS[i], HORIZONTAL_ALIGNMENT_LEFT, 140, 20, tint)
	var items := ", ".join(inventory) if not inventory.is_empty() else "(vuoto)"
	draw_string(ThemeDB.fallback_font, Vector2(25, h - 28), "Inventario: " + items, HORIZONTAL_ALIGNMENT_LEFT, int(w - 50), 19, Color("#e0ddd6"))

func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	var p: Vector2 = event.position
	if p.y >= size.y - 103:
		if p.y <= size.y - 52 and p.x >= 25:
			var index := int((p.x - 25) / 145)
			if index >= 0 and index < VERBS.size():
				verb = VERBS[index]
				message = verb + "..."
	elif p.y < size.y - 145:
		var hit := false
		for spot in spots:
			if spot["area"].has_point(p):
				hit = true
				interact(spot)
				break
		if not hit:
			destination = Vector2(clampf(p.x, 30, size.x - 30), clampf(p.y, 350, 560))
			message = "Montana si avvicina..."
	queue_redraw()

func interact(spot: Dictionary) -> void:
	var name: String = spot["name"]
	match verb:
		"Esamina":
			message = spot["detail"]
		"Prendi":
			if name == "Anfora" and not inventory.has("Frammento"):
				inventory.append("Frammento")
				message = "Hai raccolto un frammento di ceramica."
			else:
				message = "Non posso prenderlo."
		"Usa":
			if name == "Stele" and inventory.has("Frammento"):
				message = "Il frammento combacia con la stele! Primo indizio trovato."
			else:
				message = "Non sembra funzionare."
		"Parla":
			message = "Non credo che " + name + " possa rispondermi."
		_:
			destination = spot["area"].get_center() + Vector2(0, 90)
			destination.y = clampf(destination.y, 350, 560)
			message = "Mi avvicino a " + name + "."
