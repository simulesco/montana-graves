extends Control
## Montana Graves - prototype 0.2. All visuals are temporary vector shapes.
const VERBS := ["Cammina", "Esamina", "Prendi", "Usa", "Parla"]
const SAVE_PATH := "user://montana_graves_save.json"
var hero := Vector2(470, 505)
var destination := Vector2(470, 505)
var verb := "Esamina"
var message := "Tharros, 1936. Una scoperta attende tra le rovine."
var inventory: Array[String] = []
var selected_item := ""
var puzzle_solved := false
var dialogue_open := false
var dialogue_options := ["Chi sei?", "Cosa sai della stele?", "Arrivederci."]
var hotspots := [
	{"name":"Stele", "area":Rect2(805, 360, 92, 115), "detail":"Un'iscrizione di fantasia, ispirata al mondo fenicio-punico. Manca una tessera."},
	{"name":"Anfora", "area":Rect2(283, 475, 82, 77), "detail":"Un recipiente rotto. Tra i cocci intravedo qualcosa."},
	{"name":"Portico", "area":Rect2(76, 260, 280, 185), "detail":"Rovine stratificate: non tutte appartengono alla stessa epoca."},
	{"name":"Archeologa", "area":Rect2(1025, 385, 65, 165), "detail":"Una studiosa osserva gli scavi con attenzione."}
]

func _ready() -> void:
	set_process(true)
	queue_redraw()

func _process(delta: float) -> void:
	hero = hero.move_toward(destination, 190.0 * delta)
	queue_redraw()

func _draw() -> void:
	var w := size.x
	var h := size.y
	# Sea, sky and landscape (placeholder illustration).
	draw_rect(Rect2(0, 0, w, h), Color("#d9af7c"))
	draw_rect(Rect2(0, 0, w, 295), Color("#8cc5dc"))
	draw_rect(Rect2(0, 243, w, 93), Color("#3a86a2"))
	draw_circle(Vector2(w * 0.81, 110), 51, Color("#ffe0a0"))
	draw_colored_polygon(PackedVector2Array([Vector2(0,335),Vector2(160,310),Vector2(450,346),Vector2(740,307),Vector2(1000,342),Vector2(w,313),Vector2(w,575),Vector2(0,575)]),Color("#d6ae79"))
	for x in [112, 205, 299]:
		draw_rect(Rect2(x, 276, 24, 169), Color("#9d7a59"))
		draw_rect(Rect2(x - 8, 263, 40, 16), Color("#c6a17a"))
	draw_rect(Rect2(74, 252, 273, 16), Color("#b58b65"))
	# Stele and invented glyph marks.
	draw_rect(Rect2(811, 369, 75, 106), Color("#96765d"))
	for i in range(4):
		draw_line(Vector2(825, 391 + i * 18), Vector2(866, 391 + i * 18), Color("#534538"), 3)
	# Amphora.
	if not inventory.has("Frammento"):
		draw_circle(Vector2(323, 514), 28, Color("#ab603c"))
		draw_rect(Rect2(308, 481, 30, 16), Color("#ab603c"))
	else:
		draw_circle(Vector2(323, 520), 22, Color("#965a3e"))
	# Archaeologist NPC.
	draw_rect(Rect2(1044, 441, 28, 65), Color("#596d65"))
	draw_circle(Vector2(1058, 425), 15, Color("#c58e6d"))
	draw_rect(Rect2(1037, 407, 42, 7), Color("#544437"))
	# Player.
	draw_line(hero + Vector2(-8,-20), hero + Vector2(-13,0), Color("#37343a"), 7)
	draw_line(hero + Vector2(8,-20), hero + Vector2(13,0), Color("#37343a"), 7)
	draw_rect(Rect2(hero.x - 15, hero.y - 65, 30, 46), Color("#735336"))
	draw_circle(hero + Vector2(0,-78), 14, Color("#e1ae83"))
	draw_rect(Rect2(hero.x - 23, hero.y - 94, 46, 7), Color("#49372b"))
	draw_rect(Rect2(hero.x - 14, hero.y - 102, 28, 11), Color("#49372b"))
	# Interface.
	draw_rect(Rect2(0, h - 151, w, 151), Color("#292836"))
	draw_string(ThemeDB.fallback_font, Vector2(22,h - 119), message, HORIZONTAL_ALIGNMENT_LEFT, int(w - 44), 20, Color("#ffe6ba"))
	for i in range(VERBS.size()):
		var tint := Color("#ffd27d") if VERBS[i] == verb else Color("#e0ddd6")
		draw_string(ThemeDB.fallback_font, Vector2(24 + i * 145,h - 82), VERBS[i], HORIZONTAL_ALIGNMENT_LEFT, 138, 20, tint)
	var items := ", ".join(inventory) if not inventory.is_empty() else "(vuoto)"
	draw_string(ThemeDB.fallback_font, Vector2(24,h - 36), "Inventario (clic per selezionare): " + items, HORIZONTAL_ALIGNMENT_LEFT, int(w - 50), 18, Color("#e0ddd6"))
	draw_string(ThemeDB.fallback_font, Vector2(w - 295,h - 10), "F5 salva  |  F9 carica", HORIZONTAL_ALIGNMENT_LEFT, 280, 15, Color("#b6b4bc"))
	if selected_item != "":
		draw_string(ThemeDB.fallback_font, Vector2(755,h - 82), "Selezionato: " + selected_item, HORIZONTAL_ALIGNMENT_LEFT, 500, 18, Color("#ffd27d"))
	if dialogue_open:
		draw_rect(Rect2(330, 75, 650, 230), Color("#252734"))
		draw_string(ThemeDB.fallback_font, Vector2(355,110), "Conversazione con l'archeologa", HORIZONTAL_ALIGNMENT_LEFT, 610, 22, Color("#ffe2ad"))
		for i in range(dialogue_options.size()):
			draw_string(ThemeDB.fallback_font, Vector2(365,158 + i * 49), str(i + 1) + ". " + dialogue_options[i], HORIZONTAL_ALIGNMENT_LEFT, 580, 20, Color("#eeeeee"))

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F5:
			save_game()
		elif event.keycode == KEY_F9:
			load_game()
		elif dialogue_open and event.keycode >= KEY_1 and event.keycode <= KEY_3:
			answer_dialogue(event.keycode - KEY_1)

func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	var p: Vector2 = event.position
	if dialogue_open:
		if Rect2(330, 75, 650, 230).has_point(p):
			var choice := int((p.y - 125) / 49)
			if choice >= 0 and choice < dialogue_options.size():
				answer_dialogue(choice)
		return
	if p.y >= size.y - 104:
		if p.y <= size.y - 53 and p.x >= 24:
			var index := int((p.x - 24) / 145)
			if index >= 0 and index < VERBS.size():
				verb = VERBS[index]
				selected_item = ""
				message = verb + "..."
		elif p.y > size.y - 53 and not inventory.is_empty():
			selected_item = inventory[0]
			verb = "Usa"
			message = "Usa " + selected_item + " con..."
	elif p.y < size.y - 151:
		var hit := false
		for spot in hotspots:
			if spot["area"].has_point(p):
				hit = true
				interact(spot)
				break
		if not hit:
			destination = Vector2(clampf(p.x,30,size.x - 30),clampf(p.y,355,550))
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
				message = "Raccolto: frammento con un'incisione."
			else:
				message = "Non posso prenderlo."
		"Usa":
			if name == "Stele" and inventory.has("Frammento") and (selected_item == "Frammento" or selected_item == ""):
				puzzle_solved = true
				message = "Il frammento completa il disegno! Una pista conduce a Nora."
				selected_item = ""
			else:
				message = "Non sembra funzionare."
		"Parla":
			if name == "Archeologa":
				dialogue_open = true
				message = "Una collega si presenta."
			else:
				message = "Non ricevo risposta."
		_:
			destination = spot["area"].get_center() + Vector2(0,85)
			destination.y = clampf(destination.y,355,550)
			message = "Mi avvicino a " + name + "."

func answer_dialogue(choice: int) -> void:
	dialogue_open = false
	match choice:
		0:
			message = "Sono Elena Serra. Studio le tracce delle antiche rotte mediterranee."
		1:
			message = "Elena: Non confondere le epoche. Questa iscrizione è una finzione del nostro mistero."
		_:
			message = "Elena: Buona fortuna, Montana."
	queue_redraw()

func save_game() -> void:
	var data := {"hero_x":hero.x,"hero_y":hero.y,"inventory":inventory,"puzzle_solved":puzzle_solved}
	var file := FileAccess.open(SAVE_PATH,FileAccess.WRITE)
	if file == null:
		message = "Impossibile salvare."
		return
	file.store_string(JSON.stringify(data))
	message = "Partita salvata."

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		message = "Nessun salvataggio trovato."
		return
	var file := FileAccess.open(SAVE_PATH,FileAccess.READ)
	if file == null:
		message = "Impossibile caricare."
		return
	var data = JSON.parse_string(file.get_as_text())
	if not (data is Dictionary):
		message = "Salvataggio non valido."
		return
	hero = Vector2(float(data.get("hero_x",470)),float(data.get("hero_y",505)))
	destination = hero
	inventory.clear()
	for item in data.get("inventory",[]):
		if item is String:
			inventory.append(item)
	puzzle_solved = bool(data.get("puzzle_solved",false))
	selected_item = ""
	dialogue_open = false
	message = "Partita caricata."
