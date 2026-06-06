extends Node

const WORLD_MAP_SCRIPT := preload("res://scripts/world/world_map.gd")
const LOCAL_AREA_SCRIPT := preload("res://scripts/world/local_area_map.gd")
const STAGE_FOREGROUND_SCRIPT := preload("res://scripts/world/local_stage_foreground.gd")
const PLAYER_SCRIPT := preload("res://scripts/entities/player.gd")
const NPC_SCRIPT := preload("res://scripts/entities/npc.gd")
const WORLD_MAP_PANEL_SCRIPT := preload("res://scripts/ui/world_map_panel.gd")

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

	var test_root := Node2D.new()
	add_child(test_root)

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
	_check(_texture_variant_count(world_map, WORLD_TILE_WATER) >= 4, "世界地图应加载多变体水面瓦片")
	_check(_actors_use_y_sort(world_map.npc_nodes), "世界层 NPC 应按脚底 Y 坐标排序")

	var player = PLAYER_SCRIPT.new()
	player.world_map = world_map
	player.position = GameState.player_position
	test_root.add_child(player)
	await get_tree().process_frame
	_check(player.z_index == int(player.position.y), "玩家应按脚底 Y 坐标排序")
	_check(PLAYER_SCRIPT.SPRITE_TARGET_HEIGHT >= 116.0, "玩家地图角色显示不应继续偏小")
	_check(PLAYER_SCRIPT.LOCAL_STAGE_PRESENCE_SCALE >= 1.20, "玩家局部横版舞台应叠加额外角色存在感缩放")
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
	_check(PLAYER_SCRIPT.PLAYER_STAGE_CENTERLINE_ALPHA >= 0.20, "玩家局部横版舞台应保留重心/躯干中心线")
	_check(PLAYER_SCRIPT.STAGE_DEPTH_SCALE_MAX > PLAYER_SCRIPT.STAGE_DEPTH_SCALE_MIN, "玩家应支持局部舞台深度缩放")
	player.facing = Vector2.LEFT
	_check(player._facing_side() < 0.0, "玩家横版舞台侧向层应响应向左朝向")
	player.facing = Vector2.RIGHT
	_check(player._facing_side() > 0.0, "玩家横版舞台侧向层应响应向右朝向")
	player.facing = Vector2.DOWN
	_check(NPC_SCRIPT.BASE_SPRITE_HEIGHT >= 112.0, "NPC 地图贴图基础高度不应继续偏小")
	_check(NPC_SCRIPT.STAGE_PRESENCE_SCALE >= 1.32, "NPC 局部横版舞台应叠加额外角色存在感缩放")
	_check(NPC_SCRIPT.STAGE_MASTER_EXTRA_SCALE > 1.0 and NPC_SCRIPT.STAGE_ENEMY_EXTRA_SCALE > 1.0, "掌门/敌人应在局部横版舞台获得额外体量")
	_check(NPC_SCRIPT.STAGE_SPRITE_MIN_SCALE >= 1.16, "NPC 局部横版舞台应保留最低视觉体量")
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
	_check(_stage_role_scale_bonus(), "掌门/敌人局部舞台体量应大于普通 NPC")

	var local_area = LOCAL_AREA_SCRIPT.new()
	test_root.add_child(local_area)
	await get_tree().process_frame
	local_area.setup_region(GameData.get_region("qinghe"))
	await get_tree().process_frame

	_check(local_area.npc_nodes.size() >= 8, "平安镇局部地图应生成镇民 NPC，当前=%d" % local_area.npc_nodes.size())
	_check(local_area.scene_background_texture != null, "局部地图应加载区域水墨氛围背景")
	_check(local_area.side_view_stage_enabled and LOCAL_AREA_SCRIPT.SIDE_VIEW_STAGE_LANE_ALPHA >= 0.40, "局部地图应启用横版舞台式视觉层")
	_check(LOCAL_AREA_SCRIPT.SIDE_VIEW_PLAY_LANE_COUNT >= 5, "局部横版舞台应保留多条可行走平台带")
	_check(LOCAL_AREA_SCRIPT.SIDE_VIEW_PLAY_LANE_ALPHA >= 0.20, "局部横版舞台可行走平台带应有足够可见度")
	_check(LOCAL_AREA_SCRIPT.SIDE_VIEW_PLAY_LANE_EDGE_ALPHA >= 0.26, "局部横版舞台平台边线应有足够层次")
	_check(LOCAL_AREA_SCRIPT.SIDE_VIEW_LANE_DECAL_COUNT >= 20, "局部横版舞台地面应保留走位带细节标识")
	_check(LOCAL_AREA_SCRIPT.SIDE_VIEW_SIDE_EXIT_COUNT >= 4, "局部横版舞台应保留左右副本式出入口框")
	_check(LOCAL_AREA_SCRIPT.SIDE_VIEW_SIDE_EXIT_ALPHA >= 0.24, "局部横版舞台出入口框应有足够可见度")
	var lane_positions: Array = local_area.get_stage_play_lane_y_positions()
	_check(lane_positions.size() == LOCAL_AREA_SCRIPT.SIDE_VIEW_PLAY_LANE_COUNT, "局部横版舞台应向系统暴露可行走平台带位置")
	if lane_positions.size() >= 2:
		_check(float(lane_positions[0]) < float(lane_positions[lane_positions.size() - 1]), "局部横版舞台平台带应从远景到前景排序")
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
	_check(local_area.stage_postfx_overlay != null and local_area.stage_postfx_overlay.visible, "局部横版舞台应创建镜头光影后期层")
	_check(LOCAL_AREA_SCRIPT.SIDE_VIEW_POSTFX_Z > 3000 and LOCAL_AREA_SCRIPT.SIDE_VIEW_POSTFX_Z < LOCAL_AREA_SCRIPT.SIDE_VIEW_FOREGROUND_OVERLAY_Z, "局部横版舞台后期层应位于角色上方且低于真实前景遮挡")
	_check(local_area.stage_foreground_overlay != null and local_area.stage_foreground_overlay.visible, "局部横版舞台应创建真实前景遮挡层")
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
	_check(_actor_depth_scale_range(local_area.npc_nodes) >= 0.10, "局部 NPC 应按舞台前后排产生大小差异")
	_check(_actors_marked_stage(local_area.npc_nodes), "局部地图 NPC 应标记为横版舞台角色")
	_check(_actors_have_idle_motion(local_area.npc_nodes), "局部地图 NPC 应有待机轻微动态")
	_check(_actors_have_stage_rim(local_area.npc_nodes), "局部地图 NPC 应显示舞台贴图轮廓高光")
	_check(_actors_have_stage_pose_overlay(local_area.npc_nodes), "局部地图 NPC 应显示贴图前方姿态线")
	_check(_actors_have_stage_body_overlays(local_area.npc_nodes), "局部地图 NPC 应显示躯干、腰带和武器辉光前层")
	_check(_actors_have_stage_activity(local_area.npc_nodes), "局部地图 NPC 应具备职业/行为视觉提示")
	_check(NPC_SCRIPT.STAGE_POSE_LINE_ALPHA >= 0.22, "NPC 局部舞台姿态线应有足够可见度")
	_check(NPC_SCRIPT.STAGE_FOOT_ANCHOR_ALPHA >= 0.16, "NPC 局部舞台脚步锚点应有足够可见度")
	_check(_texture_variant_count(local_area, LOCAL_TILE_MOUNTAIN) >= 4, "局部地图应加载多变体山体瓦片")
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
	player.position = Vector2(stage_rect.size.x * 0.5, stage_rect.size.y * LOCAL_AREA_SCRIPT.STAGE_DEPTH_BOTTOM_RATIO)
	player._refresh_stage_depth_scale()
	_check(player.stage_depth_scale > 1.08, "玩家在局部地图前景站位应明显放大")
	_check(player.get_map_actor_visual_scale() > player.stage_depth_scale, "玩家局部横版地图应在景深外叠加舞台角色缩放")
	_check(PLAYER_SCRIPT.PLAYER_STAGE_FOOT_ANCHOR_ALPHA >= 0.20, "玩家局部横版地图应显示脚步锚点")
	_check(PLAYER_SCRIPT.PLAYER_STAGE_WEAPON_POSE_ALPHA >= 0.30, "玩家局部横版地图应显示前持武器姿态")
	_check(PLAYER_SCRIPT.PLAYER_STAGE_SHOULDER_GLOW_ALPHA >= 0.16, "玩家局部横版地图应显示肩部高光姿态层")
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
	_check(not _first_portal(local_area, "travel_region").is_empty(), "平安镇应生成相邻区域转场入口")
	_check(_portal_count(local_area, "landmark") >= 3, "平安镇应生成可互动地标")
	_check(_portal_count(local_area, "resource") >= 2, "平安镇应生成每日资源点")

	var shop_portal := _first_portal(local_area, "shop")
	_check(not shop_portal.is_empty(), "平安镇应存在可进入商铺")
	if not shop_portal.is_empty():
		local_area.enter_shop(shop_portal)
		await get_tree().process_frame
		_check(local_area.npc_nodes.size() == 1, "商铺内应生成 1 名掌柜")
		_check(local_area.scene_background_texture == null, "商铺内景不应继续叠加区域背景")
		_check(local_area.stage_postfx_overlay == null or not local_area.stage_postfx_overlay.visible, "商铺内景不应显示局部横版后期光影层")
		_check(local_area.stage_foreground_overlay == null or not local_area.stage_foreground_overlay.visible, "商铺内景不应显示局部横版前景遮挡层")
		_check(not _first_portal(local_area, "exit_area").is_empty(), "商铺内应有出门入口")
		if local_area.npc_nodes.size() > 0:
			var keeper_data: Dictionary = local_area.npc_nodes[0].data
			_check((keeper_data.get("sell_items", []) as Array).size() > 0, "商铺掌柜应带商品列表")

	local_area.setup_region(GameData.get_region("linan"))
	await get_tree().process_frame
	_check(not local_area.is_tile_walkable(_first_tile_with_id(local_area, LOCAL_TILE_WATER)), "临安局部水面应不可通行")

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
