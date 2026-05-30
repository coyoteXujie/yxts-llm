import arcade
import math
import random
from typing import Optional, List, Dict
from .config import GAME_CONFIG, COLORS, UI_CONFIG, VISUAL_CONFIG
from . import render as renderer
from .vfx import VFXManager
from .enhanced_world import get_enhanced_world, CITY_IDS, TOWN_IDS, WILD_IDS, SECT_IDS
from .world import MAP_W, MAP_H, WALKABLE, TS, col_to_x, row_to_y, FACTION_NAMES
from .entities import Player, NPC, Faction, NpcType, QuestType, Quest, Skill
from .quest import get_quest_manager
from .npc_brain import DialogueState, get_npc_brain_manager
from .encounter import get_encounter_manager, Encounter
from .atmosphere import AtmosphereManager
from .combat_system import HybridCombatSystem, Combatant, EncounterSystem, ActionType, CombatPhase
from .render.combat_renderer import InkCombatRenderer, CombatUIConfig
from .systems.cultivation_system import CultivationSystem
from .systems.economy_system import EconomySystem, ReputationSystem
from .systems.story_system import StoryEngine
from .systems.equipment_system import CraftingSystem, Inventory

SW = GAME_CONFIG["screen_width"]
SH = GAME_CONFIG["screen_height"]


class GameWindow(arcade.Window):
    def __init__(self):
        super().__init__(SW, SH, GAME_CONFIG["screen_title"], resizable=False)
        arcade.set_background_color((35, 32, 28))

        self.game_world = get_enhanced_world()
        self.current_npc: Optional[NPC] = None
        self.camera_x = self.game_world.player.position.x
        self.camera_y = self.game_world.player.position.y

        self.game_state = "menu"
        self.menu_selection = 0
        self.menu_items = ["开始新游戏", "读取存档", "退出游戏"]

        self.dialog_text = ""
        self.dialog_title = ""
        self.dialog_type = "info"
        self.show_dialog = False
        self.quest_manager = get_quest_manager()

        self.dialogue_state = DialogueState.GREETING
        self.dialogue_result: Optional[Dict] = None
        self.player_input_mode = False
        self.player_input_text = ""
        self.dialogue_options: List[str] = []

        self.pending_encounter: Optional[Encounter] = None
        self.encounter_display = False
        self._pending_task: Optional[Dict] = None
        self._pending_teach: Optional[Dict] = None

        self.movement = {"up": False, "down": False, "left": False, "right": False}

        self.char_name = ""
        self.char_gender = "male"
        self.char_faction = Faction.NONE
        self.char_attributes = {"strength": 15, "dexterity": 15, "intelligence": 15, "constitution": 15}
        self.attribute_points = 20
        self.selected_attr = 0
        self.focus_target = "name"
        self.char_creation_msg = ""
        self.blink_timer = 0.0
        self.float_anim = 0.0
        self.faction_scroll = 0

        self.interaction_prompt = ""
        self.interaction_npc: Optional[NPC] = None
        self.nearby_timer = 0.0

        self.show_minimap = True
        self.show_inventory = False
        self.inv_scroll = 0
        self.show_skill_panel = False
        self.skill_scroll = 0
        self.show_journal = False
        self.show_shop = False
        self.show_craft = False

        self.particles = []
        self.vfx = VFXManager(SW, SH)
        self._hurt_flash_val = 0.0
        self._shop_items = []
        self._show_tutorial = True
        self._zone_name_timer = 0

        # === 新系统 ===
        self.atmosphere = AtmosphereManager(SW, SH)
        self.combat_system = HybridCombatSystem()
        self.encounter_system = EncounterSystem(base_encounter_rate=0.02)
        self.cultivation = CultivationSystem()
        self.economy = EconomySystem()
        self.reputation = ReputationSystem()
        self.story = StoryEngine()
        self.crafting = CraftingSystem()
        self.player_inventory = Inventory()
        self.combat_renderer = InkCombatRenderer(CombatUIConfig())

        # 战斗状态
        self._in_combat = False
        self._combat_phase = "none"
        self._combat_log = []
        self._combat_menu_idx = 0
        self._combat_skill_idx = 0
        self._combat_enemy_idx = 0
        self._combat_rewards = None
        self._combat_anim_timer = 0.0

        # 剧情状态
        self._story_active = False
        self._story_choice_idx = 0

        # 遇敌冷却
        self._encounter_cooldown = 0.0

        self.font = "Arial"

    def setup(self):
        pass

    def on_draw(self):
        self.clear()
        if self.game_state == "menu":
            self._draw_menu()
        elif self.game_state == "char_creation":
            self._draw_char_creation()
        elif self.game_state == "playing":
            self._draw_game()

    def on_update(self, delta_time):
        self.blink_timer += delta_time
        self.float_anim += delta_time

        renderer.set_anim_time(self.blink_timer)
        renderer.update_dialog_anim(delta_time)

        # === 新系统更新 ===
        self.atmosphere.update(delta_time)
        if self._encounter_cooldown > 0:
            self._encounter_cooldown -= delta_time
        if self._combat_anim_timer > 0:
            self._combat_anim_timer -= delta_time
        if self._in_combat:
            self.combat_renderer.update(delta_time)

        if self._hurt_flash_val > 0:
            self._hurt_flash_val = max(0, self._hurt_flash_val - delta_time * 3)
            renderer.set_hurt_flash(self._hurt_flash_val)

        self.vfx.update(delta_time)

        if self._zone_name_timer > 0:
            self._zone_name_timer -= delta_time

        from .render.post_process import get_advanced_lights, get_env_particles, get_post_processor
        get_advanced_lights().update(delta_time)
        get_post_processor().update(delta_time)
        env = get_env_particles()
        if not env._initialized:
            env.init(SW, SH)
        day_progress = self.vfx.day_night.time if hasattr(self.vfx, 'day_night') else 0.5
        env.update(delta_time, day_progress)

        if self.game_state == "playing" and self.game_world.player:
            self.game_world.update(delta_time)

            p = self.game_world.player
            speed = 300 * delta_time
            dx, dy = 0.0, 0.0

            if self.movement["up"]:
                dy += speed
            if self.movement["down"]:
                dy -= speed
            if self.movement["left"]:
                dx -= speed
            if self.movement["right"]:
                dx += speed

            if dx != 0 and dy != 0:
                dx *= 0.7071
                dy *= 0.7071

            if dx != 0 or dy != 0:
                new_x = p.position.x + dx
                new_y = p.position.y + dy
                if self.game_world.can_walk(new_x, new_y):
                    p.position.x = new_x
                    p.position.y = new_y
                    self._check_zone_transition()

            self.nearby_timer += delta_time
            if self.nearby_timer > 0.3:
                self.nearby_timer = 0
                self._update_interaction_prompt()

            # === 遇敌检测 ===
            if not self._in_combat and self._encounter_cooldown <= 0:
                zone_type = self.game_world.current_map.zone_type if self.game_world.current_map else "city"
                player_level = self.game_world.player.level if self.game_world.player else 1
                enemies = self.encounter_system.check_encounter(zone_type, delta_time, player_level)
                if enemies:
                    self._start_combat(enemies)

            # === 战斗AI ===
            if self._in_combat and self.combat_system.phase == CombatPhase.ENEMY_TURN:
                self.combat_system.enemy_ai_action()
                self._combat_anim_timer = 0.5

            self._update_particles(delta_time)

    def _update_interaction_prompt(self):
        p = self.game_world.player
        if not p:
            return
        npc = self.game_world.get_nearby_npc(p.position, 150)
        enemy = self.game_world.get_nearby_enemy(p.position, 150)
        if npc:
            self.interaction_prompt = f"按 T 与 {npc.name} 对话"
            self.interaction_npc = npc
        elif enemy:
            self.interaction_prompt = f"按 F 攻击 {enemy.name}"
            self.interaction_npc = enemy
        else:
            self.interaction_prompt = ""
            self.interaction_npc = None

    def _check_zone_transition(self):
        cmap = self.game_world.current_map
        if not cmap or not cmap.transitions:
            return
        p = self.game_world.player
        p_col = int(p.position.x // TS)
        p_row = cmap.height - 1 - int(p.position.y // TS)
        for exit_name, exit_pos in cmap.exits.items():
            e_col = int(exit_pos.x // TS)
            e_row = cmap.height - 1 - int(exit_pos.y // TS)
            if abs(p_col - e_col) <= 1 and abs(p_row - e_row) <= 1:
                trans = cmap.transitions.get(exit_name)
                if trans:
                    target_zone_id, target_pos = trans
                    self.game_world.change_zone(target_zone_id, target_pos)
                    self.camera_x = p.position.x
                    self.camera_y = p.position.y
                    from .render.tile_renderer import invalidate_chunk_cache
                    invalidate_chunk_cache()
                    zone_name = self.game_world.current_map.name if self.game_world.current_map else ""
                    self._zone_name_timer = 3.0
                    self.show_dialog = False
                    return

    def _update_particles(self, dt):
        new_particles = []
        for p in self.particles:
            p["x"] += p["vx"] * dt
            p["y"] += p["vy"] * dt
            p["life"] -= dt
            if p["life"] > 0:
                new_particles.append(p)
        self.particles = new_particles

    def _spawn_ambient_particles(self, sx, sy):
        if random.random() < 0.02:
            self.particles.append({
                "x": sx + random.uniform(-SW / 2, SW / 2),
                "y": sy + random.uniform(-SH / 2, SH / 2),
                "vx": random.uniform(-5, 5),
                "vy": random.uniform(5, 15),
                "life": random.uniform(2, 5),
                "max_life": 5,
                "color": random.choice([(255, 255, 200), (200, 255, 200), (255, 200, 255)]),
                "size": random.uniform(1, 3),
            })

    def _R(self, l, b, w, h, c):
        arcade.draw_rect_filled(arcade.LBWH(l, b, w, h), c)

    def _RO(self, l, b, w, h, c, t=1):
        arcade.draw_rect_outline(arcade.LBWH(l, b, w, h), c, t)

    def _draw_menu(self):
        self._R(0, 0, SW, SH, (30, 28, 22))

        for i in range(60):
            x = (i * 137.5 + self.blink_timer * 8) % SW
            y = (i * 97.3 + math.sin(self.blink_timer * 0.5 + i * 0.3) * 20) % SH
            alpha = int(30 + 20 * (0.5 + 0.5 * math.sin(self.blink_timer * 1.5 + i)))
            arcade.draw_circle_filled(x, y, 1.5, (180, 155, 100, alpha))

        for i in range(5):
            mx = 100 + i * 250
            my = 200 + math.sin(self.blink_timer * 0.8 + i) * 30
            alpha = int(10 + 8 * math.sin(self.blink_timer + i))
            arcade.draw_circle_filled(mx, my, 40, (180, 155, 100, alpha))

        title_y = 560
        glow = int(20 + 15 * math.sin(self.blink_timer * 2))
        arcade.draw_text("白金英雄坛说", SW // 2 + 2, title_y - 2, (glow, glow // 2, 0, 80), 58,
                         font_name=self.font, anchor_x="center", anchor_y="center")
        arcade.draw_text("白金英雄坛说", SW // 2, title_y, COLORS["accent"], 58,
                         font_name=self.font, anchor_x="center", anchor_y="center")

        arcade.draw_text("天命所归 · 仗剑江湖", SW // 2, 500, (160, 140, 100), 22,
                         font_name=self.font, anchor_x="center", anchor_y="center")

        lw = 300
        ly = 470
        arcade.draw_line(SW // 2 - lw, ly, SW // 2 + lw, ly, (80, 60, 30), 1)
        arcade.draw_circle_filled(SW // 2, ly, 4, COLORS["accent"])

        my = 370
        for i, item in enumerate(self.menu_items):
            y = my - i * 80
            if i == self.menu_selection:
                bw, bh = 280, 50
                self._R(SW // 2 - bw // 2, y - bh // 2, bw, bh, (50, 42, 32, 200))
                self._RO(SW // 2 - bw // 2, y - bh // 2, bw, bh, COLORS["accent"], 2)
                bounce = math.sin(self.blink_timer * 4) * 3
                arcade.draw_triangle_filled(SW // 2 - bw // 2 - 20, y + bounce,
                                            SW // 2 - bw // 2 - 30, y - 8 + bounce,
                                            SW // 2 - bw // 2 - 30, y + 8 + bounce, COLORS["accent"])
                arcade.draw_text(item, SW // 2, y, COLORS["accent"], 28,
                                 font_name=self.font, anchor_x="center", anchor_y="center")
            else:
                arcade.draw_text(item, SW // 2, y, (120, 110, 90), 24,
                                 font_name=self.font, anchor_x="center", anchor_y="center")

        arcade.draw_text("v2.0 · 2026 水墨重制", SW // 2, 30, (80, 70, 55), 13,
                         font_name=self.font, anchor_x="center", anchor_y="center")

    def _draw_char_creation(self):
        self._R(0, 0, SW, SH, (28, 26, 20))
        self._R(0, SH - 3, SW, 3, COLORS["accent"])

        arcade.draw_text("创建角色", SW // 2, SH - 32, COLORS["accent"], 28,
                         font_name=self.font, anchor_x="center", anchor_y="center")

        margin = 20
        left_pw = 420
        right_pw = SW - margin * 2 - left_pw - 24
        left_px = margin
        right_px = left_px + left_pw + 24
        panel_bottom = 45
        panel_top = SH - 55
        panel_h = panel_top - panel_bottom

        left_focused = self.focus_target in ("name", "gender", "faction")
        right_focused = self.focus_target == "attr"
        self._draw_panel(left_px, panel_bottom, left_pw, panel_h, "角色信息",
                         focused=left_focused)
        self._draw_panel(right_px, panel_bottom, right_pw, panel_h, "属性分配",
                         focused=right_focused)

        pcx = left_px + left_pw // 2
        content_top = panel_bottom + panel_h - 40

        pcy = content_top - 130
        fo_val = math.sin(self.float_anim * 2) * 3

        halo_r = 58 + math.sin(self.float_anim * 3) * 4
        arcade.draw_circle_outline(pcx, pcy + fo_val, halo_r, (255, 200, 100, 28), 2)

        if self.char_gender == "male":
            bc_col, dc_col = (80, 130, 230), (60, 110, 210)
        else:
            bc_col, dc_col = (230, 130, 170), (210, 110, 150)

        arcade.draw_ellipse_filled(pcx, pcy - 70 + fo_val, 42, 9, (0, 0, 0, 28))
        arcade.draw_circle_filled(pcx, pcy + 22 + fo_val, 30, bc_col)
        arcade.draw_circle_outline(pcx, pcy + 22 + fo_val, 30, (255, 255, 255, 90), 2)
        arcade.draw_circle_filled(pcx - 9, pcy + 26 + fo_val, 2.8, (20, 20, 40))
        arcade.draw_circle_filled(pcx + 9, pcy + 26 + fo_val, 2.8, (20, 20, 40))
        self._R(pcx - 20, pcy - 38 + fo_val, 40, 54, dc_col)
        self._R(pcx - 15, pcy - 68 + fo_val, 13, 26, (55, 55, 75))
        self._R(pcx + 2, pcy - 68 + fo_val, 13, 26, (55, 55, 75))

        if self.char_gender == "male":
            arcade.draw_line(pcx + 26, pcy + 8 + fo_val, pcx + 26, pcy - 32 + fo_val, (220, 220, 230), 3)
            arcade.draw_circle_filled(pcx + 26, pcy - 32 + fo_val, 4.5, (255, 220, 100))
        else:
            arcade.draw_circle_filled(pcx, pcy + 46 + fo_val, 7.5, (255, 230, 240))
            self._R(pcx - 26, pcy - 68 + fo_val, 52, 28, (180, 90, 120))

        nlabel_y = pcy - 105
        arcade.draw_text("姓 名", pcx, nlabel_y, (150, 140, 120), 14,
                         font_name=self.font, anchor_x="center", anchor_y="center")

        nbox_w, nbox_h = 300, 38
        nbox_x = pcx - nbox_w // 2
        nbox_y = nlabel_y - 33
        nfocused = self.focus_target == "name"
        nbg = (34, 40, 64) if nfocused else (24, 28, 46)
        nbrd = COLORS["accent"] if nfocused else (48, 53, 74)
        self._R(nbox_x, nbox_y, nbox_w, nbox_h, nbg)
        self._RO(nbox_x, nbox_y, nbox_w, nbox_h, nbrd, 2 if nfocused else 1)

        dname = self.char_name if self.char_name else "点击此处输入姓名"
        nc_color = COLORS["accent"] if self.char_name else (120, 110, 90)
        arcade.draw_text(dname, pcx, nbox_y + nbox_h // 2, nc_color, 15,
                         font_name=self.font, anchor_x="center", anchor_y="center")

        if nfocused and int(self.blink_timer * 2) % 2 == 0:
            cur_x = nbox_x + 12 + len(dname) * 10
            arcade.draw_line(cur_x, nbox_y + 7, cur_x, nbox_y + nbox_h - 7, COLORS["accent"], 2)

        gbtn_y = nbox_y - 62
        gbtn_w, gbtn_h = 108, 46
        gbtn_sp = 32
        gbtn_full = gbtn_w * 2 + gbtn_sp
        gbtn_sx = pcx - gbtn_full // 2
        gfocused = self.focus_target == "gender"

        gx_male = gbtn_sx
        male_sel = self.char_gender == "male"
        if gfocused:
            self._RO(gbtn_sx - 4, gbtn_y - 4, gbtn_full + 8, gbtn_h + 8,
                     (255, 220, 100, int(80 + 40 * math.sin(self.blink_timer * 3))), 2)
        self._R(gx_male, gbtn_y, gbtn_w, gbtn_h,
                (45, 70, 130, 215) if male_sel else (28, 32, 50, 155))
        self._RO(gx_male, gbtn_y, gbtn_w, gbtn_h,
                 (100, 160, 255, 200) if (male_sel and gfocused) else ((100, 160, 255) if male_sel else (50, 55, 76)),
                 2 if (male_sel and gfocused) else (2 if male_sel else 1))
        arcade.draw_text("男", gx_male + gbtn_w // 2, gbtn_y + gbtn_h // 2,
                         (100, 160, 255) if male_sel else (118, 118, 138), 21,
                         font_name=self.font, anchor_x="center", anchor_y="center")

        gx_female = gx_male + gbtn_w + gbtn_sp
        female_sel = self.char_gender == "female"
        self._R(gx_female, gbtn_y, gbtn_w, gbtn_h,
                (110, 55, 80, 215) if female_sel else (42, 28, 38, 155))
        self._RO(gx_female, gbtn_y, gbtn_w, gbtn_h,
                 (255, 150, 180, 200) if (female_sel and gfocused) else ((255, 150, 180) if female_sel else (66, 44, 54)),
                 2 if (female_sel and gfocused) else (2 if female_sel else 1))
        arcade.draw_text("女", gx_female + gbtn_w // 2, gbtn_y + gbtn_h // 2,
                         (255, 170, 200) if female_sel else (118, 118, 138), 21,
                         font_name=self.font, anchor_x="center", anchor_y="center")

        faction_y = gbtn_y - 80
        arcade.draw_text("门 派", pcx, faction_y + 40, (150, 140, 120), 14,
                         font_name=self.font, anchor_x="center", anchor_y="center")

        factions_display = [
            (Faction.NONE, "无门无派", (150, 150, 150), "自由散人，不受门派约束"),
            (Faction.BAGUA, "八卦门", (255, 180, 80), "八卦刀法 · 混元一气 · 游龙步法"),
            (Faction.FLOWER, "花间派", (255, 150, 220), "花飞剑法 · 花团锦簇 · 三花聚顶"),
            (Faction.HONGLIAN, "红莲教", (255, 100, 100), "披风刀法 · 同击术 · 太祖长拳"),
            (Faction.NAJA, "那迦派", (180, 180, 255), "一刀斩 · 忍术 · 无影步"),
            (Faction.TAIJI, "太极门", (220, 220, 255), "太极剑法 · 太极拳法 · 太极功"),
            (Faction.XUESHAN, "雪山派", (200, 220, 255), "雪山剑法 · 雪上霜 · 踏雪无痕"),
        ]

        fc_w, fc_h = 360, 28
        fc_x = pcx - fc_w // 2
        fc_y = faction_y
        ffocused = self.focus_target == "faction"

        if ffocused:
            total_h = len(factions_display) * (fc_h + 4)
            glow_a = int(60 + 30 * math.sin(self.blink_timer * 3))
            self._RO(fc_x - 4, fc_y - total_h - 2, fc_w + 8, total_h + 8,
                     (255, 220, 100, glow_a), 2)

        for idx, (fid, fname, fcolor, fdesc) in enumerate(factions_display):
            fy = fc_y - idx * (fc_h + 4)
            is_sel = self.char_faction == fid
            if is_sel:
                self._R(fc_x, fy, fc_w, fc_h, (fcolor[0] // 6, fcolor[1] // 6, fcolor[2] // 6, 200))
                self._RO(fc_x, fy, fc_w, fc_h, fcolor, 2)
                arcade.draw_text(f"◆ {fname}", fc_x + 10, fy + fc_h // 2, fcolor, 15,
                                 font_name=self.font, anchor_x="left", anchor_y="center")
                arcade.draw_text(fdesc, fc_x + fc_w - 10, fy + fc_h // 2, (180, 180, 180), 10,
                                 font_name=self.font, anchor_x="right", anchor_y="center")
            else:
                self._R(fc_x, fy, fc_w, fc_h, (20, 24, 40, 150))
                self._RO(fc_x, fy, fc_w, fc_h, (50, 55, 70), 1)
                arcade.draw_text(f"  {fname}", fc_x + 10, fy + fc_h // 2, (100, 100, 120), 14,
                                 font_name=self.font, anchor_x="left", anchor_y="center")

        attr_keys = ["strength", "dexterity", "intelligence", "constitution"]
        attr_names = ["臂 力", "身 法", "悟 性", "根 骨"]
        attr_descs = ["近战伤害 · 负重上限", "闪避率 · 行动速度", "学习效率 · 内力上限", "生命值 · 防御力"]

        a_top_pad = 55
        a_bot_pad = 70
        a_area_top = panel_bottom + panel_h - a_top_pad
        a_area_bottom = panel_bottom + a_bot_pad
        a_area_h = a_area_top - a_area_bottom
        a_row_h = a_area_h / 4

        for idx in range(4):
            cy = a_area_top - idx * a_row_h - a_row_h / 2
            is_selected = idx == self.selected_attr
            aval = self.char_attributes[attr_keys[idx]]

            sel_box_h = a_row_h - 22
            sel_box_y = cy - sel_box_h / 2
            if is_selected:
                self._R(right_px + 18, sel_box_y, right_pw - 36, sel_box_h, (45, 38, 28, 195))
                self._RO(right_px + 18, sel_box_y, right_pw - 36, sel_box_h, (160, 140, 100), 2)

            txt_color = COLORS["accent"] if is_selected else (192, 192, 192)
            arcade.draw_text(f"【{attr_names[idx]}】", right_px + 34, cy + 7, txt_color, 19,
                             font_name=self.font, anchor_x="left", anchor_y="center")
            arcade.draw_text(attr_descs[idx], right_px + 34, cy - 14, (120, 110, 90), 12,
                             font_name=self.font, anchor_x="left", anchor_y="center")

            bar_w, bar_h = 130, 16
            bar_x = right_px + right_pw - bar_w - 125
            bar_y = cy
            self._R(bar_x, bar_y - bar_h / 2, bar_w, bar_h, (20, 18, 14))
            self._RO(bar_x, bar_y - bar_h / 2, bar_w, bar_h, (80, 70, 55), 1)

            fill_w = ((aval - 10) / 20) * bar_w
            if is_selected:
                fill_color = COLORS["accent"]
            else:
                ratio = max(0.0, min(1.0, (aval - 10) / 20.0))
                fill_color = (int(98 + 157 * ratio), int(155 - 57 * ratio), int(75 + 117 * ratio))
            if fill_w > 2:
                self._R(bar_x, bar_y - bar_h / 2 + 1, fill_w, bar_h - 2, fill_color)

            val_color = COLORS["gold"] if is_selected else (172, 162, 132)
            arcade.draw_text(f"{aval:2d}", bar_x + bar_w + 15, bar_y, val_color, 21,
                             font_name=self.font, anchor_x="left", anchor_y="center")

        pts_w, pts_h = 178, 34
        pts_x = margin
        pts_y = 10
        has_pts = self.attribute_points > 0
        self._R(pts_x, pts_y, pts_w, pts_h, (35, 50, 28) if has_pts else (55, 25, 20))
        self._RO(pts_x, pts_y, pts_w, pts_h, (120, 160, 80) if has_pts else (180, 80, 60), 2)
        arcade.draw_text(f"剩余点数: {self.attribute_points}", pts_x + pts_w // 2, pts_y + pts_h // 2,
                         COLORS["gold"] if has_pts else (198, 92, 92), 16,
                         font_name=self.font, anchor_x="center", anchor_y="center")

        hint_x = pts_x + pts_w + 22
        hint_y = pts_y + 3
        hint_list = [
            ("Tab", "切换焦点"), ("←→", "选择/加减"), ("回车", "开始游戏"), ("ESC", "返回菜单"),
        ]
        for hk, hd in hint_list:
            arcade.draw_text(hk, hint_x, hint_y, (193, 173, 113), 12,
                             font_name=self.font, anchor_x="left", anchor_y="bottom")
            hint_x += 32
            arcade.draw_text(hd, hint_x, hint_y, (110, 100, 80), 12,
                             font_name=self.font, anchor_x="left", anchor_y="bottom")
            hint_x += 102

        flabels = {"name": "◆ 姓名输入中", "gender": "◆ 性别选择中", "attr": "◆ 属性分配中", "faction": "◆ 门派选择中"}
        ftx = SW - margin - 8
        pulse_v = int(200 + 55 * math.sin(self.blink_timer * 3))
        arcade.draw_text(flabels.get(self.focus_target, ""), ftx, pts_y + pts_h // 2,
                         (pulse_v, int(pulse_v * 0.85), int(pulse_v * 0.5)), 15, font_name=self.font,
                         anchor_x="right", anchor_y="center")

        if self.char_creation_msg:
            msg_y = pts_y + pts_h + 12
            arcade.draw_text(self.char_creation_msg, margin, msg_y, (220, 80, 80), 15,
                             font_name=self.font, anchor_x="left", anchor_y="top")

    def _draw_panel(self, px, py, pw, ph, ttl, focused=False):
        self._R(px, py, pw, ph, (25, 22, 18, 245))
        border_c = COLORS["accent"] if focused else (120, 105, 80)
        border_w = 3 if focused else 2
        self._RO(px, py, pw, ph, border_c, border_w)
        if focused:
            glow_alpha = int(40 + 20 * math.sin(self.blink_timer * 3))
            self._RO(px - 1, py - 1, pw + 2, ph + 2,
                     (COLORS["accent"][0], COLORS["accent"][1], COLORS["accent"][2], glow_alpha), 2)
        arcade.draw_line(px + 14, py + ph - 11, px + pw - 14, py + ph - 11, (80, 70, 55), 1)
        ttl_color = COLORS["accent"] if focused else (180, 160, 120)
        arcade.draw_text(ttl, px + pw // 2, py + ph - 27, ttl_color, 17,
                         font_name=self.font, anchor_x="center", anchor_y="center")

    def _draw_game(self):
        if self._in_combat:
            self._draw_combat()
            return

        p = self.game_world.player
        cam = self.game_world.current_map
        if p and cam:
            target_x = p.position.x
            target_y = p.position.y
            self.camera_x += (target_x - self.camera_x) * 0.15
            self.camera_y += (target_y - self.camera_y) * 0.15

        shake_x, shake_y = self.vfx.get_camera_offset()
        cam_x = self.camera_x + shake_x
        cam_y = self.camera_y + shake_y

        # Pre-calculate screen bounds for viewport culling
        screen_left = cam_x - SW // 2 - 64
        screen_right = cam_x + SW // 2 + 64
        screen_bottom = cam_y - SH // 2 - 64
        screen_top = cam_y + SH // 2 + 64

        renderer.draw_map(cam_x, cam_y, self.game_world.current_map)

        renderer.clear_light_sources()
        for npc in self.game_world.npcs:
            if not (screen_left <= npc.position.x <= screen_right and
                    screen_bottom <= npc.position.y <= screen_top):
                continue
            if npc.is_master:
                renderer.add_light_source(npc.position.x, npc.position.y, 100, (255, 200, 100), 0.4)
            elif npc.npc_type == NpcType.ENEMY:
                renderer.add_light_source(npc.position.x, npc.position.y, 80, (255, 80, 80), 0.3)

        self._spawn_ambient_particles(cam_x, cam_y)
        for part in self.particles:
            sx, sy = renderer.world_to_screen(part["x"], part["y"], cam_x, cam_y)
            if sx < -20 or sx > SW + 20 or sy < -20 or sy > SH + 20:
                continue
            alpha = int(255 * (part["life"] / part["max_life"]))
            c = part["color"]
            arcade.draw_circle_filled(sx, sy, part["size"], (c[0], c[1], c[2], max(0, min(255, alpha))))

        for npc in self.game_world.npcs:
            if not (screen_left <= npc.position.x <= screen_right and
                    screen_bottom <= npc.position.y <= screen_top):
                continue
            renderer.draw_npc(npc, cam_x, cam_y)

        if p:
            renderer.draw_player(p, cam_x, cam_y)

        self.vfx.draw_particles()
        self.vfx.draw_damage_numbers()

        self.vfx.draw_day_night()

        self.vfx.draw_weather()

        # Draw atmosphere weather particles
        if self.atmosphere and hasattr(self.atmosphere, 'renderer'):
            particles = self.atmosphere.renderer.particles
            weather = self.atmosphere.weather
            if particles and weather:
                wtype = weather.current_weather.name
                for p in particles:
                    sx = int(p.get('x', 0))
                    sy = int(p.get('y', 0))
                    if 0 <= sx <= SW and 0 <= sy <= SH:
                        if wtype in ('RAIN', 'HEAVY_RAIN', 'THUNDER'):
                            arcade.draw_line(sx, sy, sx, sy + p.get('size', 2) * 4,
                                           (180, 200, 240, 150), 1)
                        elif wtype in ('SNOW', 'HEAVY_SNOW'):
                            arcade.draw_circle_filled(sx, sy, p.get('size', 2), (255, 255, 255, 200))
                        elif wtype == 'WIND':
                            arcade.draw_line(sx, sy, sx + p.get('size', 3) * 2, sy, (180, 150, 100, 100), 1)

        self.vfx.draw_vignette()

        from .render.post_process import get_post_processor, get_advanced_lights, get_env_particles
        post = get_post_processor()
        lights = get_advanced_lights()
        env = get_env_particles()

        day_progress = self.vfx.day_night.time if hasattr(self.vfx, 'day_night') else 0.5
        lights.draw(cam_x, cam_y, day_progress)
        env.draw(day_progress)
        post.draw_all(day_progress)

        if p:
            renderer.draw_hud(p, self.game_world.game_time, self.game_world.current_map,
                            self.atmosphere, self.reputation, self.economy)

        if self.interaction_prompt and not self.show_dialog:
            self._draw_interaction_prompt()

        if self.show_minimap:
            renderer.draw_minimap(cam_x, cam_y, self.game_world.current_map, p, self.game_world.npcs)

        if self.show_inventory and p:
            self._draw_inventory(p)

        if self.show_skill_panel and p:
            self._draw_skill_panel(p)

        if self.show_dialog and self.dialog_text:
            renderer.set_dialog_text(self.dialog_text)
            renderer.draw_dialog(self.dialog_text, SW, SH, self.dialog_title, self.dialog_type)

            if self.player_input_mode:
                input_y = 85
                self._R(40, input_y, SW - 80, 36, (20, 25, 45, 240))
                self._RO(40, input_y, SW - 80, 36, COLORS["accent"], 2)
                display_text = self.player_input_text
                if int(self.blink_timer * 2) % 2 == 0:
                    display_text += "▎"
                arcade.draw_text(f"你说：{display_text}", 60, input_y + 18,
                                 COLORS["accent"], 16, font_name=self.font,
                                 anchor_x="left", anchor_y="center")
                arcade.draw_text("回车发送 | ESC取消", SW - 60, input_y + 18,
                                 (120, 120, 140), 12, font_name=self.font,
                                 anchor_x="right", anchor_y="center")
            elif self.dialogue_options and self.current_npc:
                opt_y = 85
                opt_h = 36
                self._R(40, opt_y, SW - 80, opt_h, (15, 20, 38, 235))
                self._RO(40, opt_y, SW - 80, opt_h, (60, 70, 100), 1)
                opt_x = 60
                for i, opt in enumerate(self.dialogue_options):
                    color = COLORS["accent"] if i == 0 else (180, 180, 200)
                    arcade.draw_text(f"[{i+1}]{opt}", opt_x, opt_y + opt_h // 2,
                                     color, 14, font_name=self.font,
                                     anchor_x="left", anchor_y="center")
                    opt_x += len(opt) * 14 + 40

            if self.pending_encounter and not self.encounter_display:
                hint_y = 50
                pulse = int(200 + 55 * math.sin(self.blink_timer * 4))
                self._R(SW // 2 - 200, hint_y, 400, 30, (40, 20, 60, 220))
                self._RO(SW // 2 - 200, hint_y, 400, 30, (pulse, pulse // 2, pulse), 2)
                arcade.draw_text("✦ 感受到奇遇机缘！按 Y 查看 | 按 N 忽略",
                                 SW // 2, hint_y + 15, (pulse, pulse, min(255, pulse + 50)),
                                 14, font_name=self.font,
                                 anchor_x="center", anchor_y="center")

        if getattr(self, '_show_tutorial', False) and p:
            self._draw_tutorial()

        if self._zone_name_timer > 0 and self.game_world.current_map:
            self._draw_zone_name()

    def _draw_zone_name(self):
        cmap = self.game_world.current_map
        if not cmap:
            return
        zone_name = cmap.name
        zone_type = cmap.zone_type
        type_labels = {
            "city": "城", "town": "镇", "sect": "宗门", "wild": "野外"
        }
        type_label = type_labels.get(zone_type, "")
        alpha = min(1.0, self._zone_name_timer / 0.5) if self._zone_name_timer < 0.5 else 1.0
        alpha_int = int(255 * alpha)

        banner_w = 500
        banner_h = 80
        bx = SW // 2 - banner_w // 2
        by = SH // 2 - banner_h // 2 - 100

        self._R(bx, by, banner_w, banner_h, (20, 18, 14, int(220 * alpha)))
        self._RO(bx, by, banner_w, banner_h, (180, 155, 100, alpha_int), 2)

        deco_y_top = by + 8
        deco_y_bot = by + banner_h - 8
        deco_x_left = bx + 20
        deco_x_right = bx + banner_w - 20
        line_color = (140, 120, 80, alpha_int)
        arcade.draw_line(deco_x_left, deco_y_top, deco_x_right, deco_y_top, line_color, 1)
        arcade.draw_line(deco_x_left, deco_y_bot, deco_x_right, deco_y_bot, line_color, 1)

        if type_label:
            arcade.draw_text(f"〔{type_label}〕", SW // 2, by + banner_h - 22,
                             (160, 140, 100, alpha_int), 14, font_name=self.font,
                             anchor_x="center", anchor_y="center")

        arcade.draw_text(zone_name, SW // 2, by + banner_h // 2 + 4,
                         (230, 210, 160, alpha_int), 28, font_name=self.font,
                         anchor_x="center", anchor_y="center")

        desc = cmap.description
        if desc:
            arcade.draw_text(desc, SW // 2, by + 18,
                             (140, 130, 110, alpha_int), 12, font_name=self.font,
                             anchor_x="center", anchor_y="center")

    def _draw_interaction_prompt(self):
        pw = len(self.interaction_prompt) * 12 + 40
        ph = 36
        px = SW // 2 - pw // 2
        py = SH - 120

        self._R(px, py, pw, ph, (15, 20, 40, 220))
        self._RO(px, py, pw, ph, COLORS["accent"], 2)

        pulse = int(200 + 55 * math.sin(self.blink_timer * 3))
        arcade.draw_text(self.interaction_prompt, SW // 2, py + ph // 2,
                         (pulse, pulse, min(255, pulse + 50)), 15,
                         font_name=self.font, anchor_x="center", anchor_y="center")

    def _draw_tutorial(self):
        tw, th = 420, 380
        tx = SW // 2 - tw // 2
        ty = SH // 2 - th // 2 + 40

        self._R(tx, ty, tw, th, (30, 28, 22, 240))
        self._RO(tx, ty, tw, th, (180, 155, 100), 2)
        arcade.draw_line(tx + 14, ty + th - 40, tx + tw - 14, ty + th - 40, (120, 105, 80), 1)
        arcade.draw_text("江湖指南", tx + tw // 2, ty + th - 22, (200, 180, 130), 22,
                         font_name=self.font, anchor_x="center", anchor_y="center")

        guides = [
            ("移动", "W/A/S/D 或 方向键"),
            ("对话", "靠近NPC后按 T"),
            ("攻击", "靠近敌人后按 F"),
            ("背包", "按 B 打开/关闭"),
            ("武功", "按 K 查看技能"),
            ("使用物品", "按 E 使用背包中第一个消耗品"),
            ("客栈休息", "按 R 恢复生命和内力"),
            ("购买商品", "对话选查看商品后按数字键购买"),
            ("战斗操作", "1攻击 2技能 3防御 4逃跑 5物品"),
            ("小地图", "按 M 开关"),
            ("声望/装备", "按 P / G 查看"),
        ]

        iy = ty + th - 65
        for label, desc in guides:
            arcade.draw_text(f"【{label}】", tx + 25, iy, (200, 180, 130), 13,
                             font_name=self.font, anchor_x="left", anchor_y="center")
            arcade.draw_text(desc, tx + 110, iy, (160, 155, 140), 12,
                             font_name=self.font, anchor_x="left", anchor_y="center")
            iy -= 26

        arcade.draw_text("按 H 关闭此指南", tx + tw // 2, ty + 12, (120, 110, 90), 12,
                         font_name=self.font, anchor_x="center", anchor_y="center")

    def _draw_inventory(self, p):
        pw, ph = 400, 500
        px = SW // 2 - pw // 2
        py = SH // 2 - ph // 2

        self._R(px, py, pw, ph, (15, 20, 38, 245))
        self._RO(px, py, pw, ph, COLORS["accent"], 2)
        arcade.draw_line(px + 14, py + ph - 40, px + pw - 14, py + ph - 40, (44, 52, 72), 1)
        arcade.draw_text("背 包", px + pw // 2, py + ph - 22, COLORS["accent"], 20,
                         font_name=self.font, anchor_x="center", anchor_y="center")

        if p.inventory:
            iy = py + ph - 65
            for item_id, qty in list(p.inventory.items())[self.inv_scroll:self.inv_scroll + 12]:
                item = self.game_world.get_item_by_id(item_id)
                name = item.name if item else item_id
                type_colors = {"consumable": (100, 255, 100), "weapon": (255, 180, 100), "armor": (100, 180, 255), "book": (255, 255, 100), "material": (180, 180, 180)}
                tc = type_colors.get(item.type.value if item else "", (200, 200, 200))
                self._R(px + 15, iy - 12, pw - 30, 28, (25, 30, 50, 180))
                arcade.draw_text(f"{name} x{qty}", px + 25, iy, tc, 15,
                                 font_name=self.font, anchor_x="left", anchor_y="center")
                if item and item.price > 0:
                    arcade.draw_text(f"{item.price}文", px + pw - 25, iy, COLORS["gold"], 12,
                                     font_name=self.font, anchor_x="right", anchor_y="center")
                iy -= 34
        else:
            arcade.draw_text("背包空空如也", px + pw // 2, py + ph // 2, (100, 100, 120), 18,
                             font_name=self.font, anchor_x="center", anchor_y="center")

        arcade.draw_text("按 B 关闭 | ↑↓ 翻页", px + pw // 2, py + 15, (100, 100, 120), 12,
                         font_name=self.font, anchor_x="center", anchor_y="center")

    def _draw_skill_panel(self, p):
        pw, ph = 450, 500
        px = SW // 2 - pw // 2
        py = SH // 2 - ph // 2

        self._R(px, py, pw, ph, (15, 20, 38, 245))
        self._RO(px, py, pw, ph, (100, 180, 255), 2)
        arcade.draw_line(px + 14, py + ph - 40, px + pw - 14, py + ph - 40, (44, 52, 72), 1)
        arcade.draw_text("武 功", px + pw // 2, py + ph - 22, (100, 180, 255), 20,
                         font_name=self.font, anchor_x="center", anchor_y="center")

        from .systems.cultivation import get_cultivation_system, get_mastery_tier, get_mastery_color
        cult_sys = get_cultivation_system()

        if p.skills:
            iy = py + ph - 65
            for skill in p.skills[self.skill_scroll:self.skill_scroll + 10]:
                type_colors = {0: (255, 150, 150), 1: (150, 200, 255), 2: (255, 180, 100), 3: (200, 150, 255), 4: (150, 255, 200), 5: (200, 200, 200), 6: (255, 200, 150), 7: (200, 180, 150), 8: (255, 150, 200), 9: (255, 255, 150), 10: (255, 200, 220)}
                tc = type_colors.get(skill.type, (200, 200, 200))
                self._R(px + 15, iy - 12, pw - 30, 28, (25, 30, 50, 180))
                tier = get_mastery_tier(skill.level)
                tier_color = get_mastery_color(tier)
                arcade.draw_text(f"{skill.name} Lv.{skill.level} [{tier}]", px + 25, iy, tc, 15,
                                 font_name=self.font, anchor_x="left", anchor_y="center")
                bar_w = 100
                bar_x = px + pw - 30 - bar_w
                exp_needed = cult_sys.get_skill_exp_for_next_level(skill)
                exp_pct = skill.exp / exp_needed if exp_needed > 0 else 0
                self._R(bar_x, iy - 5, bar_w, 10, (30, 30, 50))
                if exp_pct > 0:
                    self._R(bar_x, iy - 5, int(bar_w * min(1.0, exp_pct)), 10, tier_color)
                iy -= 34
        else:
            arcade.draw_text("尚未习得武功", px + pw // 2, py + ph // 2, (100, 100, 120), 18,
                             font_name=self.font, anchor_x="center", anchor_y="center")

        arcade.draw_text("按 K 关闭 | ↑↓ 翻页", px + pw // 2, py + 15, (100, 100, 120), 12,
                         font_name=self.font, anchor_x="center", anchor_y="center")

    def on_key_press(self, key, modifiers):
        if self.game_state == "menu":
            if key == arcade.key.UP:
                self.menu_selection = (self.menu_selection - 1) % len(self.menu_items)
            elif key == arcade.key.DOWN:
                self.menu_selection = (self.menu_selection + 1) % len(self.menu_items)
            elif key == arcade.key.ENTER:
                if self.menu_selection == 0:
                    self.game_state = "char_creation"
                    self._reset_char_creation()
                elif self.menu_selection == 2:
                    arcade.close_window()
        elif self.game_state == "char_creation":
            ak = ["strength", "dexterity", "intelligence", "constitution"]
            factions_list = [Faction.NONE, Faction.BAGUA, Faction.FLOWER, Faction.HONGLIAN, Faction.NAJA, Faction.TAIJI, Faction.XUESHAN]

            if key == arcade.key.TAB:
                order = ["name", "gender", "faction", "attr"]
                cur = order.index(self.focus_target)
                self.focus_target = order[(cur + 1) % 4]
            elif key == arcade.key.LEFT:
                if self.focus_target == "name":
                    self.char_name = self.char_name[:-1]
                elif self.focus_target == "gender":
                    self.char_gender = "female" if self.char_gender == "male" else "male"
                elif self.focus_target == "faction":
                    cur_idx = factions_list.index(self.char_faction) if self.char_faction in factions_list else 0
                    self.char_faction = factions_list[(cur_idx - 1) % len(factions_list)]
                elif self.focus_target == "attr":
                    if self.char_attributes[ak[self.selected_attr]] > 10:
                        self.char_attributes[ak[self.selected_attr]] -= 1
                        self.attribute_points += 1
            elif key == arcade.key.RIGHT:
                if self.focus_target == "faction":
                    cur_idx = factions_list.index(self.char_faction) if self.char_faction in factions_list else 0
                    self.char_faction = factions_list[(cur_idx + 1) % len(factions_list)]
                elif self.focus_target == "attr":
                    if self.attribute_points > 0 and self.char_attributes[ak[self.selected_attr]] < 30:
                        self.char_attributes[ak[self.selected_attr]] += 1
                        self.attribute_points -= 1
            elif key == arcade.key.UP:
                if self.focus_target == "attr":
                    self.selected_attr = (self.selected_attr - 1) % 4
                elif self.focus_target == "faction":
                    cur_idx = factions_list.index(self.char_faction) if self.char_faction in factions_list else 0
                    self.char_faction = factions_list[(cur_idx - 1) % len(factions_list)]
            elif key == arcade.key.DOWN:
                if self.focus_target == "attr":
                    self.selected_attr = (self.selected_attr + 1) % 4
                elif self.focus_target == "faction":
                    cur_idx = factions_list.index(self.char_faction) if self.char_faction in factions_list else 0
                    self.char_faction = factions_list[(cur_idx + 1) % len(factions_list)]
            elif key == arcade.key.ENTER:
                if not self.char_name:
                    self.char_name = "无名侠客"
                if self.attribute_points > 0:
                    ak = ["strength", "dexterity", "intelligence", "constitution"]
                    idx = 0
                    while self.attribute_points > 0:
                        if self.char_attributes[ak[idx]] < 30:
                            self.char_attributes[ak[idx]] += 1
                            self.attribute_points -= 1
                        idx = (idx + 1) % 4
                self._create_player()
            elif key == arcade.key.ESCAPE:
                self.game_state = "menu"
        elif self.game_state == "playing":
            if getattr(self, '_in_combat', False) and self.show_dialog:
                combat_actions = {"1": "攻击", "2": "技能", "3": "防御", "4": "逃跑", "5": "物品"}
                if key == arcade.key.KEY_1:
                    self._combat_action("攻击")
                    return
                elif key == arcade.key.KEY_2:
                    self._combat_action("技能")
                    return
                elif key == arcade.key.KEY_3:
                    self._combat_action("防御")
                    return
                elif key == arcade.key.KEY_4:
                    self._combat_action("逃跑")
                    return
                elif key == arcade.key.KEY_5:
                    self._combat_action("物品")
                    return
                elif key == arcade.key.ESCAPE:
                    self._in_combat = False
                    self._combat_enemy = None
                    self._combat_log = []
                    self.game_world.combat_system.end_combat()
                    self.show_dialog = False
                    self.dialogue_options = []
                    return
                return

            if self._in_combat:
                cs = self.combat_system
                if key == arcade.key.UP:
                    if self._combat_menu_idx == 1:
                        self._combat_skill_idx = max(0, self._combat_skill_idx - 1)
                    else:
                        self._combat_menu_idx = max(0, self._combat_menu_idx - 1)
                elif key == arcade.key.DOWN:
                    if self._combat_menu_idx == 1:
                        self._combat_skill_idx += 1
                    else:
                        self._combat_menu_idx = min(3, self._combat_menu_idx + 1)
                elif key == arcade.key.ENTER or key == arcade.key.SPACE:
                    if cs.phase in (CombatPhase.VICTORY, CombatPhase.DEFEAT, CombatPhase.FLEE):
                        self._in_combat = False
                        self._combat_rewards = None
                    elif cs.phase == CombatPhase.PLAYER_TURN:
                        actions = ["attack", "skill", "defend", "flee"]
                        if self._combat_menu_idx < len(actions):
                            self._combat_action(actions[self._combat_menu_idx])
                elif key == arcade.key.LEFT:
                    self._combat_enemy_idx = max(0, self._combat_enemy_idx - 1)
                elif key == arcade.key.RIGHT:
                    alive = [e for e in cs.enemies if e.is_alive]
                    if alive:
                        self._combat_enemy_idx = min(len(alive)-1, self._combat_enemy_idx + 1)
                return

            if self.encounter_display:
                if key == arcade.key.Y:
                    self._accept_encounter()
                elif key == arcade.key.N or key == arcade.key.ESCAPE:
                    self.pending_encounter = None
                    self.encounter_display = False
                    self.show_dialog = False
                    self.current_npc = None
                    self.dialogue_options = []
                return

            if self.show_dialog:
                if self.player_input_mode:
                    if key == arcade.key.ENTER:
                        self._submit_player_input()
                    elif key == arcade.key.ESCAPE:
                        self.player_input_mode = False
                        self.player_input_text = ""
                    elif key == arcade.key.BACKSPACE:
                        self.player_input_text = self.player_input_text[:-1]
                    return

                if self._pending_task:
                    if key == arcade.key.Y:
                        self._accept_quest()
                        return
                    elif key == arcade.key.N:
                        self._pending_task = None
                        self.dialog_text = "你拒绝了任务。"
                        return

                if getattr(self, '_shop_items', []):
                    shop_keys = {
                        arcade.key.KEY_1: 0, arcade.key.KEY_2: 1,
                        arcade.key.KEY_3: 2, arcade.key.KEY_4: 3,
                        arcade.key.KEY_5: 4, arcade.key.KEY_6: 5,
                    }
                    if key in shop_keys:
                        idx = shop_keys[key]
                        if idx < len(self._shop_items):
                            self._buy_shop_item(idx)
                            return

                if self._pending_teach:
                    if key == arcade.key.Y:
                        self._accept_teach()
                        return
                    elif key == arcade.key.N:
                        self._pending_teach = None
                        self.dialog_text = "你放弃了学艺。"
                        return

                if self.pending_encounter:
                    if key == arcade.key.Y:
                        self._show_encounter()
                        return
                    elif key == arcade.key.N:
                        self.pending_encounter = None

                if key == arcade.key.SPACE or key == arcade.key.ESCAPE:
                    self.show_dialog = False
                    self.player_input_mode = False
                    self._pending_task = None
                    self._shop_items = []
                    self.current_npc = None
                    self.dialogue_options = []

                option_keys = {
                    arcade.key.KEY_1: 0, arcade.key.KEY_2: 1,
                    arcade.key.KEY_3: 2, arcade.key.KEY_4: 3,
                    arcade.key.KEY_5: 4, arcade.key.KEY_6: 5,
                }
                if key in option_keys:
                    idx = option_keys[key]
                    if idx < len(self.dialogue_options):
                        self._handle_dialogue_option(self.dialogue_options[idx])

                if key == arcade.key.T and self.current_npc:
                    self.player_input_mode = True
                    self.player_input_text = ""
                    self.dialog_text = "请输入你想说的话："
                return

            if self.show_inventory:
                if key == arcade.key.B or key == arcade.key.ESCAPE:
                    self.show_inventory = False
                elif key == arcade.key.UP:
                    self.inv_scroll = max(0, self.inv_scroll - 1)
                elif key == arcade.key.DOWN:
                    self.inv_scroll += 1
                return

            if self.show_skill_panel:
                if key == arcade.key.K or key == arcade.key.ESCAPE:
                    self.show_skill_panel = False
                elif key == arcade.key.UP:
                    self.skill_scroll = max(0, self.skill_scroll - 1)
                elif key == arcade.key.DOWN:
                    self.skill_scroll += 1
                return

            if key == arcade.key.W or key == arcade.key.UP:
                self.movement["up"] = True
            elif key == arcade.key.S or key == arcade.key.DOWN:
                self.movement["down"] = True
            elif key == arcade.key.A or key == arcade.key.LEFT:
                self.movement["left"] = True
            elif key == arcade.key.D or key == arcade.key.RIGHT:
                self.movement["right"] = True
            elif key == arcade.key.T:
                self.talk_to_npc()
            elif key == arcade.key.F:
                if self._in_combat:
                    self._combat_action("attack")
                else:
                    self.attack_npc()
            elif key == arcade.key.B:
                self.show_inventory = not self.show_inventory
                self.show_skill_panel = False
                self.show_journal = False
            elif key == arcade.key.K:
                self.show_skill_panel = not self.show_skill_panel
                self.show_inventory = False
                self.show_journal = False
            elif key == arcade.key.J:
                self.show_journal = not self.show_journal
                self.show_inventory = False
                self.show_skill_panel = False
            elif key == arcade.key.Q:
                self.show_quests()
            elif key == arcade.key.M:
                self.show_minimap = not self.show_minimap
            elif key == arcade.key.E:
                self._use_first_consumable()
            elif key == arcade.key.R:
                self._inn_rest()
            elif key == arcade.key.P:
                self._show_reputation()
            elif key == arcade.key.G:
                self._show_equipment()
            elif key == arcade.key.H:
                self._show_tutorial = not self._show_tutorial
            elif key == arcade.key.ESCAPE:
                self.game_state = "menu"
            elif key == arcade.key.SPACE:
                self.show_dialog = False
                self.current_npc = None
                self.dialogue_options = []

    def on_key_release(self, key, modifiers):
        if self.game_state == "playing":
            if key == arcade.key.W or key == arcade.key.UP:
                self.movement["up"] = False
            elif key == arcade.key.S or key == arcade.key.DOWN:
                self.movement["down"] = False
            elif key == arcade.key.A or key == arcade.key.LEFT:
                self.movement["left"] = False
            elif key == arcade.key.D or key == arcade.key.RIGHT:
                self.movement["right"] = False

    def on_text(self, text):
        if self.game_state == "char_creation" and self.focus_target == "name" and len(self.char_name) < 12:
            if text.isprintable():
                self.char_name += text
        elif self.game_state == "playing" and self.player_input_mode and len(self.player_input_text) < 30:
            if text.isprintable():
                self.player_input_text += text

    def _reset_char_creation(self):
        self.char_name = ""
        self.char_gender = "male"
        self.char_faction = Faction.NONE
        self.char_attributes = {"strength": 15, "dexterity": 15, "intelligence": 15, "constitution": 15}
        self.attribute_points = 20
        self.selected_attr = 0
        self.focus_target = "name"
        self.blink_timer = 0.0
        self.float_anim = 0.0

    def _create_player(self):
        p = self.game_world.player
        p.name = self.char_name or "无名侠客"
        p.gender = self.char_gender
        p.faction = self.char_faction
        p.strength = self.char_attributes["strength"]
        p.dexterity = self.char_attributes["dexterity"]
        p.intelligence = self.char_attributes["intelligence"]
        p.constitution = self.char_attributes["constitution"]
        p.setup_attr()
        p.hp = p.max_hp
        p.mp = p.max_mp
        p.position.x = col_to_x(25)
        p.position.y = row_to_y(31)
        self.camera_x = p.position.x
        self.camera_y = p.position.y

        self.game_world._init_player_skills()

        # 链接经济系统和声望系统到玩家
        self.economy.link_player(self.game_world.player)
        self.reputation.link_player(self.game_world.player)

        # === 初始化修炼系统：关联玩家并自动学习门派内功 ===
        self.cultivation.link_player(p)
        # 根据玩家门派自动学习对应内功心法
        faction_internal_map = {
            Faction.BAGUA: "hunyuan_gong",
            Faction.TAIJI: "taiji_gong",
            Faction.FLOWER: "flower_heart",
            Faction.HONGLIAN: "honglian_jue",
            Faction.NAJA: "naja_jue",
            Faction.XUESHAN: "xueshan_gong",
            Faction.XIAOYAO: "beiming_shengong",
        }
        art_id = faction_internal_map.get(self.char_faction, "")
        if art_id:
            self.cultivation.learn_internal_art(art_id)

        if self.char_faction != Faction.NONE:
            self.game_world.reputation_system.on_join_faction(p, self.char_faction)
            from .world import FACTION_SKILLS, ALL_SKILLS
            faction_skills = FACTION_SKILLS.get(self.char_faction, [])
            for skill_id in faction_skills:
                if not any(s.id == skill_id for s in p.skills):
                    if skill_id in ALL_SKILLS:
                        new_skill = Skill(
                            id=ALL_SKILLS[skill_id].id,
                            name=ALL_SKILLS[skill_id].name,
                            type=ALL_SKILLS[skill_id].type,
                            level=1, exp=0,
                            damage=ALL_SKILLS[skill_id].damage,
                            accuracy=ALL_SKILLS[skill_id].accuracy,
                        )
                        p.skills.append(new_skill)

        # 关联装备/打造系统到玩家并给予初始装备
        self.player_inventory.link_player(p)
        self.player_inventory.add_item("rusty_sword", 1)

        self.game_state = "playing"

    def talk_to_npc(self):
        if not self.game_world.player:
            return
        n = self.game_world.get_nearby_npc(self.game_world.player.position)
        if n:
            self.current_npc = n
            result = self.game_world.talk_to_npc(self.game_world.player, n)
            self.dialogue_result = result
            self.dialogue_state = result.get("state", DialogueState.GREETING)
            self.dialog_text = result.get("text", "……")
            self.dialog_title = n.name
            self.dialog_type = "npc"
            self.show_dialog = True
            self.player_input_mode = False
            self.player_input_text = ""

            self._update_dialogue_options(result)

            if "encounter" in result:
                self.pending_encounter = result["encounter"]
        else:
            self.dialog_text = "附近没有可以对话的人"
            self.dialog_title = "提示"
            self.dialog_type = "info"
            self.show_dialog = True

    def _update_dialogue_options(self, result: Dict):
        self.dialogue_options = []
        if not result:
            return
        can_quest = result.get("can_quest", False)
        can_teach = result.get("can_teach", False)
        can_trade = result.get("can_trade", False)

        self.dialogue_options.append("继续交谈")
        if can_quest:
            self.dialogue_options.append("询问任务")
        if can_teach:
            self.dialogue_options.append("请求传授武功")
        if can_trade:
            self.dialogue_options.append("查看商品")
        self.dialogue_options.append("输入话题")
        self.dialogue_options.append("告辞")

    def _handle_dialogue_option(self, option: str):
        if not self.current_npc or not self.game_world.player:
            return

        if option == "告辞":
            brain_mgr = get_npc_brain_manager()
            brain = brain_mgr.get_brain(self.current_npc)
            brain.reset_state()
            self.show_dialog = False
            self.current_npc = None
            self.dialogue_options = []
            self.dialogue_state = DialogueState.GREETING
            self.player_input_mode = False
            return

        if option == "输入话题":
            self.player_input_mode = True
            self.player_input_text = ""
            self.dialog_text = "请输入你想说的话："
            return

        if option == "询问任务":
            task = self.game_world.request_npc_quest(self.game_world.player, self.current_npc)
            if task:
                reward_parts = []
                r = task.get("reward", {})
                if "money" in r:
                    reward_parts.append(f"银两{r['money']}")
                if "exp" in r:
                    reward_parts.append(f"经验{r['exp']}")
                if "pot" in r:
                    reward_parts.append(f"潜能{r['pot']}")
                reward_str = " | ".join(reward_parts) if reward_parts else "无"
                self.dialog_text = (f"【{self.current_npc.name}】发布任务：\n\n"
                                   f"「{task.get('title', '未知任务')}」\n"
                                   f"{task.get('description', '')}\n\n"
                                   f"难度：{'★' * task.get('difficulty', 1)}\n"
                                   f"奖励：{reward_str}\n\n"
                                   f"按 Y 接受任务 | 按 N 拒绝")
                self.dialog_type = "quest"
                self._pending_task = task
            else:
                self.dialog_text = f"【{self.current_npc.name}】暂时没有适合你的任务。"
            return

        if option == "请求传授武功":
            if self.current_npc.teach_skills:
                from .world import ALL_SKILLS
                from .systems.cultivation import get_mastery_tier, get_mastery_color
                skill_info = []
                for sid in self.current_npc.teach_skills:
                    if sid in ALL_SKILLS:
                        s = ALL_SKILLS[sid]
                        player_skill = next((ps for ps in self.game_world.player.skills if ps.id == sid), None)
                        if player_skill:
                            tier = get_mastery_tier(player_skill.level)
                            skill_info.append(f"  · {s.name} (Lv.{player_skill.level} {tier})")
                        else:
                            skill_info.append(f"  · {s.name} (未学习)")
                cost = 10 + (self.current_npc.level or 1) * 2
                self.dialog_text = (f"【{self.current_npc.name}】我可以传授你：\n"
                                   + "\n".join(skill_info)
                                   + f"\n\n修炼费用：{cost}文/次"
                                   + "\n\n按 Y 开始修炼 | 按 N 取消")
                self.dialog_type = "npc"
                self._pending_teach = {"npc": self.current_npc, "skills": self.current_npc.teach_skills}
            else:
                self.dialog_text = f"【{self.current_npc.name}】我没什么可教你的。"
            return

        if option == "查看商品":
            if self.current_npc.sell_items:
                from .systems.reputation import get_reputation_system
                rep_sys = get_reputation_system()
                item_names = []
                self._shop_items = []
                for item_id in self.current_npc.sell_items[:6]:
                    item = self.game_world.get_item_by_id(item_id)
                    if item:
                        rep_mod = rep_sys.get_modifier(self.game_world.player, self.current_npc.faction, "shop_discount")
                        final_price = max(1, int(item.price * rep_mod))
                        discount = "" if rep_mod >= 1.0 else " [折扣]"
                        markup = "" if rep_mod <= 1.0 else " [加价]"
                        item_names.append(f"  {len(self._shop_items)+1}.{item.name} ({final_price}文){discount}{markup}")
                        self._shop_items.append((item_id, final_price))
                self.dialog_text = (f"【{self.current_npc.name}】本店商品：\n"
                                   + "\n".join(item_names)
                                   + f"\n\n你的银两：{self.game_world.player.money}文"
                                   + "\n\n按数字键购买 | ESC关闭")
            else:
                self.dialog_text = f"【{self.current_npc.name}】暂时没有货物。"
            return

        if option == "继续交谈":
            result = self.game_world.talk_to_npc(self.game_world.player, self.current_npc, "")
            self.dialogue_result = result
            self.dialogue_state = result.get("state", DialogueState.CHATTING)
            self.dialog_text = result.get("text", "……")
            self._update_dialogue_options(result)

            if "encounter" in result:
                self.pending_encounter = result["encounter"]

    def _submit_player_input(self):
        if not self.player_input_text or not self.current_npc:
            self.player_input_mode = False
            return

        result = self.game_world.talk_to_npc(
            self.game_world.player, self.current_npc, self.player_input_text
        )
        self.dialogue_result = result
        self.dialogue_state = result.get("state", DialogueState.CHATTING)
        self.dialog_text = result.get("text", "……")
        self._update_dialogue_options(result)
        self.player_input_mode = False
        self.player_input_text = ""

        if "encounter" in result:
            self.pending_encounter = result["encounter"]

    def _accept_quest(self):
        if not self._pending_task:
            return
        task = self._pending_task
        quest = Quest(
            task_id=task["task_id"],
            title=task["title"],
            description=task["description"],
            task_type=QuestType(task.get("task_type", "fetch")),
            target=task["target"],
            count=task.get("count", 1),
            reward=task.get("reward", {}),
            difficulty=task.get("difficulty", 1),
            level_requirement=task.get("level_requirement", 1),
            morality_requirement=task.get("morality_requirement", 0),
            time_limit=task.get("time_limit"),
            issuer_npc_id=self.current_npc.id if self.current_npc else 0,
            issuer_npc_name=self.current_npc.name if self.current_npc else "",
        )
        if self.quest_manager.accept_quest(quest, self.game_world.player):
            self.dialog_text = f"接受了任务【{quest.title}】！"
            self.dialog_type = "quest"
        else:
            self.dialog_text = "无法接受此任务"
        self._pending_task = None

    def _accept_teach(self):
        if not self._pending_teach:
            return
        teach_info = self._pending_teach
        npc = teach_info["npc"]
        skill_ids = teach_info["skills"]
        player = self.game_world.player

        results = []
        for sid in skill_ids:
            if not any(s.id == sid for s in player.skills):
                from .world import ALL_SKILLS
                if sid in ALL_SKILLS:
                    skill = ALL_SKILLS[sid]
                    new_skill = Skill(id=sid, name=skill.name, type=skill.type, level=1, exp=0,
                                      damage=skill.damage, accuracy=skill.accuracy)
                    player.skills.append(new_skill)
                    results.append(f"学会了{skill.name}！")
            else:
                train_result = self.game_world.train_skill(player, sid, npc)
                if train_result["success"]:
                    results.append(train_result["message"])
                else:
                    results.append(train_result["message"])

        self.dialog_text = f"【{npc.name}】\n" + "\n".join(results)
        self.dialog_type = "npc"
        self._pending_teach = None

    def _show_encounter(self):
        if not self.pending_encounter:
            return
        enc = self.pending_encounter
        self.encounter_display = True
        self.dialog_text = enc.get_display_text()
        self.dialog_title = f"✦ 奇遇 · {enc.title}"
        self.dialog_type = "encounter"
        self.show_dialog = True

    def _accept_encounter(self):
        if not self.pending_encounter:
            return
        result = self.game_world.accept_encounter(self.game_world.player, self.pending_encounter)
        self.dialog_text = result
        self.dialog_title = "奇遇奖励"
        self.dialog_type = "info"
        self.pending_encounter = None
        self.encounter_display = False

    def attack_npc(self):
        if not self.game_world.player:
            return
        p = self.game_world.player
        if self.game_world.combat_system.is_in_combat():
            return
        e = self.game_world.get_nearby_enemy(p.position)
        if e:
            self.game_world.combat_system.start_combat(p, e)
            self._combat_enemy = e
            self._show_combat_ui()
        else:
            self.dialog_text = "附近没有敌人"
            self.dialog_title = "提示"
            self.dialog_type = "info"
            self.show_dialog = True

    def _show_combat_ui(self):
        combat = self.game_world.combat_system
        if not combat.is_in_combat():
            return
        info = combat.get_combat_info()
        e = self._combat_enemy
        p = self.game_world.player

        p_hp_pct = info["player_hp"] / info["player_max_hp"] if info["player_max_hp"] > 0 else 0
        e_hp_pct = info["enemy_hp"] / info["enemy_max_hp"] if info["enemy_max_hp"] > 0 else 0
        p_mp_pct = info["player_mp"] / info["player_max_mp"] if info["player_max_mp"] > 0 else 0

        p_hp_c = (60,180,60) if p_hp_pct > 0.5 else ((180,180,40) if p_hp_pct > 0.25 else (200,50,50))
        e_hp_c = (60,180,60) if e_hp_pct > 0.5 else ((180,180,40) if e_hp_pct > 0.25 else (200,50,50))

        self.dialog_text = (
            f"【{p.name}】\n"
            f"  HP {info['player_hp']}/{info['player_max_hp']}  "
            f"MP {info['player_mp']}/{info['player_max_mp']}\n"
            f"【{e.name}】\n"
            f"  HP {info['enemy_hp']}/{info['enemy_max_hp']}\n"
            f"回合:{info['round']}  姿态:{info['stance_name']}  连击:{info['combo_count']}\n\n"
            f"1.攻击  2.技能  3.防御  4.逃跑  5.物品"
        )
        self.dialog_title = f"⚔ 战斗 VS {e.name}"
        self.dialog_type = "combat"
        self.show_dialog = True
        self.dialogue_options = ["攻击", "技能", "防御", "逃跑", "物品"]
        self._in_combat = True
        self._combat_bars = {
            "p_hp_pct": p_hp_pct, "p_hp_c": p_hp_c,
            "p_mp_pct": p_mp_pct,
            "e_hp_pct": e_hp_pct, "e_hp_c": e_hp_c,
        }

    def _show_combat_ui_with_log(self):
        combat = self.game_world.combat_system
        if not combat.is_in_combat():
            return
        info = combat.get_combat_info()
        e = self._combat_enemy
        p = self.game_world.player

        p_hp_pct = info["player_hp"] / info["player_max_hp"] if info["player_max_hp"] > 0 else 0
        e_hp_pct = info["enemy_hp"] / info["enemy_max_hp"] if info["enemy_max_hp"] > 0 else 0
        p_mp_pct = info["player_mp"] / info["player_max_mp"] if info["player_max_mp"] > 0 else 0

        p_hp_c = (60,180,60) if p_hp_pct > 0.5 else ((180,180,40) if p_hp_pct > 0.25 else (200,50,50))
        e_hp_c = (60,180,60) if e_hp_pct > 0.5 else ((180,180,40) if e_hp_pct > 0.25 else (200,50,50))

        log_text = "\n".join(getattr(self, '_combat_log', [])[-3:])

        self.dialog_text = (
            f"【{p.name}】\n"
            f"  HP {info['player_hp']}/{info['player_max_hp']}  "
            f"MP {info['player_mp']}/{info['player_max_mp']}\n"
            f"【{e.name}】\n"
            f"  HP {info['enemy_hp']}/{info['enemy_max_hp']}\n"
            f"回合:{info['round']}  姿态:{info['stance_name']}  连击:{info['combo_count']}\n\n"
            f"{log_text}\n\n"
            f"1.攻击  2.技能  3.防御  4.逃跑  5.物品"
        )
        self.dialog_title = f"⚔ 战斗 VS {e.name}"
        self.dialog_type = "combat"
        self.show_dialog = True
        self.dialogue_options = ["攻击", "技能", "防御", "逃跑", "物品"]
        self._combat_bars = {
            "p_hp_pct": p_hp_pct, "p_hp_c": p_hp_c,
            "p_mp_pct": p_mp_pct,
            "e_hp_pct": e_hp_pct, "e_hp_c": e_hp_c,
        }

    def _combat_action(self, action: str):
        combat = self.game_world.combat_system
        p = self.game_world.player
        if not combat.is_in_combat():
            self._in_combat = False
            return

        if action == "攻击":
            result = combat.player_attack()
        elif action == "技能":
            result = self._combat_use_skill()
            if result is None:
                return
        elif action == "防御":
            result = combat.player_defend()
        elif action == "逃跑":
            result = combat.flee()
            if result.get("success"):
                self.dialog_text = result["message"]
                self.dialog_title = "逃跑"
                self.dialog_type = "info"
                self._in_combat = False
                self._combat_enemy = None
                return
        elif action == "物品":
            self._combat_use_item()
            return
        else:
            return

        self._add_combat_log(result.get("message", ""))

        if result.get("victory"):
            self._handle_combat_victory(result)
            return
        if result.get("defeat"):
            self._handle_combat_defeat(result)
            return

        enemy_result = combat.enemy_attack()
        self._add_combat_log(enemy_result.get("message", ""))

        if enemy_result.get("defeat"):
            self._handle_combat_defeat(enemy_result)
            return

        if p.hp < p.max_hp * 0.3:
            self._hurt_flash_val = 0.6
            renderer.set_hurt_flash(0.6)

        self._show_combat_ui_with_log()

    def _combat_use_skill(self):
        combat = self.game_world.combat_system
        p = self.game_world.player
        if not p.skills:
            self.dialog_text = "你没有技能"
            return None
        usable = [s for s in p.skills if s.damage > 0 or s.type in (0, 1, 2, 6, 7, 8)]
        if not usable:
            self.dialog_text = "没有可用的攻击技能"
            return None
        skill = usable[0]
        mp_cost = skill.level * 2
        if p.mp < mp_cost:
            return combat.player_attack()
        return combat.use_skill(skill.id)

    def _combat_use_item(self):
        p = self.game_world.player
        from .entities import ItemType
        consumables = []
        for item_id, qty in p.inventory.items():
            item = self.game_world.get_item_by_id(item_id)
            if item and item.type == ItemType.CONSUMABLE:
                consumables.append((item, qty))
        if consumables:
            item, qty = consumables[0]
            result = self.game_world.combat_system.use_item(item)
            if result.get("success"):
                self._add_combat_log(result["message"])
                enemy_result = self.game_world.combat_system.enemy_attack()
                self._add_combat_log(enemy_result.get("message", ""))
                if enemy_result.get("defeat"):
                    self._handle_combat_defeat(enemy_result)
                    return
                self._show_combat_ui_with_log()
            else:
                self._show_combat_ui()
        else:
            self._show_combat_ui()

    def _add_combat_log(self, msg: str):
        if msg:
            self._combat_log = getattr(self, '_combat_log', [])
            self._combat_log.append(msg)
            if len(self._combat_log) > 5:
                self._combat_log = self._combat_log[-5:]

    def _handle_combat_victory(self, result: Dict):
        p = self.game_world.player
        msg = f"胜利！{self._combat_enemy.name}被击败！\n"
        msg += f"经验+{result.get('exp_reward', 0)}  银两+{result.get('money_reward', 0)}"
        if result.get('level_up'):
            msg += f"\n升级到第{p.level}级！"
        self.dialog_text = msg
        self.dialog_title = "战斗胜利"
        self.dialog_type = "info"
        self.show_dialog = True
        self._in_combat = False
        self._combat_log = []
        self._mark_enemy_dead(self._combat_enemy)
        self.game_world.combat_system.end_combat()
        self._combat_enemy = None

    def _handle_combat_defeat(self, result: Dict):
        p = self.game_world.player
        msg = f"你被击败了！\n"
        msg += result.get("message", "")
        p.hp = max(1, int(p.max_hp * 0.1))
        p.mp = max(0, int(p.max_mp * 0.1))
        self.dialog_text = msg
        self.dialog_title = "战斗失败"
        self.dialog_type = "info"
        self.show_dialog = True
        self._in_combat = False
        self._combat_enemy = None
        self._combat_log = []
        self.game_world.combat_system.end_combat()

    def _mark_enemy_dead(self, enemy):
        if enemy:
            enemy.hp = 0
            enemy._death_time = self.game_world.game_time

    def _buy_shop_item(self, idx: int):
        if not self._shop_items or idx >= len(self._shop_items):
            return
        item_id, price = self._shop_items[idx]
        p = self.game_world.player
        if p.money < price:
            self.dialog_text = f"银两不足！需要{price}文，你只有{p.money}文"
            return
        result = self.game_world.buy_item(p, item_id, self.current_npc)
        if result.get("success"):
            self.dialog_text = f"购买了{result.get('message', item_id)}！\n银两剩余：{p.money}文"
            self._update_shop_display()
        else:
            self.dialog_text = result.get("message", "购买失败")

    def _update_shop_display(self):
        if not self.current_npc or not self.current_npc.sell_items:
            return
        from .systems.reputation import get_reputation_system
        rep_sys = get_reputation_system()
        item_names = []
        self._shop_items = []
        for item_id in self.current_npc.sell_items[:6]:
            item = self.game_world.get_item_by_id(item_id)
            if item:
                rep_mod = rep_sys.get_modifier(self.game_world.player, self.current_npc.faction, "shop_discount")
                final_price = max(1, int(item.price * rep_mod))
                discount = "" if rep_mod >= 1.0 else " [折扣]"
                markup = "" if rep_mod <= 1.0 else " [加价]"
                qty = self.game_world.player.inventory.get(item_id, 0)
                owned = f" (已有{qty})" if qty > 0 else ""
                item_names.append(f"  {len(self._shop_items)+1}.{item.name} ({final_price}文){discount}{markup}{owned}")
                self._shop_items.append((item_id, final_price))
        self.dialog_text = (f"【{self.current_npc.name}】本店商品：\n"
                           + "\n".join(item_names)
                           + f"\n\n你的银两：{self.game_world.player.money}文"
                           + "\n\n按数字键购买 | ESC关闭")

    def show_quests(self):
        qs = self.quest_manager.get_active_quests() if self.game_world.player else []
        if qs:
            qs_text = "\n".join(f"- {q.title}" for q in qs)
            self.dialog_text = f"当前任务:\n{qs_text}"
        else:
            self.dialog_text = "暂无任务"
        self.dialog_title = "任务"
        self.dialog_type = "quest"
        self.show_dialog = True

    def _use_first_consumable(self):
        p = self.game_world.player
        if not p or not p.inventory:
            return
        from .entities import ItemType
        for item_id, qty in p.inventory.items():
            item = self.game_world.get_item_by_id(item_id)
            if item and item.type == ItemType.CONSUMABLE:
                result = self.game_world.use_item(p, item_id)
                self.dialog_text = result
                self.dialog_title = "使用物品"
                self.dialog_type = "info"
                self.show_dialog = True
                return
        self.dialog_text = "背包中没有可使用的物品"
        self.dialog_title = "提示"
        self.dialog_type = "info"
        self.show_dialog = True

    def _inn_rest(self):
        p = self.game_world.player
        if not p:
            return
        result = self.game_world.inn_rest(p)
        self.dialog_text = result["message"]
        self.dialog_title = "客栈休息"
        self.dialog_type = "info"
        self.show_dialog = True

    def _show_reputation(self):
        p = self.game_world.player
        if not p:
            return
        rep_info = self.game_world.reputation_system.get_all_reputations(p)
        lines = []
        for faction_val, info in rep_info.items():
            bar_len = 20
            filled = int((info["value"] + 100) / 200 * bar_len)
            bar = "█" * filled + "░" * (bar_len - filled)
            lines.append(f"{info['name']}: [{bar}] {info['value']:+d} ({info['tier']})")
        faction_name = FACTION_NAMES.get(p.faction, '未知门派') if p.faction else "无门无派"
        self.dialog_text = f"【江湖声望】\n门派：{faction_name}\n\n" + "\n".join(lines)
        self.dialog_title = "江湖声望"
        self.dialog_type = "info"
        self.show_dialog = True

    def _show_equipment(self):
        p = self.game_world.player
        if not p:
            return
        from .systems.equipment import EQUIPMENT_SLOTS
        equip_stats = self.game_world.equipment_system.get_equipment_stats(p, self.game_world.items)
        lines = []
        for slot, slot_name in EQUIPMENT_SLOTS.items():
            equipped = equip_stats["equipped"].get(slot)
            if equipped:
                lines.append(f"{slot_name}: {equipped['name']}")
            else:
                lines.append(f"{slot_name}: (空)")
        lines.append(f"\n攻击加成: +{equip_stats['attack_bonus']}")
        lines.append(f"防御加成: +{equip_stats['defense_bonus']}")
        self.dialog_text = f"【装备信息】\n" + "\n".join(lines)
        self.dialog_title = "装备"
        self.dialog_type = "info"
        self.show_dialog = True

    # ==================== 战斗系统 ====================

    def _start_combat(self, enemies_data):
        """开始战斗"""
        player = self.game_world.player
        if not player:
            return
        # 聚合修炼加成与装备加成
        cult_bonus = self.cultivation.get_bonuses()
        equip_bonus = self.player_inventory.get_total_stats()
        pc = Combatant(
            name=player.name,
            max_hp=player.max_hp + cult_bonus.get("max_hp", 0) + equip_bonus.get("max_hp", 0),
            hp=player.hp,
            max_mp=player.max_mp + cult_bonus.get("max_mp", 0) + equip_bonus.get("max_mp", 0),
            mp=player.mp,
            attack=player.attack + cult_bonus.get("attack", 0) + equip_bonus.get("attack", 0),
            defense=player.defense + cult_bonus.get("defense", 0) + equip_bonus.get("defense", 0),
            speed=getattr(player, 'speed', 10) + cult_bonus.get("speed", 0) + equip_bonus.get("speed", 0),
            is_player=True, faction=getattr(player, 'faction', '').value,
            skills=list(self.cultivation.skills.keys())[:4] if self.cultivation.skills else ["basic_attack"]
        )
        enemies = [
            Combatant(
                name=e["name"], max_hp=e["max_hp"], hp=e["hp"],
                max_mp=e["max_mp"], mp=e["mp"],
                attack=e["attack"], defense=e["defense"], speed=e["speed"],
                is_player=False
            )
            for e in enemies_data
        ]
        self.combat_system.start_battle(pc, enemies)
        self._in_combat = True
        self._combat_phase = "player"
        self._combat_log = self.combat_system.battle_log[:]
        self._combat_menu_idx = 0
        self._combat_rewards = None

    def _combat_action(self, action_type="attack"):
        """玩家战斗行动"""
        if not self._in_combat:
            return
        cs = self.combat_system
        if cs.phase != CombatPhase.PLAYER_TURN:
            return

        atype = {"attack": ActionType.ATTACK, "skill": ActionType.SKILL,
                 "defend": ActionType.DEFEND, "flee": ActionType.FLEE}.get(action_type, ActionType.ATTACK)

        skill_id = "basic_attack"
        if action_type == "skill" and cs.player:
            skills = list(self.cultivation.skills.keys())
            if skills:
                skill_id = skills[min(self._combat_skill_idx, len(skills)-1)]

        target = None
        if cs.enemies:
            target = cs.enemies[min(self._combat_enemy_idx, len(cs.enemies)-1)]

        cs.player_action(atype, target, skill_id)
        self._combat_log = cs.battle_log[:]

        # 检查结束
        if cs.phase in (CombatPhase.VICTORY, CombatPhase.DEFEAT, CombatPhase.FLEE):
            self._end_combat()

    def _end_combat(self):
        cs = self.combat_system
        if cs.phase == CombatPhase.VICTORY:
            rewards = cs.get_battle_rewards()
            self._combat_rewards = rewards
            player = self.game_world.player
            if player:
                player.exp += rewards.get("exp", 0)
                player.hp = min(player.max_hp, player.hp)
                player.mp = min(player.max_mp, player.mp)
            self.economy.gold += rewards.get("gold", 0)
            self.reputation.add_fame(rewards.get("exp", 0) // 2)
        else:
            self._combat_rewards = None
            player = self.game_world.player
            if player:
                player.hp = max(1, player.hp // 2)
        # 保持 _in_combat = True，让 _draw_combat 渲染胜利/失败画面
        self._combat_phase = "none"
        self._encounter_cooldown = 5.0

    def _draw_combat(self):
        """绘制战斗界面 - 水墨风格"""
        cs = self.combat_system
        cr = self.combat_renderer

        # 震动偏移
        sx, sy = cr.shake_offset

        # === 战斗背景 (水墨渐变) ===
        for y in range(0, SH, 3):
            ratio = y / SH
            r = int(26 * (0.35 + 0.65 * ratio))
            g = int(24 * (0.35 + 0.65 * ratio))
            b = int(20 * (0.35 + 0.65 * ratio))
            arcade.draw_line(0 + sx, y + sy, SW + sx, y + sy, (r, g, b, 255), 3)

        # 水墨装饰边框
        arcade.draw_rect_filled(arcade.LBWH(0 + sx, 0 + sy, SW, 4), (90, 75, 45, 140))
        arcade.draw_rect_filled(arcade.LBWH(0 + sx, SH - 4 + sy, SW, 4), (90, 75, 45, 140))

        # 闪光效果
        if cr.flash_alpha > 0:
            alpha = int(cr.flash_alpha)
            arcade.draw_rect_filled(arcade.LBWH(0, 0, SW, SH), (255, 255, 240, alpha))

        # === 回合阶段 ===
        phase_texts = {
            CombatPhase.PLAYER_TURN: "—— 你的回合 ——",
            CombatPhase.ENEMY_TURN: "—— 敌人回合 ——",
            CombatPhase.VICTORY: "【 胜 利 】",
            CombatPhase.DEFEAT: "【 败 北 】",
            CombatPhase.FLEE: "【 逃 离 】"
        }
        phase = phase_texts.get(cs.phase, "")
        if cs.phase == CombatPhase.VICTORY:
            phase_color = (140, 230, 110)
        elif cs.phase == CombatPhase.DEFEAT:
            phase_color = (230, 100, 100)
        else:
            phase_color = (200, 170, 100)
        arcade.draw_text(phase, SW // 2 + sx, SH - 28 + sy, phase_color, 20,
                         font_name=self.font, anchor_x="center")

        # === 敌人区域 ===
        if cs.enemies:
            ex_base = SW - 300
            ey_base = SH - 300
            for i, enemy in enumerate(cs.enemies):
                if not enemy.is_alive:
                    continue
                ex = ex_base + sx
                ey = ey_base - i * 150 + sy

                # 面板背景
                self._R(ex - 20, ey - 20, 260, 140, (32, 29, 25, 235))
                self._RO(ex - 20, ey - 20, 260, 140, (140, 120, 85), 2)

                # 选中指示器
                if i == self._combat_enemy_idx and cs.phase == CombatPhase.PLAYER_TURN:
                    arcade.draw_triangle_filled(
                        ex - 8, ey + 70, ex - 24, ey + 54, ex - 24, ey + 86, (200, 170, 100))

                # 头像框
                avatar_x, avatar_y = ex + 30, ey + 65
                avatar_s = 52
                arcade.draw_rect_filled(arcade.LBWH(avatar_x - avatar_s // 2, avatar_y - avatar_s // 2, avatar_s, avatar_s), (55, 40, 40))
                arcade.draw_rect_outline(arcade.LBWH(avatar_x - avatar_s // 2, avatar_y - avatar_s // 2, avatar_s, avatar_s), (140, 120, 85), 1)
                arcade.draw_text(enemy.name[0], avatar_x, avatar_y - 7, (200, 170, 100), 26,
                                 font_name=self.font, anchor_x="center")

                # 名字和等级
                arcade.draw_text(enemy.name, ex + 65, ey + 95, (200, 170, 100), 18, font_name=self.font)
                lvl = getattr(enemy, 'level', None) or getattr(enemy, 'combat_level', None)
                if lvl:
                    arcade.draw_text(f"Lv.{lvl}", ex + 210, ey + 95, (180, 170, 150), 13, font_name=self.font)

                # HP条
                hp_w, hp_h = 210, 12
                hp_x, hp_y = ex, ey
                self._R(hp_x - 1, hp_y - 1, hp_w + 2, hp_h + 2, (22, 20, 17, 230))
                hp_pct = enemy.hp_percent
                hp_fill = max(1, int(hp_w * hp_pct))
                arcade.draw_rect_filled(arcade.LBWH(hp_x, hp_y, hp_fill, hp_h),
                                        (190, 60, 50) if hp_pct < 0.3 else (180, 60, 50))
                self._RO(hp_x - 1, hp_y - 1, hp_w + 2, hp_h + 2, (140, 120, 85), 1)
                arcade.draw_text(f"HP {enemy.hp}/{enemy.max_hp}", hp_x + 4, hp_y + 1,
                               (235, 230, 220), 10, font_name=self.font)

                # 状态标记
                status_y = ey + 20
                if enemy.is_defending:
                    arcade.draw_text("【防御】", ex + 8, status_y, (100, 150, 230), 11, font_name=self.font)
                if enemy.is_stunned:
                    arcade.draw_text("【眩晕】", ex + 80, status_y, (240, 180, 20), 11, font_name=self.font)

        # === 玩家区域 ===
        if cs.player:
            player = cs.player
            px = 70 + sx
            py = SH - 320 + sy

            # 面板背景
            self._R(px - 20, py - 30, 300, 170, (32, 30, 28, 235))
            self._RO(px - 20, py - 30, 300, 170, (140, 120, 85), 2)

            # 头像框
            avatar_x, avatar_y = px + 40, py + 85
            avatar_s = 56
            arcade.draw_rect_filled(arcade.LBWH(avatar_x - avatar_s // 2, avatar_y - avatar_s // 2, avatar_s, avatar_s), (50, 45, 60))
            arcade.draw_rect_outline(arcade.LBWH(avatar_x - avatar_s // 2, avatar_y - avatar_s // 2, avatar_s, avatar_s), (140, 120, 85), 2)
            arcade.draw_text(player.name[0], avatar_x, avatar_y - 8, (200, 170, 100), 28,
                             font_name=self.font, anchor_x="center")

            # 名字和等级
            arcade.draw_text(player.name, px + 80, py + 115, (200, 170, 100), 20, font_name=self.font)
            lvl = getattr(player, 'level', None)
            if lvl:
                arcade.draw_text(f"Lv.{lvl}", px + 220, py + 115, (180, 170, 150), 14, font_name=self.font)

            # HP条
            hp_w, hp_h = 230, 14
            hp_x, hp_y = px + 10, py + 60
            self._R(hp_x - 1, hp_y - 1, hp_w + 2, hp_h + 2, (22, 20, 17, 230))
            hp_pct = player.hp_percent
            hp_fill = max(1, int(hp_w * hp_pct))
            arcade.draw_rect_filled(arcade.LBWH(hp_x, hp_y, hp_fill, hp_h),
                                    (190, 60, 50) if hp_pct < 0.3 else (180, 60, 50))
            self._RO(hp_x - 1, hp_y - 1, hp_w + 2, hp_h + 2, (140, 120, 85), 1)
            arcade.draw_text(f"气血 {player.hp}/{player.max_hp}", hp_x + 5, hp_y + 2,
                           (235, 230, 220), 10, font_name=self.font)

            # MP条
            mp_h = 10
            mp_y = py + 40
            self._R(hp_x - 1, mp_y - 1, hp_w + 2, mp_h + 2, (22, 20, 17, 230))
            mp_fill = max(1, int(hp_w * player.mp_percent))
            arcade.draw_rect_filled(arcade.LBWH(hp_x, mp_y, mp_fill, mp_h), (75, 115, 185))
            self._RO(hp_x - 1, mp_y - 1, hp_w + 2, mp_h + 2, (140, 120, 85), 1)
            arcade.draw_text(f"内力 {player.mp}/{player.max_mp}", hp_x + 5, mp_y + 1,
                           (230, 230, 240), 9, font_name=self.font)

            # 状态标记
            status_y = py + 15
            if player.is_defending:
                arcade.draw_text("【防御姿态】", px + 10, status_y, (100, 150, 230), 11, font_name=self.font)
            if player.is_stunned:
                arcade.draw_text("【眩晕】", px + 130, status_y, (240, 180, 20), 11, font_name=self.font)

        # === 行动菜单 ===
        menu_w, menu_h = 175, 170
        mx = 28 + sx
        my = 30 + sy
        self._R(mx - 2, my - 2, menu_w + 4, menu_h + 4, (32, 29, 25, 235))
        self._RO(mx - 2, my - 2, menu_w + 4, menu_h + 4, (140, 120, 85), 2)

        actions = ["攻击", "武学", "防御", "逃跑"]
        for i, act in enumerate(actions):
            y = my + menu_h - 35 - i * 38
            if i == self._combat_menu_idx:
                self._R(mx + 2, y - 5, menu_w - 4, 30, (65, 55, 40, 170))
                arcade.draw_text(f"▸ {act}", mx + 14, y, (200, 170, 100), 16, font_name=self.font)
            else:
                arcade.draw_text(f"  {act}", mx + 14, y, (150, 140, 120), 14, font_name=self.font)

        # === 武学子菜单 ===
        if self._combat_menu_idx == 1 and cs.player:
            skills = list(self.cultivation.skills.keys())[:6]
            if skills:
                smx = mx + menu_w + 14 + sx
                smy = my + sy
                smw, smh = 270, menu_h
                self._R(smx - 2, smy - 2, smw + 4, smh + 4, (32, 29, 25, 235))
                self._RO(smx - 2, smy - 2, smw + 4, smh + 4, (140, 120, 85), 2)
                for i, sid in enumerate(skills):
                    from .combat_system import SKILLS_DATABASE
                    sk = SKILLS_DATABASE.get(sid)
                    if sk:
                        y = smy + smh - 37 - i * 28
                        can_afford = cs.player.mp >= sk.mp_cost
                        if i == self._combat_skill_idx:
                            self._R(smx + 2, y - 5, smw - 4, 26, (65, 55, 40, 170))
                            arcade.draw_text(f"▸ {sk.name_zh}", smx + 10, y, (200, 170, 100), 14,
                                           font_name=self.font)
                        else:
                            color = (150, 140, 120) if can_afford else (90, 85, 75)
                            arcade.draw_text(f"  {sk.name_zh}", smx + 10, y, color, 12, font_name=self.font)
                        mp_color = (100, 140, 200) if can_afford else (80, 80, 80)
                        arcade.draw_text(f"内力:{sk.mp_cost}", smx + smw - 70, y, mp_color, 11,
                                       font_name=self.font)

        # === 战斗日志 ===
        log_w, log_h = 520, 158
        log_x = SW - log_w - 30 + sx
        log_y = 30 + sy
        self._R(log_x - 2, log_y - 2, log_w + 4, log_h + 4, (32, 29, 25, 215))
        self._RO(log_x - 2, log_y - 2, log_w + 4, log_h + 4, (140, 120, 85), 1)
        arcade.draw_line(log_x + 12, log_y + log_h - 24, log_x + log_w - 12, log_y + log_h - 24,
                         (140, 120, 85), 1)
        arcade.draw_text("—— 战斗记录 ——", log_x + log_w // 2, log_y + log_h - 22,
                        (180, 175, 155), 12, font_name=self.font, anchor_x="center")

        ly = log_y + log_h - 44
        for log_line in self._combat_log[-5:]:
            if "伤害" in log_line:
                color = (255, 150, 150, 230)
            elif "胜利" in log_line:
                color = (150, 255, 150, 230)
            elif "失败" in log_line or "败" in log_line:
                color = (255, 100, 100, 230)
            elif "暴击" in log_line:
                color = (255, 200, 50, 230)
            elif "闪避" in log_line or "格挡" in log_line:
                color = (200, 200, 150, 230)
            else:
                color = (200, 195, 170, 230)
            arcade.draw_text(log_line[:55], log_x + 12, ly, color, 12, font_name=self.font)
            ly -= 22

        # === 胜利画面 ===
        if cs.phase == CombatPhase.VICTORY:
            arcade.draw_rect_filled(arcade.LBWH(0, 0, SW, SH), (18, 32, 18, 50))
            self._vic_win(cs)
        elif cs.phase == CombatPhase.DEFEAT:
            arcade.draw_rect_filled(arcade.LBWH(0, 0, SW, SH), (35, 14, 14, 55))
            self._vic_defeat()
        elif cs.phase == CombatPhase.FLEE:
            arcade.draw_rect_filled(arcade.LBWH(0, 0, SW, SH), (28, 24, 14, 45))
            self._vic_flee()

    def _vic_win(self, cs):
        """胜利画面"""
        vw, vh = 420, 280
        vx = SW // 2 - vw // 2
        vy = SH // 2 - vh // 2
        self._R(vx, vy, vw, vh, (30, 38, 28, 250))
        self._RO(vx, vy, vw, vh, (100, 190, 80), 3)
        arcade.draw_line(vx + 30, vy + vh - 55, vx + vw - 30, vy + vh - 55, (80, 160, 70), 2)
        arcade.draw_text("战 斗 胜 利", vx + vw // 2, vy + vh - 40, (160, 230, 140), 22,
                         font_name=self.font, anchor_x="center")
        if self._combat_rewards:
            rw = self._combat_rewards
            ry = vy + vh - 100
            if rw.get("exp", 0):
                arcade.draw_text(f"经验值  +{rw['exp']}", vx + 110, ry, (220, 220, 150), 16, font_name=self.font)
                ry -= 30
            if rw.get("gold", 0):
                arcade.draw_text(f"银  两  +{rw['gold']}", vx + 110, ry, (220, 210, 120), 16, font_name=self.font)
                ry -= 30
            if rw.get("items"):
                arcade.draw_text(f"获得物品: {', '.join(rw['items'])}", vx + 110, ry, (130, 210, 130), 14,
                                 font_name=self.font)
        arcade.draw_text("按 空格键 或 回车 继续", vx + vw // 2, vy + 25, (180, 180, 180), 13,
                         font_name=self.font, anchor_x="center")

    def _vic_defeat(self):
        """战败画面"""
        vw, vh = 420, 230
        vx = SW // 2 - vw // 2
        vy = SH // 2 - vh // 2
        self._R(vx, vy, vw, vh, (40, 28, 28, 250))
        self._RO(vx, vy, vw, vh, (200, 90, 90), 3)
        arcade.draw_line(vx + 30, vy + vh - 55, vx + vw - 30, vy + vh - 55, (150, 70, 70), 2)
        arcade.draw_text("战 斗 失 败", vx + vw // 2, vy + vh - 40, (230, 130, 130), 22,
                         font_name=self.font, anchor_x="center")
        arcade.draw_text("将在最近城镇中复活", vx + vw // 2, vy + vh - 85, (200, 180, 180), 15,
                         font_name=self.font, anchor_x="center")
        arcade.draw_text("按 空格键 或 回车 继续", vx + vw // 2, vy + 25, (170, 170, 170), 13,
                         font_name=self.font, anchor_x="center")

    def _vic_flee(self):
        """逃跑画面"""
        vw, vh = 360, 180
        vx = SW // 2 - vw // 2
        vy = SH // 2 - vh // 2
        self._R(vx, vy, vw, vh, (34, 30, 24, 245))
        self._RO(vx, vy, vw, vh, (140, 120, 85), 2)
        arcade.draw_text("逃 离 战 斗", vx + vw // 2, vy + vh - 55, (200, 170, 100), 21,
                         font_name=self.font, anchor_x="center")
        arcade.draw_text("按 空格键 或 回车 继续", vx + vw // 2, vy + 30, (170, 170, 170), 13,
                         font_name=self.font, anchor_x="center")

    def _combat_input(self, key, modifiers):
        """战斗中的键盘输入"""
        cs = self.combat_system

        if cs.phase in (CombatPhase.VICTORY, CombatPhase.DEFEAT, CombatPhase.FLEE):
            if key == arcade.key.SPACE or key == arcade.key.ENTER:
                self._in_combat = False
                self._combat_rewards = None


def run_game():
    window = GameWindow()
    arcade.run()
