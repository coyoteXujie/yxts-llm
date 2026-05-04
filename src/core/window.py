import arcade
import math
import random
from typing import Optional, List, Dict
from .config import GAME_CONFIG, COLORS, UI_CONFIG, VISUAL_CONFIG
from . import renderer
from .vfx import VFXManager
from .world import GameWorld, MAP_W, MAP_H, WALKABLE, TS, col_to_x, row_to_y
from .entities import Player, NPC, Faction, NpcType, QuestType, Quest, Skill
from .quest import get_quest_manager
from .npc_brain import DialogueState, get_npc_brain_manager
from .encounter import get_encounter_manager, Encounter

SW = GAME_CONFIG["screen_width"]
SH = GAME_CONFIG["screen_height"]


class GameWindow(arcade.Window):
    def __init__(self):
        super().__init__(SW, SH, GAME_CONFIG["screen_title"], resizable=False)
        arcade.set_background_color((18, 22, 38))

        self.game_world = GameWorld()
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

        self.particles = []
        self.time_of_day = 0.0
        self.vfx = VFXManager(SW, SH)
        self._hurt_flash_val = 0.0

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
        self.time_of_day += delta_time * 0.01

        renderer.set_anim_time(self.blink_timer)
        renderer.update_dialog_anim(delta_time)

        if self._hurt_flash_val > 0:
            self._hurt_flash_val = max(0, self._hurt_flash_val - delta_time * 3)
            renderer.set_hurt_flash(self._hurt_flash_val)

        self.vfx.update(delta_time)

        if self.game_state == "playing" and self.game_world.player:
            self.game_world.update(delta_time)

            p = self.game_world.player
            speed = 200 * delta_time
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

            self.nearby_timer += delta_time
            if self.nearby_timer > 0.3:
                self.nearby_timer = 0
                self._update_interaction_prompt()

            self._update_particles(delta_time)

    def _update_interaction_prompt(self):
        p = self.game_world.player
        if not p:
            return
        npc = self.game_world.get_nearby_npc(p.position, 90)
        enemy = self.game_world.get_nearby_enemy(p.position, 90)
        if npc:
            self.interaction_prompt = f"按 T 与 {npc.name} 对话"
            self.interaction_npc = npc
        elif enemy:
            self.interaction_prompt = f"按 F 攻击 {enemy.name}"
            self.interaction_npc = enemy
        else:
            self.interaction_prompt = ""
            self.interaction_npc = None

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
        self._R(0, 0, SW, SH, (12, 16, 28))

        for i in range(60):
            x = (i * 137.5 + self.blink_timer * 8) % SW
            y = (i * 97.3 + math.sin(self.blink_timer * 0.5 + i * 0.3) * 20) % SH
            alpha = int(40 + 30 * (0.5 + 0.5 * math.sin(self.blink_timer * 1.5 + i)))
            arcade.draw_circle_filled(x, y, 1.5, (200, 180, 120, alpha))

        for i in range(5):
            mx = 100 + i * 250
            my = 200 + math.sin(self.blink_timer * 0.8 + i) * 30
            alpha = int(15 + 10 * math.sin(self.blink_timer + i))
            arcade.draw_circle_filled(mx, my, 40, (255, 200, 100, alpha))

        title_y = 560
        glow = int(20 + 15 * math.sin(self.blink_timer * 2))
        arcade.draw_text("白金英雄坛说", SW // 2 + 2, title_y - 2, (glow, glow // 2, 0, 80), 58,
                         font_name=self.font, anchor_x="center", anchor_y="center")
        arcade.draw_text("白金英雄坛说", SW // 2, title_y, COLORS["accent"], 58,
                         font_name=self.font, anchor_x="center", anchor_y="center")

        arcade.draw_text("天命所归 · 仗剑江湖", SW // 2, 500, (180, 160, 120), 22,
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
                self._R(SW // 2 - bw // 2, y - bh // 2, bw, bh, (35, 45, 70, 200))
                self._RO(SW // 2 - bw // 2, y - bh // 2, bw, bh, COLORS["accent"], 2)
                bounce = math.sin(self.blink_timer * 4) * 3
                arcade.draw_triangle_filled(SW // 2 - bw // 2 - 20, y + bounce,
                                            SW // 2 - bw // 2 - 30, y - 8 + bounce,
                                            SW // 2 - bw // 2 - 30, y + 8 + bounce, COLORS["accent"])
                arcade.draw_text(item, SW // 2, y, COLORS["accent"], 28,
                                 font_name=self.font, anchor_x="center", anchor_y="center")
            else:
                arcade.draw_text(item, SW // 2, y, (120, 120, 140), 24,
                                 font_name=self.font, anchor_x="center", anchor_y="center")

        arcade.draw_text("v2.0 · 2026 Remaster", SW // 2, 30, (60, 60, 80), 13,
                         font_name=self.font, anchor_x="center", anchor_y="center")

    def _draw_char_creation(self):
        self._R(0, 0, SW, SH, (10, 14, 24))
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

        self._draw_panel(left_px, panel_bottom, left_pw, panel_h, "角色信息")
        self._draw_panel(right_px, panel_bottom, right_pw, panel_h, "属性分配")

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
        nc_color = COLORS["accent"] if self.char_name else (108, 108, 128)
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
                self._R(right_px + 18, sel_box_y, right_pw - 36, sel_box_h, (24, 38, 62, 195))
                self._RO(right_px + 18, sel_box_y, right_pw - 36, sel_box_h, (72, 92, 142), 2)

            txt_color = COLORS["accent"] if is_selected else (192, 192, 192)
            arcade.draw_text(f"【{attr_names[idx]}】", right_px + 34, cy + 7, txt_color, 19,
                             font_name=self.font, anchor_x="left", anchor_y="center")
            arcade.draw_text(attr_descs[idx], right_px + 34, cy - 14, (108, 108, 128), 12,
                             font_name=self.font, anchor_x="left", anchor_y="center")

            bar_w, bar_h = 130, 16
            bar_x = right_px + right_pw - bar_w - 125
            bar_y = cy
            self._R(bar_x, bar_y - bar_h / 2, bar_w, bar_h, (15, 15, 25))
            self._RO(bar_x, bar_y - bar_h / 2, bar_w, bar_h, (42, 42, 56), 1)

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
        self._R(pts_x, pts_y, pts_w, pts_h, (24, 50, 24) if has_pts else (50, 20, 20))
        self._RO(pts_x, pts_y, pts_w, pts_h, (68, 162, 68) if has_pts else (162, 68, 68), 2)
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
            arcade.draw_text(hd, hint_x, hint_y, (103, 103, 123), 12,
                             font_name=self.font, anchor_x="left", anchor_y="bottom")
            hint_x += 102

        flabels = {"name": "◆ 姓名输入中", "gender": "◆ 性别选择中", "attr": "◆ 属性分配中", "faction": "◆ 门派选择中"}
        ftx = SW - margin - 8
        arcade.draw_text(flabels.get(self.focus_target, ""), ftx, pts_y + pts_h // 2,
                         (176, 166, 146), 13, font_name=self.font,
                         anchor_x="right", anchor_y="center")

    def _draw_panel(self, px, py, pw, ph, ttl):
        self._R(px, py, pw, ph, (12, 16, 28, 245))
        self._RO(px, py, pw, ph, (58, 68, 95), 2)
        arcade.draw_line(px + 14, py + ph - 11, px + pw - 14, py + ph - 11, (44, 52, 72), 1)
        arcade.draw_text(ttl, px + pw // 2, py + ph - 27, (175, 165, 145), 17,
                         font_name=self.font, anchor_x="center", anchor_y="center")

    def _draw_game(self):
        p = self.game_world.player
        cam = self.game_world.current_map
        if p and cam:
            target_x = p.position.x
            target_y = p.position.y
            self.camera_x += (target_x - self.camera_x) * 0.1
            self.camera_y += (target_y - self.camera_y) * 0.1

        shake_x, shake_y = self.vfx.get_camera_offset()
        cam_x = self.camera_x + shake_x
        cam_y = self.camera_y + shake_y

        renderer.draw_map(cam_x, cam_y, self.game_world.current_map)

        renderer.clear_light_sources()
        for npc in self.game_world.npcs:
            if npc.is_master:
                renderer.add_light_source(npc.position.x, npc.position.y, 100, (255, 200, 100), 0.4)
            elif npc.npc_type == NpcType.ENEMY:
                renderer.add_light_source(npc.position.x, npc.position.y, 80, (255, 80, 80), 0.3)

        self._spawn_ambient_particles(cam_x, cam_y)
        for part in self.particles:
            sx, sy = renderer._world_to_screen(part["x"], part["y"], cam_x, cam_y)
            alpha = int(255 * (part["life"] / part["max_life"]))
            c = part["color"]
            arcade.draw_circle_filled(sx, sy, part["size"], (c[0], c[1], c[2], max(0, min(255, alpha))))

        for npc in self.game_world.npcs:
            renderer.draw_npc(npc, cam_x, cam_y)

        if p:
            renderer.draw_player(p, cam_x, cam_y)

        self.vfx.draw_particles()
        self.vfx.draw_damage_numbers()

        self.vfx.draw_day_night()

        self.vfx.draw_weather()

        self.vfx.draw_vignette()

        if p:
            renderer.draw_hud(p, self.game_world.game_time)

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

        if p.skills:
            iy = py + ph - 65
            for skill in p.skills[self.skill_scroll:self.skill_scroll + 10]:
                type_colors = {0: (255, 150, 150), 1: (150, 200, 255), 2: (255, 180, 100), 3: (200, 150, 255), 4: (150, 255, 200), 5: (200, 200, 200), 6: (255, 200, 150), 7: (200, 180, 150), 8: (255, 150, 200), 9: (255, 255, 150), 10: (255, 200, 220)}
                tc = type_colors.get(skill.type, (200, 200, 200))
                self._R(px + 15, iy - 12, pw - 30, 28, (25, 30, 50, 180))
                arcade.draw_text(f"{skill.name} Lv.{skill.level}", px + 25, iy, tc, 15,
                                 font_name=self.font, anchor_x="left", anchor_y="center")
                bar_w = 100
                bar_x = px + pw - 30 - bar_w
                exp_pct = skill.exp / skill.get_exp_for_next_level() if skill.get_exp_for_next_level() > 0 else 0
                self._R(bar_x, iy - 5, bar_w, 10, (30, 30, 50))
                if exp_pct > 0:
                    self._R(bar_x, iy - 5, int(bar_w * exp_pct), 10, tc)
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
                self._create_player()
            elif key == arcade.key.ESCAPE:
                self.game_state = "menu"
        elif self.game_state == "playing":
            if self.encounter_display:
                if key == arcade.key.Y:
                    self._accept_encounter()
                elif key == arcade.key.N or key == arcade.key.ESCAPE:
                    self.pending_encounter = None
                    self.encounter_display = False
                    self.show_dialog = False
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
                self.attack_npc()
            elif key == arcade.key.B:
                self.show_inventory = not self.show_inventory
                self.show_skill_panel = False
            elif key == arcade.key.K:
                self.show_skill_panel = not self.show_skill_panel
                self.show_inventory = False
            elif key == arcade.key.Q:
                self.show_quests()
            elif key == arcade.key.M:
                self.show_minimap = not self.show_minimap
            elif key == arcade.key.E:
                self._use_first_consumable()
            elif key == arcade.key.ESCAPE:
                self.game_state = "menu"
            elif key == arcade.key.SPACE:
                self.show_dialog = False

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
        p.position.y = row_to_y(40)
        self.camera_x = p.position.x
        self.camera_y = p.position.y
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
                skill_names = []
                for sid in self.current_npc.teach_skills:
                    if sid in ALL_SKILLS:
                        skill_names.append(ALL_SKILLS[sid].name)
                self.dialog_text = (f"【{self.current_npc.name}】我可以传授你：\n"
                                   + "\n".join(f"  · {sn}" for sn in skill_names)
                                   + "\n\n按 Y 拜师学艺 | 按 N 取消")
                self.dialog_type = "npc"
                self._pending_teach = {"npc": self.current_npc, "skills": self.current_npc.teach_skills}
            else:
                self.dialog_text = f"【{self.current_npc.name}】我没什么可教你的。"
            return

        if option == "查看商品":
            if self.current_npc.sell_items:
                item_names = []
                for item_id in self.current_npc.sell_items[:6]:
                    item = self.game_world.get_item_by_id(item_id)
                    if item:
                        item_names.append(f"  · {item.name} ({item.price}文)")
                self.dialog_text = (f"【{self.current_npc.name}】本店商品：\n"
                                   + "\n".join(item_names))
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
        from .world import ALL_SKILLS
        learned = []
        already = []
        for sid in skill_ids:
            if sid in ALL_SKILLS:
                skill = ALL_SKILLS[sid]
                if not any(s.id == sid for s in player.skills):
                    new_skill = Skill(
                        id=sid,
                        name=skill.name,
                        type=skill.type,
                        level=1,
                        exp=0,
                    )
                    player.skills.append(new_skill)
                    learned.append(skill.name)
                else:
                    already.append(skill.name)
        parts = []
        if learned:
            parts.append(f"学会了：{', '.join(learned)}")
        if already:
            parts.append(f"已掌握：{', '.join(already)}")
        self.dialog_text = f"【{npc.name}】{parts[0] if parts else '传授完毕'}"
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
        e = self.game_world.get_nearby_enemy(self.game_world.player.position)
        if e:
            old_hp = self.game_world.player.hp
            self.dialog_text = self.game_world.start_combat(self.game_world.player, e)
            if self.game_world.player.hp < old_hp:
                self._hurt_flash_val = 1.0
                renderer.set_hurt_flash(1.0)
            self.dialog_title = "战斗"
            self.dialog_type = "combat"
            self.show_dialog = True
        else:
            self.dialog_text = "附近没有敌人"
            self.dialog_title = "提示"
            self.dialog_type = "info"
            self.show_dialog = True

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


def run_game():
    window = GameWindow()
    arcade.run()
