extends Node

const WORLD_MAP_SCRIPT := preload("res://scripts/world/world_map.gd")
const LOCAL_AREA_SCRIPT := preload("res://scripts/world/local_area_map.gd")
const MAIN_SCRIPT := preload("res://scripts/main.gd")
const STAGE_SCENE_SCRIPT := preload("res://scripts/world/local_stage_scene.gd")
const STAGE_FOREGROUND_SCRIPT := preload("res://scripts/world/local_stage_foreground.gd")
const PLAYER_SCRIPT := preload("res://scripts/entities/player.gd")
const NPC_SCRIPT := preload("res://scripts/entities/npc.gd")
const WORLD_MAP_PANEL_SCRIPT := preload("res://scripts/ui/world_map_panel.gd")
const COMBAT_STAGE_SCRIPT := preload("res://scripts/ui/combat_stage.gd")
const INVENTORY_PANEL_SCRIPT := preload("res://scripts/ui/inventory_panel.gd")

const WORLD_TILE_WATER := 2
const WORLD_TILE_BUILDING := 3
const WORLD_TILE_MOUNTAIN := 10
const LOCAL_TILE_WATER := 2
const LOCAL_TILE_MOUNTAIN := 8

var failures: Array[String] = []

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	await get_tree().process_frame
	_ensure_input_actions()
	GameState.new_game({
		"name": "自动测试",
		"gender": "male",
		"faction": "none"
	})
	var story_hint := GameState.get_active_story_quest_hint()
	_check(not story_hint.is_empty() and story_hint.contains("下一步"), "系统应生成主线/任务下一步指引")
	_check(story_hint.contains("平阿四") or story_hint.contains("捕快"), "初始任务指引应点出可行动目标")

	var test_root := Node2D.new()
	add_child(test_root)

	var base_attack := int(GameState.player.get("attack", 0))
	var base_defense := int(GameState.player.get("defense", 0))
	GameState.add_item("item_sword", 1)
	GameState.add_item("item_blade", 1)
	GameState.add_item("item_cloth", 1)
	_check(GameState.equip_item("item_sword"), "应能装备背包中的青钢剑")
	_check(str(GameState.equipment.get("weapon", "")) == "item_sword" and int(GameState.player.get("attack", 0)) == base_attack + 10, "装备青钢剑应增加攻击")
	_check(GameState.equip_item("item_blade"), "应能把青钢剑替换为雁翎刀")
	_check(str(GameState.equipment.get("weapon", "")) == "item_blade" and int(GameState.player.get("attack", 0)) == base_attack + 12, "替换雁翎刀应先移除旧武器再应用新武器攻击")
	_check(GameState.equip_item("item_cloth"), "应能装备布衣")
	_check(str(GameState.equipment.get("armor", "")) == "item_cloth" and int(GameState.player.get("defense", 0)) == base_defense + 4, "装备布衣应增加防御")

	var inventory_panel = INVENTORY_PANEL_SCRIPT.new()
	test_root.add_child(inventory_panel)
	await get_tree().process_frame
	inventory_panel.show_panel()
	var blade_index: int = inventory_panel.item_ids.find("item_blade")
	_check(blade_index >= 0 and inventory_panel.item_list.get_item_text(blade_index).contains("已装备"), "背包列表应标识当前已装备武器")
	if blade_index >= 0:
		inventory_panel._select_item(blade_index)
		_check(inventory_panel.details.text.contains("已装备：武器") and inventory_panel.details.text.contains("当前武器：雁翎刀") and inventory_panel.details.text.contains("当前加成：攻击 +12"), "背包装备详情应显示当前武器槽和加成")
	var sword_index: int = inventory_panel.item_ids.find("item_sword")
	if sword_index >= 0:
		inventory_panel._select_item(sword_index)
		_check(inventory_panel.details.text.contains("当前武器：雁翎刀") and inventory_panel.details.text.contains("攻击 -2"), "背包详情应显示换装前后攻击差值")
	inventory_panel.close_panel()

	var world_map = WORLD_MAP_SCRIPT.new()
	test_root.add_child(world_map)
	await get_tree().process_frame

	_check(world_map.npc_nodes.size() >= 12 and world_map.npc_nodes.size() <= 32, "世界层 NPC 数量应保持稀疏，当前=%d" % world_map.npc_nodes.size())
	_check(world_map.prop_nodes.size() > 20, "世界地图应生成 2.5D 遮挡节点")
	_check(_textured_prop_count(world_map.prop_nodes) > 20, "世界地图 2.5D 道具应加载 PNG 资源")
	_check(world_map.is_position_walkable(GameState.player_position), "玩家出生点应可通行")
	_check(not world_map.is_tile_walkable(_first_tile_with_id(world_map, WORLD_TILE_WATER)), "世界地图水面应不可通行")
	_check(not world_map.is_tile_walkable(_first_tile_with_id(world_map, WORLD_TILE_BUILDING)), "世界地图建筑应不可通行")
	_check(_tile_ratio(world_map, WORLD_TILE_MOUNTAIN) < 0.18, "世界地图不应被山峰瓦片铺满")
	_check(not WORLD_MAP_SCRIPT.WORLD_USE_TILE_TEXTURES, "世界地图不应继续把瓦片纹理作为主画面")
	_check(WORLD_MAP_SCRIPT.WORLD_PAINTED_BACKDROP_ENABLED, "世界地图首屏应启用连续绘制底图")
	_check(WORLD_MAP_SCRIPT.WORLD_PAINTED_BACKDROP_REPLACES_TILE_BASE, "世界地图有连续底图时不应继续绘制瓦片底层")
	_check(str(WORLD_MAP_SCRIPT.WORLD_PAINTED_BACKDROP_PATH).ends_with("world_map_painted_v1.png"), "世界地图应指向生成的连续底图资产")
	_check(world_map.is_painted_world_backdrop_active(), "世界地图应加载 PaintedWorldBackdrop 精灵层")
	var world_backdrop_size: Vector2 = world_map.get_painted_world_backdrop_size()
	_check(world_backdrop_size.x >= WORLD_MAP_SCRIPT.WORLD_PAINTED_BACKDROP_MIN_WIDTH and world_backdrop_size.y >= WORLD_MAP_SCRIPT.WORLD_PAINTED_BACKDROP_MIN_HEIGHT, "世界地图连续底图分辨率不足")
	_check(world_map.painted_backdrop_sprite != null and world_map.painted_backdrop_sprite.z_index < 0, "世界地图连续底图应位于角色与地标之后")
	_check(_actors_use_y_sort(world_map.npc_nodes), "世界层 NPC 应按脚底 Y 坐标排序")

	var player = PLAYER_SCRIPT.new()
	player.world_map = world_map
	player.position = GameState.player_position
	test_root.add_child(player)
	await get_tree().process_frame
	_check(player.z_index == int(player.position.y), "玩家应按脚底 Y 坐标排序")
	_check(PLAYER_SCRIPT.SPRITE_TARGET_HEIGHT >= 124.0, "玩家地图角色显示不应继续偏小")
	var default_player_sprite_path := str(PLAYER_SCRIPT.PLAYER_SPRITE_OVERRIDES.get("male_none", ""))
	_check(default_player_sprite_path.ends_with("player_male_none_stage_v2.png"), "默认男主应优先使用高质量生成 sprite")
	var default_player_sprite := GameData.load_texture(default_player_sprite_path, true)
	_check(default_player_sprite != null and default_player_sprite.get_size().y >= 900.0, "默认男主 sprite 应具备足够原始分辨率")
	_check(GameData.get_npc_sprite_path("平阿四").ends_with("ping_asi_stage_v2.png"), "平阿四应优先使用高质量生成地图 sprite")
	_check(GameData.get_npc_sprite_path("捕快").ends_with("constable_stage_v2.png"), "捕快应优先使用高质量生成地图 sprite")
	_check(GameData.get_npc_sprite_path("店小二").ends_with("waiter_stage_v2.png"), "店小二应优先使用高质量生成地图 sprite")
	_check(GameData.get_npc_sprite_path("阿青").ends_with("aqing_stage_v2.png"), "阿青应优先使用高质量生成地图 sprite")
	_check(GameData.get_npc_sprite_path("厨师").ends_with("chef_stage_v2.png"), "厨师应优先使用高质量生成地图 sprite")
	_check(GameData.get_npc_sprite_path("小商贩").ends_with("peddler_stage_v2.png"), "小商贩应优先使用高质量生成地图 sprite")
	_check(GameData.get_npc_sprite_path("卖花女").ends_with("flower_seller_stage_v2.png"), "卖花女应优先使用高质量生成地图 sprite")
	_check(GameData.get_npc_sprite_path("小裁缝").ends_with("tailor_stage_v2.png"), "小裁缝应优先使用高质量生成地图 sprite")
	_check(GameData.get_npc_sprite_path("何裁缝").ends_with("tailor_stage_v2.png"), "何裁缝应复用高质量裁缝地图 sprite")
	var ping_asi_sprite := GameData.load_texture(GameData.get_npc_sprite_path("平阿四"), true)
	var constable_sprite := GameData.load_texture(GameData.get_npc_sprite_path("捕快"), true)
	var waiter_sprite := GameData.load_texture(GameData.get_npc_sprite_path("店小二"), true)
	var aqing_sprite := GameData.load_texture(GameData.get_npc_sprite_path("阿青"), true)
	var chef_sprite := GameData.load_texture(GameData.get_npc_sprite_path("厨师"), true)
	var peddler_sprite := GameData.load_texture(GameData.get_npc_sprite_path("小商贩"), true)
	var flower_seller_sprite := GameData.load_texture(GameData.get_npc_sprite_path("卖花女"), true)
	var tailor_sprite := GameData.load_texture(GameData.get_npc_sprite_path("小裁缝"), true)
	_check(ping_asi_sprite != null and ping_asi_sprite.get_size().y >= 1300.0, "平阿四地图 sprite 应具备足够原始分辨率")
	_check(constable_sprite != null and constable_sprite.get_size().y >= 1300.0, "捕快地图 sprite 应具备足够原始分辨率")
	_check(waiter_sprite != null and waiter_sprite.get_size().y >= 1300.0, "店小二地图 sprite 应具备足够原始分辨率")
	_check(aqing_sprite != null and aqing_sprite.get_size().y >= 1300.0, "阿青地图 sprite 应具备足够原始分辨率")
	_check(chef_sprite != null and maxf(chef_sprite.get_size().x, chef_sprite.get_size().y) >= 1400.0, "厨师地图 sprite 应具备足够原始分辨率")
	_check(peddler_sprite != null and maxf(peddler_sprite.get_size().x, peddler_sprite.get_size().y) >= 1400.0, "小商贩地图 sprite 应具备足够原始分辨率")
	_check(flower_seller_sprite != null and maxf(flower_seller_sprite.get_size().x, flower_seller_sprite.get_size().y) >= 1400.0, "卖花女地图 sprite 应具备足够原始分辨率")
	_check(tailor_sprite != null and maxf(tailor_sprite.get_size().x, tailor_sprite.get_size().y) >= 1400.0, "裁缝地图 sprite 应具备足够原始分辨率")
	_check(PLAYER_SCRIPT.LOCAL_STAGE_PRESENCE_SCALE >= 1.26, "玩家局部横版舞台应叠加额外角色存在感缩放")
	_check(PLAYER_SCRIPT.PLAYER_CONTACT_GLOW_ALPHA > 0.08, "玩家脚下应保留接触光表现")
	_check(PLAYER_SCRIPT.STEP_DUST_RADIUS.x >= 8.0, "玩家移动应保留脚步尘表现参数")
	_check(PLAYER_SCRIPT.PLAYER_STAGE_RIM_ALPHA >= 0.18, "玩家局部横版舞台应有更明确的贴图轮廓高光")
	_check(PLAYER_SCRIPT.PLAYER_WEAPON_SILHOUETTE_ALPHA >= 0.30, "玩家局部横版舞台应保留武侠武器剪影层")
	_check(PLAYER_SCRIPT.PLAYER_CLOTH_LAYER_ALPHA >= 0.24, "玩家局部横版舞台应保留衣摆前后层")
	_check(PLAYER_SCRIPT.PLAYER_MOTION_AFTERIMAGE_ALPHA >= 0.10, "玩家移动应保留横版舞台残影反馈")
	_check(PLAYER_SCRIPT.PLAYER_STAGE_GROUND_LOCK_ALPHA >= 0.24, "玩家局部横版舞台应保留脚底接地锁定层")
	_check(PLAYER_SCRIPT.PLAYER_STAGE_STANCE_LINE_ALPHA >= 0.22, "玩家局部横版舞台应保留躯干/腿部姿态线")
	_check(PLAYER_SCRIPT.PLAYER_STAGE_RUN_RIBBON_ALPHA >= 0.16, "玩家跑动应保留衣带拖线反馈")
	_check(PLAYER_SCRIPT.PLAYER_STAGE_RUN_RIBBON_COUNT >= 3, "玩家跑动衣带拖线应具备多层残留")
	_check(PLAYER_SCRIPT.PLAYER_STAGE_IDLE_FOCUS_ALPHA >= 0.18, "玩家局部横版舞台待机时应保留头部/视线关注层")
	_check(PLAYER_SCRIPT.PLAYER_STAGE_FACTION_SIGIL_ALPHA >= 0.16, "玩家局部横版舞台应保留门派/主角气质提示层")
	_check(PLAYER_SCRIPT.PLAYER_STAGE_IDLE_CLOTH_SWAY_ALPHA >= 0.20, "玩家局部横版舞台待机时应保留衣摆轻摆层")
	_check(PLAYER_SCRIPT.PLAYER_STAGE_POSE_RIG_ALPHA >= 0.26, "玩家局部横版舞台应保留前后肢体动作姿态层")
	_check(PLAYER_SCRIPT.PLAYER_STAGE_ARM_SWING_ALPHA >= 0.24, "玩家局部横版舞台移动时应保留手臂摆动层")
	_check(PLAYER_SCRIPT.PLAYER_STAGE_STEP_ARC_ALPHA >= 0.18, "玩家局部横版舞台应保留步幅轨迹弧")
	_check(PLAYER_SCRIPT.PLAYER_STAGE_IDLE_GUARD_ALPHA >= 0.16, "玩家局部横版舞台待机时应保留守势气口")
	_check(PLAYER_SCRIPT.PLAYER_STAGE_READY_STANCE_ALPHA >= 0.22, "玩家局部横版舞台待机时应保留前后手守势姿态")
	_check(PLAYER_SCRIPT.PLAYER_STAGE_CENTERLINE_ALPHA >= 0.20, "玩家局部横版舞台应保留重心/躯干中心线")
	_check(PLAYER_SCRIPT.PLAYER_STAGE_LANE_LOCK_ALPHA >= 0.16, "玩家局部横版舞台应保留平台带脚底锁定线")
	_check(PLAYER_SCRIPT.PLAYER_STAGE_HEAD_TURN_ALPHA >= 0.18, "玩家局部横版舞台应保留头肩/视线转向细节")
	_check(PLAYER_SCRIPT.PLAYER_STAGE_WEIGHT_SHIFT_ALPHA >= 0.20, "玩家局部横版舞台应保留脚底重心转移提示")
	_check(PLAYER_SCRIPT.PLAYER_STAGE_SIDE_INPUT_DEADZONE <= 0.24, "玩家横版朝向应由明确左右输入驱动")
	_check(PLAYER_SCRIPT.PLAYER_STAGE_TURN_ACCENT_ALPHA >= 0.20, "玩家左右切向应有转身动作提示层")
	_check(PLAYER_SCRIPT.PLAYER_SPRITE_SOURCE_FACES_LEFT, "当前默认玩家源图按朝左资源处理，向右时应镜像底图")
	_check(PLAYER_SCRIPT.STAGE_DEPTH_SCALE_MAX > PLAYER_SCRIPT.STAGE_DEPTH_SCALE_MIN, "玩家应支持局部舞台深度缩放")
	player.facing = Vector2.LEFT
	_check(player._facing_side() < 0.0, "玩家横版舞台侧向层应响应向左朝向")
	player.facing = Vector2.RIGHT
	_check(player._facing_side() > 0.0, "玩家横版舞台侧向层应响应向右朝向")
	player.facing = Vector2.DOWN
	player.has_lateral_facing_side = false
	player._update_lateral_facing(Vector2.LEFT)
	_check(player.has_lateral_facing_side and player.lateral_facing_side < 0.0, "玩家向左输入应锁定横版朝左状态")
	_check(player._facing_side() < 0.0, "玩家横版朝向锁定后应优先使用最后左右方向")
	_check(not player._should_mirror_sprite_for_side(-1.0), "源图朝左时，向左不应镜像底图")
	var turn_timer_left: float = player.turn_accent_timer
	player._update_lateral_facing(Vector2.UP)
	_check(player._facing_side() < 0.0 and player.turn_accent_timer == turn_timer_left, "玩家上/下移动不应重置最后横版朝向")
	player._update_lateral_facing(Vector2.RIGHT)
	_check(player.has_lateral_facing_side and player.lateral_facing_side > 0.0, "玩家向右输入应锁定横版朝右状态")
	_check(player._should_mirror_sprite_for_side(1.0), "源图朝左时，向右应镜像底图")
	_check(player.turn_accent_timer > 0.0 and player.turn_accent_side > 0.0, "玩家左右切向应触发短暂转身提示")
	_check(NPC_SCRIPT.BASE_SPRITE_HEIGHT >= 124.0, "NPC 地图贴图基础高度不应继续偏小")
	_check(NPC_SCRIPT.STAGE_PRESENCE_SCALE >= 1.42, "NPC 局部横版舞台应叠加额外角色存在感缩放")
	_check(NPC_SCRIPT.STAGE_MASTER_SCALE_BIAS >= 1.08 and NPC_SCRIPT.STAGE_ENEMY_SCALE_BIAS >= 1.10, "掌门/敌人应在局部横版舞台获得额外体量")
	_check(NPC_SCRIPT.STAGE_SPRITE_MIN_SCALE >= 1.28, "NPC 局部横版舞台应保留最低视觉体量")
	_check(NPC_SCRIPT.STAGE_SPRITE_MAX_SCALE >= 1.84, "NPC 局部横版舞台应允许前景角色获得更强体量")
	_check(NPC_SCRIPT.STAGE_WIDE_SPRITE_WIDTH_BONUS >= 1.50, "NPC 局部横版舞台应给宽道具 sprite 足够宽度余量")
	_check(NPC_SCRIPT.STAGE_RIM_ALPHA >= 0.12, "NPC 局部横版舞台应有贴图轮廓高光")
	_check(NPC_SCRIPT.STAGE_ROLE_CUE_ALPHA >= 0.16, "NPC 局部横版舞台应有身份提示动效")
	_check(NPC_SCRIPT.CONTACT_GLOW_ALPHA > 0.08, "NPC 脚下应保留接触光表现")
	_check(NPC_SCRIPT.STAGE_GROUND_LOCK_ALPHA >= 0.20, "NPC 局部横版舞台应保留脚底接地锁定层")
	_check(NPC_SCRIPT.STAGE_TORSO_LINE_ALPHA >= 0.20, "NPC 局部横版舞台应保留躯干姿态线")
	_check(NPC_SCRIPT.STAGE_SASH_LINE_ALPHA >= 0.18, "NPC 局部横版舞台应保留腰带/衣摆动态线")
	_check(NPC_SCRIPT.STAGE_WEAPON_GLOW_ALPHA >= 0.20, "NPC 局部横版舞台应保留武器辉光层")
	_check(NPC_SCRIPT.STAGE_LIMB_POSE_ALPHA >= 0.24, "NPC 局部横版舞台应保留前后肢体站姿层")
	_check(NPC_SCRIPT.STAGE_STEP_SWEEP_ALPHA >= 0.18, "NPC 局部横版舞台应保留脚步扫线")
	_check(NPC_SCRIPT.STAGE_IDLE_GUARD_ALPHA >= 0.16, "NPC 局部横版舞台应保留守势/身份站姿线")
	_check(NPC_SCRIPT.STAGE_ROLE_STANCE_SWAY_PIXELS >= 2.0, "NPC 局部横版舞台身份站姿应有轻微动态")
	_check(NPC_SCRIPT.STAGE_ACTIVITY_CUE_ALPHA >= 0.22, "NPC 局部横版舞台应保留职业/行为提示层")
	_check(NPC_SCRIPT.STAGE_ACTIVITY_SWAY_PIXELS >= 4.0, "NPC 局部横版舞台职业/行为提示应有轻微动态")
	_check(NPC_SCRIPT.STAGE_ACTIVITY_GLOW_ALPHA >= 0.14, "NPC 局部横版舞台职业/行为提示应保留光效")
	_check(NPC_SCRIPT.STAGE_LANE_LOCK_ALPHA >= 0.16, "NPC 局部横版舞台应保留平台带脚底锁定线")
	_check(NPC_SCRIPT.STAGE_FACING_CUE_ALPHA >= 0.16, "NPC 局部横版舞台应保留朝向/视线提示层")
	_check(NPC_SCRIPT.STAGE_HEAD_TURN_ALPHA >= 0.18, "NPC 局部横版舞台应保留头肩/视线转向细节")
	_check(NPC_SCRIPT.STAGE_WEIGHT_SHIFT_ALPHA >= 0.20, "NPC 局部横版舞台应保留脚底重心转移提示")
	_check(_stage_role_scale_bonus(), "掌门/敌人局部舞台体量应大于普通 NPC")

	var local_area = LOCAL_AREA_SCRIPT.new()
	test_root.add_child(local_area)
	await get_tree().process_frame
	local_area.setup_region(GameData.get_region("qinghe"))
	await get_tree().process_frame

	var qinghe_stage_profile: Dictionary = local_area.get_stage_scene_profile()
	_check(LOCAL_AREA_SCRIPT.SIDE_VIEW_REGION_PROFILE_ENABLED, "局部横版舞台应启用区域场景风格 profile")
	_check(LOCAL_AREA_SCRIPT.STAGE_SCENE_PROFILE_STYLE_COUNT >= 16, "区域场景风格 profile 应覆盖城池、小镇、水域、山林、雪地、荒漠和门派等主类型")
	_check(str(qinghe_stage_profile.get("style", "")) == LOCAL_AREA_SCRIPT.STAGE_SCENE_STYLE_STARTER_TOWN, "平安镇应走新手镇横版街景 profile")
	_check(bool(qinghe_stage_profile.get("has_market", false)) and bool(qinghe_stage_profile.get("has_lanterns", false)), "新手镇 profile 应标记市集门脸和灯笼层")
	_check(float(qinghe_stage_profile.get("market_density", 0.0)) >= 0.60, "新手镇 profile 应提供足够商铺/商贩密度")
	var luoyang_stage_profile: Dictionary = local_area.get_stage_scene_profile(GameData.get_region("luoyang"))
	_check(str(luoyang_stage_profile.get("style", "")) == LOCAL_AREA_SCRIPT.STAGE_SCENE_STYLE_CITY, "洛阳应走都城街道 profile")
	_check(bool(luoyang_stage_profile.get("has_market", false)) and bool(luoyang_stage_profile.get("has_lanterns", false)), "洛阳都城 profile 应标记市井门脸和灯笼层")
	_check(float(luoyang_stage_profile.get("building_density", 0.0)) >= 0.70 and float(luoyang_stage_profile.get("market_density", 0.0)) >= 0.80, "洛阳都城 profile 应提供高建筑/市场密度")
	var linan_stage_profile: Dictionary = local_area.get_stage_scene_profile(GameData.get_region("linan"))
	_check(str(linan_stage_profile.get("style", "")) == LOCAL_AREA_SCRIPT.STAGE_SCENE_STYLE_WATER_CITY, "临安应走水城街道 profile")
	_check(bool(linan_stage_profile.get("has_water", false)) and bool(linan_stage_profile.get("has_bridge", false)), "临安水城 profile 应标记水系和桥")
	_check(float(linan_stage_profile.get("bridge_density", 0.0)) >= 0.70, "临安水城 profile 应具备足够桥/码头密度")
	var beiling_stage_profile: Dictionary = local_area.get_stage_scene_profile(GameData.get_region("beiling_mtn"))
	_check(str(beiling_stage_profile.get("style", "")) == LOCAL_AREA_SCRIPT.STAGE_SCENE_STYLE_MOUNTAIN and bool(beiling_stage_profile.get("has_mountain", false)), "北岭群山应走山道 profile")
	_check(float(beiling_stage_profile.get("landmark_density", 0.0)) >= 0.50 and float(beiling_stage_profile.get("tree_density", 0.0)) >= 0.20, "北岭群山 profile 应提供山体和林木地标密度")
	var bamboo_stage_profile: Dictionary = local_area.get_stage_scene_profile(GameData.get_region("bashu_bamboo"))
	_check(str(bamboo_stage_profile.get("style", "")) == LOCAL_AREA_SCRIPT.STAGE_SCENE_STYLE_BAMBOO and bool(bamboo_stage_profile.get("has_forest", false)), "巴蜀竹海应走竹林 profile")
	_check(float(bamboo_stage_profile.get("tree_density", 0.0)) >= 0.88, "巴蜀竹海 profile 应提供高树冠密度")
	var xueshan_stage_profile: Dictionary = local_area.get_stage_scene_profile(GameData.get_region("xueshan_sect"))
	_check(str(xueshan_stage_profile.get("style", "")) == LOCAL_AREA_SCRIPT.STAGE_SCENE_STYLE_SECT_SNOW and bool(xueshan_stage_profile.get("is_sect", false)), "雪山派应走雪山门派 profile")
	var flower_stage_profile: Dictionary = local_area.get_stage_scene_profile(GameData.get_region("flower_sect"))
	_check(str(flower_stage_profile.get("style", "")) == LOCAL_AREA_SCRIPT.STAGE_SCENE_STYLE_SECT_FOREST and bool(flower_stage_profile.get("is_sect", false)), "花间派应走花林门派 profile")
	_check(bool(flower_stage_profile.get("has_forest", false)) and float(flower_stage_profile.get("tree_density", 0.0)) >= 0.78, "花间派 profile 应提供高花林/树冠密度")
	_check(float(flower_stage_profile.get("landmark_density", 0.0)) >= 0.80 and float(flower_stage_profile.get("building_density", 0.0)) >= 0.40, "花间派 profile 应保留门派建筑与地标密度")

	_check(local_area.npc_nodes.size() >= 8, "平安镇局部地图应生成镇民 NPC，当前=%d" % local_area.npc_nodes.size())
	_check(local_area.scene_background_texture != null, "局部地图应加载区域水墨氛围背景")
	_check(GameData.get_scene_background_path("qinghe").ends_with("scene_qinghe_dnf_town_v1.png"), "清河镇应接入 DNF 式横版城镇整屏背景")
	_check(local_area.side_view_stage_enabled and LOCAL_AREA_SCRIPT.SIDE_VIEW_STAGE_LANE_ALPHA >= 0.40, "局部地图应启用横版舞台式视觉层")
	_check(LOCAL_AREA_SCRIPT.LOCAL_SIDE_VIEW_HIDE_TILE_GRID, "局部横版舞台不应继续把瓦片网格作为主背景")
	_check(LOCAL_AREA_SCRIPT.LOCAL_PAINTED_STAGE_TEXTURE_PRIORITY, "有生成舞台贴图的局部地图应采用贴图优先渲染")
	_check(local_area.is_painted_stage_stack_active(), "清河镇局部横版舞台应走整屏贴图优先分支")
	var stage_scene = local_area.stage_scene_layer
	_check(stage_scene != null and stage_scene.visible, "清河镇局部横版舞台应创建原生场景背景层")
	_check(stage_scene != null and bool(stage_scene.get("active")), "原生场景背景层应处于激活状态")
	_check(stage_scene != null and bool(stage_scene.get("built_from_stage_layers")), "原生场景背景层应使用清河生成舞台贴图栈")
	_check(stage_scene != null and int(stage_scene.get("parallax_layer_count")) >= 2, "原生场景背景层应使用 Parallax2D 组织背景和中景")
	_check(STAGE_SCENE_SCRIPT.BACKDROP_SCROLL_SCALE == Vector2.ONE and STAGE_SCENE_SCRIPT.MIDGROUND_SCROLL_SCALE == Vector2.ONE, "同源 DNF 城镇图层应按同一相机坐标静态对齐")
	_check(STAGE_SCENE_SCRIPT.BACKDROP_AUTOSCROLL == Vector2.ZERO and STAGE_SCENE_SCRIPT.MIDGROUND_AUTOSCROLL == Vector2.ZERO, "同源 DNF 城镇图层不应自动滚动造成门脸错位")
	_check(STAGE_SCENE_SCRIPT.STAGE_TEXTURE_RECT_OFFSET.y > 0.0 and STAGE_SCENE_SCRIPT.STAGE_TEXTURE_RECT_SIZE.y < 1.0, "局部舞台场景图应锚定在城镇主街视窗区")
	_check(LOCAL_AREA_SCRIPT.SIDE_VIEW_STAGE_SCENE_Z < 0, "原生场景背景层应绘制在角色和交互元素后方")
	_check(LOCAL_AREA_SCRIPT.SIDE_VIEW_PAINTED_BACKDROP_ALPHA >= 0.80, "局部横版舞台应把生成背景作为主视觉底图合成")
	_check(LOCAL_AREA_SCRIPT.LOCAL_STAGE_REDRAW_INTERVAL >= 1.0 / 24.0 and LOCAL_AREA_SCRIPT.LOCAL_STAGE_REDRAW_INTERVAL <= 1.0 / 12.0, "局部横版舞台背景动效应降频重绘以避免移动卡顿")
	_check(not MAIN_SCRIPT.LOCAL_CAMERA_SMOOTHING_ENABLED, "局部地图镜头不应继续用平滑拖尾制造移动滞后")
	_check(MAIN_SCRIPT.NEW_GAME_STARTS_IN_LOCAL_TOWN and MAIN_SCRIPT.NEW_GAME_START_REGION_ID == "qinghe", "新游戏首屏应直接进入平安镇横版城镇")
	_check(local_area.scene_midground_layer_texture != null, "清河镇局部横版舞台应加载生成店铺中景层")
	_check(local_area.scene_floor_layer_texture != null, "清河镇局部横版舞台应加载生成地面贴图层")
	_check(GameData.get_stage_layer_path("qinghe", "floor").ends_with("qinghe_dnf_floor_v1.png"), "清河镇应映射 DNF 式横版地面贴图层")
	var qinghe_floor_layer := GameData.load_texture(GameData.get_stage_layer_path("qinghe", "floor"), true)
	_check(qinghe_floor_layer != null and qinghe_floor_layer.get_size().x >= 1600.0 and qinghe_floor_layer.get_size().y >= 900.0, "清河镇地面贴图层应具备横版舞台分辨率")
	_check(GameData.get_stage_layer_path("qinghe", "midground").ends_with("qinghe_dnf_shopfronts_v1.png"), "清河镇应映射 DNF 式横版店铺中景层")
	var qinghe_midground_layer := GameData.load_texture(GameData.get_stage_layer_path("qinghe", "midground"), true)
	_check(qinghe_midground_layer != null and qinghe_midground_layer.get_size().x >= 1600.0 and qinghe_midground_layer.get_size().y >= 500.0, "清河镇店铺中景层应具备横版舞台分辨率")
	_check(GameData.get_stage_layer_path("qinghe", "foreground").ends_with("qinghe_dnf_foreground_v1.png"), "清河镇应映射 DNF 式横版前景遮挡层")
	var qinghe_foreground_layer := GameData.load_texture(GameData.get_stage_layer_path("qinghe", "foreground"), true)
	_check(qinghe_foreground_layer != null and qinghe_foreground_layer.get_size().x >= 1600.0 and qinghe_foreground_layer.get_size().y >= 900.0, "清河镇前景遮挡层应具备横版舞台分辨率")
	_check(qinghe_midground_layer != null and qinghe_floor_layer != null and qinghe_midground_layer.get_size() == qinghe_floor_layer.get_size(), "清河镇同源城镇中景和地面层应同尺寸对齐")
	_check(qinghe_foreground_layer != null and qinghe_floor_layer != null and qinghe_foreground_layer.get_size() == qinghe_floor_layer.get_size(), "清河镇同源城镇前景和地面层应同尺寸对齐")
	_check(local_area.world_to_tile(local_area.get_entry_position("world")).y <= local_area.map_height / 2 + 8, "平安镇入口应落在主街视窗区而不是地图底边")
	_check(LOCAL_AREA_SCRIPT.SIDE_VIEW_PAINTED_MIDGROUND_LAYER_ALPHA >= 0.90, "清河镇店铺中景层应作为主画面而不是弱贴图")
	_check(LOCAL_AREA_SCRIPT.SIDE_VIEW_PAINTED_FLOOR_LAYER_ALPHA >= 0.90, "清河镇地面层应盖住程序化平台线的瓦片感")
	_check(STAGE_FOREGROUND_SCRIPT.PAINTED_FOREGROUND_LAYER_ALPHA >= 0.62, "清河镇生成前景遮挡层应有足够可见度")
	_check(LOCAL_AREA_SCRIPT.SIDE_VIEW_PLAY_LANE_COUNT >= 5, "局部横版舞台应保留多条可行走平台带")
	_check(LOCAL_AREA_SCRIPT.SIDE_VIEW_PLAY_LANE_ALPHA >= 0.20, "局部横版舞台可行走平台带应有足够可见度")
	_check(LOCAL_AREA_SCRIPT.SIDE_VIEW_PLAY_LANE_EDGE_ALPHA >= 0.26, "局部横版舞台平台边线应有足够层次")
	_check(LOCAL_AREA_SCRIPT.SIDE_VIEW_LANE_DECAL_COUNT >= 20, "局部横版舞台地面应保留走位带细节标识")
	_check(LOCAL_AREA_SCRIPT.SIDE_VIEW_LANE_SHADOW_COUNT >= 5, "局部横版舞台应保留可走平台带阴影栈")
	_check(LOCAL_AREA_SCRIPT.SIDE_VIEW_LANE_SHADOW_ALPHA >= 0.22, "局部横版舞台可走平台带阴影栈应有足够可见度")
	_check(LOCAL_AREA_SCRIPT.SIDE_VIEW_SIDE_EXIT_COUNT >= 4, "局部横版舞台应保留左右副本式出入口框")
	_check(LOCAL_AREA_SCRIPT.SIDE_VIEW_SIDE_EXIT_ALPHA >= 0.24, "局部横版舞台出入口框应有足够可见度")
	_check(LOCAL_AREA_SCRIPT.SIDE_VIEW_TERRACE_BAND_COUNT >= 4, "局部横版舞台应保留多层地形台阶/平台剪影")
	_check(LOCAL_AREA_SCRIPT.SIDE_VIEW_TERRACE_ALPHA >= 0.30, "局部横版舞台地形台阶应有足够可见度")
	_check(LOCAL_AREA_SCRIPT.SIDE_VIEW_TERRACE_RAIL_ALPHA >= 0.28, "局部横版舞台台阶/栏杆细节应有足够可见度")
	_check(LOCAL_AREA_SCRIPT.SIDE_VIEW_TERRAIN_OCCLUDER_COUNT >= 8, "局部横版舞台应保留近景地形遮挡物")
	_check(LOCAL_AREA_SCRIPT.SIDE_VIEW_TERRAIN_OCCLUDER_ALPHA >= 0.26, "局部横版舞台近景地形遮挡物应有足够层次")
	_check(LOCAL_AREA_SCRIPT.SIDE_VIEW_LANE_ANCHOR_MAX_DISTANCE >= 80.0, "局部横版舞台应提供足够宽容的平台锚点捕捉范围")
	var stage_rect_for_lanes: Rect2 = local_area.get_world_rect()
	var lane_positions: Array = local_area.get_stage_play_lane_y_positions()
	_check(lane_positions.size() == LOCAL_AREA_SCRIPT.SIDE_VIEW_PLAY_LANE_COUNT, "局部横版舞台应向系统暴露可行走平台带位置")
	if lane_positions.size() >= 2:
		_check(float(lane_positions[0]) < float(lane_positions[lane_positions.size() - 1]), "局部横版舞台平台带应从远景到前景排序")
	if not lane_positions.is_empty():
		var near_lane_y := float(lane_positions[min(1, lane_positions.size() - 1)])
		var lane_anchor: Dictionary = local_area.get_stage_lane_anchor(Vector2(stage_rect_for_lanes.size.x * 0.5, near_lane_y - 12.0))
		_check(not lane_anchor.is_empty(), "局部横版舞台应能返回最近平台带锚点")
		_check(absf(float(lane_anchor.get("offset_y", 0.0)) - 12.0) <= 0.1, "局部横版舞台平台锚点应返回正确的脚底偏移")
		_check(float(lane_anchor.get("strength", 0.0)) > 0.85, "局部横版舞台平台锚点应在近距离保持强吸附")
	_check(local_area.get_stage_actor_facing_side(Vector2(stage_rect_for_lanes.size.x * 0.25, stage_rect_for_lanes.size.y * 0.6)) > 0.0, "局部横版舞台左侧角色应面向舞台中心")
	_check(local_area.get_stage_actor_facing_side(Vector2(stage_rect_for_lanes.size.x * 0.75, stage_rect_for_lanes.size.y * 0.6)) < 0.0, "局部横版舞台右侧角色应面向舞台中心")
	_check(LOCAL_AREA_SCRIPT.SIDE_VIEW_AMBIENT_PARTICLES >= 24, "局部横版舞台应保留动态氛围粒子")
	_check(LOCAL_AREA_SCRIPT.SIDE_VIEW_MIDGROUND_STRUCTURE_ALPHA >= 0.40, "局部横版舞台应保留地域化中景结构")
	_check(LOCAL_AREA_SCRIPT.SIDE_VIEW_PLATFORM_EDGE_ALPHA >= 0.38, "局部横版舞台应保留地面平台前沿")
	_check(LOCAL_AREA_SCRIPT.SIDE_VIEW_NEAR_PROP_COUNT >= 12, "局部横版舞台应保留近景地物细节")
	_check(LOCAL_AREA_SCRIPT.SIDE_VIEW_FLOOR_DETAIL_COUNT >= 32, "局部横版舞台地面应保留裂纹/碎石细节")
	_check(LOCAL_AREA_SCRIPT.SIDE_VIEW_FLOOR_DETAIL_ALPHA >= 0.12, "局部横版舞台地面细节应有足够可见度")
	_check(LOCAL_AREA_SCRIPT.SIDE_VIEW_PERSPECTIVE_EDGE_ALPHA >= 0.14, "局部横版舞台应保留透视边线")
	_check(LOCAL_AREA_SCRIPT.SIDE_VIEW_PARALLAX_LAYER_COUNT >= 3, "局部横版舞台应保留多层视差远景")
	_check(LOCAL_AREA_SCRIPT.SIDE_VIEW_BACKDROP_DETAIL_COUNT >= 16, "局部横版舞台远景应保留建筑/山石轮廓细节")
	_check(LOCAL_AREA_SCRIPT.SIDE_VIEW_SETPIECE_COUNT >= 10, "局部横版舞台应保留横向布景构件")
	_check(LOCAL_AREA_SCRIPT.SIDE_VIEW_SETPIECE_ALPHA >= 0.30, "局部横版舞台横向布景应有足够可见度")
	_check(LOCAL_AREA_SCRIPT.SIDE_VIEW_SETPIECE_DEPTH_BANDS >= 3, "局部横版舞台横向布景应有前后层次")
	_check(LOCAL_AREA_SCRIPT.SIDE_VIEW_STREET_FACADE_COUNT >= 10, "局部横版城镇舞台应保留连续建筑立面")
	_check(LOCAL_AREA_SCRIPT.SIDE_VIEW_STREET_FACADE_ALPHA >= 0.40, "局部横版城镇建筑立面应有足够可见度")
	_check(LOCAL_AREA_SCRIPT.SIDE_VIEW_STREET_ROOF_DEPTH_ALPHA >= 0.32, "局部横版城镇屋檐应保留深度遮挡")
	_check(LOCAL_AREA_SCRIPT.SIDE_VIEW_STREET_SIGN_COUNT >= 6, "局部横版城镇舞台应保留招牌/灯笼层")
	_check(LOCAL_AREA_SCRIPT.LOCAL_TOWN_SHOP_ENTRANCE_ALPHA >= 0.78 and LOCAL_AREA_SCRIPT.LOCAL_TOWN_SHOP_SIGN_WIDTH >= 96.0, "局部横版城镇商铺入口应有明显门脸和招牌")
	_check(LOCAL_AREA_SCRIPT.LOCAL_TOWN_SHOP_DOOR_GLOW_ALPHA >= 0.30, "局部横版城镇商铺入口应有门口光效")
	_check(LOCAL_AREA_SCRIPT.SIDE_VIEW_UPPER_WALKWAY_COUNT >= 3, "局部横版舞台应保留二层平台/檐廊纵深")
	_check(LOCAL_AREA_SCRIPT.SIDE_VIEW_UPPER_WALKWAY_ALPHA >= 0.30, "局部横版舞台二层平台应有足够可见度")
	_check(LOCAL_AREA_SCRIPT.SIDE_VIEW_STAIR_LINK_COUNT >= 2, "局部横版舞台应保留上下层连接楼梯")
	_check(LOCAL_AREA_SCRIPT.SIDE_VIEW_BALCONY_LANTERN_COUNT >= 6, "局部横版舞台二层应保留灯笼/栏杆细节")
	_check(LOCAL_AREA_SCRIPT.SIDE_VIEW_LIVING_ACTOR_COUNT >= 10, "局部横版舞台应保留背景人流/门人/船工剪影")
	_check(LOCAL_AREA_SCRIPT.SIDE_VIEW_LIVING_ACTOR_ALPHA >= 0.26, "局部横版舞台生活剪影应有足够可见度")
	_check(LOCAL_AREA_SCRIPT.SIDE_VIEW_LIVING_ACTION_ARC_COUNT >= 6, "局部横版门派舞台应保留练功动作轨迹")
	_check(LOCAL_AREA_SCRIPT.SIDE_VIEW_DIRECTOR_BAND_ALPHA >= 0.20, "局部横版舞台应保留上下遮幅/舞台压缩层")
	_check(LOCAL_AREA_SCRIPT.SIDE_VIEW_DEPTH_FOG_BAND_COUNT >= 5, "局部横版舞台应保留多层景深雾带")
	_check(LOCAL_AREA_SCRIPT.SIDE_VIEW_PLATFORM_RIM_COUNT >= 4, "局部横版舞台应保留多段平台亮边")
	_check(LOCAL_AREA_SCRIPT.SIDE_VIEW_STAGE_FOCUS_RAY_COUNT >= 6, "局部横版舞台应保留舞台聚焦光束")
	_check(LOCAL_AREA_SCRIPT.SIDE_VIEW_STAGE_FOCUS_ALPHA >= 0.14, "局部横版舞台聚焦光束应有足够可见度")
	_check(STAGE_FOREGROUND_SCRIPT.BOTTOM_OCCLUDER_COUNT >= 8, "局部横版舞台前景层应保留底部遮挡物")
	_check(STAGE_FOREGROUND_SCRIPT.BOTTOM_OCCLUDER_ALPHA >= 0.20, "局部横版舞台底部遮挡物应有足够层次")
	_check(STAGE_FOREGROUND_SCRIPT.HANGING_FOREGROUND_COUNT >= 6, "局部横版舞台应保留顶部近景挂饰/枝叶")
	_check(STAGE_FOREGROUND_SCRIPT.HANGING_FOREGROUND_ALPHA >= 0.20, "局部横版舞台顶部近景挂饰应有足够可见度")
	_check(STAGE_FOREGROUND_SCRIPT.FRONT_SETPIECE_COUNT >= 4, "局部横版舞台应保留近景柱/树/码头桩遮挡")
	_check(STAGE_FOREGROUND_SCRIPT.FRONT_SETPIECE_ALPHA >= 0.24, "局部横版舞台近景遮挡应有足够可见度")
	_check(STAGE_FOREGROUND_SCRIPT.SIDE_WING_PANEL_COUNT >= 5, "局部横版舞台应保留左右舞台翼墙/近景侧向压场")
	_check(STAGE_FOREGROUND_SCRIPT.SIDE_WING_ALPHA >= 0.30, "局部横版舞台左右翼墙应有足够可见度")
	_check(STAGE_FOREGROUND_SCRIPT.FRONT_DEPTH_FRAME_COUNT >= 4, "局部横版舞台应保留贴近镜头的门框/梁柱深度框架")
	_check(STAGE_FOREGROUND_SCRIPT.FRONT_DEPTH_FRAME_ALPHA >= 0.30, "局部横版舞台近景深度框架应有足够压场层次")
	_check(local_area.stage_postfx_overlay != null and local_area.stage_postfx_overlay.visible, "局部横版舞台应创建镜头光影后期层")
	_check(LOCAL_AREA_SCRIPT.SIDE_VIEW_POSTFX_Z > 3000 and LOCAL_AREA_SCRIPT.SIDE_VIEW_POSTFX_Z < LOCAL_AREA_SCRIPT.SIDE_VIEW_FOREGROUND_OVERLAY_Z, "局部横版舞台后期层应位于角色上方且低于真实前景遮挡")
	_check(local_area.stage_foreground_overlay != null and local_area.stage_foreground_overlay.visible, "局部横版舞台应创建真实前景遮挡层")
	_check(local_area.stage_foreground_overlay.get("painted_foreground_texture") != null, "清河镇局部横版舞台前景 overlay 应加载生成前景遮挡层")
	_check(LOCAL_AREA_SCRIPT.SIDE_VIEW_FOREGROUND_OVERLAY_Z >= 3000, "局部横版舞台前景遮挡层应绘制在角色前方")
	_check(local_area.is_side_view_stage_active(), "局部地图应能向角色暴露横版舞台状态")
	var previous_stage_phase: float = local_area.stage_visual_phase
	var previous_overlay_phase: float = float(local_area.stage_foreground_overlay.get("visual_phase"))
	var previous_postfx_phase: float = float(local_area.stage_postfx_overlay.get("visual_phase"))
	local_area._process(1.0)
	_check(local_area.stage_visual_phase > previous_stage_phase, "局部横版舞台动效时钟应持续推进")
	_check(float(local_area.stage_foreground_overlay.get("visual_phase")) > previous_overlay_phase, "局部横版舞台前景遮挡层应同步动效时钟")
	_check(float(local_area.stage_postfx_overlay.get("visual_phase")) > previous_postfx_phase, "局部横版舞台后期光影层应同步动效时钟")
	var stage_rect: Rect2 = local_area.get_world_rect()
	var back_scale: float = local_area.get_actor_depth_scale(Vector2(stage_rect.size.x * 0.5, stage_rect.size.y * LOCAL_AREA_SCRIPT.STAGE_DEPTH_TOP_RATIO))
	var front_scale: float = local_area.get_actor_depth_scale(Vector2(stage_rect.size.x * 0.5, stage_rect.size.y * LOCAL_AREA_SCRIPT.STAGE_DEPTH_BOTTOM_RATIO))
	_check(front_scale - back_scale >= 0.25, "局部舞台应按前后排缩放角色")
	_check(local_area.prop_nodes.size() > 0, "平安镇局部地图应生成 2.5D 遮挡节点")
	_check(_textured_prop_count(local_area.prop_nodes) > 0, "平安镇 2.5D 道具应加载 PNG 资源")
	_check(_max_textured_actor_height(local_area.npc_nodes) >= 115.0, "局部地图 NPC 贴图显示不应继续偏小")
	_check(_max_textured_actor_height(local_area.npc_nodes) >= 135.0, "局部横版舞台 NPC 贴图应具备更强存在感")
	_check(_textured_actor_height_by_name(local_area.npc_nodes, "小商贩") >= 145.0, "小商贩宽道具 sprite 不应被宽度预算压得过小")
	_check(_textured_actor_height_by_name(local_area.npc_nodes, "厨师") >= 145.0, "厨师宽道具 sprite 不应被宽度预算压得过小")
	_check(NPC_SCRIPT.STAGE_BASE_SPRITE_WIDTH >= 108.0, "局部横版舞台 NPC 应放开贴图宽度预算")
	_check(NPC_SCRIPT.STAGE_MASTER_SPRITE_WIDTH >= 118.0 and NPC_SCRIPT.STAGE_ENEMY_SPRITE_WIDTH >= 116.0, "局部横版舞台掌门/敌人应放开更高贴图宽度预算")
	_check(_actor_depth_scale_range(local_area.npc_nodes) >= 0.10, "局部 NPC 应按舞台前后排产生大小差异")
	_check(_actors_marked_stage(local_area.npc_nodes), "局部地图 NPC 应标记为横版舞台角色")
	_check(_actors_have_idle_motion(local_area.npc_nodes), "局部地图 NPC 应有待机轻微动态")
	_check(_actors_have_stage_rim(local_area.npc_nodes), "局部地图 NPC 应显示舞台贴图轮廓高光")
	_check(_actors_have_stage_pose_overlay(local_area.npc_nodes), "局部地图 NPC 应显示贴图前方姿态线")
	_check(_actors_have_stage_body_overlays(local_area.npc_nodes), "局部地图 NPC 应显示躯干、腰带和武器辉光前层")
	_check(_actors_have_stage_activity(local_area.npc_nodes), "局部地图 NPC 应具备职业/行为视觉提示")
	_check(NPC_SCRIPT.STAGE_IDLE_GESTURE_COUNT >= 4, "局部地图 NPC 应保留待机手势层")
	_check(NPC_SCRIPT.STAGE_IDLE_GESTURE_ALPHA >= 0.18, "局部地图 NPC 待机手势层应有足够可见度")
	_check(_actors_have_stage_lane_anchor(local_area.npc_nodes), "局部地图 NPC 应绑定最近横版平台带锚点")
	_check(_actors_face_stage_center(local_area.npc_nodes, stage_rect.size.x * 0.5), "局部地图 NPC 应根据站位面向舞台中心")
	_check(_stage_labels_and_bubbles_clear_actor_heads(local_area.npc_nodes), "局部横版舞台 NPC 放大后姓名牌/气泡应避开头部")
	_check(NPC_SCRIPT.STAGE_POSE_LINE_ALPHA >= 0.22, "NPC 局部舞台姿态线应有足够可见度")
	_check(NPC_SCRIPT.STAGE_FOOT_ANCHOR_ALPHA >= 0.16, "NPC 局部舞台脚步锚点应有足够可见度")
	_check(not LOCAL_AREA_SCRIPT.LOCAL_USE_TILE_TEXTURES and LOCAL_AREA_SCRIPT.LOCAL_SIDE_VIEW_HIDE_TILE_GRID, "局部横版舞台不应继续依赖多变体瓦片纹理做主背景")
	_check(_min_actor_distance(local_area.npc_nodes) >= GameData.TILE_SIZE * 1.35, "平安镇 NPC 间距过近")
	_check(_actors_use_y_sort(local_area.npc_nodes), "局部地图 NPC 应按脚底 Y 坐标排序")
	_check(GameData.get_neighbor_regions("qinghe", 4).size() >= 3, "平安镇应能计算相邻区域")
	var travel_plan := GameState.build_region_travel_plan("luoyang")
	_check((travel_plan.get("route", []) as Array).size() >= 2, "平安镇到洛阳应能生成驿路路线")
	_check(float(travel_plan.get("hours", 0.0)) >= 1.0, "驿路路线应给出有效耗时")
	_check(not str(travel_plan.get("risk_label", "")).is_empty(), "驿路路线应给出风险等级")
	_check(int(travel_plan.get("fare", 0)) >= 3, "驿路路线应给出有效旅费")
	GameState.update_current_region(GameData.get_region("qinghe"), Vector2i(30, 16))
	GameState.region_state["luoyang"] = {"discovered": true, "exploration": 30, "visited": []}
	var previous_time := float(GameState.day) * 24.0 + GameState.hour
	var previous_money := int(GameState.player.get("money", 0))
	var previous_event_count := GameState.world_events.size()
	var travel_hours := GameState.apply_fast_travel_time("luoyang")
	_check(travel_hours >= 1.0, "满足条件后应能应用快速旅行")
	_check(float(GameState.day) * 24.0 + GameState.hour > previous_time, "快速旅行应推进时间")
	_check(int(GameState.player.get("money", 0)) == previous_money - int(travel_plan.get("fare", 0)), "快速旅行应扣除驿路费用")
	_check(GameState.world_events.size() > previous_event_count, "快速旅行应写入旅行事件")
	_check(GameState.resolve_fast_travel_risk(travel_plan).is_empty(), "低风险驿路不应触发旅途后果")
	player.world_map = local_area
	player.facing = Vector2.DOWN
	player.has_lateral_facing_side = false
	player.position = Vector2(stage_rect.size.x * 0.25, stage_rect.size.y * 0.62)
	_check(player._facing_side() > 0.0, "玩家局部横版舞台左侧待机应面向舞台中心")
	player.position = Vector2(stage_rect.size.x * 0.75, stage_rect.size.y * 0.62)
	_check(player._facing_side() < 0.0, "玩家局部横版舞台右侧待机应面向舞台中心")
	player._update_lateral_facing(Vector2.RIGHT)
	player.position = Vector2(stage_rect.size.x * 0.75, stage_rect.size.y * 0.62)
	_check(player._facing_side() > 0.0, "玩家横向输入后，上下移动或换站位仍应保持最后横版朝向")
	var front_lane_y := stage_rect.size.y * LOCAL_AREA_SCRIPT.STAGE_DEPTH_BOTTOM_RATIO
	if not lane_positions.is_empty():
		front_lane_y = float(lane_positions[lane_positions.size() - 1])
	player.position = Vector2(stage_rect.size.x * 0.5, front_lane_y - 12.0)
	player._refresh_stage_depth_scale()
	player._refresh_stage_lane_anchor()
	_check(player.stage_depth_scale > 1.08, "玩家在局部地图前景站位应明显放大")
	_check(player.get_map_actor_visual_scale() > player.stage_depth_scale, "玩家局部横版地图应在景深外叠加舞台角色缩放")
	_check(player.stage_lane_lock_strength > 0.80, "玩家局部横版地图应读取最近平台带锚点")
	_check(player.get_stage_lane_visual_offset() > 3.0, "玩家局部横版地图应产生平台带视觉吸附偏移")
	_check(PLAYER_SCRIPT.PLAYER_STAGE_FOOT_ANCHOR_ALPHA >= 0.20, "玩家局部横版地图应显示脚步锚点")
	_check(PLAYER_SCRIPT.PLAYER_STAGE_WEAPON_POSE_ALPHA >= 0.30, "玩家局部横版地图应显示前持武器姿态")
	_check(PLAYER_SCRIPT.PLAYER_STAGE_SHOULDER_GLOW_ALPHA >= 0.16, "玩家局部横版地图应显示肩部高光姿态层")
	_check(PLAYER_SCRIPT.PLAYER_STAGE_BREATH_AURA_RINGS >= 3, "玩家局部横版待机应保留多层呼吸气场")
	_check(PLAYER_SCRIPT.PLAYER_STAGE_BREATH_AURA_ALPHA >= 0.16, "玩家局部横版待机呼吸气场应有足够可见度")
	_check(COMBAT_STAGE_SCRIPT.COMBAT_EVENT_AIR_CUT_COUNT >= 6, "战斗舞台攻击事件应保留多段空气斩痕")
	_check(COMBAT_STAGE_SCRIPT.COMBAT_EVENT_AIR_CUT_ALPHA >= 0.22, "战斗舞台空气斩痕应有足够可见度")
	_check(COMBAT_STAGE_SCRIPT.COMBAT_EVENT_FOREGROUND_RIPPLE_COUNT >= 5, "战斗舞台攻击事件应保留近景气浪层")
	_check(COMBAT_STAGE_SCRIPT.COMBAT_EVENT_FOREGROUND_RIPPLE_ALPHA >= 0.20, "战斗舞台近景气浪层应有足够可见度")
	player.world_map = world_map
	player.position = GameState.player_position
	player._refresh_stage_depth_scale()
	var map_panel = WORLD_MAP_PANEL_SCRIPT.new()
	add_child(map_panel)
	map_panel.show_panel()
	map_panel._select_region_by_id("luoyang")
	await get_tree().process_frame
	_check((map_panel.map_canvas.route_plan.get("route", []) as Array).size() >= 2, "世界地图面板应把选中区域的驿路线传给地图画布")
	map_panel.close_panel()
	map_panel.queue_free()
	var travel_region_portal := _first_portal(local_area, "travel_region")
	_check(not travel_region_portal.is_empty(), "平安镇应生成相邻区域转场入口")
	_check(not str(travel_region_portal.get("direction", "")).is_empty() and not str(travel_region_portal.get("direction_label", "")).is_empty(), "相邻区域入口应带方向信息")
	_check(float(travel_region_portal.get("travel_hours", 0.0)) >= 0.5, "相邻区域入口应带预计行路耗时")
	_check(int(travel_region_portal.get("risk_level", 0)) >= 1 and not str(travel_region_portal.get("risk_label", "")).is_empty(), "相邻区域入口应带路况风险")
	var travel_region_label := _portal_label(local_area, str(travel_region_portal.get("id", "")))
	_check(travel_region_label != null and travel_region_label.text.contains("时辰") and travel_region_label.text.contains("路"), "相邻区域入口标签应展示方向、耗时和风险")
	_check(_portal_count(local_area, "landmark") >= 3, "平安镇应生成可互动地标")
	_check(_portal_count(local_area, "resource") >= 2, "平安镇应生成每日资源点")
	_check(LOCAL_AREA_SCRIPT.RICH_SHOP_INTERIOR_ENABLED, "商铺内景应启用高完成度室内 overlay")
	_check(LOCAL_AREA_SCRIPT.SHOP_INTERIOR_BACK_WALL_RATIO > 0.38 and LOCAL_AREA_SCRIPT.SHOP_INTERIOR_BACK_WALL_RATIO < 0.56, "商铺内景应保留横版后墙和透视地面比例")
	_check(LOCAL_AREA_SCRIPT.SHOP_INTERIOR_COUNTER_ALPHA >= 0.86, "商铺内景柜台应作为主视觉层")
	_check(LOCAL_AREA_SCRIPT.SHOP_INTERIOR_SHELF_ALPHA >= 0.76, "商铺内景应有可见货架层")
	_check(LOCAL_AREA_SCRIPT.SHOP_INTERIOR_THEME_PROP_ALPHA >= 0.82, "商铺内景应按店铺类型绘制主题道具")
	_check(LOCAL_AREA_SCRIPT.SHOP_INTERIOR_LIGHT_ALPHA >= 0.28, "商铺内景应有灯光氛围层")

	var shop_portal := _first_portal(local_area, "shop")
	_check(not shop_portal.is_empty(), "平安镇应存在可进入商铺")
	if not shop_portal.is_empty():
		local_area.enter_shop(shop_portal)
		await get_tree().process_frame
		_check(local_area.current_mode == "shop" and not local_area.side_view_stage_enabled, "商铺内景应切出室外横版街景模式")
		_check(not local_area.active_shop_id.is_empty() and LOCAL_AREA_SCRIPT.SHOP_DEFINITIONS.has(local_area.active_shop_id), "商铺内景应保留当前店铺类型用于主题绘制")
		_check(local_area.npc_nodes.size() == 1, "商铺内应生成 1 名掌柜")
		_check(local_area.scene_background_texture == null, "商铺内景不应继续叠加区域背景")
		_check(local_area.stage_postfx_overlay == null or not local_area.stage_postfx_overlay.visible, "商铺内景不应显示局部横版后期光影层")
		_check(local_area.stage_foreground_overlay == null or not local_area.stage_foreground_overlay.visible, "商铺内景不应显示局部横版前景遮挡层")
		_check(not _first_portal(local_area, "exit_area").is_empty(), "商铺内应有出门入口")
		if local_area.npc_nodes.size() > 0:
			var keeper_data: Dictionary = local_area.npc_nodes[0].data
			_check((keeper_data.get("sell_items", []) as Array).size() > 0, "商铺掌柜应带商品列表")

	local_area.setup_region(GameData.get_region("luoyang"))
	await get_tree().process_frame
	_check(GameData.get_scene_background_path("luoyang").ends_with("scene_luoyang_dnf_capital_v1.png"), "洛阳应接入 DNF 式都城横版整屏背景")
	_check(local_area.is_painted_stage_stack_active(), "洛阳局部横版舞台应走整屏贴图优先分支")
	_check(local_area.scene_midground_layer_texture != null and local_area.scene_floor_layer_texture != null, "洛阳应加载都城中景和地面贴图层")
	_check(GameData.get_stage_layer_path("luoyang", "floor").ends_with("luoyang_dnf_capital_floor_v1.png"), "洛阳应映射都城地面贴图层")
	var luoyang_floor_layer := GameData.load_texture(GameData.get_stage_layer_path("luoyang", "floor"), true)
	var luoyang_midground_layer := GameData.load_texture(GameData.get_stage_layer_path("luoyang", "midground"), true)
	var luoyang_foreground_layer := GameData.load_texture(GameData.get_stage_layer_path("luoyang", "foreground"), true)
	_check(luoyang_floor_layer != null and luoyang_floor_layer.get_size().x >= 1600.0 and luoyang_floor_layer.get_size().y >= 900.0, "洛阳都城地面层应具备横版舞台分辨率")
	_check(luoyang_midground_layer != null and luoyang_floor_layer != null and luoyang_midground_layer.get_size() == luoyang_floor_layer.get_size(), "洛阳都城中景层应与地面层同尺寸对齐")
	_check(luoyang_foreground_layer != null and luoyang_floor_layer != null and luoyang_foreground_layer.get_size() == luoyang_floor_layer.get_size(), "洛阳都城前景层应与地面层同尺寸对齐")

	local_area.setup_region(GameData.get_region("linan"))
	await get_tree().process_frame
	_check(GameData.get_scene_background_path("linan").ends_with("scene_linan_dnf_water_city_v1.png"), "临安应接入 DNF 式水城横版整屏背景")
	_check(local_area.is_painted_stage_stack_active(), "临安局部横版舞台应走整屏贴图优先分支")
	_check(local_area.scene_midground_layer_texture != null and local_area.scene_floor_layer_texture != null, "临安应加载水城中景和地面/水道贴图层")
	_check(GameData.get_stage_layer_path("linan", "floor").ends_with("linan_dnf_water_floor_v1.png"), "临安应映射水城地面/水道贴图层")
	var linan_floor_layer := GameData.load_texture(GameData.get_stage_layer_path("linan", "floor"), true)
	var linan_midground_layer := GameData.load_texture(GameData.get_stage_layer_path("linan", "midground"), true)
	var linan_foreground_layer := GameData.load_texture(GameData.get_stage_layer_path("linan", "foreground"), true)
	_check(linan_floor_layer != null and linan_floor_layer.get_size().x >= 1600.0 and linan_floor_layer.get_size().y >= 900.0, "临安水城地面层应具备横版舞台分辨率")
	_check(linan_midground_layer != null and linan_floor_layer != null and linan_midground_layer.get_size() == linan_floor_layer.get_size(), "临安水城中景层应与地面层同尺寸对齐")
	_check(linan_foreground_layer != null and linan_floor_layer != null and linan_foreground_layer.get_size() == linan_floor_layer.get_size(), "临安水城前景层应与地面层同尺寸对齐")
	_check(not local_area.is_tile_walkable(_first_tile_with_id(local_area, LOCAL_TILE_WATER)), "临安局部水面应不可通行")

	local_area.setup_region(GameData.get_region("beiling_mtn"))
	await get_tree().process_frame
	_check(GameData.get_scene_background_path("beiling_mtn").ends_with("scene_beiling_mtn_dnf_mountain_v1.png"), "北岭群山应接入 DNF 式野外山道整屏背景")
	_check(local_area.is_painted_stage_stack_active(), "北岭群山局部横版舞台应走整屏贴图优先分支")
	_check(local_area.scene_midground_layer_texture != null and local_area.scene_floor_layer_texture != null, "北岭群山应加载山道中景和地面贴图层")
	_check(GameData.get_stage_layer_path("beiling_mtn", "floor").ends_with("beiling_mtn_dnf_mountain_floor_v1.png"), "北岭群山应映射山道地面贴图层")
	var beiling_floor_layer := GameData.load_texture(GameData.get_stage_layer_path("beiling_mtn", "floor"), true)
	var beiling_midground_layer := GameData.load_texture(GameData.get_stage_layer_path("beiling_mtn", "midground"), true)
	var beiling_foreground_layer := GameData.load_texture(GameData.get_stage_layer_path("beiling_mtn", "foreground"), true)
	_check(beiling_floor_layer != null and beiling_floor_layer.get_size().x >= 1600.0 and beiling_floor_layer.get_size().y >= 900.0, "北岭群山地面层应具备横版舞台分辨率")
	_check(beiling_midground_layer != null and beiling_floor_layer != null and beiling_midground_layer.get_size() == beiling_floor_layer.get_size(), "北岭群山中景层应与地面层同尺寸对齐")
	_check(beiling_foreground_layer != null and beiling_floor_layer != null and beiling_foreground_layer.get_size() == beiling_floor_layer.get_size(), "北岭群山前景层应与地面层同尺寸对齐")

	local_area.setup_region(GameData.get_region("bashu_bamboo"))
	await get_tree().process_frame
	_check(GameData.get_scene_background_path("bashu_bamboo").ends_with("scene_bashu_bamboo_dnf_bamboo_v1.png"), "巴蜀竹海应接入 DNF 式竹林山道整屏背景")
	_check(local_area.is_painted_stage_stack_active(), "巴蜀竹海局部横版舞台应走整屏贴图优先分支")
	_check(local_area.scene_midground_layer_texture != null and local_area.scene_floor_layer_texture != null, "巴蜀竹海应加载竹林中景和地面贴图层")
	_check(GameData.get_stage_layer_path("bashu_bamboo", "floor").ends_with("bashu_bamboo_dnf_floor_v1.png"), "巴蜀竹海应映射竹林地面贴图层")
	var bamboo_floor_layer := GameData.load_texture(GameData.get_stage_layer_path("bashu_bamboo", "floor"), true)
	var bamboo_midground_layer := GameData.load_texture(GameData.get_stage_layer_path("bashu_bamboo", "midground"), true)
	var bamboo_foreground_layer := GameData.load_texture(GameData.get_stage_layer_path("bashu_bamboo", "foreground"), true)
	_check(bamboo_floor_layer != null and bamboo_floor_layer.get_size().x >= 1600.0 and bamboo_floor_layer.get_size().y >= 900.0, "巴蜀竹海地面层应具备横版舞台分辨率")
	_check(bamboo_midground_layer != null and bamboo_floor_layer != null and bamboo_midground_layer.get_size() == bamboo_floor_layer.get_size(), "巴蜀竹海中景层应与地面层同尺寸对齐")
	_check(bamboo_foreground_layer != null and bamboo_floor_layer != null and bamboo_foreground_layer.get_size() == bamboo_floor_layer.get_size(), "巴蜀竹海前景层应与地面层同尺寸对齐")

	local_area.setup_region(GameData.get_region("flower_sect"))
	await get_tree().process_frame
	_check(GameData.get_scene_background_path("flower_sect").ends_with("scene_flower_sect_dnf_garden_v1.png"), "花间派应接入 DNF 式花林门派整屏背景")
	_check(local_area.is_painted_stage_stack_active(), "花间派局部横版舞台应走整屏贴图优先分支")
	_check(local_area.scene_midground_layer_texture != null and local_area.scene_floor_layer_texture != null, "花间派应加载门派庭院中景和地面贴图层")
	_check(GameData.get_stage_layer_path("flower_sect", "floor").ends_with("flower_sect_dnf_garden_floor_v1.png"), "花间派应映射门派庭院地面贴图层")
	var flower_floor_layer := GameData.load_texture(GameData.get_stage_layer_path("flower_sect", "floor"), true)
	var flower_midground_layer := GameData.load_texture(GameData.get_stage_layer_path("flower_sect", "midground"), true)
	var flower_foreground_layer := GameData.load_texture(GameData.get_stage_layer_path("flower_sect", "foreground"), true)
	_check(flower_floor_layer != null and flower_floor_layer.get_size().x >= 1600.0 and flower_floor_layer.get_size().y >= 900.0, "花间派地面层应具备横版舞台分辨率")
	_check(flower_midground_layer != null and flower_floor_layer != null and flower_midground_layer.get_size() == flower_floor_layer.get_size(), "花间派中景层应与地面层同尺寸对齐")
	_check(flower_foreground_layer != null and flower_floor_layer != null and flower_foreground_layer.get_size() == flower_floor_layer.get_size(), "花间派前景层应与地面层同尺寸对齐")

	local_area.setup_region(GameData.get_region("emei_sacred"))
	await get_tree().process_frame
	_check(_tile_ratio(local_area, LOCAL_TILE_MOUNTAIN) < 0.32, "山地区域不应被山峰瓦片铺满")
	_check(local_area.is_position_walkable(local_area.get_entry_position("world")), "山地区域入口应可通行")

	test_root.queue_free()
	if failures.is_empty():
		print("PLAYTEST_SMOKE_OK")
		get_tree().quit(0)
	else:
		for message in failures:
			push_error(message)
		get_tree().quit(1)

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _ensure_input_actions() -> void:
	for action_name in ["move_right", "move_left", "move_down", "move_up"]:
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)

func _first_tile_with_id(map_node, tile_id: int) -> Vector2i:
	for y in range(map_node.map_height):
		for x in range(map_node.map_width):
			if int(map_node.tiles[y][x]) == tile_id:
				return Vector2i(x, y)
	return Vector2i.ZERO

func _first_portal(local_area, portal_type: String) -> Dictionary:
	for portal in local_area.portals:
		if str(portal.get("type", "")) == portal_type:
			return portal
	return {}

func _portal_count(local_area, portal_type: String) -> int:
	var count := 0
	for portal in local_area.portals:
		if str(portal.get("type", "")) == portal_type:
			count += 1
	return count

func _portal_label(local_area, portal_id: String) -> Label:
	for label in local_area.portal_labels:
		if is_instance_valid(label) and str(label.name) == portal_id:
			return label
	return null

func _tile_ratio(map_node, tile_id: int) -> float:
	var count := 0
	var total: int = max(1, int(map_node.map_width) * int(map_node.map_height))
	for y in range(map_node.map_height):
		for x in range(map_node.map_width):
			if int(map_node.tiles[y][x]) == tile_id:
				count += 1
	return float(count) / float(total)

func _texture_variant_count(map_node, tile_id: int) -> int:
	var variants = map_node.tile_textures.get(tile_id, [])
	if typeof(variants) == TYPE_ARRAY:
		return (variants as Array).size()
	return 0

func _textured_prop_count(nodes: Array) -> int:
	var count := 0
	for prop in nodes:
		if is_instance_valid(prop) and prop.prop_texture != null:
			count += 1
	return count

func _max_textured_actor_height(nodes: Array) -> float:
	var max_height := 0.0
	for actor in nodes:
		if not is_instance_valid(actor) or actor.sprite_node == null or actor.sprite_node.texture == null:
			continue
		var texture_size: Vector2 = actor.sprite_node.texture.get_size()
		max_height = maxf(max_height, texture_size.y * actor.sprite_node.scale.y)
	return max_height

func _textured_actor_height_by_name(nodes: Array, actor_name: String) -> float:
	for actor in nodes:
		if not is_instance_valid(actor) or str(actor.data.get("name", "")) != actor_name:
			continue
		if actor.sprite_node == null or actor.sprite_node.texture == null:
			return 0.0
		var texture_size: Vector2 = actor.sprite_node.texture.get_size()
		return texture_size.y * actor.sprite_node.scale.y
	return 0.0

func _actor_depth_scale_range(nodes: Array) -> float:
	var min_scale := INF
	var max_scale := -INF
	for actor in nodes:
		if not is_instance_valid(actor):
			continue
		if not actor.data.has("map_actor_scale"):
			continue
		var actor_scale := float(actor.data.get("map_actor_scale", 1.0))
		min_scale = minf(min_scale, actor_scale)
		max_scale = maxf(max_scale, actor_scale)
	if min_scale == INF:
		return 0.0
	return max_scale - min_scale

func _actors_have_idle_motion(nodes: Array) -> bool:
	for actor in nodes:
		if is_instance_valid(actor) and actor.visual_phase > 0.0:
			return true
	return false

func _actors_have_stage_rim(nodes: Array) -> bool:
	for actor in nodes:
		if not is_instance_valid(actor):
			continue
		if not bool(actor.data.get("stage_actor", false)):
			continue
		if actor.sprite_rim_node != null and actor.sprite_rim_node.visible:
			return true
	return false

func _actors_have_stage_pose_overlay(nodes: Array) -> bool:
	for actor in nodes:
		if not is_instance_valid(actor):
			continue
		if not bool(actor.data.get("stage_actor", false)):
			continue
		if actor.stage_pose_line_node != null and actor.stage_pose_line_node.visible and actor.stage_pose_line_node.points.size() >= 3:
			return true
	return false

func _actors_have_stage_body_overlays(nodes: Array) -> bool:
	for actor in nodes:
		if not is_instance_valid(actor):
			continue
		if not bool(actor.data.get("stage_actor", false)):
			continue
		var has_torso: bool = actor.stage_torso_line_node != null and actor.stage_torso_line_node.visible and actor.stage_torso_line_node.points.size() >= 3
		var has_sash: bool = actor.stage_sash_line_node != null and actor.stage_sash_line_node.visible and actor.stage_sash_line_node.points.size() >= 4
		var has_weapon_glow: bool = actor.stage_weapon_glow_node != null and actor.stage_weapon_glow_node.visible and actor.stage_weapon_glow_node.points.size() >= 2
		if has_torso and has_sash and has_weapon_glow:
			return true
	return false

func _actors_have_stage_activity(nodes: Array) -> bool:
	var seen := {}
	for actor in nodes:
		if not is_instance_valid(actor):
			continue
		if not bool(actor.data.get("stage_actor", false)):
			continue
		var activity := str(actor._stage_activity_type())
		if not activity.is_empty():
			seen[activity] = true
	return seen.size() >= 3

func _actors_have_stage_lane_anchor(nodes: Array) -> bool:
	for actor in nodes:
		if not is_instance_valid(actor):
			continue
		if not bool(actor.data.get("stage_actor", false)):
			continue
		if not actor.data.has("stage_lane_y") or not actor.data.has("stage_lane_offset_y"):
			continue
		if float(actor.data.get("stage_lane_strength", 0.0)) <= 0.0:
			continue
		if absf(float(actor._stage_lane_visual_offset())) <= NPC_SCRIPT.STAGE_LANE_MAX_VISUAL_OFFSET:
			return true
	return false

func _actors_face_stage_center(nodes: Array, center_x: float) -> bool:
	var checked := 0
	for actor in nodes:
		if not is_instance_valid(actor):
			continue
		if not bool(actor.data.get("stage_actor", false)):
			continue
		if not actor.data.has("stage_facing_side"):
			return false
		var side := float(actor._stage_facing_side())
		if actor.position.x < center_x - GameData.TILE_SIZE * 0.5 and side <= 0.0:
			return false
		if actor.position.x > center_x + GameData.TILE_SIZE * 0.5 and side >= 0.0:
			return false
		checked += 1
	return checked > 0

func _stage_labels_and_bubbles_clear_actor_heads(nodes: Array) -> bool:
	var checked := 0
	for actor in nodes:
		if not is_instance_valid(actor):
			continue
		if not bool(actor.data.get("stage_actor", false)):
			continue
		if actor.name_label == null:
			return false
		var map_scale := float(actor._map_actor_scale())
		if actor.name_label.position.y > -96.0 * map_scale:
			return false
		if float(actor._ambient_bubble_position().y) > -136.0 * map_scale:
			return false
		checked += 1
	return checked > 0

func _stage_role_scale_bonus() -> bool:
	var normal = NPC_SCRIPT.new()
	normal.data = {"stage_actor": true, "map_actor_scale": 1.0, "npc_type": "normal"}
	var master = NPC_SCRIPT.new()
	master.data = {"stage_actor": true, "map_actor_scale": 1.0, "npc_type": "master", "is_master": true}
	var enemy = NPC_SCRIPT.new()
	enemy.data = {"stage_actor": true, "map_actor_scale": 1.0, "npc_type": "enemy"}
	var normal_scale: float = normal._map_actor_scale()
	var master_scale: float = master._map_actor_scale()
	var enemy_scale: float = enemy._map_actor_scale()
	normal.free()
	master.free()
	enemy.free()
	return master_scale > normal_scale and enemy_scale > normal_scale

func _actors_marked_stage(nodes: Array) -> bool:
	if nodes.is_empty():
		return false
	for actor in nodes:
		if not is_instance_valid(actor):
			continue
		if not bool(actor.data.get("stage_actor", false)):
			return false
	return true

func _actors_use_y_sort(nodes: Array) -> bool:
	for actor in nodes:
		if not is_instance_valid(actor):
			continue
		if actor.z_index != int(actor.position.y):
			return false
	return true

func _min_actor_distance(nodes: Array) -> float:
	var min_distance := INF
	for i in range(nodes.size()):
		var a = nodes[i]
		if not is_instance_valid(a):
			continue
		for j in range(i + 1, nodes.size()):
			var b = nodes[j]
			if not is_instance_valid(b):
				continue
			min_distance = min(min_distance, a.position.distance_to(b.position))
	if min_distance == INF:
		return 999999.0
	return min_distance
