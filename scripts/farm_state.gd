class_name FarmState
extends RefCounted
## Pure game rules. One watered night advances one growth stage.

const COLUMNS := 8
const ROWS := 5
const SAVE_PATH := "user://farm_save.json"
const CROPS := [
	{"name": "Cà rốt", "days": 2, "buy": 5, "sell": 14, "color": Color("ed944b")},
	{"name": "Lúa mì", "days": 3, "buy": 8, "sell": 24, "color": Color("efcf6b")},
	{"name": "Cà chua", "days": 4, "buy": 14, "sell": 44, "color": Color("dc6b59")},
	{"name": "Bí ngô", "days": 5, "buy": 22, "sell": 72, "color": Color("df943e")},
]

var day: int = 1
var money: int = 80
var harvested: int = 0
var seeds: Array = [6, 3, 0, 0]
var produce: Array = [0, 0, 0, 0]
var plots: Array = []
var player_position := Vector2(420, 510)
var last_error := ""
var changed := false

func _init() -> void:
	for index in range(COLUMNS * ROWS):
		plots.append({"tilled": false, "crop": -1, "growth": 0, "watered": false})

func is_ripe(plot: Dictionary) -> bool:
	return plot.crop >= 0 and plot.growth >= CROPS[plot.crop].days

func work(index: int, tool: int, selected: int) -> String:
	changed = false
	if index < 0 or index >= plots.size() or selected < 0 or selected >= CROPS.size():
		return "Chọn một ô trong ruộng nhé."
	var plot: Dictionary = plots[index]
	match tool:
		0:
			if plot.tilled:
				return "Ô này đã được cuốc. Chọn hạt giống để gieo."
			plot.tilled = true
		1:
			if not plot.tilled:
				return "Cuốc đất trước khi gieo hạt (phím 1)."
			if plot.crop >= 0:
				return "Ô đất đã có cây."
			if seeds[selected] <= 0:
				return "Đã hết hạt giống này. Ghé cửa hàng để mua thêm."
			seeds[selected] -= 1
			plot.crop = selected
			plot.growth = 0
		2:
			if not plot.tilled:
				return "Hãy cuốc đất trước khi tưới nước."
			if plot.watered:
				return "Ô đất đã đủ nước hôm nay."
			plot.watered = true
		3:
			if plot.crop < 0:
				return "Chưa có cây để thu hoạch."
			if not is_ripe(plot):
				return "Cây chưa chín. Tưới nước mỗi ngày và ngủ để cây lớn."
			produce[plot.crop] += 1
			harvested += 1
			plot.crop = -1
			plot.growth = 0
		_:
			return "Công cụ không hợp lệ."
	changed = true
	return ["Đã cuốc đất. Tiếp theo: gieo hạt (2).", "Đã gieo hạt. Nhớ tưới nước (3)!", "Đã tưới nước. Về nhà ngủ để sang ngày mới.", "Đã thu hoạch! Ghé cửa hàng để bán nông sản."][tool]

func next_day() -> int:
	day += 1
	var grown := 0
	for plot in plots:
		if plot.crop >= 0 and plot.watered and not is_ripe(plot):
			plot.growth += 1
			grown += 1
		plot.watered = false
	return grown

func buy(crop: int) -> String:
	changed = false
	if crop < 0 or crop >= CROPS.size():
		return "Hạt giống không hợp lệ."
	if money < CROPS[crop].buy:
		return "Chưa đủ xu. Hãy bán nông sản trước nhé!"
	money -= CROPS[crop].buy
	seeds[crop] += 1
	changed = true
	return "Đã mua 1 hạt %s." % CROPS[crop].name

func sell_value() -> int:
	var total := 0
	for index in range(CROPS.size()):
		total += produce[index] * CROPS[index].sell
	return total

func sell_all() -> String:
	changed = false
	var total := sell_value()
	if total == 0:
		return "Túi chưa có nông sản để bán."
	money += total
	produce = [0, 0, 0, 0]
	changed = true
	return "Đã bán nông sản, nhận %d xu!" % total

func to_data() -> Dictionary:
	return {"version": 1, "day": day, "money": money, "harvested": harvested,
		"seeds": seeds.duplicate(), "produce": produce.duplicate(), "plots": plots.duplicate(true),
		"player": [player_position.x, player_position.y]}

static func whole(value: Variant, minimum: int, maximum: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) \
		and float(value) == floor(float(value)) and value >= minimum and value <= maximum

static func valid_data(data: Variant) -> bool:
	if not data is Dictionary or not whole(data.get("version"), 1, 1):
		return false
	for key in ["day", "money", "harvested"]:
		if not whole(data.get(key), 1 if key == "day" else 0, 1000000000):
			return false
	for key in ["seeds", "produce"]:
		var bag: Variant = data.get(key)
		if not bag is Array or bag.size() != CROPS.size():
			return false
		for count in bag:
			if not whole(count, 0, 1000000000):
				return false
	var position_data: Variant = data.get("player")
	if not position_data is Array or position_data.size() != 2:
		return false
	for axis in position_data:
		if not (axis is int or axis is float) or not is_finite(float(axis)):
			return false
	if position_data[0] < 30 or position_data[0] > 1570 or position_data[1] < 30 or position_data[1] > 1020:
		return false
	var tiles: Variant = data.get("plots")
	if not tiles is Array or tiles.size() != COLUMNS * ROWS:
		return false
	for tile in tiles:
		if not tile is Dictionary or not tile.get("tilled") is bool or not tile.get("watered") is bool:
			return false
		if not whole(tile.get("crop"), -1, CROPS.size() - 1) or not whole(tile.get("growth"), 0, 5):
			return false
		if not tile.tilled and (tile.crop != -1 or tile.watered):
			return false
		if tile.crop == -1 and tile.growth != 0:
			return false
		if tile.crop >= 0 and tile.growth > CROPS[int(tile.crop)].days:
			return false
	return true

func apply_data(data: Dictionary) -> void:
	day = int(data.day)
	money = int(data.money)
	harvested = int(data.harvested)
	for index in range(CROPS.size()):
		seeds[index] = int(data.seeds[index])
		produce[index] = int(data.produce[index])
	for index in range(plots.size()):
		var tile: Dictionary = data.plots[index]
		plots[index] = {"tilled": tile.tilled, "watered": tile.watered,
			"crop": int(tile.crop), "growth": int(tile.growth)}
	player_position = Vector2(data.player[0], data.player[1])

func save_game(path: String = SAVE_PATH) -> bool:
	last_error = ""
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null:
		last_error = "Không thể mở tệp lưu: %s" % error_string(FileAccess.get_open_error())
		return false
	file.store_string(JSON.stringify(to_data()))
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		last_error = "Không ghi được tiến trình."
		return false
	var absolute := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(path):
		if FileAccess.file_exists(path + ".bak"):
			if DirAccess.remove_absolute(absolute + ".bak") != OK:
				last_error = "Không thể cập nhật bản sao lưu."
				return false
		if DirAccess.rename_absolute(absolute, absolute + ".bak") != OK:
			last_error = "Không thể thay thế bản lưu cũ."
			return false
	if DirAccess.rename_absolute(absolute + ".tmp", absolute) != OK:
		if FileAccess.file_exists(path + ".bak"):
			DirAccess.rename_absolute(absolute + ".bak", absolute)
		last_error = "Không thể hoàn tất lưu game."
		return false
	return true

func load_game(path: String = SAVE_PATH) -> bool:
	last_error = ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		last_error = "Chưa có bản lưu hoặc không thể đọc tệp."
		return false
	var data: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not valid_data(data):
		last_error = "Bản lưu không hợp lệ. Tiến trình hiện tại được giữ nguyên."
		return false
	apply_data(data)
	return true
