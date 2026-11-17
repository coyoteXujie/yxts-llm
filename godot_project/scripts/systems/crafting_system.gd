extends RefCounted
## 锻造系统：管理配方、材料消耗与装备生成

## 配方数据路径 — 可通过外部赋值替换，方便测试
var _recipes_path := "res://data/crafting_recipes.json"

var _recipes: Array = []

func _init(path_override: String = "") -> void:
	if not path_override.is_empty():
		_recipes_path = path_override
	_load_recipes()

func _load_recipes() -> void:
	var file = FileAccess.open(_recipes_path, FileAccess.READ)
	if file == null:
		push_error("锻造配方文件加载失败: %s" % _recipes_path)
		return
	var text = file.get_as_text()
	var json = JSON.new()
	if json.parse(text) != OK:
		push_error("锻造配方解析失败: %s" % json.get_error_message())
		return
	if typeof(json.data) != TYPE_ARRAY:
		push_error("锻造配方数据格式错误，期望 Array")
		return
	_recipes = json.data

## 获取所有配方
func get_recipes() -> Array[Dictionary]:
	return _recipes.duplicate(true)

## 获取指定配方
func get_recipe(recipe_id: String) -> Dictionary:
	for r in _recipes:
		if r.get("id", "") == recipe_id:
			return r.duplicate(true)
	return {}

## 检查玩家是否能锻造此配方
func can_craft(recipe_id: String) -> Dictionary:
	var recipe: Variant = get_recipe(recipe_id)
	if recipe.is_empty():
		return {"ok": false, "reason": "配方不存在"}

	var player_data := GameState.player
	if player_data == null or typeof(player_data) != TYPE_DICTIONARY:
		return {"ok": false, "reason": "玩家数据不可用"}
	var forge_level: int = int(player_data.get("forge_level", 0))
	var skill_req: int = int(recipe.get("skill_req", 0))
	if forge_level < skill_req:
		return {"ok": false, "reason": "锻造等级不足（需要 %d）" % skill_req}

	var materials: Dictionary = recipe.get("materials", {})
	for mat_id in materials.keys():
		var need: int = int(materials[mat_id])
		var have: int = int(GameState.inventory.get(mat_id, 0))
		if have < need:
			var item: Dictionary = GameData.get_item(mat_id)
			return {"ok": false, "reason": "材料不足：缺少 %s x%d" % [item.get("name", mat_id), need - have]}

	return {"ok": true, "reason": ""}

## 执行锻造
func craft(recipe_id: String) -> Dictionary:
	var recipe: Variant = get_recipe(recipe_id)
	if recipe.is_empty():
		return {"ok": false, "reason": "配方不存在"}

	var check: Variant = can_craft(recipe_id)
	if not check.get("ok", false):
		return check

	var materials: Dictionary = recipe.get("materials", {})
	for mat_id in materials.keys():
		var need: int = int(materials[mat_id])
		if not GameState.remove_item(mat_id, need):
			return {"ok": false, "reason": "材料不足"}

	var result_id: String = str(recipe.get("result_id", ""))
	var result_count: int = int(recipe.get("result_count", 1))
	if result_id.is_empty():
		return {"ok": false, "reason": "产物配置错误"}

	GameState.add_item(result_id, result_count)

	var item: Dictionary = GameData.get_item(result_id)
	var item_name: String = str(item.get("name", result_id))
	var rarity: String = str(item.get("rarity", "common"))
	var quality_label: String = ""
	match rarity:
		"legendary": quality_label = "✨ 传说"
		"epic":      quality_label = "⭐ 极品"
		"rare":      quality_label = "🌟 精品"
		_:           quality_label = "◆ 良品"

	return {
		"ok": true,
		"item_id": result_id,
		"item_name": item_name,
		"item_count": result_count,
		"quality": quality_label
	}