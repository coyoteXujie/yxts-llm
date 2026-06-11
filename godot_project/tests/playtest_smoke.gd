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
	_check(GameState.get_exploration_title_for_value(0) == "初到", "区域探索 0% 应显示初到阶段")
	_check(GameState.get_exploration_title_for_value(25) == "初识此地", "区域探索 25% 应显示初识阶段")
	_check(GameState.get_exploration_title_for_value(50) == "路熟半城", "区域探索 50% 应显示熟路阶段")
	var before_milestone_events := GameState.world_events.size()
	GameState.region_state["gongyi"] = {"discovered": true, "exploration": 20, "visited": []}
	_check(GameState.add_region_exploration("gongyi", 6) == 26, "区域探索增量应推进到跨阈值后的数值")
	var gongyi_state: Dictionary = GameState.get_region_state("gongyi")
	_check((gongyi_state.get("exploration_milestones", []) as Array).has(25), "首次跨过 25% 应记录区域探索阶段")
	_check(GameState.world_events.size() == before_milestone_events + 1 and GameState.get_world_event_summary(1).contains("初识此地"), "首次跨过探索阶段应写入江湖传闻")
	var after_first_milestone_events := GameState.world_events.size()
	_check(GameState.add_region_exploration("gongyi", 3) == 29, "同一阶段内继续探索仍应推进数值")
	_check(GameState.world_events.size() == after_first_milestone_events, "未跨过新探索阶段不应重复写入传闻")
	_check(GameState.add_region_exploration("gongyi", 21) == 50, "跨过下一阶段应推进到 50%")
	_check(GameState.world_events.size() == after_first_milestone_events + 1 and GameState.get_world_event_summary(1).contains("路熟半城"), "跨过 50% 应写入新的探索阶段传闻")
	var before_adventure_clues := GameState.get_adventure_clues(0).size()
	var adventure_clue := GameState.record_adventure_clue("smoke_hidden_path", "烟测试秘径", "用于验证奇遇线索可记录、去重并进入存档。", "qinghe", "smoke", "luoyang")
	_check(not adventure_clue.is_empty() and GameState.get_adventure_clues(0).size() == before_adventure_clues + 1, "奇遇线索应可记录到 GameState")
	_check(str(adventure_clue.get("target_region_id", "")) == "luoyang" and str(adventure_clue.get("target_region_name", "")) == "洛阳城", "奇遇线索应记录指向区域")
	GameState.record_adventure_clue("smoke_hidden_path", "烟测试秘径", "重复记录不应增加线索。", "qinghe", "smoke")
	_check(GameState.get_adventure_clues(0).size() == before_adventure_clues + 1, "重复奇遇线索不应膨胀列表")
	_check(not GameState.is_adventure_clue_resolved("smoke_hidden_path"), "新记录的奇遇线索默认不应标记完成")
	var resolved_adventure_clue := GameState.resolve_adventure_clue("smoke_hidden_path")
	_check(bool(resolved_adventure_clue.get("resolved", false)) and GameState.is_adventure_clue_resolved("smoke_hidden_path"), "奇遇线索应可标记为已追到")
	var save_snapshot := GameState.build_save_snapshot(GameState.player_position)
	_check((save_snapshot.get("adventure_clues", []) as Array).size() == GameState.get_adventure_clues(0).size(), "奇遇线索应写入存档快照")
	var saved_smoke_clue: Dictionary = {}
	for saved_clue in (save_snapshot.get("adventure_clues", []) as Array):
		if typeof(saved_clue) == TYPE_DICTIONARY and str((saved_clue as Dictionary).get("id", "")) == "smoke_hidden_path":
			saved_smoke_clue = saved_clue
	_check(bool(saved_smoke_clue.get("resolved", false)), "奇遇线索完成状态应写入存档快照")

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
	_check(PLAYER_SCRIPT.PLAYER_AXIS_FALLBACK_ENABLED, "玩家贴边移动应启用轴向滑步回退，避免不可走落点造成整步卡死")
	var fallback_axes: Array[Vector2] = player._movement_axis_fallback_order(Vector2(1.0, 1.0).normalized())
	_check(fallback_axes.size() == 2 and fallback_axes[0] == Vector2.RIGHT and fallback_axes[1] == Vector2.DOWN, "玩家对角移动受阻时应横向优先尝试滑步，再尝试纵向")
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
	_check(PLAYER_SCRIPT.PLAYER_STAGE_TURN_ACCENT_ALPHA >= 0.30, "玩家左右切向应有足够明显的转身动作提示层")
	_check(PLAYER_SCRIPT.PLAYER_STAGE_SIDE_PROFILE_ALPHA >= 0.30 and PLAYER_SCRIPT.PLAYER_STAGE_DIRECTIONAL_WEAPON_ALPHA >= 0.40, "玩家横版左右姿态应有独立侧身轮廓和兵器方向层")
	_check(PLAYER_SCRIPT.PLAYER_IDLE_REDRAW_INTERVAL >= 1.0 / 15.0, "玩家静止状态不应每帧重绘整套自绘层")
	_check(PLAYER_SCRIPT.PLAYER_MOVING_REDRAW_INTERVAL >= 1.0 / 35.0 and PLAYER_SCRIPT.PLAYER_MOVING_REDRAW_INTERVAL <= 1.0 / 24.0, "玩家移动状态应节流自绘动画，位置移动不应被每帧手绘层拖慢")
	_check(PLAYER_SCRIPT.PLAYER_TURN_REDRAW_INTERVAL <= 1.0 / 40.0, "玩家转身过渡应比普通移动保留更高的动画刷新")
	_check(PLAYER_SCRIPT.PLAYER_STAGE_TURN_TEXTURE_SWAP_PROGRESS > 0.35 and PLAYER_SCRIPT.PLAYER_STAGE_TURN_TEXTURE_SWAP_PROGRESS < 0.70, "玩家转身不应一开始就镜像底图，应先保留旧侧身压缩帧")
	_check(not PLAYER_SCRIPT.PLAYER_SPRITE_SOURCE_FACES_LEFT, "当前默认玩家源图按朝右资源处理，向右时不应镜像底图")
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
	_check(player._should_mirror_sprite_for_side(-1.0), "源图朝右时，向左应镜像底图")
	var turn_timer_left: float = player.turn_accent_timer
	player._update_lateral_facing(Vector2.UP)
	_check(player._facing_side() < 0.0 and player.turn_accent_timer == turn_timer_left, "玩家上/下移动不应重置最后横版朝向")
	player._update_lateral_facing(Vector2.RIGHT)
	_check(player.has_lateral_facing_side and player.lateral_facing_side > 0.0, "玩家向右输入应锁定横版朝右状态")
	_check(not player._should_mirror_sprite_for_side(1.0), "源图朝右时，向右不应镜像底图")
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
	var qinghe_shops := GameData.get_region_shop_ids(GameData.get_region("qinghe"))
	_check(qinghe_shops.size() == 5 and qinghe_shops[0] == "inn" and qinghe_shops.has("blacksmith"), "平安镇商铺清单应从数据默认小镇配置读取")
	var qinghe_landmarks := GameData.get_region_points("qinghe", "landmarks")
	var qinghe_resources := GameData.get_region_points("qinghe", "resources")
	_check(qinghe_landmarks.size() == 3 and str(qinghe_landmarks[0].get("label", "")) == "镇口告示", "平安镇地标应从区域兴趣点数据读取")
	_check(qinghe_resources.size() == 2 and str(qinghe_resources[0].get("reward_item", "")) == "item_red_flower", "平安镇资源点应从区域兴趣点数据读取")
	var linan_shops := GameData.get_region_shop_ids(GameData.get_region("linan"))
	var linan_landmarks := GameData.get_region_points("linan", "landmarks")
	var linan_resources := GameData.get_region_points("linan", "resources")
	_check(linan_shops.size() == 6 and linan_shops[1] == "teahouse" and linan_shops.has("blacksmith"), "临安商铺清单应使用水城覆盖配置")
	_check(linan_landmarks.size() == 2 and linan_resources.size() == 3, "临安水城地标和资源点应从区域兴趣点数据读取")
	var chengdu_shops := GameData.get_region_shop_ids(GameData.get_region("chengdu"))
	var chengdu_landmarks := GameData.get_region_points("chengdu", "landmarks")
	var chengdu_resources := GameData.get_region_points("chengdu", "resources")
	_check(chengdu_shops.size() == 6 and chengdu_shops[0] == "inn" and chengdu_shops.has("teahouse"), "成都商铺清单应使用天府城池覆盖配置")
	_check(chengdu_landmarks.size() == 3 and str(chengdu_landmarks[0].get("label", "")) == "天府药市", "成都地标应从天府药市兴趣点数据读取")
	_check(chengdu_resources.size() == 3 and str(chengdu_resources[1].get("reward_item", "")) == "item_wine", "成都资源点应从药市/茶肆/水渠数据读取")
	var dujiang_landmarks := GameData.get_region_points("dujiang_weir", "landmarks")
	var dujiang_resources := GameData.get_region_points("dujiang_weir", "resources")
	_check(dujiang_landmarks.size() == 3 and str(dujiang_landmarks[0].get("label", "")) == "飞沙分水堰", "都江古堰地标应从水工古堰兴趣点数据读取")
	_check(dujiang_resources.size() == 3 and str(dujiang_resources[0].get("reward_item", "")) == "item_fish", "都江古堰资源点应从水渠/水工棚数据读取")
	var minjiang_landmarks := GameData.get_region_points("minjiang_river", "landmarks")
	var minjiang_resources := GameData.get_region_points("minjiang_river", "resources")
	_check(minjiang_landmarks.size() == 3 and str(minjiang_landmarks[0].get("label", "")) == "岷江索桥", "岷江河谷地标应从河谷渡口兴趣点数据读取")
	_check(minjiang_resources.size() == 3 and str(minjiang_resources[0].get("reward_item", "")) == "item_fish", "岷江河谷资源点应从浅湾鱼篓/河滩药草数据读取")
	var shudao_landmarks := GameData.get_region_points("shudao_mtn", "landmarks")
	var shudao_resources := GameData.get_region_points("shudao_mtn", "resources")
	_check(shudao_landmarks.size() == 3 and str(shudao_landmarks[0].get("label", "")) == "蜀道栈关", "蜀道群山地标应从栈关/绝壁栈道兴趣点数据读取")
	_check(shudao_resources.size() == 3 and str(shudao_resources[1].get("reward_item", "")) == "item_baozi", "蜀道群山资源点应从崖缝药草/栈道补给箱数据读取")
	var xindu_landmarks := GameData.get_region_points("xindu_field", "landmarks")
	var xindu_resources := GameData.get_region_points("xindu_field", "resources")
	_check(xindu_landmarks.size() == 3 and str(xindu_landmarks[0].get("label", "")) == "连片稻田", "新都平原地标应从稻田/古道驿站兴趣点数据读取")
	_check(xindu_resources.size() == 3 and str(xindu_resources[1].get("reward_item", "")) == "item_yao", "新都平原资源点应从田埂稻束/林间草药数据读取")
	var wenjiang_landmarks := GameData.get_region_points("wenjiang_garden", "landmarks")
	var wenjiang_resources := GameData.get_region_points("wenjiang_garden", "resources")
	_check(wenjiang_landmarks.size() == 3 and str(wenjiang_landmarks[0].get("label", "")) == "四季花田", "温江花田地标应从花田/花商小棚兴趣点数据读取")
	_check(wenjiang_resources.size() == 3 and str(wenjiang_resources[1].get("reward_item", "")) == "item_red_flower", "温江花田资源点应从花种/花田草药数据读取")
	var western_landmarks := GameData.get_region_points("western_plateau", "landmarks")
	var western_resources := GameData.get_region_points("western_plateau", "resources")
	_check(western_landmarks.size() == 3 and str(western_landmarks[0].get("label", "")) == "高原古寺", "西岭高原地标应从古寺/冰洞/神坛兴趣点数据读取")
	_check(western_resources.size() == 3 and str(western_resources[1].get("kind", "")) == "ore", "西岭高原资源点应从高原草药/雪线寒石数据读取")
	var funiu_landmarks := GameData.get_region_points("funiu_mtn", "landmarks")
	var funiu_resources := GameData.get_region_points("funiu_mtn", "resources")
	_check(funiu_landmarks.size() == 3 and str(funiu_landmarks[0].get("label", "")) == "伏牛古矿洞", "伏牛山地标应从古矿洞/密林入口/山顶神坛兴趣点数据读取")
	_check(funiu_resources.size() == 3 and str(funiu_resources[1].get("kind", "")) == "ore", "伏牛山资源点应从草药/寒铁矿脉/山阴老参数据读取")
	var wudang_landmarks := GameData.get_region_points("wudang_peak", "landmarks")
	var wudang_resources := GameData.get_region_points("wudang_peak", "resources")
	_check(wudang_landmarks.size() == 3 and str(wudang_landmarks[0].get("label", "")) == "武当金顶", "武当山地标应从金顶/演武台/后山隐径兴趣点数据读取")
	_check(wudang_resources.size() == 3 and str(wudang_resources[1].get("reward_item", "")) == "item_red_flower", "武当山资源点应从古松松脂/金顶仙草数据读取")
	var three_gorges_landmarks := GameData.get_region_points("three_gorges", "landmarks")
	var three_gorges_resources := GameData.get_region_points("three_gorges", "resources")
	_check(three_gorges_landmarks.size() == 3 and str(three_gorges_landmarks[0].get("label", "")) == "瞿塘古栈道", "三峡险滩地标应从古栈道/云渡/险滩兴趣点数据读取")
	_check(three_gorges_resources.size() == 3 and str(three_gorges_resources[0].get("reward_item", "")) == "item_fish", "三峡险滩资源点应从江滩鱼篓/峡畔草药数据读取")
	var yiling_landmarks := GameData.get_region_points("yiling_gap", "landmarks")
	var yiling_resources := GameData.get_region_points("yiling_gap", "resources")
	_check(yiling_landmarks.size() == 3 and str(yiling_landmarks[2].get("label", "")) == "瀑布水帘", "夷陵峡谷地标应从峡谷密室/隐蔽山谷/瀑布水帘兴趣点数据读取")
	_check(yiling_resources.size() == 3 and str(yiling_resources[1].get("kind", "")) == "ore", "夷陵峡谷资源点应从峡谷草药/崖壁铁矿/峡谷山参数据读取")
	var dangyang_landmarks := GameData.get_region_points("dangyang_plain", "landmarks")
	var dangyang_resources := GameData.get_region_points("dangyang_plain", "resources")
	_check(dangyang_landmarks.size() == 3 and str(dangyang_landmarks[0].get("label", "")) == "三国古战场", "当阳平原地标应从古战场/古墓/古道驿站兴趣点数据读取")
	_check(dangyang_resources.size() == 3 and str(dangyang_resources[1].get("reward_item", "")) == "item_yao", "当阳平原资源点应从稻米/草药/古战场遗物数据读取")
	var hanjiang_landmarks := GameData.get_region_points("hanjiang_river", "landmarks")
	var hanjiang_resources := GameData.get_region_points("hanjiang_river", "resources")
	_check(hanjiang_landmarks.size() == 3 and str(hanjiang_landmarks[0].get("label", "")) == "汉江古渡", "汉江地标应从古渡/沙洲密室/江底洞穴兴趣点数据读取")
	_check(hanjiang_resources.size() == 3 and str(hanjiang_resources[0].get("reward_item", "")) == "item_fish", "汉江资源点应从汉江鲤鱼/江畔草药/汉江古物数据读取")
	var yunmeng_landmarks := GameData.get_region_points("yunmeng_marsh", "landmarks")
	var yunmeng_resources := GameData.get_region_points("yunmeng_marsh", "resources")
	_check(yunmeng_landmarks.size() == 3 and str(yunmeng_landmarks[1].get("label", "")) == "水贼巢穴", "云梦泽地标应从古泽/水贼巢穴/沼泽密室兴趣点数据读取")
	_check(yunmeng_resources.size() == 3 and str(yunmeng_resources[1].get("reward_item", "")) == "item_yao", "云梦泽资源点应从莲藕/草药/河蚌珠壳数据读取")
	var daba_landmarks := GameData.get_region_points("daba_mtn", "landmarks")
	var daba_resources := GameData.get_region_points("daba_mtn", "resources")
	_check(daba_landmarks.size() == 3 and str(daba_landmarks[0].get("label", "")) == "大巴古矿洞", "大巴山地标应从古矿洞/山顶神坛/山间暗道兴趣点数据读取")
	_check(daba_resources.size() == 3 and str(daba_resources[1].get("kind", "")) == "ore", "大巴山资源点应从草药/铜矿/山参数据读取")
	var shennong_landmarks := GameData.get_region_points("shennongjia", "landmarks")
	var shennong_resources := GameData.get_region_points("shennongjia", "resources")
	_check(shennong_landmarks.size() == 3 and str(shennong_landmarks[0].get("label", "")) == "神农百草谷", "神农架地标应从百草谷/洞穴/林心兴趣点数据读取")
	_check(shennong_resources.size() == 3 and str(shennong_resources[1].get("reward_item", "")) == "item_shengji", "神农架资源点应从神农草药/神农山参数据读取")
	var qingcheng_landmarks := GameData.get_region_points("qingcheng_mtn", "landmarks")
	var qingcheng_resources := GameData.get_region_points("qingcheng_mtn", "resources")
	_check(qingcheng_landmarks.size() == 3 and str(qingcheng_landmarks[0].get("label", "")) == "青城山门", "青城山地标应从道观山门兴趣点数据读取")
	_check(qingcheng_resources.size() == 3 and str(qingcheng_resources[1].get("reward_item", "")) == "item_yao", "青城山资源点应从松根药草/道童香囊数据读取")
	var emei_landmarks := GameData.get_region_points("emei_sacred", "landmarks")
	var emei_resources := GameData.get_region_points("emei_sacred", "resources")
	_check(emei_landmarks.size() == 3 and str(emei_landmarks[0].get("label", "")) == "金顶山寺", "峨眉圣山地标应从云海金顶兴趣点数据读取")
	_check(emei_resources.size() == 3 and str(emei_resources[1].get("reward_item", "")) == "item_red_flower", "峨眉圣山资源点应从山寺药箱/云雾灵草数据读取")
	var jiangling_shops := GameData.get_region_shop_ids(GameData.get_region("jiangling"))
	var jiangling_landmarks := GameData.get_region_points("jiangling", "landmarks")
	var jiangling_resources := GameData.get_region_points("jiangling", "resources")
	_check(jiangling_shops.size() == 5 and jiangling_shops[0] == "inn" and jiangling_shops.has("tailor"), "江陵商铺清单应使用荆楚城池覆盖配置")
	_check(jiangling_landmarks.size() == 3 and str(jiangling_landmarks[0].get("label", "")) == "江防码头", "江陵地标应从区域兴趣点数据读取")
	_check(jiangling_resources.size() == 3 and str(jiangling_resources[1].get("reward_item", "")) == "item_yao", "江陵资源点应从区域兴趣点数据读取")
	var luoshui_landmarks := GameData.get_region_points("luoshui_river", "landmarks")
	var luoshui_resources := GameData.get_region_points("luoshui_river", "resources")
	_check(luoshui_landmarks.size() == 3 and str(luoshui_landmarks[0].get("label", "")) == "洛水拱桥", "洛水河畔地标应从区域兴趣点数据读取")
	_check(luoshui_resources.size() == 3 and str(luoshui_resources[0].get("reward_item", "")) == "item_fish", "洛水河畔资源点应从区域兴趣点数据读取")
	var flower_shops := GameData.get_region_shop_ids(GameData.get_region("flower_sect"))
	var flower_landmarks := GameData.get_region_points("flower_sect", "landmarks")
	var flower_resources := GameData.get_region_points("flower_sect", "resources")
	_check(flower_shops.size() == 2 and flower_shops.has("medicine") and flower_shops.has("market"), "门派商铺清单应从数据默认门派配置读取")
	_check(flower_landmarks.size() == 2 and flower_resources.size() == 2, "花间派地标和补给点应从区域兴趣点数据读取")
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
	_check(_portal_count(local_area, "shop") == qinghe_shops.size(), "平安镇应按数据商铺清单生成商铺入口")
	_check(_portal_count(local_area, "landmark") == qinghe_landmarks.size() and _portal_count(local_area, "resource") == qinghe_resources.size(), "平安镇应按数据兴趣点生成地标和资源入口")
	_check(_portal_count(local_area, "hidden_clue") == 0, "探索度不足时平安镇不应提前生成隐藏线索入口")
	GameState.region_state["qinghe"] = {"discovered": true, "exploration": 75, "visited": [], "exploration_milestones": [25, 50, 75]}
	local_area.setup_region(GameData.get_region("qinghe"))
	await get_tree().process_frame
	_check(_portal_count(local_area, "shop") == qinghe_shops.size(), "高探索重建区域后商铺入口数量应保持稳定")
	_check(_portal_count(local_area, "landmark") == qinghe_landmarks.size() and _portal_count(local_area, "resource") == qinghe_resources.size(), "高探索隐藏入口不应混入地标或资源计数")
	_check(_portal_count(local_area, "hidden_clue") == 1, "探索达到寻幽探隐后应生成隐藏线索入口")
	var hidden_clue_portal := _first_portal(local_area, "hidden_clue")
	_check(not hidden_clue_portal.is_empty() and str(hidden_clue_portal.get("action_label", "")) == "追查" and str(hidden_clue_portal.get("interaction_hint", "")) == "隐线", "隐藏线索入口应带追查动作和隐线类型提示")
	if not hidden_clue_portal.is_empty():
		var hidden_clue_label := _portal_label(local_area, str(hidden_clue_portal.get("id", "")))
		_check(hidden_clue_label != null and hidden_clue_label.text.contains("追查") and hidden_clue_label.text.contains(str(hidden_clue_portal.get("label", ""))), "隐藏线索标签应展示追查动作和线索名")
	GameState.region_state.erase("qinghe")
	local_area.setup_region(GameData.get_region("qinghe"))
	await get_tree().process_frame
	_check(local_area.scene_background_texture != null, "局部地图应加载区域水墨氛围背景")
	_check(GameData.get_scene_background_path("qinghe").ends_with("scene_qinghe_dnf_town_v2.png"), "清河镇应接入高细节 v2 DNF 式横版城镇整屏背景")
	var qinghe_background_texture := GameData.load_texture(GameData.get_scene_background_path("qinghe"), true)
	_check(qinghe_background_texture != null and qinghe_background_texture.get_size().x >= 1600.0 and qinghe_background_texture.get_size().y >= 900.0, "清河镇 v2 背景应具备横版舞台分辨率")
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
	_check(GameData.get_stage_layer_path("qinghe", "floor").ends_with("qinghe_dnf_floor_v2.png"), "清河镇应映射 v2 DNF 式横版地面贴图层")
	var qinghe_floor_layer := GameData.load_texture(GameData.get_stage_layer_path("qinghe", "floor"), true)
	_check(qinghe_floor_layer != null and qinghe_floor_layer.get_size().x >= 1600.0 and qinghe_floor_layer.get_size().y >= 900.0, "清河镇地面贴图层应具备横版舞台分辨率")
	_check(GameData.get_stage_layer_path("qinghe", "midground").ends_with("qinghe_dnf_shopfronts_v2.png"), "清河镇应映射高细节 v2 DNF 式横版店铺中景层")
	var qinghe_midground_layer := GameData.load_texture(GameData.get_stage_layer_path("qinghe", "midground"), true)
	_check(qinghe_midground_layer != null and qinghe_midground_layer.get_size().x >= 1600.0 and qinghe_midground_layer.get_size().y >= 900.0, "清河镇店铺中景层应具备横版舞台分辨率")
	_check(GameData.get_stage_layer_path("qinghe", "foreground").ends_with("qinghe_dnf_foreground_v2.png"), "清河镇应映射高细节 v2 DNF 式横版前景遮挡层")
	var qinghe_foreground_layer := GameData.load_texture(GameData.get_stage_layer_path("qinghe", "foreground"), true)
	_check(qinghe_foreground_layer != null and qinghe_foreground_layer.get_size().x >= 1600.0 and qinghe_foreground_layer.get_size().y >= 900.0, "清河镇前景遮挡层应具备横版舞台分辨率")
	_check(qinghe_midground_layer != null and qinghe_floor_layer != null and qinghe_midground_layer.get_size() == qinghe_floor_layer.get_size(), "清河镇同源城镇中景和地面层应同尺寸对齐")
	_check(qinghe_foreground_layer != null and qinghe_floor_layer != null and qinghe_foreground_layer.get_size() == qinghe_floor_layer.get_size(), "清河镇同源城镇前景和地面层应同尺寸对齐")
	_check(qinghe_background_texture != null and qinghe_floor_layer != null and qinghe_background_texture.get_size() == qinghe_floor_layer.get_size(), "清河镇 v2 背景和舞台层应同尺寸对齐")
	_check(GameData.get_stage_layer_source_region_id("changan") == "changan", "长安应使用专属西市三层舞台资产")
	_check(GameData.get_stage_layer_source_region_id("chengdu") == "chengdu", "成都应使用专属天府药市三层舞台资产")
	_check(GameData.get_stage_layer_source_region_id("jiangling") == "jiangling", "江陵应使用专属江防码头三层舞台资产")
	_check(GameData.get_stage_layer_source_region_id("luoshui_river") == "luoshui_river", "洛水河畔应使用专属水岸桥景三层舞台资产")
	_check(GameData.get_stage_layer_source_region_id("shaoxing_water") == "linan", "水巷/运河区域应复用水城三层舞台资产")
	_check(GameData.get_stage_layer_source_region_id("wuyi_for") == "bashu_bamboo", "林地区域应复用竹林三层舞台资产")
	_check(GameData.get_stage_layer_source_region_id("xueshan_sect") == "beiling_mtn", "雪山门派应复用山道三层舞台资产")
	_check(GameData.get_stage_layer_source_region_id("taiji_sect") == "flower_sect", "没有专属舞台层的普通门派应复用门派庭院三层舞台资产")
	_check(GameData.get_stage_layer_source_region_id("dujiang_weir") == "dujiang_weir", "都江古堰应使用专属水工古堰三层舞台资产")
	_check(GameData.get_scene_background_path("minjiang_river").ends_with("scene_minjiang_river_dnf_valley_v1.png"), "岷江河谷应接入专属河谷横版整屏背景")
	_check(GameData.get_stage_layer_source_region_id("minjiang_river") == "minjiang_river", "岷江河谷应使用专属河谷三层舞台资产")
	_check(GameData.get_stage_layer_path("minjiang_river", "floor").ends_with("minjiang_river_dnf_floor_v1.png"), "岷江河谷应映射河滩地面贴图层")
	var minjiang_floor_layer := GameData.load_texture(GameData.get_stage_layer_path("minjiang_river", "floor"), true)
	_check(minjiang_floor_layer != null and minjiang_floor_layer.get_size().x >= 1600.0 and minjiang_floor_layer.get_size().y >= 900.0, "岷江河谷地面贴图层应具备横版舞台分辨率")
	_check(GameData.get_scene_background_path("shudao_mtn").ends_with("scene_shudao_mtn_dnf_cliff_road_v1.png"), "蜀道群山应接入专属悬崖栈道整屏背景")
	_check(GameData.get_stage_layer_source_region_id("shudao_mtn") == "shudao_mtn", "蜀道群山应使用专属悬崖栈道三层舞台资产")
	_check(GameData.get_stage_layer_path("shudao_mtn", "midground").ends_with("shudao_mtn_dnf_midground_v1.png"), "蜀道群山应映射栈关中景贴图层")
	var shudao_midground_layer := GameData.load_texture(GameData.get_stage_layer_path("shudao_mtn", "midground"), true)
	_check(shudao_midground_layer != null and shudao_midground_layer.get_size().x >= 1600.0 and shudao_midground_layer.get_size().y >= 900.0, "蜀道群山中景贴图层应具备横版舞台分辨率")
	_check(GameData.get_scene_background_path("xindu_field").ends_with("scene_xindu_field_dnf_farmland_v1.png"), "新都平原应接入专属稻田村舍横版整屏背景")
	_check(GameData.get_stage_layer_source_region_id("xindu_field") == "xindu_field", "新都平原应使用专属稻田村舍三层舞台资产")
	_check(GameData.get_stage_layer_path("xindu_field", "foreground").ends_with("xindu_field_dnf_foreground_v1.png"), "新都平原应映射田埂前景遮挡层")
	var xindu_foreground_layer := GameData.load_texture(GameData.get_stage_layer_path("xindu_field", "foreground"), true)
	_check(xindu_foreground_layer != null and xindu_foreground_layer.get_size().x >= 1600.0 and xindu_foreground_layer.get_size().y >= 900.0, "新都平原前景贴图层应具备横版舞台分辨率")
	_check(GameData.get_scene_background_path("wenjiang_garden").ends_with("scene_wenjiang_garden_dnf_flower_fields_v1.png"), "温江花田应接入专属花田横版整屏背景")
	_check(GameData.get_stage_layer_source_region_id("wenjiang_garden") == "wenjiang_garden", "温江花田应使用专属花田三层舞台资产")
	_check(GameData.get_stage_layer_path("wenjiang_garden", "floor").ends_with("wenjiang_garden_dnf_floor_v1.png"), "温江花田应映射花田小径地面贴图层")
	var wenjiang_floor_layer := GameData.load_texture(GameData.get_stage_layer_path("wenjiang_garden", "floor"), true)
	_check(wenjiang_floor_layer != null and wenjiang_floor_layer.get_size().x >= 1600.0 and wenjiang_floor_layer.get_size().y >= 900.0, "温江花田地面贴图层应具备横版舞台分辨率")
	_check(GameData.get_scene_background_path("western_plateau").ends_with("scene_western_plateau_dnf_snow_v1.png"), "西岭高原应接入专属雪山高原横版整屏背景")
	_check(GameData.get_stage_layer_source_region_id("western_plateau") == "western_plateau", "西岭高原应使用专属雪山高原三层舞台资产")
	_check(GameData.get_stage_layer_path("western_plateau", "midground").ends_with("western_plateau_dnf_midground_v1.png"), "西岭高原应映射古寺冰洞中景贴图层")
	var western_midground_layer := GameData.load_texture(GameData.get_stage_layer_path("western_plateau", "midground"), true)
	_check(western_midground_layer != null and western_midground_layer.get_size().x >= 1600.0 and western_midground_layer.get_size().y >= 900.0, "西岭高原中景贴图层应具备横版舞台分辨率")
	_check(GameData.get_scene_background_path("funiu_mtn").ends_with("scene_funiu_mtn_dnf_forest_mine_v1.png"), "伏牛山应接入专属密林古矿横版整屏背景")
	_check(GameData.get_stage_layer_source_region_id("funiu_mtn") == "funiu_mtn", "伏牛山应使用专属密林古矿三层舞台资产")
	_check(GameData.get_stage_layer_path("funiu_mtn", "midground").ends_with("funiu_mtn_dnf_midground_v1.png"), "伏牛山应映射矿洞瀑布密林中景贴图层")
	var funiu_midground_layer := GameData.load_texture(GameData.get_stage_layer_path("funiu_mtn", "midground"), true)
	_check(funiu_midground_layer != null and funiu_midground_layer.get_size().x >= 1600.0 and funiu_midground_layer.get_size().y >= 900.0, "伏牛山中景贴图层应具备横版舞台分辨率")
	_check(GameData.get_scene_background_path("wudang_peak").ends_with("scene_wudang_peak_dnf_golden_summit_v1.png"), "武当山应接入专属金顶道观横版整屏背景")
	_check(GameData.get_stage_layer_source_region_id("wudang_peak") == "wudang_peak", "武当山应使用专属金顶道观三层舞台资产")
	_check(GameData.get_stage_layer_path("wudang_peak", "foreground").ends_with("wudang_peak_dnf_foreground_v1.png"), "武当山应映射云海栏杆前景遮挡层")
	var wudang_foreground_layer := GameData.load_texture(GameData.get_stage_layer_path("wudang_peak", "foreground"), true)
	_check(wudang_foreground_layer != null and wudang_foreground_layer.get_size().x >= 1600.0 and wudang_foreground_layer.get_size().y >= 900.0, "武当山前景贴图层应具备横版舞台分辨率")
	_check(GameData.get_scene_background_path("three_gorges").ends_with("scene_three_gorges_dnf_rapids_v1.png"), "三峡险滩应接入专属峡谷急流横版整屏背景")
	_check(GameData.get_stage_layer_source_region_id("three_gorges") == "three_gorges", "三峡险滩应使用专属峡谷急流三层舞台资产")
	_check(GameData.get_stage_layer_path("three_gorges", "midground").ends_with("three_gorges_dnf_midground_v1.png"), "三峡险滩应映射峭壁古栈道中景贴图层")
	var three_gorges_midground_layer := GameData.load_texture(GameData.get_stage_layer_path("three_gorges", "midground"), true)
	_check(three_gorges_midground_layer != null and three_gorges_midground_layer.get_size().x >= 1600.0 and three_gorges_midground_layer.get_size().y >= 900.0, "三峡险滩中景贴图层应具备横版舞台分辨率")
	_check(GameData.get_scene_background_path("yiling_gap").ends_with("scene_yiling_gap_dnf_canyon_gate_v1.png"), "夷陵峡谷应接入专属峡谷入口横版整屏背景")
	_check(GameData.get_stage_layer_source_region_id("yiling_gap") == "yiling_gap", "夷陵峡谷应使用专属峡谷入口三层舞台资产")
	_check(GameData.get_stage_layer_path("yiling_gap", "midground").ends_with("yiling_gap_dnf_midground_v1.png"), "夷陵峡谷应映射峭壁水帘中景贴图层")
	var yiling_midground_layer := GameData.load_texture(GameData.get_stage_layer_path("yiling_gap", "midground"), true)
	_check(yiling_midground_layer != null and yiling_midground_layer.get_size().x >= 1600.0 and yiling_midground_layer.get_size().y >= 900.0, "夷陵峡谷中景贴图层应具备横版舞台分辨率")
	_check(GameData.get_scene_background_path("dangyang_plain").ends_with("scene_dangyang_plain_dnf_battlefield_v1.png"), "当阳平原应接入专属古战场官道横版整屏背景")
	_check(GameData.get_stage_layer_source_region_id("dangyang_plain") == "dangyang_plain", "当阳平原应使用专属古战场官道三层舞台资产")
	_check(GameData.get_stage_layer_path("dangyang_plain", "midground").ends_with("dangyang_plain_dnf_midground_v1.png"), "当阳平原应映射废驿站古战场中景贴图层")
	var dangyang_midground_layer := GameData.load_texture(GameData.get_stage_layer_path("dangyang_plain", "midground"), true)
	_check(dangyang_midground_layer != null and dangyang_midground_layer.get_size().x >= 1600.0 and dangyang_midground_layer.get_size().y >= 900.0, "当阳平原中景贴图层应具备横版舞台分辨率")
	_check(GameData.get_scene_background_path("hanjiang_river").ends_with("scene_hanjiang_river_dnf_clear_ferry_v1.png"), "汉江应接入专属清江古渡横版整屏背景")
	_check(GameData.get_stage_layer_source_region_id("hanjiang_river") == "hanjiang_river", "汉江应使用专属清江古渡三层舞台资产")
	_check(GameData.get_stage_layer_path("hanjiang_river", "foreground").ends_with("hanjiang_river_dnf_foreground_v1.png"), "汉江应映射芦苇柳岸前景遮挡层")
	var hanjiang_foreground_layer := GameData.load_texture(GameData.get_stage_layer_path("hanjiang_river", "foreground"), true)
	_check(hanjiang_foreground_layer != null and hanjiang_foreground_layer.get_size().x >= 1600.0 and hanjiang_foreground_layer.get_size().y >= 900.0, "汉江前景贴图层应具备横版舞台分辨率")
	_check(GameData.get_scene_background_path("yunmeng_marsh").ends_with("scene_yunmeng_marsh_dnf_mist_v1.png"), "云梦泽应接入专属迷雾沼泽横版整屏背景")
	_check(GameData.get_stage_layer_source_region_id("yunmeng_marsh") == "yunmeng_marsh", "云梦泽应使用专属迷雾沼泽三层舞台资产")
	_check(GameData.get_stage_layer_path("yunmeng_marsh", "foreground").ends_with("yunmeng_marsh_dnf_foreground_v1.png"), "云梦泽应映射芦苇毒雾前景遮挡层")
	var yunmeng_foreground_layer := GameData.load_texture(GameData.get_stage_layer_path("yunmeng_marsh", "foreground"), true)
	_check(yunmeng_foreground_layer != null and yunmeng_foreground_layer.get_size().x >= 1600.0 and yunmeng_foreground_layer.get_size().y >= 900.0, "云梦泽前景贴图层应具备横版舞台分辨率")
	_check(GameData.get_scene_background_path("daba_mtn").ends_with("scene_daba_mtn_dnf_mine_peak_v1.png"), "大巴山应接入专属深山矿道横版整屏背景")
	_check(GameData.get_stage_layer_source_region_id("daba_mtn") == "daba_mtn", "大巴山应使用专属深山矿道三层舞台资产")
	_check(GameData.get_stage_layer_path("daba_mtn", "midground").ends_with("daba_mtn_dnf_midground_v1.png"), "大巴山应映射古矿洞瀑布神坛中景贴图层")
	var daba_midground_layer := GameData.load_texture(GameData.get_stage_layer_path("daba_mtn", "midground"), true)
	_check(daba_midground_layer != null and daba_midground_layer.get_size().x >= 1600.0 and daba_midground_layer.get_size().y >= 900.0, "大巴山中景贴图层应具备横版舞台分辨率")
	_check(GameData.get_scene_background_path("shennongjia").ends_with("scene_shennongjia_dnf_ancient_forest_v1.png"), "神农架应接入专属原始森林横版整屏背景")
	_check(GameData.get_stage_layer_source_region_id("shennongjia") == "shennongjia", "神农架应使用专属原始森林三层舞台资产")
	_check(GameData.get_stage_layer_path("shennongjia", "midground").ends_with("shennongjia_dnf_midground_v1.png"), "神农架应映射巨木洞穴瀑布中景贴图层")
	var shennong_midground_layer := GameData.load_texture(GameData.get_stage_layer_path("shennongjia", "midground"), true)
	_check(shennong_midground_layer != null and shennong_midground_layer.get_size().x >= 1600.0 and shennong_midground_layer.get_size().y >= 900.0, "神农架中景贴图层应具备横版舞台分辨率")
	_check(GameData.get_stage_layer_source_region_id("qingcheng_mtn") == "qingcheng_mtn", "青城山应使用专属道观山门三层舞台资产")
	_check(GameData.get_stage_layer_source_region_id("emei_sacred") == "emei_sacred", "峨眉圣山应使用专属云海金顶三层舞台资产")
	var required_stage_layer_names := ["floor", "midground", "foreground"]
	for region in GameData.get_regions():
		var checked_region_id := str(region.get("id", ""))
		for layer_name in required_stage_layer_names:
			_check(not GameData.get_stage_layer_path(checked_region_id, str(layer_name)).is_empty(), "所有区域都应通过专属或同类复用拿到横版舞台%s层：%s" % [str(layer_name), checked_region_id])
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
	GameState.region_state["changan"] = {"discovered": true, "exploration": 25, "visited": [], "exploration_milestones": [25]}
	var changan_base_plan := GameState.build_region_travel_plan("changan")
	GameState.region_state["changan"] = {"discovered": true, "exploration": 75, "visited": [], "exploration_milestones": [25, 50, 75]}
	var changan_familiar_plan := GameState.build_region_travel_plan("changan")
	_check(str(changan_familiar_plan.get("familiarity_note", "")).contains("寻幽探隐"), "高探索区域驿路计划应显示熟路加成")
	_check(float(changan_familiar_plan.get("hours", 0.0)) <= float(changan_base_plan.get("hours", 0.0)), "高探索区域驿路耗时不应高于低探索基准")
	_check(int(changan_familiar_plan.get("fare", 0)) <= int(changan_base_plan.get("fare", 0)), "高探索区域驿路费用不应高于低探索基准")
	_check(int(changan_familiar_plan.get("risk_level", 0)) <= int(changan_base_plan.get("risk_level", 0)), "高探索区域驿路风险不应高于低探索基准")
	_check(float(changan_familiar_plan.get("hours", 0.0)) < float(changan_base_plan.get("hours", 0.0)) or int(changan_familiar_plan.get("fare", 0)) < int(changan_base_plan.get("fare", 0)), "高探索区域应至少降低驿路耗时或费用")
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
	_check(PLAYER_SCRIPT.PLAYER_STAGE_DIRECTIONAL_POSE_ENABLED, "玩家横版朝向应启用独立方向姿态状态，而不是只做贴图镜像")
	player._update_lateral_facing(Vector2.LEFT)
	_check(player.get_stage_turn_strength() > 0.75 and player.stage_turn_from_side > 0.0 and player.stage_turn_to_side < 0.0, "玩家横向反向输入应记录旧方向和目标方向，进入独立转身姿态")
	_check(player._stage_draw_facing_side() > 0.0, "玩家转身起手应先保留旧侧身压缩帧，而不是立即镜像到底图新方向")
	var turn_width_scale := player.get_stage_pose_width_scale(true)
	_check(turn_width_scale >= PLAYER_SCRIPT.PLAYER_STAGE_TURN_SQUASH_MIN and turn_width_scale < 1.0, "玩家转身时应压缩侧身宽度形成转身帧，而不是静态镜像")
	_check(absf(player.get_stage_pose_x_offset(100.0, -1.0)) > 1.0, "玩家转身时应产生身体横向错位")
	player._update_stage_visual_facing(0.10)
	_check(player._stage_draw_facing_side() < 0.0, "玩家转身过半后才应切到目标侧身方向")
	player._update_stage_visual_facing(1.0)
	_check(player.visual_facing_side < 0.0 and player.get_stage_turn_strength() <= 0.01, "玩家转身状态应收敛到新的左向侧身")
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
	_check(PLAYER_SCRIPT.PLAYER_STAGE_SIDE_PROFILE_ALPHA >= 0.20 and PLAYER_SCRIPT.PLAYER_STAGE_DIRECTIONAL_WEAPON_ALPHA >= 0.28, "玩家横版侧身应有方向化前层、武器和视线叠层")
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
	_check(map_panel.details.text.contains("探索：30%·初识此地"), "世界地图面板区域详情应显示探索阶段名")
	map_panel._select_region_by_id("changan")
	await get_tree().process_frame
	_check(map_panel.details.text.contains("熟路加成"), "世界地图面板应显示高探索区域的驿路熟路收益")
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
	var landmark_portal := _first_portal(local_area, "landmark")
	_check(not landmark_portal.is_empty() and str(landmark_portal.get("action_label", "")) == "探索" and not str(landmark_portal.get("interaction_hint", "")).is_empty(), "可互动地标应带探索动作和地标类型提示")
	if not landmark_portal.is_empty():
		var landmark_label := _portal_label(local_area, str(landmark_portal.get("id", "")))
		_check(landmark_label != null and landmark_label.text.contains("探索") and landmark_label.text.contains(str(landmark_portal.get("label", ""))), "可互动地标标签应展示探索动作和地标名")
	var resource_portal := _first_portal(local_area, "resource")
	_check(not resource_portal.is_empty() and str(resource_portal.get("action_label", "")) == "采集" and not str(resource_portal.get("interaction_hint", "")).is_empty(), "每日资源点应带采集动作和资源类型提示")
	if not resource_portal.is_empty():
		var resource_label := _portal_label(local_area, str(resource_portal.get("id", "")))
		_check(resource_label != null and resource_label.text.contains("采集") and resource_label.text.contains(str(resource_portal.get("label", ""))), "每日资源点标签应展示采集动作和资源名")
	_check(LOCAL_AREA_SCRIPT.LOCAL_INTERACTION_MARKER_ALPHA >= 0.78 and LOCAL_AREA_SCRIPT.LOCAL_RESOURCE_MARKER_ALPHA >= 0.74, "局部交互入口应有足够可见的舞台标记")
	_check(LOCAL_AREA_SCRIPT.LOCAL_INTERACTION_BOARD_HEIGHT >= 28.0, "局部交互标签应为双行语义留出高度")
	_check(LOCAL_AREA_SCRIPT.RICH_SHOP_INTERIOR_ENABLED, "商铺内景应启用高完成度室内 overlay")
	_check(LOCAL_AREA_SCRIPT.SHOP_INTERIOR_TEXTURE_PRIORITY, "商铺内景应优先使用 DNF 式整屏室内背景 PNG")
	_check(LOCAL_AREA_SCRIPT.SHOP_INTERIOR_TEXTURE_ALPHA >= 0.98, "商铺内景整屏背景应作为主视觉层")
	_check(LOCAL_AREA_SCRIPT.SHOP_INTERIOR_TEXTURE_MIN_WIDTH >= 1280.0 and LOCAL_AREA_SCRIPT.SHOP_INTERIOR_TEXTURE_MIN_HEIGHT >= 800.0, "商铺内景整屏背景应具备横版舞台分辨率下限")
	_check(LOCAL_AREA_SCRIPT.SHOP_INTERIOR_BACK_WALL_RATIO > 0.38 and LOCAL_AREA_SCRIPT.SHOP_INTERIOR_BACK_WALL_RATIO < 0.56, "商铺内景应保留横版后墙和透视地面比例")
	_check(LOCAL_AREA_SCRIPT.SHOP_INTERIOR_COUNTER_ALPHA >= 0.86, "商铺内景柜台应作为主视觉层")
	_check(LOCAL_AREA_SCRIPT.SHOP_INTERIOR_SHELF_ALPHA >= 0.76, "商铺内景应有可见货架层")
	_check(LOCAL_AREA_SCRIPT.SHOP_INTERIOR_THEME_PROP_ALPHA >= 0.82, "商铺内景应按店铺类型绘制主题道具")
	_check(LOCAL_AREA_SCRIPT.SHOP_INTERIOR_LIGHT_ALPHA >= 0.28, "商铺内景应有灯光氛围层")
	_check(LOCAL_AREA_SCRIPT.SHOP_INTERIOR_SIGNBOARD_ALPHA >= 0.72, "商铺内景应有明显后墙招牌焦点")
	_check(LOCAL_AREA_SCRIPT.SHOP_INTERIOR_DEPTH_ARCH_ALPHA >= 0.40, "商铺内景应保留梁柱/拱架纵深")
	_check(LOCAL_AREA_SCRIPT.SHOP_INTERIOR_SERVICE_ZONE_ALPHA >= 0.30, "商铺内景应标识柜台服务区和玩家站位")
	_check(LOCAL_AREA_SCRIPT.SHOP_INTERIOR_FLOOR_LANE_ALPHA >= 0.20, "商铺内景地面应有透视走位引导")
	_check(LOCAL_AREA_SCRIPT.SHOP_INTERIOR_FOREGROUND_VIGNETTE_ALPHA >= 0.42, "商铺内景应有近景梁柱压场")
	_check(LOCAL_AREA_SCRIPT.SHOP_INTERIOR_PERSPECTIVE_GUIDE_COUNT >= 8, "商铺内景应绘制足够地面透视线")
	_check(LOCAL_AREA_SCRIPT.SHOP_INTERIOR_DISPLAY_CLUSTER_COUNT >= 5, "商铺内景应按店铺类型补充陈列物")
	_check(LOCAL_AREA_SCRIPT.SHOP_INTERIOR_HANGING_DECOR_COUNT >= 5, "商铺内景应有悬挂式店铺道具和招幌层")
	_check(LOCAL_AREA_SCRIPT.SHOP_INTERIOR_COUNTER_ITEM_COUNT >= 6, "商铺内景柜台应摆放按店铺类型变化的商品")
	_check(LOCAL_AREA_SCRIPT.SHOP_INTERIOR_FOREGROUND_PROP_COUNT >= 8, "商铺内景应有前景货物遮挡层增强店面深度")
	_check(LOCAL_AREA_SCRIPT.SHOP_INTERIOR_BACKGROUND_NPC_COUNT >= 4 and LOCAL_AREA_SCRIPT.SHOP_INTERIOR_BACKGROUND_NPC_ALPHA >= 0.36, "商铺内景应有背景伙计/顾客剪影增强生活感")
	var inn_interior_path := GameData.get_shop_interior_background_path("inn")
	_check(inn_interior_path.ends_with("shop_inn_dnf_interior_v2.png"), "客栈内景应使用带二楼栏杆/楼梯/客桌/伙计剪影的 v2 整屏背景")
	var inn_interior_texture := GameData.load_texture(inn_interior_path, true)
	_check(inn_interior_texture != null and inn_interior_texture.get_size().x >= 1600.0 and inn_interior_texture.get_size().y >= 900.0, "客栈 v2 内景应具备 1600x900 横版整屏分辨率")
	var medicine_interior_path := GameData.get_shop_interior_background_path("medicine")
	_check(medicine_interior_path.ends_with("shop_medicine_dnf_interior_v2.png"), "药铺内景应使用带药斗柜/药秤/捣药台/药草挂束的 v2 整屏背景")
	var medicine_interior_texture := GameData.load_texture(medicine_interior_path, true)
	_check(medicine_interior_texture != null and medicine_interior_texture.get_size().x >= 1600.0 and medicine_interior_texture.get_size().y >= 900.0, "药铺 v2 内景应具备 1600x900 横版整屏分辨率")
	var blacksmith_interior_path := GameData.get_shop_interior_background_path("blacksmith")
	_check(blacksmith_interior_path.ends_with("shop_blacksmith_dnf_interior_v2.png"), "铁匠铺内景应使用带炉火/铁砧/兵器架/火星的 v2 整屏背景")
	var blacksmith_interior_texture := GameData.load_texture(blacksmith_interior_path, true)
	_check(blacksmith_interior_texture != null and blacksmith_interior_texture.get_size().x >= 1600.0 and blacksmith_interior_texture.get_size().y >= 900.0, "铁匠铺 v2 内景应具备 1600x900 横版整屏分辨率")
	var tailor_interior_path := GameData.get_shop_interior_background_path("tailor")
	_check(tailor_interior_path.ends_with("shop_tailor_dnf_interior_v2.png"), "布庄内景应使用带布匹货架/裁剪台/染缸/衣架的 v2 整屏背景")
	var tailor_interior_texture := GameData.load_texture(tailor_interior_path, true)
	_check(tailor_interior_texture != null and tailor_interior_texture.get_size().x >= 1600.0 and tailor_interior_texture.get_size().y >= 900.0, "布庄 v2 内景应具备 1600x900 横版整屏分辨率")
	var market_interior_path := GameData.get_shop_interior_background_path("market")
	_check(market_interior_path.ends_with("shop_market_dnf_interior_v2.png"), "市集内景应使用带摊位/货箱/菜蔬干货/灯笼/顾客剪影的 v2 整屏背景")
	var market_interior_texture := GameData.load_texture(market_interior_path, true)
	_check(market_interior_texture != null and market_interior_texture.get_size().x >= 1600.0 and market_interior_texture.get_size().y >= 900.0, "市集 v2 内景应具备 1600x900 横版整屏分辨率")
	var teahouse_interior_path := GameData.get_shop_interior_background_path("teahouse")
	_check(teahouse_interior_path.ends_with("shop_teahouse_dnf_interior_v2.png"), "茶肆内景应使用带茶柜/茶桌/炉壶/窗格/茶客剪影的 v2 整屏背景")
	var teahouse_interior_texture := GameData.load_texture(teahouse_interior_path, true)
	_check(teahouse_interior_texture != null and teahouse_interior_texture.get_size().x >= 1600.0 and teahouse_interior_texture.get_size().y >= 900.0, "茶肆 v2 内景应具备 1600x900 横版整屏分辨率")
	for shop_id in LOCAL_AREA_SCRIPT.SHOP_DEFINITIONS.keys():
		var shop_interior_path := GameData.get_shop_interior_background_path(str(shop_id))
		var expected_shop_suffix := "shop_%s_dnf_interior_v1.png" % [str(shop_id)]
		if str(shop_id) == "inn":
			expected_shop_suffix = "shop_inn_dnf_interior_v2.png"
		elif str(shop_id) == "medicine":
			expected_shop_suffix = "shop_medicine_dnf_interior_v2.png"
		elif str(shop_id) == "blacksmith":
			expected_shop_suffix = "shop_blacksmith_dnf_interior_v2.png"
		elif str(shop_id) == "tailor":
			expected_shop_suffix = "shop_tailor_dnf_interior_v2.png"
		elif str(shop_id) == "market":
			expected_shop_suffix = "shop_market_dnf_interior_v2.png"
		elif str(shop_id) == "teahouse":
			expected_shop_suffix = "shop_teahouse_dnf_interior_v2.png"
		_check(shop_interior_path.ends_with(expected_shop_suffix), "六类商铺都应映射专属 DNF 式室内背景：%s" % [str(shop_id)])

	var shop_portal := _first_portal(local_area, "shop")
	_check(not shop_portal.is_empty(), "平安镇应存在可进入商铺")
	if not shop_portal.is_empty():
		local_area.enter_shop(shop_portal)
		await get_tree().process_frame
		_check(local_area.current_mode == "shop" and not local_area.side_view_stage_enabled, "商铺内景应切出室外横版街景模式")
		_check(not local_area.active_shop_id.is_empty() and LOCAL_AREA_SCRIPT.SHOP_DEFINITIONS.has(local_area.active_shop_id), "商铺内景应保留当前店铺类型用于主题绘制")
		_check(local_area.npc_nodes.size() == 1, "商铺内应生成 1 名掌柜")
		_check(local_area.scene_background_texture == null, "商铺内景不应继续叠加区域背景")
		_check(local_area.shop_interior_texture != null, "商铺内景应加载店铺类型专属整屏背景")
		if local_area.shop_interior_texture != null:
			_check(local_area.shop_interior_texture.get_size().x >= LOCAL_AREA_SCRIPT.SHOP_INTERIOR_TEXTURE_MIN_WIDTH and local_area.shop_interior_texture.get_size().y >= LOCAL_AREA_SCRIPT.SHOP_INTERIOR_TEXTURE_MIN_HEIGHT, "商铺内景整屏背景应达到横版舞台分辨率")
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

	local_area.setup_region(GameData.get_region("changan"))
	await get_tree().process_frame
	_check(GameData.get_scene_background_path("changan").ends_with("scene_changan_dnf_west_market_v1.png"), "长安应接入 DNF 式西市横版整屏背景")
	_check(local_area.is_painted_stage_stack_active(), "长安局部横版舞台应走整屏贴图优先分支")
	_check(local_area.scene_midground_layer_texture != null and local_area.scene_floor_layer_texture != null, "长安应加载西市中景和地面贴图层")
	_check(GameData.get_stage_layer_path("changan", "floor").ends_with("changan_dnf_west_market_floor_v1.png"), "长安应映射西市地面贴图层")
	var changan_floor_layer := GameData.load_texture(GameData.get_stage_layer_path("changan", "floor"), true)
	var changan_midground_layer := GameData.load_texture(GameData.get_stage_layer_path("changan", "midground"), true)
	var changan_foreground_layer := GameData.load_texture(GameData.get_stage_layer_path("changan", "foreground"), true)
	_check(changan_floor_layer != null and changan_floor_layer.get_size().x >= 1600.0 and changan_floor_layer.get_size().y >= 900.0, "长安西市地面层应具备横版舞台分辨率")
	_check(changan_midground_layer != null and changan_floor_layer != null and changan_midground_layer.get_size() == changan_floor_layer.get_size(), "长安西市中景层应与地面层同尺寸对齐")
	_check(changan_foreground_layer != null and changan_floor_layer != null and changan_foreground_layer.get_size() == changan_floor_layer.get_size(), "长安西市前景层应与地面层同尺寸对齐")

	local_area.setup_region(GameData.get_region("chengdu"))
	await get_tree().process_frame
	_check(GameData.get_scene_background_path("chengdu").ends_with("scene_chengdu_dnf_tianfu_market_v1.png"), "成都应接入 DNF 式天府药市横版整屏背景")
	_check(local_area.is_painted_stage_stack_active(), "成都局部横版舞台应走整屏贴图优先分支")
	_check(local_area.scene_midground_layer_texture != null and local_area.scene_floor_layer_texture != null, "成都应加载天府药市中景和地面贴图层")
	_check(_portal_count(local_area, "shop") == chengdu_shops.size(), "成都应按数据商铺清单生成六类天府城池商铺入口")
	_check(_portal_count(local_area, "landmark") == chengdu_landmarks.size() and _portal_count(local_area, "resource") == chengdu_resources.size(), "成都应按数据兴趣点生成药市、渠眼、茶肆和资源入口")
	_check(GameData.get_stage_layer_path("chengdu", "floor").ends_with("chengdu_dnf_tianfu_floor_v1.png"), "成都应映射天府药市地面贴图层")
	var chengdu_floor_layer := GameData.load_texture(GameData.get_stage_layer_path("chengdu", "floor"), true)
	var chengdu_midground_layer := GameData.load_texture(GameData.get_stage_layer_path("chengdu", "midground"), true)
	var chengdu_foreground_layer := GameData.load_texture(GameData.get_stage_layer_path("chengdu", "foreground"), true)
	_check(chengdu_floor_layer != null and chengdu_floor_layer.get_size().x >= 1600.0 and chengdu_floor_layer.get_size().y >= 900.0, "成都天府药市地面层应具备横版舞台分辨率")
	_check(chengdu_midground_layer != null and chengdu_floor_layer != null and chengdu_midground_layer.get_size() == chengdu_floor_layer.get_size(), "成都天府药市中景层应与地面层同尺寸对齐")
	_check(chengdu_foreground_layer != null and chengdu_floor_layer != null and chengdu_foreground_layer.get_size() == chengdu_floor_layer.get_size(), "成都天府药市前景层应与地面层同尺寸对齐")

	local_area.setup_region(GameData.get_region("jiangling"))
	await get_tree().process_frame
	_check(GameData.get_scene_background_path("jiangling").ends_with("scene_jiangling_dnf_river_city_v1.png"), "江陵应接入 DNF 式江防码头横版整屏背景")
	_check(local_area.is_painted_stage_stack_active(), "江陵局部横版舞台应走整屏贴图优先分支")
	_check(local_area.scene_midground_layer_texture != null and local_area.scene_floor_layer_texture != null, "江陵应加载江防码头中景和地面贴图层")
	_check(_portal_count(local_area, "shop") == jiangling_shops.size(), "江陵应按数据商铺清单生成五类城池商铺入口")
	_check(_portal_count(local_area, "landmark") == jiangling_landmarks.size() and _portal_count(local_area, "resource") == jiangling_resources.size(), "江陵应按数据兴趣点生成码头、战鼓台、货栈和资源入口")
	_check(GameData.get_stage_layer_path("jiangling", "floor").ends_with("jiangling_dnf_river_city_floor_v1.png"), "江陵应映射江防码头地面贴图层")
	var jiangling_floor_layer := GameData.load_texture(GameData.get_stage_layer_path("jiangling", "floor"), true)
	var jiangling_midground_layer := GameData.load_texture(GameData.get_stage_layer_path("jiangling", "midground"), true)
	var jiangling_foreground_layer := GameData.load_texture(GameData.get_stage_layer_path("jiangling", "foreground"), true)
	_check(jiangling_floor_layer != null and jiangling_floor_layer.get_size().x >= 1600.0 and jiangling_floor_layer.get_size().y >= 900.0, "江陵地面层应具备横版舞台分辨率")
	_check(jiangling_midground_layer != null and jiangling_floor_layer != null and jiangling_midground_layer.get_size() == jiangling_floor_layer.get_size(), "江陵中景层应与地面层同尺寸对齐")
	_check(jiangling_foreground_layer != null and jiangling_floor_layer != null and jiangling_foreground_layer.get_size() == jiangling_floor_layer.get_size(), "江陵前景层应与地面层同尺寸对齐")

	local_area.setup_region(GameData.get_region("linan"))
	await get_tree().process_frame
	_check(GameData.get_scene_background_path("linan").ends_with("scene_linan_dnf_water_city_v1.png"), "临安应接入 DNF 式水城横版整屏背景")
	_check(local_area.is_painted_stage_stack_active(), "临安局部横版舞台应走整屏贴图优先分支")
	_check(local_area.scene_midground_layer_texture != null and local_area.scene_floor_layer_texture != null, "临安应加载水城中景和地面/水道贴图层")
	_check(_portal_count(local_area, "shop") == linan_shops.size(), "临安应按数据商铺清单生成六类城池商铺入口")
	_check(_portal_count(local_area, "landmark") == linan_landmarks.size() and _portal_count(local_area, "resource") == linan_resources.size(), "临安应按数据兴趣点生成水城地标和资源入口")
	_check(GameData.get_stage_layer_path("linan", "floor").ends_with("linan_dnf_water_floor_v1.png"), "临安应映射水城地面/水道贴图层")
	var linan_floor_layer := GameData.load_texture(GameData.get_stage_layer_path("linan", "floor"), true)
	var linan_midground_layer := GameData.load_texture(GameData.get_stage_layer_path("linan", "midground"), true)
	var linan_foreground_layer := GameData.load_texture(GameData.get_stage_layer_path("linan", "foreground"), true)
	_check(linan_floor_layer != null and linan_floor_layer.get_size().x >= 1600.0 and linan_floor_layer.get_size().y >= 900.0, "临安水城地面层应具备横版舞台分辨率")
	_check(linan_midground_layer != null and linan_floor_layer != null and linan_midground_layer.get_size() == linan_floor_layer.get_size(), "临安水城中景层应与地面层同尺寸对齐")
	_check(linan_foreground_layer != null and linan_floor_layer != null and linan_foreground_layer.get_size() == linan_floor_layer.get_size(), "临安水城前景层应与地面层同尺寸对齐")
	_check(not local_area.is_tile_walkable(_first_tile_with_id(local_area, LOCAL_TILE_WATER)), "临安局部水面应不可通行")

	local_area.setup_region(GameData.get_region("luoshui_river"))
	await get_tree().process_frame
	_check(GameData.get_scene_background_path("luoshui_river").ends_with("scene_luoshui_river_dnf_bridge_v1.png"), "洛水河畔应接入 DNF 式野外水岸桥景整屏背景")
	_check(local_area.is_painted_stage_stack_active(), "洛水河畔局部横版舞台应走整屏贴图优先分支")
	_check(local_area.scene_midground_layer_texture != null and local_area.scene_floor_layer_texture != null, "洛水河畔应加载水岸中景和河岸地面贴图层")
	_check(_portal_count(local_area, "landmark") == luoshui_landmarks.size() and _portal_count(local_area, "resource") == luoshui_resources.size(), "洛水河畔应按数据兴趣点生成桥、渡口、茶棚和资源入口")
	_check(GameData.get_stage_layer_path("luoshui_river", "floor").ends_with("luoshui_river_dnf_floor_v1.png"), "洛水河畔应映射水岸河面地面贴图层")
	var luoshui_floor_layer := GameData.load_texture(GameData.get_stage_layer_path("luoshui_river", "floor"), true)
	var luoshui_midground_layer := GameData.load_texture(GameData.get_stage_layer_path("luoshui_river", "midground"), true)
	var luoshui_foreground_layer := GameData.load_texture(GameData.get_stage_layer_path("luoshui_river", "foreground"), true)
	_check(luoshui_floor_layer != null and luoshui_floor_layer.get_size().x >= 1600.0 and luoshui_floor_layer.get_size().y >= 900.0, "洛水河畔地面/河面层应具备横版舞台分辨率")
	_check(luoshui_midground_layer != null and luoshui_floor_layer != null and luoshui_midground_layer.get_size() == luoshui_floor_layer.get_size(), "洛水河畔中景层应与地面层同尺寸对齐")
	_check(luoshui_foreground_layer != null and luoshui_floor_layer != null and luoshui_foreground_layer.get_size() == luoshui_floor_layer.get_size(), "洛水河畔前景层应与地面层同尺寸对齐")

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

	local_area.setup_region(GameData.get_region("dujiang_weir"))
	await get_tree().process_frame
	_check(GameData.get_scene_background_path("dujiang_weir").ends_with("scene_dujiang_weir_dnf_waterworks_v1.png"), "都江古堰应接入 DNF 式水工古堰整屏背景")
	_check(local_area.is_painted_stage_stack_active(), "都江古堰局部横版舞台应走整屏贴图优先分支")
	_check(local_area.scene_midground_layer_texture != null and local_area.scene_floor_layer_texture != null, "都江古堰应加载水工中景和水渠地面贴图层")
	_check(_portal_count(local_area, "landmark") == dujiang_landmarks.size() and _portal_count(local_area, "resource") == dujiang_resources.size(), "都江古堰应按数据兴趣点生成分水堰、鱼嘴石堤、水工棚和资源入口")
	_check(GameData.get_stage_layer_path("dujiang_weir", "floor").ends_with("dujiang_weir_dnf_floor_v1.png"), "都江古堰应映射水工古堰地面贴图层")
	var dujiang_floor_layer := GameData.load_texture(GameData.get_stage_layer_path("dujiang_weir", "floor"), true)
	var dujiang_midground_layer := GameData.load_texture(GameData.get_stage_layer_path("dujiang_weir", "midground"), true)
	var dujiang_foreground_layer := GameData.load_texture(GameData.get_stage_layer_path("dujiang_weir", "foreground"), true)
	_check(dujiang_floor_layer != null and dujiang_floor_layer.get_size().x >= 1600.0 and dujiang_floor_layer.get_size().y >= 900.0, "都江古堰地面/水渠层应具备横版舞台分辨率")
	_check(dujiang_midground_layer != null and dujiang_floor_layer != null and dujiang_midground_layer.get_size() == dujiang_floor_layer.get_size(), "都江古堰中景层应与地面层同尺寸对齐")
	_check(dujiang_foreground_layer != null and dujiang_floor_layer != null and dujiang_foreground_layer.get_size() == dujiang_floor_layer.get_size(), "都江古堰前景层应与地面层同尺寸对齐")

	local_area.setup_region(GameData.get_region("qingcheng_mtn"))
	await get_tree().process_frame
	_check(GameData.get_scene_background_path("qingcheng_mtn").ends_with("scene_qingcheng_mtn_dnf_daoist_gate_v1.png"), "青城山应接入 DNF 式道观山门整屏背景")
	_check(local_area.is_painted_stage_stack_active(), "青城山局部横版舞台应走整屏贴图优先分支")
	_check(local_area.scene_midground_layer_texture != null and local_area.scene_floor_layer_texture != null, "青城山应加载道观山门中景和石阶地面贴图层")
	_check(_portal_count(local_area, "landmark") == qingcheng_landmarks.size() and _portal_count(local_area, "resource") == qingcheng_resources.size(), "青城山应按数据兴趣点生成山门、问道台、小桥和资源入口")
	_check(GameData.get_stage_layer_path("qingcheng_mtn", "floor").ends_with("qingcheng_mtn_dnf_floor_v1.png"), "青城山应映射道观山门地面贴图层")
	var qingcheng_floor_layer := GameData.load_texture(GameData.get_stage_layer_path("qingcheng_mtn", "floor"), true)
	var qingcheng_midground_layer := GameData.load_texture(GameData.get_stage_layer_path("qingcheng_mtn", "midground"), true)
	var qingcheng_foreground_layer := GameData.load_texture(GameData.get_stage_layer_path("qingcheng_mtn", "foreground"), true)
	_check(qingcheng_floor_layer != null and qingcheng_floor_layer.get_size().x >= 1600.0 and qingcheng_floor_layer.get_size().y >= 900.0, "青城山石阶地面层应具备横版舞台分辨率")
	_check(qingcheng_midground_layer != null and qingcheng_floor_layer != null and qingcheng_midground_layer.get_size() == qingcheng_floor_layer.get_size(), "青城山中景层应与地面层同尺寸对齐")
	_check(qingcheng_foreground_layer != null and qingcheng_floor_layer != null and qingcheng_foreground_layer.get_size() == qingcheng_floor_layer.get_size(), "青城山前景层应与地面层同尺寸对齐")

	local_area.setup_region(GameData.get_region("flower_sect"))
	await get_tree().process_frame
	_check(GameData.get_scene_background_path("flower_sect").ends_with("scene_flower_sect_dnf_garden_v1.png"), "花间派应接入 DNF 式花林门派整屏背景")
	_check(local_area.is_painted_stage_stack_active(), "花间派局部横版舞台应走整屏贴图优先分支")
	_check(local_area.scene_midground_layer_texture != null and local_area.scene_floor_layer_texture != null, "花间派应加载门派庭院中景和地面贴图层")
	_check(_portal_count(local_area, "shop") == flower_shops.size(), "花间派应按数据商铺清单生成门派补给入口")
	_check(_portal_count(local_area, "landmark") == flower_landmarks.size() and _portal_count(local_area, "resource") == flower_resources.size(), "花间派应按数据兴趣点生成门派地标和补给入口")
	_check(GameData.get_stage_layer_path("flower_sect", "floor").ends_with("flower_sect_dnf_garden_floor_v1.png"), "花间派应映射门派庭院地面贴图层")
	var flower_floor_layer := GameData.load_texture(GameData.get_stage_layer_path("flower_sect", "floor"), true)
	var flower_midground_layer := GameData.load_texture(GameData.get_stage_layer_path("flower_sect", "midground"), true)
	var flower_foreground_layer := GameData.load_texture(GameData.get_stage_layer_path("flower_sect", "foreground"), true)
	_check(flower_floor_layer != null and flower_floor_layer.get_size().x >= 1600.0 and flower_floor_layer.get_size().y >= 900.0, "花间派地面层应具备横版舞台分辨率")
	_check(flower_midground_layer != null and flower_floor_layer != null and flower_midground_layer.get_size() == flower_floor_layer.get_size(), "花间派中景层应与地面层同尺寸对齐")
	_check(flower_foreground_layer != null and flower_floor_layer != null and flower_foreground_layer.get_size() == flower_floor_layer.get_size(), "花间派前景层应与地面层同尺寸对齐")

	local_area.setup_region(GameData.get_region("emei_sacred"))
	await get_tree().process_frame
	_check(GameData.get_scene_background_path("emei_sacred").ends_with("scene_emei_sacred_dnf_cloud_temple_v1.png"), "峨眉圣山应接入 DNF 式云海金顶整屏背景")
	_check(local_area.is_painted_stage_stack_active(), "峨眉圣山局部横版舞台应走整屏贴图优先分支")
	_check(local_area.scene_midground_layer_texture != null and local_area.scene_floor_layer_texture != null, "峨眉圣山应加载云海金顶中景和石阶地面贴图层")
	_check(_portal_count(local_area, "landmark") == emei_landmarks.size() and _portal_count(local_area, "resource") == emei_resources.size(), "峨眉圣山应按数据兴趣点生成金顶山寺、云海观台、舍身崖和资源入口")
	_check(GameData.get_stage_layer_path("emei_sacred", "floor").ends_with("emei_sacred_dnf_floor_v1.png"), "峨眉圣山应映射云海金顶地面贴图层")
	var emei_floor_layer := GameData.load_texture(GameData.get_stage_layer_path("emei_sacred", "floor"), true)
	var emei_midground_layer := GameData.load_texture(GameData.get_stage_layer_path("emei_sacred", "midground"), true)
	var emei_foreground_layer := GameData.load_texture(GameData.get_stage_layer_path("emei_sacred", "foreground"), true)
	_check(emei_floor_layer != null and emei_floor_layer.get_size().x >= 1600.0 and emei_floor_layer.get_size().y >= 900.0, "峨眉圣山石阶地面层应具备横版舞台分辨率")
	_check(emei_midground_layer != null and emei_floor_layer != null and emei_midground_layer.get_size() == emei_floor_layer.get_size(), "峨眉圣山中景层应与地面层同尺寸对齐")
	_check(emei_foreground_layer != null and emei_floor_layer != null and emei_foreground_layer.get_size() == emei_floor_layer.get_size(), "峨眉圣山前景层应与地面层同尺寸对齐")
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
