# 侠影江湖 — 美术资产提示文档（完整版）
> **文档版本**: v3.0 | **最后更新**: 2026-05-19 | **对应代码**: ink_renderer.py / ink_char_renderer.py / tile_renderer.py

> **项目名称**：侠影江湖（Xiá Yǐng Jiāng Hú）
> **文档版本**：v3.0
> **最后更新**：2026-05-19
> **风格定位**：中国水墨画 + 仙侠游戏美术
> **目标**：为Stable Diffusion、Midjourney、DALL-E等AI绘图工具提供详细的图像生成提示

---

## 目录

1. [一、角色美术Prompt](#一角色美术prompt)
   - [1.1 角色设计规范](#11-角色设计规范)
   - [1.2 核心NPC](#12-核心npc)
   - [1.3 七大门派角色](#13-七大门派角色)
   - [1.4 通用NPC模板](#14-通用npc模板)
   - [1.5 敌人角色](#15-敌人角色)
2. [二、场景美术Prompt](#二场景美术prompt)
   - [2.1 五大城池](#21-五大城池)
   - [2.2 十六小镇](#22-十六小镇)
   - [2.3 四十五野外区域](#23-四十五野外区域)
   - [2.4 七大门派场景](#24-七大门派场景)
   - [2.5 地图瓦片](#25-地图瓦片)
3. [三、UI美术Prompt](#三ui美术prompt)
   - [3.1 界面元素](#31-界面元素)
   - [3.2 特效美术](#32-特效美术)
4. [四、武器装备美术Prompt](#四武器装备美术prompt)
   - [4.1 武器](#41-武器)
   - [4.2 防具](#42-防具)
   - [4.3 饰品](#43-饰品)
5. [五、动画规范](#五动画规范)
   - [5.1 角色动画](#51-角色动画)
   - [5.2 特效动画](#52-特效动画)
6. [六、风格指南](#六风格指南)
   - [6.1 水墨风格规范](#61-水墨风格规范)
   - [6.2 配色方案](#62-配色方案)
   - [6.3 输出规范](#63-输出规范)

---

## 一、角色美术Prompt

### 通用风格规范

所有角色美术必须遵循以下规范：

**英文风格提示：**
```
Chinese ink wash painting style, traditional Chinese martial arts, wuxia character, elegant composition, gold accents, cinematic lighting, masterpiece, best quality, 8k, ultra detailed
```

**中文风格提示：**
```
中国水墨画风格，传统武侠角色，优雅构图，金色点缀，电影级光影，杰作，最佳质量，8k，超详细
```

**变体要求：**
- 立绘（全身，正面）
- 半身像（腰部以上）
- Q版（2.5头身，可爱风格）
- 战斗姿势（动态，带特效）
- 三视图（正面/侧面/背面）

---

### 1.0 Godot 2D NPC拆件套件（实装规范）

> 本节是 Godot 版当前使用的 2D NPC 地图形象规范。目标不是先追求高精度立绘，而是建立一套可复用、可扩展、能在地图上快速识别角色身份的“水墨小人拆件系统”。当前 Godot 已用该拆件规则批量生成透明 PNG sprite，并在地图上优先使用这些资源。

#### 1.0.1 拆件字段

每个 NPC 可以通过 `appearance` 字段覆盖外观。若不填写，Godot 会按 NPC 名称、门派、类型自动匹配预设。

```json
"appearance": {
  "archetype": "innkeeper",
  "build": "round",
  "head": "round",
  "hair": "sideburns",
  "hat": "merchant_cap",
  "outfit": "merchant_robe",
  "prop": "abacus",
  "motif": "coin",
  "primary": [0.62, 0.36, 0.20],
  "secondary": [0.84, 0.68, 0.36],
  "accent": [0.96, 0.78, 0.34]
}
```

| 字段 | 用途 | 示例 |
|------|------|------|
| `archetype` | 角色职业/身份模板 | `innkeeper`, `scholar`, `constable`, `bagua_master` |
| `build` | 体型轮廓 | `round`, `slim`, `broad`, `aged`, `boss` |
| `head` | 头脸轮廓 | `round`, `oval`, `square`, `long`, `sharp`, `aged` |
| `hair` | 头发/胡须基础 | `short`, `topknot`, `long_tail`, `white_beard`, `bald`, `messy` |
| `hat` | 帽子/头饰 | `merchant_cap`, `scholar_hat`, `constable_hat`, `daoist_crown`, `snow_hood` |
| `outfit` | 服装结构 | `merchant_robe`, `work_apron`, `official_uniform`, `monk_robe`, `dark_armor` |
| `prop` | 手持物/职业道具 | `abacus`, `scroll`, `dao`, `hammer`, `fan`, `great_blade` |
| `motif` | 胸口/身份纹样 | `coin`, `book`, `badge`, `bagua`, `flower`, `taiji`, `snow`, `dragon` |
| `primary` | 主衣色 RGB 0-1 | `[0.44, 0.43, 0.38]` |
| `secondary` | 辅助衣色/深色部件 | `[0.18, 0.17, 0.16]` |
| `accent` | 高亮色/纹样/腰带 | `[0.82, 0.68, 0.38]` |

#### 1.0.2 当前职业模板

| 模板 | 身份识别重点 | 头帽 | 服饰 | 道具 | 地图识别目标 |
|------|--------------|------|------|------|--------------|
| `innkeeper` 掌柜 | 圆润、精明、店铺经营者 | 商人帽、鬓角 | 暖棕商人袍、金色腰带 | 算盘 | 一眼看出能交易/住店 |
| `waiter` 店小二 | 机灵、跑堂、轻快 | 布帽 | 短褂围裙 | 毛巾 | 客栈服务人员 |
| `tofu_seller` 阿青 | 清爽、温柔、隐藏剑意 | 长发束尾 | 浅色素衣 | 竹篮 | 市井少女但有武学气质 |
| `scholar` 夫子 | 文气、瘦长、年长 | 方巾/书生帽、胡须 | 青灰长衫 | 书卷 | 教学/识字 NPC |
| `constable` 捕快 | 正直、执法、压迫感 | 捕快帽 | 深蓝官服、胸牌 | 朴刀 | 治安/除暴任务入口 |
| `elder` 村长 | 年长、稳重、乡土权威 | 软帽、白须 | 土褐长袍 | 手杖 | 镇内事务中心 |
| `monk` 和尚 | 僧侣、慈悲、戒律 | 光头戒疤 | 橘褐僧袍 | 佛珠 | 内功/道德相关 |
| `blacksmith` 铁匠 | 强壮、粗粝、工具感 | 头巾 | 深色皮围裙 | 铁锤 | 武器防具商店 |
| `wandering_hero` 大侠 | 挺拔、游侠、主线引导 | 高束发 | 深蓝侠客服 | 长剑 | 高等级引路人 |

#### 1.0.3 门派掌门模板

| 模板 | 门派气质 | 头饰 | 服装轮廓 | 武器/道具 | 纹样 |
|------|----------|------|----------|-----------|------|
| `bagua_master` 韦扬 | 稳、厚、阵法感 | 小冠 | 灰黑门派袍、金腰带 | 刀 | 八卦圆盘 |
| `flower_master` 清照 | 雅、柔、花影流动 | 花簪 | 粉红流袖汉服 | 扇 | 花瓣 |
| `taiji_master` 清虚道人 | 静、虚、道家 | 道冠 | 黑白道袍 | 拂尘 | 太极 |
| `xueshan_master` 白瑞德 | 冷、硬、雪山高处 | 雪帽/兜帽 | 冰蓝毛领袍 | 剑 | 雪花 |

#### 1.0.4 敌人模板

| 模板 | 敌人层级 | 轮廓 | 服饰 | 武器 | 视觉语言 |
|------|----------|------|------|------|----------|
| `thug` 流氓 | 低级杂兵 | 粗短、不端正 | 破衣 | 木棍 | 红褐色、疤痕 |
| `bandit` 流氓头/土匪 | 小头目 | 宽肩、压迫感 | 皮甲/头巾 | 刀 | 更深红、更厚重 |
| `assassin` 采花大盗 | 速度型敌人 | 瘦长、尖锐 | 夜行衣/面罩 | 匕首 | 黑红、遮脸 |
| `boss` 神秘人 | 阶段 BOSS | 高大、外放 | 暗甲/冠饰 | 大刀 | 暗红龙纹、危险光环 |

#### 1.0.5 设计原则

1. 地图上优先看“剪影”：帽子、肩宽、衣摆、道具必须比脸部细节更明显。
2. NPC 身份由三件事决定：`帽子/发型 + 服装轮廓 + 手持物`。
3. 门派角色必须有统一色彩和胸口纹样，掌门再额外加光环。
4. 敌人不只换颜色，要改变姿态和轮廓：破衣、面罩、武器外露、暗色光环。
5. 地图小人用于地图识别；对话半身像和正式立绘可在同一 `appearance` 字段基础上扩展。

#### 1.0.6 当前 NPC 对应表

| NPC | 模板 | 关键视觉 |
|-----|------|----------|
| 平阿四 | `innkeeper` | 商人帽、暖棕袍、算盘、铜钱纹 |
| 店小二 | `waiter` | 布帽、围裙、毛巾 |
| 阿青 | `tofu_seller` | 浅色素衣、长发、竹篮、水纹 |
| 老夫子 | `scholar` | 书生帽、青灰长衫、书卷、书纹 |
| 捕快 | `constable` | 捕快帽、深蓝官服、胸牌、朴刀 |
| 村长 | `elder` | 软帽、白须、手杖、土褐袍 |
| 道德和尚 | `monk` | 光头戒疤、僧袍、佛珠、莲纹 |
| 铁匠 | `blacksmith` | 头巾、皮围裙、铁锤、火星纹 |
| 大侠 | `wandering_hero` | 高束发、侠客服、长剑、风纹 |
| 韦扬 | `bagua_master` | 小冠、灰黑袍、刀、八卦纹 |
| 清照 | `flower_master` | 花簪、流袖汉服、扇、花纹 |
| 清虚道人 | `taiji_master` | 道冠、太极袍、拂尘、太极纹 |
| 白瑞德 | `xueshan_master` | 雪帽、毛领袍、剑、雪花纹 |
| 流氓 | `thug` | 破衣、乱发、木棍、疤痕 |
| 流氓头 | `bandit` | 头巾、皮甲、刀、疤痕 |
| 采花大盗 | `assassin` | 面罩、夜行衣、匕首、暗影纹 |
| 神秘人 | `boss` | 暗冠、暗甲、大刀、龙纹 |

#### 1.0.7 Godot 当前实装资产

- Godot 工程当前已恢复并扩展到 `99` 个 NPC 数据，来源为旧 Python 版本的 `src/data/npcs.json` 和第一批文档核心角色。
- `tools/generate_godot_art_assets.py` 已按拆件规则生成第一批可直接使用资源：`99` 个 NPC 地图 sprite、`99` 个 NPC 对话头像、`16` 个玩家门派/性别 sprite、`29` 个头部/服饰/道具拆件 PNG、`20` 个地图瓦片 PNG、`22` 个物品图标、`73` 个区域场景背景、`8` 个基础 UI PNG。
- 当前大地图 NPC 优先使用 `godot_project/assets/characters/generated_map_sprites/` 的统一风格透明 PNG，避免整身 PNG 与临时程序小人混用导致精细度不一致。
- NPC 对话头像保存在 `godot_project/assets/characters/npc/portraits/`，当前对话面板已按 NPC 名称加载这些头像。
- 玩家地图 sprite 保存在 `godot_project/assets/characters/player/`，拆件源资源保存在 `godot_project/assets/characters/parts/`。
- 地图瓦片保存在 `godot_project/assets/world/tiles/`，区域场景背景保存在 `godot_project/assets/world/scenes/`，物品图标保存在 `godot_project/assets/items/icons/`，基础 UI 资源保存在 `godot_project/assets/ui/`。
- 背包/商店已按物品 ID 加载 `assets/items/icons/` 图标，世界地图面板已按区域 ID 加载 `assets/world/scenes/` 背景，并使用 `assets/ui/` 的地图标记 PNG。
- 资源预览保存在 `godot_project/assets/previews/`，包含瓦片、地图 NPC、玩家、NPC 头像、物品图标和场景背景预览。
- 旧 PNG 图集仍保存在 `godot_project/assets/characters/npc/atlases/`，切片后的单角色 sprite 仍保存在 `godot_project/assets/characters/npc/sprites/`，后续更适合作为头像、立绘或战斗展示素材库。
- `godot_project/data/npc_sprite_assets.json` 负责把 99 个 NPC 名称映射到当前地图 PNG；未映射的 NPC 才回退到 `appearance` 拆件系统自动渲染。
- `godot_project/data/npc_portrait_assets.json` 负责把 99 个 NPC 名称映射到对话头像。
- `godot_project/data/item_icon_assets.json` 负责把 22 个物品 ID 映射到图标。
- `godot_project/data/scene_background_assets.json` 负责把 73 个区域 ID 映射到场景背景。
- 后续新增 NPC 美术时，优先按 `帽子/发型 + 服装轮廓 + 手持物 + 门派纹样` 四件套设计，保证地图上不用读字也能辨识身份。

---

### 1.1 角色设计规范

#### 1.1.1 角色比例标准

**头身比参考表：**

| 角色类型 | 头身比 | 肩宽比例 | 腿长比例 | 适用角色 |
|---------|--------|---------|---------|---------|
| Q版角色 | 2.5头身 | 1.2头宽 | 0.8头长 | 可爱NPC、宠物、小精灵 |
| 少年角色 | 5.5头身 | 1.5头宽 | 2.5头长 | 年轻弟子、学徒、少年侠客 |
| 标准成人 | 7头身 | 2头宽 | 3.5头长 | 普通成人、一般NPC |
| 武侠成人 | 7.5头身 | 2.2头宽 | 3.8头长 | 武林高手、主角、重要NPC |
| 魁梧壮汉 | 6.5头身 | 2.8头宽 | 2.8头长 | 壮汉、力士、坦克型角色 |

**比例Prompt示例：**

**英文：**
```
Character proportion: 7.5 heads tall, shoulder width 2.2 head widths, leg length 3.8 head lengths, elegant martial arts physique, balanced proportions
```

**中文：**
```
角色比例：7.5头身，肩宽2.2头宽，腿长3.8头长，优雅的武术体型，均衡比例
```

---

#### 1.1.2 面部特征库

**基础脸型（10种）：**

| 编号 | 脸型名称 | 英文描述 | 中文描述 |
|-----|---------|---------|---------|
| F-01 | 鹅蛋脸 | Oval face, soft curved jawline | 鹅蛋脸，柔和弯曲的下颌线 |
| F-02 | 瓜子脸 | Melon seed face, pointed chin | 瓜子脸，尖下巴 |
| F-03 | 圆脸 | Round face, full cheeks | 圆脸，饱满脸颊 |
| F-04 | 方脸 | Square face, strong jaw | 方脸，坚毅下颌 |
| F-05 | 长脸 | Long face, elongated features | 长脸，拉长的五官 |
| F-06 | 菱形脸 | Diamond face, prominent cheekbones | 菱形脸，突出颧骨 |
| F-07 | 心形脸 | Heart-shaped face, wide forehead | 心形脸，宽额头 |
| F-08 | 国字脸 | Guozi face, strong angular jaw | 国字脸，棱角分明的下颌 |
| F-09 | 梨形脸 | Pear face, narrow forehead wide jaw | 梨形脸，窄额头宽下颌 |
| F-10 | 申字脸 | Shen face, narrow at both ends | 申字脸，两端窄中间宽 |

**眼型（20种）：**

| 编号 | 眼型名称 | 英文描述 | 中文描述 |
|-----|---------|---------|---------|
| E-01 | 杏眼 | Almond eyes, gentle curve | 杏眼，柔和弧度 |
| E-02 | 丹凤眼 | Phoenix eyes, upward outer corner | 丹凤眼，外眼角上扬 |
| E-03 | 桃花眼 | Peach blossom eyes, watery gaze | 桃花眼，水汪汪的眼神 |
| E-04 | 柳叶眼 | Willow leaf eyes, slender shape | 柳叶眼，细长形状 |
| E-05 | 狐狸眼 | Fox eyes, sharp upward tilt | 狐狸眼，锐利上扬 |
| E-06 | 圆眼 | Round eyes, innocent look | 圆眼，天真神情 |
| E-07 | 细长眼 | Slender eyes, narrow and long | 细长眼，窄而长 |
| E-08 | 三角眼 | Triangular eyes, sharp inner corner | 三角眼，内眼角锐利 |
| E-09 | 吊梢眼 | Upturned eyes, dramatic lift | 吊梢眼，夸张上扬 |
| E-10 | 下垂眼 | Downturned eyes, sad gentle look | 下垂眼，忧伤温柔 |
| E-11 | 单眼皮 | Single eyelid, Asian feature | 单眼皮，亚洲特征 |
| E-12 | 双眼皮 | Double eyelid, defined crease | 双眼皮，明显褶皱 |
| E-13 | 内双 | Hidden double eyelid | 内双，隐藏式双眼皮 |
| E-14 | 三白眼 | Sanbai eyes, visible white below iris | 三白眼，虹膜下露白 |
| E-15 | 四白眼 | Sibai eyes, white visible all around | 四白眼，四周露白 |
| E-16 | 眯缝眼 | Narrow slit eyes | 眯缝眼，细长缝隙 |
| E-17 | 深眼窝 | Deep-set eyes, prominent brow | 深眼窝，突出眉骨 |
| E-18 | 凸眼 | Prominent eyes, forward projection | 凸眼，向前突出 |
| E-19 | 鸳鸯眼 | Mismatched eyes, different colors | 鸳鸯眼，异色瞳 |
| E-20 | 凤目 | Phoenix eyes with double eyelid | 凤目，双眼皮丹凤眼 |

**鼻型（15种）：**

| 编号 | 鼻型名称 | 英文描述 | 中文描述 |
|-----|---------|---------|---------|
| N-01 | 直鼻 | Straight nose, linear profile | 直鼻，线条笔直 |
| N-02 | 鹰钩鼻 | Hooked nose, curved bridge | 鹰钩鼻，鼻梁弯曲 |
| N-03 | 蒜头鼻 | Garlic nose, rounded tip | 蒜头鼻，圆鼻头 |
| N-04 | 小翘鼻 | Upturned nose, perky tip | 小翘鼻，俏皮鼻尖 |
| N-05 | 罗马鼻 | Roman nose, prominent bridge | 罗马鼻，高鼻梁 |
| N-06 | 希腊鼻 | Greek nose, straight narrow | 希腊鼻，笔直窄细 |
| N-07 | 塌鼻 | Flat nose, low bridge | 塌鼻，低鼻梁 |
| N-08 | 宽鼻 | Wide nose, broad nostrils | 宽鼻，鼻孔宽大 |
| N-09 | 窄鼻 | Narrow nose, thin nostrils | 窄鼻，鼻孔细小 |
| N-10 | 朝天鼻 | Snub nose, upturned nostrils | 朝天鼻，鼻孔朝上 |
| N-11 | 驼峰鼻 | Hump nose, bony ridge | 驼峰鼻，骨节隆起 |
| N-12 | 悬胆鼻 | Suspended gall nose, rounded full | 悬胆鼻，圆润饱满 |
| N-13 | 剑鼻 | Sword nose, sharp defined | 剑鼻，锐利分明 |
| N-14 | 福鼻 | Fortune nose, fleshy tip | 福鼻，肉鼻头 |
| N-15 | 龙鼻 | Dragon nose, majestic prominent | 龙鼻，威严突出 |

**嘴型（15种）：**

| 编号 | 嘴型名称 | 英文描述 | 中文描述 |
|-----|---------|---------|---------|
| M-01 | 樱桃小嘴 | Cherry lips, small full | 樱桃小嘴，小巧饱满 |
| M-02 | 薄唇 | Thin lips, delicate line | 薄唇，线条精致 |
| M-03 | 厚唇 | Full lips, voluptuous | 厚唇，丰满性感 |
| M-04 | 弓形唇 | Bow lips, defined cupid bow | 弓形唇，明显丘比特弓 |
| M-05 | 平直唇 | Straight lips, neutral expression | 平直唇，中性表情 |
| M-06 | 上扬唇 | Upturned lips, smiling base | 上扬唇，微笑基底 |
| M-07 | 下垂唇 | Downturned lips, serious base | 下垂唇，严肃基底 |
| M-08 | 心形唇 | Heart lips, pointed center | 心形唇，中心尖形 |
| M-09 | 宽唇 | Wide lips, broad smile | 宽唇，宽阔笑容 |
| M-10 | 窄唇 | Narrow lips, refined | 窄唇，精致 |
| M-11 | 方唇 | Square lips, defined corners | 方唇，分明嘴角 |
| M-12 | 圆唇 | Round lips, soft edges | 圆唇，柔和边缘 |
| M-13 | 花瓣唇 | Petal lips, layered appearance | 花瓣唇，层次分明 |
| M-14 | 微笑唇 | Smiling lips, upward curve | 微笑唇，上扬曲线 |
| M-15 | 严肃唇 | Serious lips, firm line | 严肃唇，坚定线条 |

---

#### 1.1.3 表情系统

**6种基础表情 × 3种强度 = 18种表情变化**

| 基础表情 | 轻度(1级) | 中度(2级) | 强烈(3级) |
|---------|----------|----------|----------|
| **喜悦** | 微笑，嘴角微扬，眼睛温和 | 开怀，露齿笑，眼睛弯起 | 狂喜，大笑，眼睛眯起 |
| **愤怒** | 微怒，眉头微皱，嘴角下撇 | 愤怒，眉头紧锁，咬牙 | 暴怒，怒目圆睁，咆哮 |
| **悲伤** | 忧郁，眼神黯淡，嘴角下垂 | 悲伤，泪眼，嘴唇颤抖 | 痛哭，泪流满面，张嘴 |
| **惊讶** | 意外，眉毛微抬，嘴微张 | 惊讶，眉毛高抬，眼睁大 | 震惊，瞪大眼睛，嘴大张 |
| **恐惧** | 不安，眼神闪烁，眉头微蹙 | 害怕，瞳孔收缩，身体后仰 | 惊恐，脸色苍白，尖叫状 |
| **厌恶** | 不悦，鼻子微皱，嘴角下撇 | 厌恶，皱眉，撇嘴 | 憎恨，怒目，咬牙切齿 |

**表情Prompt示例：**

**喜悦-中度：**
```
English: Joyful expression, open-mouthed smile showing teeth, eyes curved in crescent shape, raised cheeks, warm genuine happiness
Chinese: 喜悦表情，露齿笑，眼睛弯成月牙形，脸颊上扬，温暖真诚的快乐
```

**愤怒-强烈：**
```
English: Furious expression, brows deeply furrowed, eyes wide with rage, teeth bared, veins visible on forehead, intense anger
Chinese: 暴怒表情，眉头深锁，怒目圆睁，咬牙切齿，额头青筋可见，强烈愤怒
```

---

#### 1.1.4 年龄表现

**年龄阶段绘制差异：**

| 年龄阶段 | 头身比 | 面部特征 | 皮肤质感 | 体态特征 |
|---------|--------|---------|---------|---------|
| **少年(12-16)** | 5.5-6头身 | 圆润脸庞，大眼睛，短眉毛 | 光滑细腻，红润 | 轻盈灵活，姿态活泼 |
| **青年(17-30)** | 7-7.5头身 | 轮廓分明，眼神锐利 | 紧致有弹性，光泽 | 挺拔有力，姿态自信 |
| **中年(31-50)** | 7头身 | 成熟稳重，眼角细纹 | 开始出现皱纹，肤色均匀 | 稳重沉着，姿态从容 |
| **老年(51+)** | 6.5-7头身 | 皱纹明显，眼窝深陷 | 松弛有皱纹，老年斑 | 略微佝偻，姿态缓慢 |

**年龄表现Prompt示例：**

**少年：**
```
English: Youthful appearance, round soft face, large bright eyes, short neat eyebrows, smooth skin with healthy glow, energetic posture
Chinese: 少年外貌，圆润柔和的脸庞，大而明亮的眼睛，短而整齐的眉毛，光滑肌肤带健康光泽，充满活力的姿态
```

**老年：**
```
English: Elderly appearance, deeply wrinkled face, sunken eyes, white/grey hair and beard, age spots on skin, slightly hunched posture, wise expression
Chinese: 老年外貌，深深皱纹的脸庞，凹陷的眼睛，白发白须，皮肤有老年斑，略微佝偻的姿态，睿智的表情
```

---

### 1.2 核心NPC

#### NPC-001 逍遥子

**角色名称：** 逍遥子

**身份：** 逍遥派掌门、主角引路人、江湖散仙

**完整英文Prompt：**
```
Chinese ink wash painting, ancient Chinese immortal, slender elegant old man with white hair and beard, wearing flowing white silk robe with cloud patterns, holding pine wood sword, standing in misty mountains, ethereal aura, wise eyes with starlight, celestial being, wuxia master, elegant composition, gold accents, cinematic lighting, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt：**
```
中国水墨画风格，中国古代仙人，身材修长优雅的老者，白发白须，身穿流动的白色丝绸长袍，带有云纹图案，手持松木剑，站在雾蒙蒙的山间，空灵气质，智慧的眼睛带有星光，天人，武侠宗师，优雅构图，金色点缀，电影级光影，杰作，最佳质量，8k，超详细
```

**角色三视图描述：**
- **正面：** 仙风道骨的老者，白发及腰，白须垂胸，手持松木剑，白色云纹长袍飘逸
- **侧面：** 修长身材，微驼背，长袍下摆随风飘动，剑尖触地
- **背面：** 长发披肩，长袍后摆有云雾图案，背影仙意盎然

**服装细节分解：**
- **头部：** 白发束髻，插玉簪，白须三缕
- **身体：** 白色丝绸道袍，云纹刺绣，宽袖飘逸
- **手部：** 修长手指，持松木剑，指甲修剪整齐
- **脚部：** 云纹布鞋，白色布袜
- **配饰：** 腰间玉佩，手腕佛珠

**配色方案：**
- 主色：#FFFFFF（纯白）
- 辅色：#C9A96E（金色）
- 点缀色：#4A8A5A（翠绿）

**武器设计：** 松风古剑 - 千年松木所制，剑身有天然松纹，剑柄缠绿丝

**表情参考图描述：** 慈祥微笑，眼神深邃如星空，眉宇间透着超凡脱俗

**风格参考：** 中国水墨画、仙侠游戏风格、《一人之下》老天师风格

**需要生成的变体：**
- 立绘（全身正面）
- 半身像（腰部以上）
- Q版（2.5头身）
- 战斗姿势（动态，带剑气特效）
- 三视图（正面/侧面/背面）

---

#### NPC-002 道德和尚

**角色名称：** 道德和尚

**身份：** 少林叛僧、前达摩院首座、心怀愧疚之人

**完整英文Prompt：**
```
Chinese ink wash painting, powerful Buddhist monk, muscular build, shaved head with precept scars, wearing worn gray monk robes, holding heavy iron monk staff, fierce but compassionate eyes, standing in meditation pose, wuxia master, temple background, elegant composition, gold accents, cinematic lighting, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt：**
```
中国水墨画风格，威武的和尚，肌肉发达，光头带戒疤，身穿破旧的灰色僧袍，手持沉重的铁禅杖，眼神凶狠但慈悲，站立冥想姿势，武侠宗师，寺庙背景，优雅构图，金色点缀，电影级光影，杰作，最佳质量，8k，超详细
```

**角色三视图描述：**
- **正面：** 魁梧身材，光头九疤，灰色僧袍，手持铁禅杖，表情威严
- **侧面：** 厚实胸膛，粗壮手臂，禅杖竖立，身形如山
- **背面：** 僧袍后背有补丁，肌肉线条明显，背影沉稳

**服装细节分解：**
- **头部：** 光头，九枚戒疤排列整齐
- **身体：** 灰色棉布僧袍，多处补丁，腰带系紧
- **手部：** 粗大手掌，老茧遍布，握禅杖有力
- **脚部：** 草鞋，脚踝有绑带
- **配饰：** 佛珠挂颈，铜钵挂腰

**配色方案：**
- 主色：#808080（灰色）
- 辅色：#8B4513（褐色）
- 点缀色：#C9A96E（金色）

**武器设计：** 伏魔禅杖 - 玄铁打造，杖身雕龙虎，重逾百斤

**表情参考图描述：** 眉头微皱，眼神复杂，既有威严又有悲悯

**风格参考：** 中国水墨画、少林寺主题、《天龙八部》扫地僧风格

**需要生成的变体：**
- 立绘（全身正面）
- 半身像（腰部以上）
- Q版（2.5头身）
- 战斗姿势（动态，带禅杖特效）
- 三视图（正面/侧面/背面）

---

#### NPC-003 老夫子

**角色名称：** 老夫子

**身份：** 前翰林学士、私塾先生、暗藏秘密之人

**完整英文Prompt：**
```
Chinese ink wash painting, elderly scholar, thin hunchback figure, wearing worn blue traditional robes with ink stains, holding jade writing brush, thick round glasses, goatee, standing in study with bookshelves, wise but troubled eyes, calligraphy scrolls on walls, elegant composition, gold accents, cinematic lighting, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt：**
```
中国水墨画风格，老年学者，瘦弱驼背的身材，身穿带墨迹的破旧蓝色传统长袍，手持玉笔，厚重圆框眼镜，山羊胡，站在书房中，周围有书架，智慧但忧虑的眼神，墙上挂着书法卷轴，优雅构图，金色点缀，电影级光影，杰作，最佳质量，8k，超详细
```

**角色三视图描述：**
- **正面：** 瘦小身材，驼背，圆框眼镜，山羊胡，蓝色长袍
- **侧面：** 明显驼背，长袍拖地，手持毛笔，身形佝偻
- **背面：** 驼背轮廓，长袍后摆，白发稀疏

**服装细节分解：**
- **头部：** 稀疏白发，圆框铜边眼镜，山羊胡
- **身体：** 蓝色棉布长袍，多处墨迹，宽松舒适
- **手部：** 枯瘦手指，握玉笔，指甲略长
- **脚部：** 布鞋，布袜
- **配饰：** 腰间挂玉佩，胸前挂老花镜

**配色方案：**
- 主色：#4169E1（皇家蓝）
- 辅色：#F5F0E8（米白）
- 点缀色：#8B4513（褐色）

**武器设计：** 判官笔 - 玉制笔杆，狼毫笔尖，可书可武

**表情参考图描述：** 眉头紧锁，眼神忧虑，嘴角下垂，似有难言之隐

**风格参考：** 中国水墨画、文人画风格、《三国演义》诸葛亮风格

**需要生成的变体：**
- 立绘（全身正面）
- 半身像（腰部以上）
- Q版（2.5头身）
- 战斗姿势（动态，带判官笔特效）
- 三视图（正面/侧面/背面）

---

#### NPC-004 村长

**角色名称：** 村长

**身份：** 平安镇村长、德高望重的老者

**完整英文Prompt：**
```
Chinese ink wash painting, middle-aged village chief, slightly chubby build, warm smile, wearing dark blue silk robes with black mandarin jacket, holding wooden crutch, standing in village square, kind eyes, village background, elegant composition, gold accents, cinematic lighting, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt：**
```
中国水墨画风格，中年村长，微胖身材，温暖的笑容，身穿深蓝色丝绸长袍配黑色马褂，手持木拐，站在村庄广场上，慈祥的眼神，村庄背景，优雅构图，金色点缀，电影级光影，杰作，最佳质量，8k，超详细
```

**角色三视图描述：**
- **正面：** 微胖身材，和蔼面容，深蓝长袍，黑马褂，持木拐
- **侧面：** 微凸腹部，木拐支撑，身形稳重
- **背面：** 黑马褂后背，长袍下摆，背影亲切

**服装细节分解：**
- **头部：** 灰白短发，无须，面容圆润
- **身体：** 深蓝丝绸长袍，黑马褂，盘扣整齐
- **手部：** 圆润手掌，握木拐，戴玉扳指
- **脚部：** 黑布鞋，白布袜
- **配饰：** 腰间挂铜钱串，胸前挂老花镜

**配色方案：**
- 主色：#191970（深蓝）
- 辅色：#000000（黑色）
- 点缀色：#C9A96E（金色）

**武器设计：** 无（持木拐作为辅助行走）

**表情参考图描述：** 慈祥微笑，眼角有皱纹，眼神温暖如春日阳光

**风格参考：** 中国水墨画、民间年画风格、《水浒传》晁盖风格

**需要生成的变体：**
- 立绘（全身正面）
- 半身像（腰部以上）
- Q版（2.5头身）
- 战斗姿势（动态，带拐杖特效）
- 三视图（正面/侧面/背面）

---

### 1.3 七大门派角色

#### 1.3.1 八卦门

**门派主题色：** 主色 #4A3B6B（紫黑），辅色 #C9A96E（金），背景 #2D1B4E（深紫）

---

##### 八卦门-掌门：韦扬

**角色名称：** 韦扬

**身份：** 八卦门掌门、混元一气宗师、正道之盾

**完整英文Prompt（200字+）：**
```
Chinese ink wash painting, powerful martial arts grandmaster, muscular mountain-like build with imposing presence, 7.5 heads tall with broad shoulders, wearing luxurious black silk martial arts robes with intricate gold bagua trigram patterns embroidered on chest and sleeves, holding legendary Bagua purple gold broadsword with dragon carvings, stern dignified expression with piercing eagle eyes, silver-streaked black hair tied in warrior topknot, standing in majestic martial arts hall with bagua symbols glowing in background, wuxia grandmaster aura radiating authority, elegant composition, gold accents highlighting edges, cinematic lighting with dramatic shadows, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt（200字+）：**
```
中国水墨画风格，威武的武术大宗师，如山般魁梧的身材带着威严气势，7.5头身宽肩体型，身穿华丽的黑色丝绸武术长袍，胸前和袖子绣有复杂的金色八卦卦象图案，手持带有龙纹雕刻的传奇八卦紫金刀，严肃威严的表情配上锐利的鹰眼，银丝夹杂的黑发束成武士发髻，站在宏伟的武馆大厅中，背景有发光的八卦符号，武侠大宗师气场散发着权威，优雅构图，金色点缀勾勒边缘，电影级光影配戏剧性阴影，杰作，最佳质量，8k，超详细
```

**角色三视图描述：**
- **正面：** 魁梧身材，紫黑长袍金八卦纹，手持紫金刀，眼神威严，银丝黑发束顶
- **侧面：** 如山轮廓，长袍飘动，刀身反光，身形挺拔
- **背面：** 后背大八卦图案，长袍后摆，银发飘逸

**服装细节分解：**
- **头部：** 银丝黑发武士髻，金冠束发，浓眉鹰眼
- **身体：** 紫黑丝绸长袍，金八卦刺绣，宽袖束腰
- **手部：** 粗壮有力，握紫金刀，戴金护腕
- **脚部：** 黑金战靴，云纹鞋底
- **配饰：** 腰间玉佩，胸前八卦护心镜，肩披金色披风

**配色方案：**
- 主色：#4A3B6B（紫黑）
- 辅色：#C9A96E（金色）
- 点缀色：#8B0000（暗红）

**武器设计：** 八卦紫金刀 - 刀身紫金双色，刀背雕八卦，刀柄缠金丝

**表情参考图描述：** 不怒自威，眼神如电，眉宇间透着正气

---

##### 八卦门-弟子：陆明

**角色名称：** 陆明

**身份：** 八卦门核心弟子、韦扬亲传

**完整英文Prompt：**
```
Chinese ink wash painting, young martial arts disciple, athletic build, 7 heads tall, wearing black training robes with small gold bagua patterns on collar and cuffs, serious focused expression with determined eyes, short black hair in simple warrior style, holding training broadsword in ready stance, practicing martial arts forms in training hall, wuxia character, elegant composition, gold accents, cinematic lighting, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt：**
```
中国水墨画风格，年轻武术弟子，运动型身材，7头身，身穿黑色练功服，领口袖口有小金色八卦图案，严肃专注的表情配上坚定的眼神，黑发简单武士发型，手持训练大刀呈备战姿态，在武馆中练习武术招式，武侠角色，优雅构图，金色点缀，电影级光影，杰作，最佳质量，8k，超详细
```

**角色三视图描述：**
- **正面：** 年轻英挺，黑袍金纹，持刀站立，眼神坚定
- **侧面：** 标准身材，长袍修身，刀尖指地
- **背面：** 后背小八卦，长发束起，身形挺拔

**服装细节分解：**
- **头部：** 黑发束髻，无冠，年轻面容
- **身体：** 黑色练功袍，金八卦领口，束腰
- **手部：** 年轻有力，握训练刀，戴布护腕
- **脚部：** 黑布鞋，布袜
- **配饰：** 腰间布带，胸前无装饰

**配色方案：**
- 主色：#1A1A2E（深黑）
- 辅色：#C9A96E（金色）
- 点缀色：#4A3B6B（紫黑）

**武器设计：** 训练大刀 - 木柄铁刃，无装饰，实用为主

**表情参考图描述：** 专注认真，眼神清澈，充满朝气

---

##### 八卦门-叛徒：阴九

**角色名称：** 阴九

**身份：** 八卦门叛徒、堕入邪道

**完整英文Prompt：**
```
Chinese ink wash painting, fallen martial arts master, lean wiry build with sinister aura, 7 heads tall, wearing tattered black robes with faded bagua patterns, cruel cunning expression with narrow snake-like eyes, disheveled black hair with white streaks, holding corrupted dark blade with purple energy, standing in shadowy cave, wuxia villain, elegant composition, purple accents, cinematic lighting, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt：**
```
中国水墨画风格，堕落的武术高手，精瘦身材带着阴险气场，7头身，身穿破烂黑袍，八卦图案褪色，残忍狡猾的表情配上细长的蛇眼，蓬乱黑发带白丝，手持散发着紫色能量的腐化黑刃，站在阴暗洞穴中，武侠反派，优雅构图，紫色点缀，电影级光影，杰作，最佳质量，8k，超详细
```

**角色三视图描述：**
- **正面：** 瘦削阴鸷，黑袍破旧，持黑刃，眼神阴毒
- **侧面：** 佝偻身形，长袍破烂，刃发紫光
- **背面：** 后背八卦褪色，白发飘散，背影阴森

**服装细节分解：**
- **头部：** 蓬乱黑发带白，面容枯槁，眼神阴鸷
- **身体：** 破烂黑袍，八卦褪色，腰带松散
- **手部：** 枯瘦如爪，握黑刃，指甲发黑
- **脚部：** 破布鞋，脚踝有锁链痕
- **配饰：** 腰间骷髅挂饰，颈间黑珠链

**配色方案：**
- 主色：#0D0D0D（纯黑）
- 辅色：#800080（紫色）
- 点缀色：#C0C0C0（银白）

**武器设计：** 腐化黑刃 - 原八卦刀堕落而成，刀身发黑，散发紫气

**表情参考图描述：** 阴笑，眼神恶毒，眉宇间透着邪气

---

#### 1.3.2 花间派

**门派主题色：** 主色 #C9708A（粉红），辅色 #F0C040（金），背景 #FFE4E1（浅粉）

---

##### 花间派-掌门：清照

**角色名称：** 清照

**身份：** 花间派掌门、三花聚顶宗师、百岁老妪

**完整英文Prompt（200字+）：**
```
Chinese ink wash painting, ageless female immortal, slender elegant figure with ethereal grace, 7 heads tall with willow-like posture, wearing flowing light pink silk robes with intricate floral embroidery of peonies and orchids, holding jade writing brush with flower-shaped tip, silver hair flowing down like waterfall with flower ornaments, timeless beauty with wise gentle eyes showing centuries of wisdom, standing in magnificent flower garden with blossoms blooming around her, wuxia grandmaster aura of serenity, elegant composition, pink and gold accents, soft cinematic lighting, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt（200字+）：**
```
中国水墨画风格，不老的女仙，修长优雅的身材带着空灵气质，7头身柳姿，身穿飘逸的淡粉色丝绸长袍，绣有精美的牡丹和兰花花卉刺绣，手持花形笔尖的玉笔，银色长发如瀑布般垂落并饰有花朵饰品，不老的美丽配上睿智温柔的眼睛显示着数百年的智慧，站在宏伟的花园中，周围鲜花盛开，武侠大宗师宁静气场，优雅构图，粉金点缀，柔和电影级光影，杰作，最佳质量，8k，超详细
```

**角色三视图描述：**
- **正面：** 优雅身姿，粉袍花绣，银发及腰，手持玉笔，眼神温柔
- **侧面：** 柳腰轻摆，长袍飘逸，银发如瀑，身形婀娜
- **背面：** 后背花团锦簇，银发披肩，背影仙姿

**服装细节分解：**
- **头部：** 银发及腰，花饰点缀，面容不老
- **身体：** 淡粉丝绸长袍，牡丹兰花刺绣，广袖流仙
- **手部：** 修长如玉，握玉笔，戴花形戒指
- **脚部：** 粉色绣鞋，花瓣图案
- **配饰：** 腰间花囊，颈间花形玉佩，头戴花冠

**配色方案：**
- 主色：#C9708A（粉红）
- 辅色：#F0C040（金色）
- 点缀色：#FFB6C1（浅粉）

**武器设计：** 百花拂穴笔 - 玉制笔杆，笔尖可射花针，笔身雕百花

**表情参考图描述：** 慈眉善目，眼神温柔如水，嘴角含笑

---

##### 花间派-弟子：花解语

**角色名称：** 花解语

**身份：** 花间派核心弟子、清照亲传

**完整英文Prompt：**
```
Chinese ink wash painting, beautiful young female disciple, graceful slender build, 7 heads tall, wearing light pink silk robes with small floral embroidery, gentle elegant expression with bright almond eyes, black hair in elaborate flower-adorned bun, holding flower hairpin as weapon, practicing flower sword dance in garden, wuxia character, elegant composition, pink accents, cinematic lighting, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt：**
```
中国水墨画风格，美丽的年轻女弟子，优雅修长身材，7头身，身穿淡粉色丝绸长袍，有小花卉刺绣，温柔优雅的表情配上明亮的杏眼，黑发梳成精美的花饰发髻，手持花簪作为武器，在花园中练习花剑舞，武侠角色，优雅构图，粉色点缀，电影级光影，杰作，最佳质量，8k，超详细
```

**角色三视图描述：**
- **正面：** 年轻貌美，粉袍花绣，花簪在手，眼神明亮
- **侧面：** 身姿婀娜，长袍飘逸，花簪闪光
- **背面：** 后背简洁，长发及腰，身形窈窕

**服装细节分解：**
- **头部：** 黑发花髻，面容姣好，眼神清澈
- **身体：** 淡粉长袍，小花刺绣，束腰设计
- **手部：** 纤细柔软，握花簪，戴花戒
- **脚部：** 粉色绣鞋，小巧精致
- **配饰：** 腰间香囊，耳戴花坠

**配色方案：**
- 主色：#FFB6C1（浅粉）
- 辅色：#F0C040（金色）
- 点缀色：#FF69B4（深粉）

**武器设计：** 花簪 - 金制花形，可射花针，亦可近身点穴

**表情参考图描述：** 甜美微笑，眼神清澈，充满青春活力

---

##### 花间派-叛徒：毒牡丹

**角色名称：** 毒牡丹

**身份：** 花间派叛徒、以花入毒

**完整英文Prompt：**
```
Chinese ink wash painting, fallen flower sect master, seductive dangerous beauty, 7 heads tall, wearing dark magenta robes with blackened flower patterns, cruel seductive expression with poison-green eyes, black hair with crimson streaks, holding thorny vine whip dripping with purple poison, standing in withered garden, wuxia villainess, elegant composition, dark purple accents, cinematic lighting, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt：**
```
中国水墨画风格，堕落的花派高手，危险诱人的美丽，7头身，身穿深洋红色长袍，带有黑色花卉图案，残忍诱惑的表情配上毒绿色的眼睛，黑发带深红条纹，手持滴着紫色毒液的荆棘藤鞭，站在枯萎的花园中，武侠女反派，优雅构图，深紫点缀，电影级光影，杰作，最佳质量，8k，超详细
```

**角色三视图描述：**
- **正面：** 妖艳面容，深红长袍，持毒鞭，眼神毒辣
- **侧面：** 身姿妖娆，长袍贴身，鞭发毒光
- **背面：** 后背黑花图案，红发飘散，背影妖冶

**服装细节分解：**
- **头部：** 黑红长发，面容妖艳，眼神毒绿
- **身体：** 深红长袍，黑花刺绣，紧身设计
- **手部：** 苍白细长，握毒鞭，指甲紫黑
- **脚部：** 红绣鞋，高跟设计
- **配饰：** 腰间毒囊，颈间毒花项链

**配色方案：**
- 主色：#8B008B（深洋红）
- 辅色：#2F4F4F（深灰）
- 点缀色：#9400D3（紫罗兰）

**武器设计：** 毒荆棘鞭 - 带刺藤蔓淬毒，鞭身缠绕紫气

**表情参考图描述：** 妖媚冷笑，眼神毒辣，嘴角带邪

---

#### 1.3.3 红莲教

**门派主题色：** 主色 #8B2020（深红），辅色 #F0C040（金），背景 #4A0000（暗红）

---

##### 红莲教-教主：于红儒

**角色名称：** 于红儒

**身份：** 红莲教教主、同击术宗师、赤焰之心

**完整英文Prompt（200字+）：**
```
Chinese ink wash painting, passionate rebel leader with burning spirit, tall muscular build with powerful commanding presence, 7.5 heads tall with broad shoulders and strong arms, wearing dark red martial arts robes with intricate red lotus embroidery in gold thread, holding flaming fist gauntlets that glow with inner fire, fierce determined expression with intense burning eyes and distinctive scar on left cheek, black hair tied in warrior knot with red ribbons, standing with rebel army background showing followers, wuxia grandmaster aura of revolutionary fervor, elegant composition, red and gold accents, dramatic fiery lighting, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt（200字+）：**
```
中国水墨画风格，激情的起义领袖带着燃烧的精神，高大魁梧的身材带着强大的统帅气质，7.5头身宽肩强壮手臂，身穿深红色武术长袍，有金线绣制的精美红莲刺绣，手持散发着内在火焰光芒的烈焰拳套，凶狠坚定的表情配上强烈的燃烧眼神和左脸颊独特的伤疤，黑发束成武士髻配红丝带，站立于起义军背景中显示追随者，武侠大宗师革命热情气场，优雅构图，红金点缀，戏剧性火焰光影，杰作，最佳质量，8k，超详细
```

**角色三视图描述：**
- **正面：** 魁梧身材，深红长袍金莲绣，戴烈焰拳套，左颊有疤，眼神如火
- **侧面：** 如山轮廓，长袍飘动，拳套发火光，身形威猛
- **背面：** 后背大火莲图案，红发带飘扬，背影霸气

**服装细节分解：**
- **头部：** 黑发武士髻，红丝带，左颊刀疤，浓眉火眼
- **身体：** 深红丝绸长袍，金线红莲刺绣，宽袖束腰
- **手部：** 粗壮有力，戴烈焰拳套，火光缭绕
- **脚部：** 红金战靴，火焰纹路
- **配饰：** 腰间火焰玉佩，肩披烈焰披风，颈间红莲坠

**配色方案：**
- 主色：#8B2020（深红）
- 辅色：#F0C040（金色）
- 点缀色：#FF4500（橙红）

**武器设计：** 红莲烈焰拳套 - 玄铁打造，拳面嵌红莲宝石，发火光

**表情参考图描述：** 坚毅不屈，眼神如火，眉宇间透着革命热情

---

##### 红莲教-弟子：赤焰

**角色名称：** 赤焰

**身份：** 红莲教核心弟子、于红儒亲传

**完整英文Prompt：**
```
Chinese ink wash painting, passionate young rebel fighter, athletic muscular build, 7 heads tall, wearing red martial arts robes with small lotus patterns, determined fierce expression with burning eyes, short black hair with red headband, holding simple iron staff with red cloth wrapping, standing with fellow rebels in camp, wuxia character, elegant composition, red accents, cinematic lighting, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt：**
```
中国水墨画风格，激情的年轻起义战士，运动型肌肉身材，7头身，身穿红色武术长袍，有小莲花图案，坚定凶狠的表情配上燃烧的眼神，短发配红头带，手持缠红布的简易铁棍，与教友站在营地中，武侠角色，优雅构图，红色点缀，电影级光影，杰作，最佳质量，8k，超详细
```

**角色三视图描述：**
- **正面：** 年轻健壮，红袍莲纹，持铁棍，眼神炽热
- **侧面：** 标准身材，长袍修身，棍身缠红布
- **背面：** 后背小莲花，红头带，身形挺拔

**服装细节分解：**
- **头部：** 短发红带，面容坚毅，眼神炽热
- **身体：** 红色练功袍，小莲纹领口，束腰
- **手部：** 年轻有力，握铁棍，戴红护腕
- **脚部：** 红布鞋，布袜
- **配饰：** 腰间红布带，胸前小莲佩

**配色方案：**
- 主色：#B22222（火砖红）
- 辅色：#F0C040（金色）
- 点缀色：#8B0000（暗红）

**武器设计：** 红布铁棍 - 玄铁短棍，缠红布，朴实无华

**表情参考图描述：** 热血激昂，眼神坚定，充满革命热情

---

##### 红莲教-叛徒：血手

**角色名称：** 血手

**身份：** 红莲教叛徒、嗜血成性

**完整英文Prompt：**
```
Chinese ink wash painting, bloodthirsty fallen rebel, hulking brutal build, 7 heads tall, wearing blood-stained crimson robes with blackened lotus, savage cruel expression with blood-red eyes, wild black hair with blood splatters, holding blood-dripping twin axes, standing in battlefield with corpses, wuxia villain, elegant composition, blood red accents, dark cinematic lighting, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt：**
```
中国水墨画风格，嗜血的堕落起义者，庞大残暴身材，7头身，身穿血迹斑斑的深红长袍，莲花发黑，野蛮残忍的表情配上血红的眼睛，蓬乱黑发带血迹，手持滴血的双斧，站在尸横遍野的战场中，武侠反派，优雅构图，血红点缀，暗黑电影级光影，杰作，最佳质量，8k，超详细
```

**角色三视图描述：**
- **正面：** 魁梧残暴，血红长袍，持双斧，眼神血红
- **侧面：** 庞大身形，长袍破烂，斧头发血光
- **背面：** 后背莲花发黑，血迹斑斑，背影狰狞

**服装细节分解：**
- **头部：** 蓬乱黑发带血，面容狰狞，眼神血红
- **身体：** 血红长袍发黑，血迹斑斑，破烂不堪
- **手部：** 粗壮血腥，握双斧，满手血迹
- **脚部：** 血染战靴，铁钉鞋底
- **配饰：** 腰间人头挂饰，颈间血珠链

**配色方案：**
- 主色：#8B0000（暗红）
- 辅色：#000000（黑色）
- 点缀色：#DC143C（猩红）

**武器设计：** 血煞双斧 - 双刃染血，斧身刻恶鬼，杀气腾腾

**表情参考图描述：** 狰狞狂笑，眼神嗜血，面目扭曲

---

#### 1.3.4 那迦派

**门派主题色：** 主色 #5B3A8C（暗紫），辅色 #C9A96E（金），背景 #2D1B4E（深紫）

---

##### 那迦派-掌门：钟央

**角色名称：** 钟央

**身份：** 那迦派掌门、忍术宗师、沉默之影

**完整英文Prompt（200字+）：**
```
Chinese ink wash painting, mysterious ninja grandmaster with deadly silence, lean muscular build with panther-like agility, 7.5 heads tall with compact powerful frame, wearing black tight ninja outfit with dark gray cloak and intricate snake patterns embroidered in silver thread, holding pair of short ninja swords with poisoned edges, cold expressionless face with piercing snake-like eyes that seem to see through souls, black hair tied in ninja topknot with purple band, hidden in shadows with only eyes visible, wuxia grandmaster aura of lethal stealth, elegant composition, purple and silver accents, dramatic shadow lighting, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt（200字+）：**
```
中国水墨画风格，带着致命沉默的神秘忍者宗师，精瘦肌肉身材带着豹子般的敏捷，7.5头身紧凑有力体型，身穿黑色紧身忍者服配深灰色斗篷，有银线绣制的精美蛇纹图案，手持带毒刃的双短忍刀，冷酷无表情的面容配上似乎能看穿灵魂的锐利蛇眼，黑发束成忍者髻配紫带，隐藏在阴影中只有眼睛可见，武侠大宗师致命隐秘气场，优雅构图，紫银点缀，戏剧性阴影光影，杰作，最佳质量，8k，超详细
```

**角色三视图描述：**
- **正面：** 精瘦身材，黑忍服银蛇纹，双短刀，眼神如蛇，面无表情
- **侧面：** 敏捷轮廓，斗篷飘动，刀身反光，身形如豹
- **背面：** 后背大蛇图案，紫带飘扬，背影如鬼

**服装细节分解：**
- **头部：** 黑发忍者髻，紫带束发，面容冷峻，蛇眼锐利
- **身体：** 黑色紧身忍服，银蛇纹刺绣，深灰斗篷
- **手部：** 精瘦有力，握双短刀，戴黑手套
- **脚部：** 黑色忍者鞋，软底无声
- **配饰：** 腰间忍具包，颈间蛇牙项链，臂缠银蛇带

**配色方案：**
- 主色：#5B3A8C（暗紫）
- 辅色：#C9A96E（金色）
- 点缀色：#C0C0C0（银色）

**武器设计：** 影杀双忍刀 - 短刃淬毒，刀身刻蛇纹，出鞘无声

**表情参考图描述：** 面无表情，眼神如蛇，透着致命冷漠

---

##### 那迦派-弟子：影蛇

**角色名称：** 影蛇

**身份：** 那迦派核心弟子、钟央亲传

**完整英文Prompt：**
```
Chinese ink wash painting, stealthy young ninja disciple, lean wiry build, 7 heads tall, wearing black ninja outfit with small snake patterns, hidden expression with watchful eyes, black hair in simple ninja style, holding shuriken in ready position, hiding in shadows of ninja village, wuxia character, elegant composition, dark purple accents, cinematic lighting, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt：**
```
中国水墨画风格，隐秘的年轻忍者弟子，精瘦身材，7头身，身穿黑色忍者服，有小蛇纹图案，隐藏的表情配上警惕的眼神，黑发简单忍者发型，手持手里剑呈备战姿态，隐藏在忍者村庄的阴影中，武侠角色，优雅构图，深紫点缀，电影级光影，杰作，最佳质量，8k，超详细
```

**角色三视图描述：**
- **正面：** 年轻敏捷，黑忍服蛇纹，持手里剑，眼神警惕
- **侧面：** 标准身材，忍服贴身，手里剑闪光
- **背面：** 后背小蛇纹，黑发束起，身形灵活

**服装细节分解：**
- **头部：** 黑发束髻，面容年轻，眼神警惕
- **身体：** 黑色忍服，小蛇纹领口，束腰
- **手部：** 年轻有力，持手里剑，戴黑手套
- **脚部：** 黑忍者鞋，软底
- **配饰：** 腰间忍具包，胸前小蛇佩

**配色方案：**
- 主色：#1A1A2E（深黑）
- 辅色：#5B3A8C（暗紫）
- 点缀色：#C0C0C0（银色）

**武器设计：** 手里剑 - 六角星形，刃口淬毒，可远程可近战

**表情参考图描述：** 面无表情，眼神警惕，透着年轻杀手的冷静

---

##### 那迦派-叛徒：毒牙

**角色名称：** 毒牙

**身份：** 那迦派叛徒、毒术入魔

**完整英文Prompt：**
```
Chinese ink wash painting, poison-obsessed fallen ninja, gaunt sinister build, 7 heads tall, wearing tattered black robes with glowing green snake patterns, mad obsessive expression with glowing green eyes, wild black hair with snakes woven in, holding venom-dripping snake-headed staff, standing in poison swamp, wuxia villain, elegant composition, toxic green accents, eerie lighting, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt：**
```
中国水墨画风格，痴迷毒术的堕落忍者，枯瘦阴险身材，7头身，身穿破烂黑袍，有发光的绿色蛇纹图案，疯狂痴迷的表情配上发光的绿眼，蓬乱黑发中编织着蛇，手持滴着毒液的蛇头法杖，站在毒沼泽中，武侠反派，优雅构图，毒绿点缀，诡异光影，杰作，最佳质量，8k，超详细
```

**角色三视图描述：**
- **正面：** 枯瘦阴鸷，黑袍绿蛇纹，持蛇杖，眼神发绿光
- **侧面：** 佝偻身形，长袍破烂，杖头发绿光
- **背面：** 后背蛇纹发光，蛇发蠕动，背影诡异

**服装细节分解：**
- **头部：** 蛇发缠绕，面容枯槁，眼神发绿光
- **身体：** 破烂黑袍，绿蛇纹发光，腰带松散
- **手部：** 枯瘦如爪，握蛇杖，指甲绿黑
- **脚部：** 破布鞋，脚踝有蛇缠绕
- **配饰：** 腰间毒囊，颈间蛇骨链

**配色方案：**
- 主色：#0D0D0D（纯黑）
- 辅色：#00FF00（绿色）
- 点缀色：#32CD32（酸橙绿）

**武器设计：** 毒蛇法杖 - 蛇头杖顶，可喷毒液，杖身刻满毒咒

**表情参考图描述：** 疯狂狞笑，眼神发绿，透着对毒的痴迷

---

#### 1.3.5 太极门

**门派主题色：** 主色 #8A9AAA（银灰），辅色 #C9A96E（金），背景 #708090（灰）

---

##### 太极门-掌门：清虚道人

**角色名称：** 清虚道人

**身份：** 太极门掌门、太极功宗师、暗藏叛变之人

**完整英文Prompt（200字+）：**
```
Chinese ink wash painting, elegant Taoist immortal with hidden depths, slender tall figure with willow-like grace, 7.5 heads tall with flowing ethereal posture, wearing pristine white silk Taoist robes with subtle Yin-Yang patterns embroidered in silver thread, holding jade fly-whisk with Yin-Yang symbol on handle, wise but calculating eyes that hide secret ambitions, long white beard and hair flowing in mystical breeze, standing in mountain temple with mist swirling around, wuxia grandmaster aura of deceptive tranquility, elegant composition, silver and gold accents, soft ethereal lighting, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt（200字+）：**
```
中国水墨画风格，带着隐藏深度的优雅道士仙人，修长高大身材带着柳姿优雅，7.5头身飘逸姿态，身穿洁白的白色丝绸道袍，有银线绣制的微妙阴阳图案，手持柄上有阴阳符号的玉拂尘，智慧但精明的眼睛隐藏着秘密野心，长长的白须白发在神秘微风中飘动，站在山间道观中，周围雾气缭绕，武侠大宗师欺骗性宁静气场，优雅构图，金银点缀，柔和空灵光影，杰作，最佳质量，8k，超详细
```

**角色三视图描述：**
- **正面：** 修长身材，白袍银阴阳纹，持玉拂尘，眼神深不可测
- **侧面：** 飘逸轮廓，长袍随风，拂尘轻摆，身形如仙
- **背面：** 后背大阴阳图案，白发飘逸，背影仙风道骨

**服装细节分解：**
- **头部：** 白发束髻，插玉簪，白须三缕，面容清癯
- **身体：** 白色丝绸道袍，银阴阳刺绣，广袖飘逸
- **手部：** 修长如玉，握玉拂尘，指甲修剪整齐
- **脚部：** 白布鞋，白布袜
- **配饰：** 腰间玉佩，手腕银镯，肩披白纱

**配色方案：**
- 主色：#8A9AAA（银灰）
- 辅色：#C9A96E（金色）
- 点缀色：#C0C0C0（银色）

**武器设计：** 太极拂尘 - 玉柄银丝，柄刻阴阳，可柔可刚

**表情参考图描述：** 仙风道骨，眼神深不可测，嘴角似有若无的笑

---

##### 太极门-弟子：云清

**角色名称：** 云清

**身份：** 太极门核心弟子、清虚亲传

**完整英文Prompt：**
```
Chinese ink wash painting, calm young Taoist disciple, slender graceful build, 7 heads tall, wearing gray Taoist robes with small Yin-Yang patterns, peaceful serene expression with gentle eyes, black hair in simple Taoist topknot, practicing Tai Chi forms in mountain courtyard, wuxia character, elegant composition, gray and silver accents, soft cinematic lighting, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt：**
```
中国水墨画风格，冷静的年轻道教学徒，修长优雅身材，7头身，身穿灰色道袍，有小阴阳图案，平和宁静的表情配上温柔的眼神，黑发简单道士发髻，在山间庭院中练习太极招式，武侠角色，优雅构图，灰银点缀，柔和电影级光影，杰作，最佳质量，8k，超详细
```

**角色三视图描述：**
- **正面：** 年轻清瘦，灰袍阴阳纹，练太极，眼神平和
- **侧面：** 标准身材，长袍飘逸，动作舒缓
- **背面：** 后背小阴阳，长发束起，身形舒缓

**服装细节分解：**
- **头部：** 黑发束髻，面容清秀，眼神平和
- **身体：** 灰色道袍，小阴阳领口，宽松舒适
- **手部：** 年轻修长，练太极手，无饰品
- **脚部：** 灰布鞋，布袜
- **配饰：** 腰间布带，胸前小阴阳佩

**配色方案：**
- 主色：#808080（灰色）
- 辅色：#C0C0C0（银色）
- 点缀色：#8A9AAA（银灰）

**武器设计：** 无（以太极功法为主）

**表情参考图描述：** 平和宁静，眼神清澈，透着道家无为

---

##### 太极门-叛徒：阴极

**角色名称：** 阴极

**身份：** 太极门叛徒、堕入阴邪

**完整英文Prompt：**
```
Chinese ink wash painting, fallen Taoist master consumed by darkness, emaciated ghostly build, 7 heads tall, wearing tattered white robes turned gray with corrupted black Yin-Yang, malevolent expression with pure black eyes, wild white hair turned half black, holding corrupted dark fly-whisk oozing shadow energy, standing in ruined temple, wuxia villain, elegant composition, dark gray accents, ominous lighting, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt：**
```
中国水墨画风格，被黑暗吞噬的堕落道士高手，憔悴鬼魅身材，7头身，身穿破烂的白色长袍变成灰色，阴阳图案腐化成黑色，恶毒的表情配上纯黑的眼睛，蓬乱白发半黑，手持散发着暗影能量的腐化黑拂尘，站在破败道观中，武侠反派，优雅构图，深灰点缀，不祥光影，杰作，最佳质量，8k，超详细
```

**角色三视图描述：**
- **正面：** 枯瘦鬼魅，灰袍黑阴阳，持黑拂尘，眼神纯黑
- **侧面：** 佝偻身形，长袍破烂，拂尘发黑气
- **背面：** 后背阴阳腐化，半黑半白头发，背影阴森

**服装细节分解：**
- **头部：** 半黑半白头发，面容枯槁，眼神纯黑
- **身体：** 破烂灰袍，黑阴阳图案，腰带松散
- **手部：** 枯瘦如爪，握黑拂尘，指甲发黑
- **脚部：** 破布鞋，脚踝有锁链痕
- **配饰：** 腰间骷髅挂饰，颈间黑珠链

**配色方案：**
- 主色：#2F4F4F（深灰）
- 辅色：#000000（黑色）
- 点缀色：#696969（暗灰）

**武器设计：** 腐化黑拂尘 - 原太极拂尘堕落而成，拂丝发黑，散发阴气

**表情参考图描述：** 阴森冷笑，眼神纯黑，透着邪道气息

---

#### 1.3.6 雪山派

**门派主题色：** 主色 #5A8AAA（冰蓝），辅色 #C9A96E（金），背景 #B0C4DE（浅蓝灰）

---

##### 雪山派-掌门：白瑞德

**角色名称：** 白瑞德

**身份：** 雪山派掌门、雪上霜宗师、冰魄之主

**完整英文Prompt（200字+）：**
```
Chinese ink wash painting, cold ice immortal with frozen majesty, tall imposing figure with glacier-like presence, 7.5 heads tall with broad shoulders and regal posture, wearing pristine white silk robes with delicate snowflake patterns embroidered in silver and ice blue threads, holding ice crystal sword that glows with inner cold light, stern expressionless face with piercing ice-blue eyes and silver-white hair with blue tint, standing on snowy mountain peak with blizzard swirling around, wuxia grandmaster aura of absolute zero, elegant composition, ice blue and silver accents, cold ethereal lighting, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt（200字+）：**
```
中国水墨画风格，带着冰冻威严的冷漠冰仙，高大威严身材带着冰川般的气场，7.5头身宽肩威严姿态，身穿洁白的白色丝绸长袍，有银线和冰蓝色线绣制的精美雪花图案，手持散发着内在寒光的冰晶剑，严厉无表情的面容配上锐利的冰蓝色眼睛和带蓝色调的银白色头发，站在雪山之巅，周围暴风雪呼啸，武侠大宗师绝对零度气场，优雅构图，冰蓝银点缀，冰冷空灵光影，杰作，最佳质量，8k，超详细
```

**角色三视图描述：**
- **正面：** 高大威严，白袍银雪花纹，持冰晶剑，眼神冰蓝，银发飘逸
- **侧面：** 冰川轮廓，长袍随风，剑身发寒光，身形如冰
- **背面：** 后背大雪花图案，银发飘扬，背影如雪山

**服装细节分解：**
- **头部：** 银白发束髻，插冰晶簪，白须三缕，面容如冰
- **身体：** 白色丝绸长袍，银雪花刺绣，广袖飘逸
- **手部：** 苍白如玉，握冰晶剑，戴银护腕
- **脚部：** 白冰靴，冰纹鞋底
- **配饰：** 腰间冰玉佩，肩披雪貂披风，颈间雪花坠

**配色方案：**
- 主色：#5A8AAA（冰蓝）
- 辅色：#C9A96E（金色）
- 点缀色：#C0C0C0（银色）

**武器设计：** 冰魄寒光剑 - 万年冰晶所制，剑身透明，散发寒气

**表情参考图描述：** 面无表情，眼神冰蓝，透着拒人千里的冷漠

---

##### 雪山派-弟子：霜华

**角色名称：** 霜华

**身份：** 雪山派核心弟子、白瑞德亲传

**完整英文Prompt：**
```
Chinese ink wash painting, cold young ice warrior, athletic build with pale skin, 7 heads tall, wearing white and light blue martial arts robes with small snowflake patterns, stern focused expression with pale blue eyes, white hair with blue tint in simple warrior style, holding ice training sword, training on snowy mountain peak, wuxia character, elegant composition, ice blue accents, cold cinematic lighting, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt：**
```
中国水墨画风格，冷漠的年轻冰战士，运动型身材配苍白皮肤，7头身，身穿白色和浅蓝色武术长袍，有小雪花图案，严厉专注的表情配上淡蓝的眼睛，带蓝色调的白发简单武士发型，手持冰训练剑，在雪山之巅训练，武侠角色，优雅构图，冰蓝点缀，寒冷电影级光影，杰作，最佳质量，8k，超详细
```

**角色三视图描述：**
- **正面：** 年轻冷峻，白蓝袍雪花纹，持冰剑，眼神淡蓝
- **侧面：** 标准身材，长袍飘逸，剑身发寒光
- **背面：** 后背小雪花，白发束起，身形挺拔

**服装细节分解：**
- **头部：** 白发束髻，面容年轻冷峻，眼神淡蓝
- **身体：** 白蓝练功袍，小雪花领口，束腰
- **手部：** 年轻苍白，握冰剑，戴银护腕
- **脚部：** 白冰鞋，冰纹鞋底
- **配饰：** 腰间银带，胸前小雪花佩

**配色方案：**
- 主色：#B0C4DE（浅蓝灰）
- 辅色：#5A8AAA（冰蓝）
- 点缀色：#C0C0C0（银色）

**武器设计：** 冰训练剑 - 冰晶所制，无装饰，寒气逼人

**表情参考图描述：** 冷峻专注，眼神淡蓝，透着雪山弟子的孤傲

---

##### 雪山派-叛徒：寒毒

**角色名称：** 寒毒

**身份：** 雪山派叛徒、以寒入毒

**完整英文Prompt：**
```
Chinese ink wash painting, ice master corrupted by dark poison, gaunt deathly build, 7 heads tall, wearing tattered white robes turned sickly green with corrupted snowflakes, twisted cruel expression with glowing green eyes, wild white hair turned greenish, holding poisoned ice dagger dripping green venom, standing in frozen wasteland, wuxia villain, elegant composition, sickly green accents, eerie cold lighting, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt：**
```
中国水墨画风格，被黑暗毒素腐蚀的冰高手，憔悴死寂身材，7头身，身穿破烂的白色长袍变成病态绿色，雪花图案腐化，扭曲残忍的表情配上发光的绿眼，蓬乱白发变绿，手持滴着绿色毒液的淬毒冰匕首，站在冰冻荒原中，武侠反派，优雅构图，病态绿点缀，诡异寒冷光影，杰作，最佳质量，8k，超详细
```

**角色三视图描述：**
- **正面：** 枯瘦病态，绿袍腐雪花，持毒冰匕，眼神发绿光
- **侧面：** 佝偻身形，长袍破烂，匕首发绿光
- **背面：** 后背雪花腐化，绿发飘散，背影阴森

**服装细节分解：**
- **头部：** 绿发蓬乱，面容枯槁，眼神发绿光
- **身体：** 破烂绿袍，腐雪花图案，腰带松散
- **手部：** 枯瘦如爪，握毒冰匕，指甲绿黑
- **脚部：** 破冰鞋，脚踝有冻伤痕
- **配饰：** 腰间毒囊，颈间毒冰链

**配色方案：**
- 主色：#2F4F4F（深灰绿）
- 辅色：#00FF00（绿色）
- 点缀色：#006400（深绿）

**武器设计：** 毒冰匕首 - 冰晶淬毒，刃口发绿光，寒气带毒

**表情参考图描述：** 病态狞笑，眼神发绿，透着寒毒的阴冷

---

#### 1.3.7 逍遥派

**门派主题色：** 主色 #4A8A5A（翠绿），辅色 #C9A96E（金），背景 #90EE90（浅绿）

---

##### 逍遥派-掌门：逍遥子（见1.2核心NPC）

---

##### 逍遥派-弟子：清风

**角色名称：** 清风

**身份：** 逍遥派核心弟子、逍遥子亲传

**完整英文Prompt：**
```
Chinese ink wash painting, carefree young cultivator with natural harmony, slender graceful build, 7 heads tall, wearing light green flowing robes with nature patterns of bamboo and pine, relaxed content expression with bright clear eyes, black hair in simple loose style with green ribbon, holding simple wooden sword, standing in misty bamboo forest, wuxia character, ethereal aura, elegant composition, green and gold accents, soft natural lighting, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt：**
```
中国水墨画风格，与自然和谐的逍遥年轻修炼者，修长优雅身材，7头身，身穿淡绿色飘逸长袍，有竹子松树的自然图案，放松满足的表情配上明亮清澈的眼神，黑发简单松散发型配绿丝带，手持简易木剑，站在雾蒙蒙的竹林中，武侠角色，空灵气质，优雅构图，绿金点缀，柔和自然光影，杰作，最佳质量，8k，超详细
```

**角色三视图描述：**
- **正面：** 年轻俊逸，绿袍自然纹，持木剑，眼神清澈
- **侧面：** 标准身材，长袍飘逸，木剑朴实
- **背面：** 后背竹纹图案，绿带飘扬，身形逍遥

**服装细节分解：**
- **头部：** 黑发松散，面容俊逸，眼神清澈
- **身体：** 淡绿长袍，竹纹刺绣，宽松舒适
- **手部：** 年轻修长，握木剑，无饰品
- **脚部：** 绿布鞋，草编鞋底
- **配饰：** 腰间竹笛，胸前小玉佩

**配色方案：**
- 主色：#4A8A5A（翠绿）
- 辅色：#C9A96E（金色）
- 点缀色：#90EE90（浅绿）

**武器设计：** 松木剑 - 千年松木所制，朴实无华，剑身有松香

**表情参考图描述：** 轻松自在，眼神清澈，透着逍遥无为

---

##### 逍遥派-叛徒：邪风

**角色名称：** 邪风

**身份：** 逍遥派叛徒、走火入魔

**完整英文Prompt：**
```
Chinese ink wash painting, fallen carefree master consumed by chaos, wild disheveled build, 7 heads tall, wearing tattered green robes turned chaotic black-green, mad frenzied expression with wild bloodshot eyes, wild black hair standing on end, holding corrupted wooden sword oozing dark energy, standing in withered forest, wuxia villain, elegant composition, dark green accents, chaotic lighting, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt：**
```
中国水墨画风格，被混乱吞噬的堕落逍遥高手，狂野蓬乱身材，7头身，身穿破烂的绿色长袍变成混乱的黑绿色，疯狂狂躁的表情配上狂野充血的眼睛，蓬乱黑发竖立，手持散发着黑暗能量的腐化木剑，站在枯萎的森林中，武侠反派，优雅构图，深绿点缀，混乱光影，杰作，最佳质量，8k，超详细
```

**角色三视图描述：**
- **正面：** 枯瘦狂乱，黑绿袍，持腐木剑，眼神充血
- **侧面：** 佝偻身形，长袍破烂，剑发黑气
- **背面：** 后背竹纹腐化，乱发飘散，背影狂乱

**服装细节分解：**
- **头部：** 乱发竖立，面容枯槁，眼神充血
- **身体：** 破烂黑绿袍，腐竹纹图案，腰带松散
- **手部：** 枯瘦如爪，握腐木剑，指甲发黑
- **脚部：** 破布鞋，脚踝有伤痕
- **配饰：** 腰间断笛，颈间黑珠链

**配色方案：**
- 主色：#006400（深绿）
- 辅色：#000000（黑色）
- 点缀色：#228B22（森林绿）

**武器设计：** 腐化木剑 - 原松木剑堕落而成，剑身发黑，散发邪气

**表情参考图描述：** 疯狂狂笑，眼神充血，透着走火入魔的狂乱

---

### 1.4 通用NPC模板

#### 1.4.1 客栈老板

**年轻变体（25-30岁）：**

**英文Prompt：**
```
Chinese ink wash painting, young innkeeper, lean energetic build, 7 heads tall, wearing clean brown cotton robes with apron, friendly welcoming expression with bright eyes, black hair in neat bun, holding abacus and wine jug, standing in inn lobby, wuxia NPC, elegant composition, warm brown accents, soft lighting, masterpiece, best quality, 8k, ultra detailed
```

**中文Prompt：**
```
中国水墨画风格，年轻客栈老板，精干活力身材，7头身，身穿干净的棕色棉布长袍配围裙，友好热情的表情配上明亮的眼神，黑发整齐发髻，手持算盘和酒壶，站在客栈大堂中，武侠NPC，优雅构图，暖棕点缀，柔和光影，杰作，最佳质量，8k，超详细
```

**中年变体（40-50岁）：**

**英文Prompt：**
```
Chinese ink wash painting, middle-aged innkeeper, slightly chubby build, 7 heads tall, wearing worn brown robes with stained apron, shrewd calculating expression with narrowed eyes, black hair with gray streaks in simple bun, holding ledger and wine cup, standing behind inn counter, wuxia NPC, elegant composition, brown and gold accents, warm lighting, masterpiece, best quality, 8k, ultra detailed
```

**中文Prompt：**
```
中国水墨画风格，中年客栈老板，微胖身材，7头身，身穿破旧的棕色长袍配污渍围裙，精明算计的表情配上眯起的眼睛，黑发带灰丝简单发髻，手持账本和酒杯，站在客栈柜台后，武侠NPC，优雅构图，棕金点缀，暖色光影，杰作，最佳质量，8k，超详细
```

**老年变体（60+岁）：**

**英文Prompt：**
```
Chinese ink wash painting, elderly innkeeper, thin frail build, 6.5 heads tall, wearing faded brown robes with patched apron, wise kind expression with cloudy eyes, white hair and beard, holding wooden cane and tea pot, sitting in inn corner, wuxia NPC, elegant composition, sepia accents, soft lighting, masterpiece, best quality, 8k, ultra detailed
```

**中文Prompt：**
```
中国水墨画风格，老年客栈老板，瘦弱憔悴身材，6.5头身，身穿褪色的棕色长袍配补丁围裙，睿智慈祥的表情配上浑浊的眼睛，白发白须，手持木杖和茶壶，坐在客栈角落，武侠NPC，优雅构图，棕褐点缀，柔和光影，杰作，最佳质量，8k，超详细
```

---

#### 1.4.2 铁匠

**年轻变体（25-30岁）：**

**英文Prompt：**
```
Chinese ink wash painting, young blacksmith, muscular athletic build, 7 heads tall, wearing leather apron over bare chest, determined focused expression with sweat on brow, black hair tied back with leather strap, holding hammer over anvil, standing in forge with fire glowing, wuxia NPC, elegant composition, orange and brown accents, warm fiery lighting, masterpiece, best quality, 8k, ultra detailed
```

**中文Prompt：**
```
中国水墨画风格，年轻铁匠，肌肉运动型身材，7头身，身穿皮围裙配赤裸胸膛，坚定专注的表情配额头汗水，黑发用皮带束后，手持锤子架在铁砧上，站在火光闪耀的铁匠铺中，武侠NPC，优雅构图，橙棕点缀，温暖火光光影，杰作，最佳质量，8k，超详细
```

**中年变体（40-50岁）：**

**英文Prompt：**
```
Chinese ink wash painting, middle-aged blacksmith, burly powerful build, 7 heads tall, wearing heavy leather apron with burn marks, gruff experienced expression with scarred arms, black hair with gray in warrior knot, holding heavy hammer, standing in busy forge, wuxia NPC, elegant composition, dark brown and orange accents, dramatic lighting, masterpiece, best quality, 8k, ultra detailed
```

**中文Prompt：**
```
中国水墨画风格，中年铁匠，魁梧强壮身材，7头身，身穿带烧伤痕迹的重皮围裙，粗犷经验丰富的表情配手臂伤疤，黑发带灰武士发髻，手持重锤，站在繁忙的铁匠铺中，武侠NPC，优雅构图，深棕橙点缀，戏剧性光影，杰作，最佳质量，8k，超详细
```

**老年变体（60+岁）：**

**英文Prompt：**
```
Chinese ink wash painting, elderly blacksmith, wiry strong build, 6.5 heads tall, wearing worn leather apron with countless patches, wise patient expression with calloused hands, white hair and beard, holding small hammer inspecting blade, sitting in forge corner, wuxia NPC, elegant composition, brown and gray accents, soft lighting, masterpiece, best quality, 8k, ultra detailed
```

**中文Prompt：**
```
中国水墨画风格，老年铁匠，精瘦强壮身材，6.5头身，身穿带无数补丁的破旧皮围裙，睿智耐心的表情配老茧双手，白发白须，手持小锤检视刀刃，坐在铁匠铺角落，武侠NPC，优雅构图，棕灰点缀，柔和光影，杰作，最佳质量，8k，超详细
```

---

#### 1.4.3 药商

**年轻变体（25-30岁）：**

**英文Prompt：**
```
Chinese ink wash painting, young medicine merchant, slender neat build, 7 heads tall, wearing clean green robes with herb pouches, eager knowledgeable expression with bright curious eyes, black hair in neat scholar bun, holding herb bundle and scale, standing in medicine shop, wuxia NPC, elegant composition, green and brown accents, natural lighting, masterpiece, best quality, 8k, ultra detailed
```

**中文Prompt：**
```
中国水墨画风格，年轻药商，修长整洁身材，7头身，身穿干净的绿色长袍配药囊，热切博学的表情配明亮好奇的眼神，黑发整齐书生发髻，手持药草束和秤，站在药铺中，武侠NPC，优雅构图，绿棕点缀，自然光影，杰作，最佳质量，8k，超详细
```

**中年变体（40-50岁）：**

**英文Prompt：**
```
Chinese ink wash painting, middle-aged medicine merchant, average build, 7 heads tall, wearing faded green robes with many herb pouches, shrewd knowledgeable expression with calculating eyes, black hair with gray in simple style, holding mortar and pestle, standing behind medicine counter, wuxia NPC, elegant composition, green and gold accents, soft lighting, masterpiece, best quality, 8k, ultra detailed
```

**中文Prompt：**
```
中国水墨画风格，中年药商，普通身材，7头身，身穿褪色的绿色长袍配许多药囊，精明博学的表情配算计的眼神，黑发带灰简单发型，手持研钵和杵，站在药铺柜台后，武侠NPC，优雅构图，绿金点缀，柔和光影，杰作，最佳质量，8k，超详细
```

**老年变体（60+岁）：**

**英文Prompt：**
```
Chinese ink wash painting, elderly medicine merchant, thin wise build, 6.5 heads tall, wearing ancient green robes with countless herb bags, deeply knowledgeable expression with wise kind eyes, white long beard and hair, holding ancient medical text and herb, sitting in medicine shop, wuxia NPC, elegant composition, sage green accents, soft lighting, masterpiece, best quality, 8k, ultra detailed
```

**中文Prompt：**
```
中国水墨画风格，老年药商，瘦削睿智身材，6.5头身，身穿古老的绿色长袍配无数药袋，深博学睿智的表情配睿智慈祥的眼神，白色长须长发，手持古医书和药草，坐在药铺中，武侠NPC，优雅构图，鼠尾草绿点缀，柔和光影，杰作，最佳质量，8k，超详细
```

---

#### 1.4.4 书生

**年轻变体（18-25岁）：**

**英文Prompt：**
```
Chinese ink wash painting, young scholar, slender delicate build, 7 heads tall, wearing clean blue scholar robes with book satchel, earnest idealistic expression with bright intelligent eyes, black hair in neat topknot with simple cap, holding scroll and brush, standing in study, wuxia NPC, elegant composition, blue and white accents, soft lighting, masterpiece, best quality, 8k, ultra detailed
```

**中文Prompt：**
```
中国水墨画风格，年轻书生，修长纤细身材，7头身，身穿干净的蓝色书生长袍配书袋，认真理想的表情配明亮聪慧的眼神，黑发整齐发髻配简单帽子，手持卷轴和毛笔，站在书房中，武侠NPC，优雅构图，蓝白点缀，柔和光影，杰作，最佳质量，8k，超详细
```

**中年变体（35-45岁）：**

**英文Prompt：**
```
Chinese ink wash painting, middle-aged scholar, average build, 7 heads tall, wearing worn blue robes with ink stains, tired resigned expression with world-weary eyes, black hair with gray in scholar cap, holding wine cup and poetry scroll, sitting in tavern, wuxia NPC, elegant composition, blue and gray accents, dim lighting, masterpiece, best quality, 8k, ultra detailed
```

**中文Prompt：**
```
中国水墨画风格，中年书生，普通身材，7头身，身穿破旧的蓝色长袍配墨迹，疲惫认命的表情配世故疲惫的眼神，黑发带灰书生帽，手持酒杯和诗卷，坐在酒馆中，武侠NPC，优雅构图，蓝灰点缀，昏暗光影，杰作，最佳质量，8k，超详细
```

**老年变体（60+岁）：**

**英文Prompt：**
```
Chinese ink wash painting, elderly scholar, thin dignified build, 6.5 heads tall, wearing ancient blue robes with countless scrolls, wise serene expression with deeply knowledgeable eyes, white long beard and hair, holding ancient book and writing brush, sitting in library, wuxia NPC, elegant composition, navy blue accents, soft lighting, masterpiece, best quality, 8k, ultra detailed
```

**中文Prompt：**
```
中国水墨画风格，老年书生，瘦削威严身材，6.5头身，身穿古老的蓝色长袍配无数卷轴，睿智宁静的表情配深博学眼神，白色长须长发，手持古书和毛笔，坐在藏书阁中，武侠NPC，优雅构图，海军蓝点缀，柔和光影，杰作，最佳质量，8k，超详细
```

---

#### 1.4.5 乞丐

**年轻变体（20-30岁）：**

**英文Prompt：**
Chinese ink wash painting, young beggar, thin wiry build, 7 heads tall, wearing tattered patched rags, cunning resourceful expression with sharp alert eyes, messy black hair, holding broken bowl and wooden staff, sitting on street corner, wuxia NPC, elegant composition, gray and brown accents, harsh lighting, masterpiece, best quality, 8k, ultra detailed
```

**中文Prompt：**
```
中国水墨画风格，年轻乞丐，精瘦身材，7头身，身穿破烂补丁破布，狡猾机智的表情配锐利警觉的眼神，蓬乱黑发，手持破碗和木杖，坐在街角，武侠NPC，优雅构图，灰棕点缀，强烈光影，杰作，最佳质量，8k，超详细
```

**中年变体（40-50岁）：**

**英文Prompt：**
```
Chinese ink wash painting, middle-aged beggar, thin weathered build, 6.5 heads tall, wearing filthy rags with many patches, resigned hopeless expression with hollow eyes, unkempt hair with gray, holding chipped bowl and gnarled staff, sitting against wall, wuxia NPC, elegant composition, gray and brown accents, dim lighting, masterpiece, best quality, 8k, ultra detailed
```

**中文Prompt：**
```
中国水墨画风格，中年乞丐，精瘦风霜身材，6.5头身，身穿肮脏破布配许多补丁，认命绝望的表情配空洞眼神，蓬乱头发带灰，手持缺口碗和弯曲木杖，靠墙坐着，武侠NPC，优雅构图，灰棕点缀，昏暗光影，杰作，最佳质量，8k，超详细
```

**老年变体（60+岁）：**

**英文Prompt：**
```
Chinese ink wash painting, elderly beggar, frail emaciated build, 6 heads tall, wearing barely covered rags, peaceful accepting expression with cloudy wise eyes, white unkempt hair and beard, holding cracked bowl and walking stick, sitting in temple doorway, wuxia NPC, elegant composition, sepia accents, soft lighting, masterpiece, best quality, 8k, ultra detailed
```

**中文Prompt：**
```
中国水墨画风格，老年乞丐，虚弱憔悴身材，6头身，身穿勉强遮体的破布，平和认命的表情配浑浊睿智的眼神，白色蓬乱头发胡须，手持裂纹碗和拐杖，坐在寺庙门口，武侠NPC，优雅构图，棕褐点缀，柔和光影，杰作，最佳质量，8k，超详细
```

---

#### 1.4.6 官兵

**年轻变体（20-25岁）：**

**英文Prompt：**
```
Chinese ink wash painting, young soldier, athletic build, 7 heads tall, wearing clean red military uniform with armor plates, eager loyal expression with determined eyes, black hair in military topknot under helmet, holding spear and shield, standing at attention, wuxia NPC, elegant composition, red and silver accents, bright lighting, masterpiece, best quality, 8k, ultra detailed
```

**中文Prompt：**
```
中国水墨画风格，年轻官兵，运动型身材，7头身，身穿干净的红色军装配铠甲片，热切忠诚的表情配坚定的眼神，黑发军髻配头盔，手持长矛和盾牌，立正站立，武侠NPC，优雅构图，红银点缀，明亮光影，杰作，最佳质量，8k，超详细
```

**中年变体（35-45岁）：**

**英文Prompt：**
```
Chinese ink wash painting, middle-aged soldier, sturdy build, 7 heads tall, wearing worn red uniform with battle-scarred armor, stern experienced expression with watchful eyes, black hair with gray in military style, holding sword and official seal, standing guard, wuxia NPC, elegant composition, red and gold accents, dramatic lighting, masterpiece, best quality, 8k, ultra detailed
```

**中文Prompt：**
```
中国水墨画风格，中年官兵，结实身材，7头身，身穿破旧的红色军装配战痕累累的铠甲，严厉经验丰富的表情配警惕的眼神，黑发带灰军人发型，手持长剑和官印，站岗守卫，武侠NPC，优雅构图，红金点缀，戏剧性光影，杰作，最佳质量，8k，超详细
```

**老年变体（55+岁）：**

**英文Prompt：**
```
Chinese ink wash painting, elderly soldier, wiry tough build, 6.5 heads tall, wearing faded red uniform with ancient armor, wise stern expression with knowing eyes, white hair and beard under helmet, holding commander's sword, sitting at guard post, wuxia NPC, elegant composition, dark red accents, soft lighting, masterpiece, best quality, 8k, ultra detailed
```

**中文Prompt：**
```
中国水墨画风格，老年官兵，精瘦坚韧身材，6.5头身，身穿褪色的红色军装配古老铠甲，睿智严厉的表情配洞察的眼神，白发白须在头盔下，手持指挥剑，坐在哨岗，武侠NPC，优雅构图，深红点缀，柔和光影，杰作，最佳质量，8k，超详细
```

---

#### 1.4.7 渔夫

**年轻变体（25-30岁）：**

**英文Prompt：**
```
Chinese ink wash painting, young fisherman, lean tanned build, 7 heads tall, wearing simple blue work clothes with straw hat, cheerful optimistic expression with sun-tanned face, black hair under straw hat, holding fishing rod and basket, standing on riverbank, wuxia NPC, elegant composition, blue and brown accents, natural lighting, masterpiece, best quality, 8k, ultra detailed
```

**中文Prompt：**
```
中国水墨画风格，年轻渔夫，精瘦黝黑身材，7头身，身穿简单的蓝色工作服配草帽，开朗乐观的表情配晒黑的脸庞，草帽下黑发，手持钓竿和鱼篓，站在河岸边，武侠NPC，优雅构图，蓝棕点缀，自然光影，杰作，最佳质量，8k，超详细
```

**中年变体（40-50岁）：**

**英文Prompt：**
```
Chinese ink wash painting, middle-aged fisherman, sturdy weathered build, 7 heads tall, wearing worn blue clothes with patched straw hat, calm experienced expression with wise eyes, black hair with gray under hat, holding net and fishing rod, standing in boat, wuxia NPC, elegant composition, blue and gray accents, soft lighting, masterpiece, best quality, 8k, ultra detailed
```

**中文Prompt：**
```
中国水墨画风格，中年渔夫，结实风霜身材，7头身，身穿破旧的蓝色衣服配补丁草帽，平静经验丰富的表情配睿智眼神，帽子下黑发带灰，手持渔网和钓竿，站在船上，武侠NPC，优雅构图，蓝灰点缀，柔和光影，杰作，最佳质量，8k，超详细
```

**老年变体（60+岁）：**

**英文Prompt：**
```
Chinese ink wash painting, elderly fisherman, thin wiry build, 6.5 heads tall, wearing ancient blue clothes with tattered straw hat, peaceful content expression with deeply wrinkled face, white hair and beard, holding simple fishing line, sitting on riverbank, wuxia NPC, elegant composition, blue and silver accents, golden hour lighting, masterpiece, best quality, 8k, ultra detailed
```

**中文Prompt：**
```
中国水墨画风格，老年渔夫，精瘦身材，6.5头身，身穿古老的蓝色衣服配破烂草帽，平和满足的表情配深深皱纹的脸庞，白发白须，手持简单钓线，坐在河岸边，武侠NPC，优雅构图，蓝银点缀，黄金时刻光影，杰作，最佳质量，8k，超详细
```

---

#### 1.4.8 农夫

**年轻变体（20-30岁）：**

**英文Prompt：**
```
Chinese ink wash painting, young farmer, strong tanned build, 7 heads tall, wearing simple brown work clothes with straw hat, energetic hardworking expression with bright eyes, black hair under straw hat, holding hoe and basket, standing in rice field, wuxia NPC, elegant composition, brown and green accents, bright sunlight, masterpiece, best quality, 8k, ultra detailed
```

**中文Prompt：**
```
中国水墨画风格，年轻农夫，强壮黝黑身材，7头身，身穿简单的棕色工作服配草帽，精力充沛勤劳的表情配明亮眼神，草帽下黑发，手持锄头和篮子，站在稻田中，武侠NPC，优雅构图，棕绿点缀，明亮阳光，杰作，最佳质量，8k，超详细
```

**中年变体（40-50岁）：**

**英文Prompt：**
```
Chinese ink wash painting, middle-aged farmer, sturdy weathered build, 7 heads tall, wearing worn brown clothes with wide straw hat, tired but content expression with calloused hands, black hair with gray under hat, holding plow and guiding ox, working in field, wuxia NPC, elegant composition, earth tone accents, warm lighting, masterpiece, best quality, 8k, ultra detailed
```

**中文Prompt：**
```
中国水墨画风格，中年农夫，结实风霜身材，7头身，身穿破旧的棕色衣服配宽边草帽，疲惫但满足的表情配老茧双手，帽子下黑发带灰，手持犁引导牛，在田间劳作，武侠NPC，优雅构图，大地色调点缀，温暖光影，杰作，最佳质量，8k，超详细
```

**老年变体（60+岁）：**

**英文Prompt：**
```
Chinese ink wash painting, elderly farmer, thin bent build, 6.5 heads tall, wearing faded brown clothes with ancient straw hat, peaceful wise expression with deeply lined face, white hair and beard, holding walking stick, sitting under tree watching fields, wuxia NPC, elegant composition, brown and gold accents, soft lighting, masterpiece, best quality, 8k, ultra detailed
```

**中文Prompt：**
```
中国水墨画风格，老年农夫，瘦削佝偻身材，6.5头身，身穿褪色的棕色衣服配古老草帽，平和睿智的表情配深深皱纹的脸庞，白发白须，手持拐杖，坐在树下看田地，武侠NPC，优雅构图，棕金点缀，柔和光影，杰作，最佳质量，8k，超详细
```

---

#### 1.4.9 商贩

**年轻变体（25-30岁）：**

**英文Prompt：**
```
Chinese ink wash painting, young merchant, average build, 7 heads tall, wearing colorful trade clothes with many pouches, enthusiastic cunning expression with quick eyes, black hair in merchant style, holding abacus and sample goods, standing by market stall, wuxia NPC, elegant composition, multicolor accents, bright lighting, masterpiece, best quality, 8k, ultra detailed
```

**中文Prompt：**
```
中国水墨画风格，年轻商贩，普通身材，7头身，身穿 colorful 贸易服装配许多袋子，热情狡猾的表情配灵活眼神，黑发商人发型，手持算盘和样品货物，站在市场摊位旁，武侠NPC，优雅构图，多彩点缀，明亮光影，杰作，最佳质量，8k，超详细
```

**中年变体（40-50岁）：**

**英文Prompt：**
```
Chinese ink wash painting, middle-aged merchant, slightly chubby build, 7 heads tall, wearing rich merchant robes with gold trim, shrewd calculating expression with assessing eyes, black hair with gray in merchant cap, holding ledger and money bag, sitting in shop, wuxia NPC, elegant composition, gold and red accents, warm lighting, masterpiece, best quality, 8k, ultra detailed
```

**中文Prompt：**
```
中国水墨画风格，中年商贩，微胖身材，7头身，身穿 rich 商人长袍配金边，精明算计的表情配评估的眼神，黑发带灰商人帽，手持账本和钱袋，坐在店铺中，武侠NPC，优雅构图，金红点缀，温暖光影，杰作，最佳质量，8k，超详细
```

**老年变体（60+岁）：**

**英文Prompt：**
```
Chinese ink wash painting, elderly merchant, thin dignified build, 6.5 heads tall, wearing ancient rich robes with countless jade accessories, wise knowing expression with experienced eyes, white hair and beard, holding antique item and scale, sitting in prestigious shop, wuxia NPC, elegant composition, jade green and gold accents, soft lighting, masterpiece, best quality, 8k, ultra detailed
```

**中文Prompt：**
```
中国水墨画风格，老年商贩，瘦削威严身材，6.5头身，身穿古老 rich 长袍配无数玉饰，睿智洞察的表情配经验丰富的眼神，白发白须，手持古董和秤，坐在名店中，武侠NPC，优雅构图，玉绿金点缀，柔和光影，杰作，最佳质量，8k，超详细
```

---

#### 1.4.10 戏子

**年轻变体（18-25岁）：**

**英文Prompt：**
```
Chinese ink wash painting, young opera performer, slender graceful build, 7 heads tall, wearing colorful opera costume with elaborate makeup, dramatic expressive expression with painted face, black hair in elaborate opera style, holding fan and prop sword, posing on stage, wuxia NPC, elegant composition, vibrant color accents, dramatic lighting, masterpiece, best quality, 8k, ultra detailed
```

**中文Prompt：**
```
中国水墨画风格，年轻戏子，修长优雅身材，7头身，身穿 colorful 戏服配精致妆容，戏剧化表现力的表情配脸谱，黑发精美戏曲发型，手持扇子和道具剑，在舞台上摆姿势，武侠NPC，优雅构图，鲜艳色彩点缀，戏剧性光影，杰作，最佳质量，8k，超详细
```

**中年变体（35-45岁）：**

**英文Prompt：**
```
Chinese ink wash painting, middle-aged opera performer, average build, 7 heads tall, wearing worn opera costume with faded makeup, tired nostalgic expression with traces of former glory, black hair with gray in opera style, holding old fan, sitting backstage, wuxia NPC, elegant composition, muted color accents, dim lighting, masterpiece, best quality, 8k, ultra detailed
```

**中文Prompt：**
```
中国水墨画风格，中年戏子，普通身材，7头身，身穿破旧的戏服配褪色妆容，疲惫怀旧的表情配昔日荣耀痕迹，黑发带灰戏曲发型，手持旧扇子，坐在后台，武侠NPC，优雅构图，柔和色彩点缀，昏暗光影，杰作，最佳质量，8k，超详细
```

**老年变体（60+岁）：**

**英文Prompt：**
```
Chinese ink wash painting, elderly opera master, thin dignified build, 6.5 heads tall, wearing ancient opera costume with minimal makeup, wise serene expression with deeply knowledgeable eyes, white hair in traditional opera style, holding antique fan and teaching stick, teaching young performers, wuxia NPC, elegant composition, gold and red accents, soft lighting, masterpiece, best quality, 8k, ultra detailed
```

**中文Prompt：**
```
中国水墨画风格，老年戏班主，瘦削威严身材，6.5头身，身穿古老戏服配淡妆，睿智宁静的表情配深博学眼神，白发传统戏曲发型，手持古扇和教鞭，教导年轻演员，武侠NPC，优雅构图，金红点缀，柔和光影，杰作，最佳质量，8k，超详细
```

---

### 1.5 敌人角色

#### 1.5.1 山贼

**普通等级：**

**英文Prompt：**
```
Chinese ink wash painting, common bandit, scruffy average build, 7 heads tall, wearing mismatched leather and cloth armor, greedy cruel expression with shifty eyes, unkempt black hair, holding crude sword and club, lurking on mountain path, wuxia enemy, elegant composition, brown and gray accents, harsh lighting, masterpiece, best quality, 8k, ultra detailed
```

**中文Prompt：**
```
中国水墨画风格，普通山贼，邋遢普通身材，7头身，身穿不搭配的皮革和布甲，贪婪残忍的表情配狡猾眼神，蓬乱黑发，手持粗糙的剑和棍棒，潜伏在山路上，武侠敌人，优雅构图，棕灰点缀，强烈光影，杰作，最佳质量，8k，超详细
```

**精英等级：**

**英文Prompt：**
```
Chinese ink wash painting, elite bandit leader, muscular intimidating build, 7 heads tall, wearing reinforced leather armor with metal plates, fierce cunning expression with scarred face, wild black hair with braids, holding quality sword and shield, commanding on cliff, wuxia elite enemy, elegant composition, dark brown and silver accents, dramatic lighting, masterpiece, best quality, 8k, ultra detailed
```

**中文Prompt：**
```
中国水墨画风格，精英山贼头目，肌肉威慑身材，7头身，身穿加强皮革甲配金属片，凶猛狡猾的表情配伤疤脸庞，狂野黑发带辫子，手持优质剑和盾，在悬崖上指挥，武侠精英敌人，优雅构图，深棕银点缀，戏剧性光影，杰作，最佳质量，8k，超详细
```

**首领等级：**

**英文Prompt：**
```
Chinese ink wash painting, bandit king, massive powerful build, 7.5 heads tall, wearing ornate battle armor with fur cape, tyrannical ruthless expression with piercing eyes, long black hair with gold ornaments, holding massive battle axe, sitting on stolen throne in mountain fortress, wuxia boss enemy, elegant composition, gold and crimson accents, dramatic cinematic lighting, masterpiece, best quality, 8k, ultra detailed
```

**中文Prompt：**
```
中国水墨画风格，山贼王，庞大强壮身材，7.5头身，身穿华丽战甲配毛皮披风，暴君般无情的表情配锐利眼神，长发配金饰，手持巨型战斧，坐在山寨中被盗的宝座上，武侠首领敌人，优雅构图，金深红点缀，戏剧性电影级光影，杰作，最佳质量，8k，超详细
```

---

#### 1.5.2 流寇

**普通等级：**

**英文Prompt：**
```
Chinese ink wash painting, common rogue, thin wiry build, 7 heads tall, wearing tattered military castoffs, desperate ruthless expression with hollow hungry eyes, unkempt hair, holding spear and knife, scavenging in ruins, wuxia enemy, elegant composition, gray and brown accents, dim lighting, masterpiece, best quality, 8k, ultra detailed
```

**中文Prompt：**
```
中国水墨画风格，普通流寇，精瘦身材，7头身，身穿破烂的军用旧衣，绝望无情的表情配空洞饥饿的眼神，蓬乱头发，手持长矛和匕首，在废墟中 scavenging，武侠敌人，优雅构图，灰棕点缀，昏暗光影，杰作，最佳质量，8k，超详细
```

**精英等级：**

**英文Prompt：**
```
Chinese ink wash painting, elite rogue captain, athletic dangerous build, 7 heads tall, wearing scavenged armor pieces, cold calculating expression with predatory eyes, wild hair with trophies, holding curved blade and crossbow, leading raid on village, wuxia elite enemy, elegant composition, dark gray and red accents, dramatic lighting, masterpiece, best quality, 8k, ultra detailed
```

**中文Prompt：**
```
中国水墨画风格，精英流寇队长，运动型危险身材，7头身，身穿 scavenged 甲片，冷酷算计的表情配掠夺性眼神，狂野头发配战利品，手持弯刀和弩，带领袭击村庄，武侠精英敌人，优雅构图，深灰红点缀，戏剧性光影，杰作，最佳质量，8k，超详细
```

**首领等级：**

**英文Prompt：**
```
Chinese ink wash painting, rogue warlord, imposing battle-hardened build, 7.5 heads tall, wearing patchwork armor of defeated foes, merciless ambitious expression with cold intelligent eyes, wild hair with crown of bones, holding unique stolen sword, commanding army of outlaws, wuxia boss enemy, elegant composition, iron gray and blood red accents, ominous lighting, masterpiece, best quality, 8k, ultra detailed
```

**中文Prompt：**
```
中国水墨画风格，流寇军阀，威严身经百战身材，7.5头身，身穿击败敌人拼凑的甲胄，无情野心的表情配冷酷智慧眼神，狂野头发配骨冠，手持独特的被盗宝剑，指挥 outlaw 军队，武侠首领敌人，优雅构图，铁灰血红点缀，不祥光影，杰作，最佳质量，8k，超详细
```

---

#### 1.5.3 邪教徒

**普通等级：**

**英文Prompt：**
```
Chinese ink wash painting, common cultist, thin fanatical build, 7 heads tall, wearing dark ritual robes with crude symbols, fanatic glazed expression with unfocused eyes, shaved head with brand marks, holding ritual dagger and censer, chanting in dark cave, wuxia enemy, elegant composition, dark purple and black accents, eerie lighting, masterpiece, best quality, 8k, ultra detailed
```

**中文Prompt：**
```
中国水墨画风格，普通邪教徒，精瘦狂热身材，7头身，身穿黑暗仪式长袍配粗糙符号，狂热茫然的表情配涣散眼神，剃光头带烙印，手持仪式匕首和香炉，在黑暗洞穴中吟唱，武侠敌人，优雅构图，深紫黑点缀，诡异光影，杰作，最佳质量，8k，超详细
```

**精英等级：**

**英文Prompt：**
```
Chinese ink wash painting, elite cult enforcer, muscular imposing build, 7 heads tall, wearing ornate dark robes with glowing symbols, fanatical intense expression with glowing eyes, bald head with elaborate tattoos, holding cursed weapon and dark orb, guarding ritual chamber, wuxia elite enemy, elegant composition, purple and green accents, supernatural lighting, masterpiece, best quality, 8k, ultra detailed
```

**中文Prompt：**
```
中国水墨画风格，精英邪教执法者，肌肉威严身材，7头身，身穿华丽黑暗长袍配发光符号，狂热强烈的表情配发光眼睛，光头配精美纹身，手持诅咒武器和黑球，守卫仪式室，武侠精英敌人，优雅构图，紫绿点缀，超自然光影，杰作，最佳质量，8k，超详细
```

**首领等级：**

**英文Prompt：**
```
Chinese ink wash painting, cult high priest, gaunt otherworldly build, 7 heads tall, wearing magnificent dark ceremonial robes with living shadows, transcendent mad expression with void-like eyes, bald with crown of dark energy, holding unholy staff and ancient tome, presiding over dark ritual, wuxia boss enemy, elegant composition, black and purple accents, otherworldly lighting, masterpiece, best quality, 8k, ultra detailed
```

**中文Prompt：**
```
中国水墨画风格，邪教大祭司，憔悴超凡身材，7头身，身穿华丽黑暗仪式长袍配活影，超凡疯狂的表情配虚空般眼神，光头配黑暗能量冠，手持邪恶法杖和古书，主持黑暗仪式，武侠首领敌人，优雅构图，黑紫点缀，超凡光影，杰作，最佳质量，8k，超详细
```

---

#### 1.5.4 野兽

**普通等级：**

**英文Prompt：**
Chinese ink wash painting, wild wolf, lean predatory build, 4 heads tall at shoulder, gray fur with darker markings, feral hungry expression with yellow eyes, shaggy fur, bared fangs, prowling in forest, wuxia beast enemy, elegant composition, gray and brown accents, natural lighting, masterpiece, best quality, 8k, ultra detailed
```

**中文Prompt：**
```
中国水墨画风格，野狼，精瘦掠食身材，肩高4头身，灰毛配深色斑纹，野性饥饿的表情配黄眼，蓬乱皮毛，露出尖牙，在森林中潜行，武侠野兽敌人，优雅构图，灰棕点缀，自然光影，杰作，最佳质量，8k，超详细
```

**精英等级：**

**英文Prompt：**
```
Chinese ink wash painting, alpha wolf, massive powerful build, 5 heads tall at shoulder, silver-white fur with battle scars, dominant intelligent expression with piercing blue eyes, thick luxurious fur, massive fangs, leading pack on cliff, wuxia elite beast enemy, elegant composition, silver and white accents, moonlight lighting, masterpiece, best quality, 8k, ultra detailed
```

**中文Prompt：**
```
中国水墨画风格，头狼，庞大强壮身材，肩高5头身，银白皮毛配战疤，支配性智慧的表情配锐利蓝眼，厚实华丽皮毛，巨大尖牙，带领狼群在悬崖上，武侠精英野兽敌人，优雅构图，银白点缀，月光光影，杰作，最佳质量，8k，超详细
```

**首领等级：**

**英文Prompt：**
```
Chinese ink wash painting, mythical wolf king, gigantic divine build, 6 heads tall at shoulder, pure white fur with golden markings and ethereal glow, wise ancient expression with glowing golden eyes, magnificent flowing fur, legendary fangs, standing on sacred mountain peak, wuxia boss beast enemy, elegant composition, gold and white accents, divine lighting, masterpiece, best quality, 8k, ultra detailed
```

**中文Prompt：**
```
中国水墨画风格，神话狼王，巨大神圣身材，肩高6头身，纯白皮毛配金色斑纹和空灵光芒，睿智古老的表情配发光金眼，华丽飘逸皮毛，传奇尖牙，站在神圣山峰之巅，武侠首领野兽敌人，优雅构图，金白点缀，神圣光影，杰作，最佳质量，8k，超详细
```

---

#### 1.5.5 精怪

**普通等级：**

**英文Prompt：**
```
Chinese ink wash painting, minor forest spirit, small ethereal build, 3 heads tall, translucent green form with leaf patterns, mischievous curious expression with glowing green eyes, flowing hair like vines, holding small nature magic, flitting between trees, wuxia spirit enemy, elegant composition, green and gold accents, magical lighting, masterpiece, best quality, 8k, ultra detailed
```

**中文Prompt：**
```
中国水墨画风格，低级森林精怪，小空灵身材，3头身，半透明绿色形态配叶子图案，调皮好奇的表情配发光绿眼，如藤蔓的飘逸头发，施展小自然魔法，在树间飞舞，武侠精怪敌人，优雅构图，绿金点缀，魔法光影，杰作，最佳质量，8k，超详细
```

**精英等级：**

**英文Prompt：**
```
Chinese ink wash painting, powerful nature spirit, tall graceful ethereal build, 6 heads tall, semi-corporeal form with bark skin and leaf hair, ancient wise expression with luminescent eyes, flowing form with natural armor, wielding nature magic staff, guarding sacred grove, wuxia elite spirit enemy, elegant composition, forest green and silver accents, ethereal lighting, masterpiece, best quality, 8k, ultra detailed
```

**中文Prompt：**
```
中国水墨画风格，强大自然精怪，高优雅空灵身材，6头身，半实体形态配树皮皮肤和叶子头发，古老睿智的表情配发光眼睛，飘逸形态配自然护甲，挥舞自然魔法法杖，守卫神圣林地，武侠精英精怪敌人，优雅构图，森林绿银点缀，空灵光影，杰作，最佳质量，8k，超详细
```

**首领等级：**

**英文Prompt：**
```
Chinese ink wash painting, ancient spirit lord, majestic divine ethereal build, 8 heads tall, magnificent form of living nature with tree bark skin and flowing water hair, transcendent powerful expression with eyes like forest pools, majestic form with natural crown and armor, wielding primal nature power, ruling over spirit realm, wuxia boss spirit enemy, elegant composition, emerald and gold accents, divine ethereal lighting, masterpiece, best quality, 8k, ultra detailed
```

**中文Prompt：**
```
中国水墨画风格，古老精怪领主，威严神圣空灵身材，8头身，活自然的华丽形态配树皮皮肤和流水头发，超凡强大的表情配如森林池水的眼睛，威严形态配自然冠和护甲，挥舞原始自然力量，统治精怪领域，武侠首领精怪敌人，优雅构图，翡翠金点缀，神圣空灵光影，杰作，最佳质量，8k，超详细
```

---

#### 1.5.6 朝廷鹰犬

**普通等级：**

**英文Prompt：**
```
Chinese ink wash painting, government enforcer, average disciplined build, 7 heads tall, wearing standard government armor with insignia, cold obedient expression with blank eyes, neat black hair under helmet, holding standard sword and shackles, patrolling streets, wuxia enemy, elegant composition, black and red accents, harsh lighting, masterpiece, best quality, 8k, ultra detailed
```

**中文Prompt：**
```
中国水墨画风格，朝廷鹰犬，普通纪律身材，7头身，身穿标准官甲配徽章，冷酷服从的表情配空洞眼神，头盔下整齐黑发，手持标准剑和镣铐，在街道巡逻，武侠敌人，优雅构图，黑红点缀，强烈光影，杰作，最佳质量，8k，超详细
```

**精英等级：**

**英文Prompt：**
```
Chinese ink wash painting, government captain, athletic commanding build, 7 heads tall, wearing ornate government armor with rank insignia, ruthless efficient expression with calculating eyes, black hair in military style, holding quality sword and official seal, leading squad, wuxia elite enemy, elegant composition, crimson and gold accents, dramatic lighting, masterpiece, best quality, 8k, ultra detailed
```

**中文Prompt：**
```
中国水墨画风格，朝廷队长，运动型指挥身材，7头身，身穿华丽官甲配军衔徽章，无情高效的表达式配算计眼神，黑发军人发型，手持优质剑和官印，带领小队，武侠精英敌人，优雅构图，深红金点缀，戏剧性光影，杰作，最佳质量，8k，超详细
```

**首领等级：**

**英文Prompt：**
```
Chinese ink wash painting, government grand enforcer, imposing terrifying build, 7.5 heads tall, wearing magnificent dark gold armor with imperial dragon, cold absolute authority expression with pitiless eyes, long black hair with imperial ornaments, holding legendary executioner blade and imperial decree, commanding secret police force, wuxia boss enemy, elegant composition, imperial gold and black accents, ominous dramatic lighting, masterpiece, best quality, 8k, ultra detailed
```

**中文Prompt：**
```
中国水墨画风格，朝廷大鹰犬，威严恐怖身材，7.5头身，身穿华丽暗金甲配帝国龙纹，冷酷绝对权威的表情配无情眼神，长发配帝国饰品，手持传奇处决刃和圣旨，指挥秘密警察部队，武侠首领敌人，优雅构图，帝国金黑点缀，不祥戏剧性光影，杰作，最佳质量，8k，超详细
```

---

## 二、场景美术Prompt

### 2.1 五大城池

#### 2.1.1 长安（首都·帝都）

**场景1：城门**

**场景氛围描述：**
- **时间：** 清晨，朝阳初升
- **天气：** 晴朗，微风
- **人流：** 熙熙攘攘，商旅络绎不绝
- **声音：** 叫卖声、马蹄声、城门守卫的呵斥声

**完整英文Prompt：**
```
Chinese ink wash painting, magnificent ancient Chinese capital city gate at dawn, grand vermilion gates with golden roof tiles, massive stone walls with guard towers, bustling crowds of merchants and travelers passing through, morning sunlight casting long shadows, traditional Chinese architecture, wuxia world, elegant composition, gold and vermilion accents, warm morning lighting, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt：**
```
中国水墨画风格，清晨宏伟的中国古代都城城门，朱红色大门配金色琉璃瓦，巨大石墙配瞭望塔，熙熙攘攘的商旅人群穿梭，晨阳投下长长阴影，传统中国建筑，武侠世界，优雅构图，金朱红点缀，温暖晨光，杰作，最佳质量，8k，超详细
```

**关键元素列表：**
- 朱红色城门（必须）
- 金色琉璃瓦（必须）
- 石狮子（必须）
- 守卫士兵（必须）
- 商旅人群（必须）
- 城墙垛口（可选）
- 城门匾额（可选）

**构图建议：**
- **Camera角度：** 低角度仰视，突出城门宏伟
- **焦点：** 城门中央，人群引导视线
- **景深：** 前景人群虚化，城门清晰，远景城墙延伸

---

**场景2：主街**

**场景氛围描述：**
- **时间：** 正午，烈日当空
- **天气：** 晴朗，风沙
- **人流：** 商旅驼队，络绎不绝
- **声音：** 驼铃声、风沙声、叫卖声

**完整英文Prompt：**
```
Chinese ink wash painting, Silk Road main street in desert oasis city at noon, bustling avenue with foreign merchants, exotic goods from many lands, colorful awnings providing shade, camels and horses tied along street, mixed Chinese and Central Asian architecture, wuxia world, elegant composition, gold and multicolor accents, harsh desert lighting, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt：**
```
中国水墨画风格，正午沙漠绿洲城市丝路主街，繁华大道配外国商人，来自多地的 exotic 货物， colorful 遮阳篷提供阴凉，骆驼和马匹拴在街道两旁，中国和中亚混合建筑，武侠世界，优雅构图，金多彩点缀，强烈沙漠光影，杰作，最佳质量，8k，超详细
```

**关键元素列表：**
- 丝路街道（必须）
- 外国商人（必须）
- 异域货物（必须）
- 骆驼马匹（必须）
- 遮阳篷（可选）
- 风沙（可选）

**构图建议：**
- **Camera角度：** 平视，街道延伸感
- **焦点：** 街道中段，异域风情
- **景深：** 前景商铺，中景人群，远景沙漠

---

**场景3：市集**

**场景氛围描述：**
- **时间：** 上午，热闹喧嚣
- **天气：** 晴朗，风沙
- **人流：** 人声鼎沸，讨价还价
- **声音：** 叫卖声、讨价还价声、驼铃声

**完整英文Prompt：**
```
Chinese ink wash painting, Silk Road market in desert oasis city, crowded stalls with exotic goods from many lands, foreign merchants haggling, colorful textiles and spices, camels resting nearby, mixed cultural atmosphere, traditional Silk Road market, wuxia world, elegant composition, multicolor accents, bright morning lighting, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt：**
```
中国水墨画风格，沙漠绿洲城市丝路市集，拥挤摊位配来自多地的 exotic 货物，外国商人讨价还价， colorful 纺织品和香料，骆驼在旁休息，混合文化氛围，传统丝路市集，武侠世界，优雅构图，多彩点缀，明亮晨光，杰作，最佳质量，8k，超详细
```

**关键元素列表：**
- 丝路摊位（必须）
- 异域货物（必须）
- 外国商人（必须）
- 骆驼（必须）
- 纺织品（可选）
- 香料（可选）

**构图建议：**
- **Camera角度：** 俯视角度，展现市集全貌
- **焦点：** 市集中心，异域交易
- **景深：** 整体清晰，展现热闹氛围

---

**场景4：官府**

**场景氛围描述：**
- **时间：** 午后，庄严肃穆
- **天气：** 晴朗，风沙
- **人流：** 军事人员
- **声音：** 命令声、脚步声、风沙声

**完整英文Prompt：**
```
Chinese ink wash painting, military government office in desert oasis city, fortified building with watchtowers, soldiers standing guard, military officials in desert-adapted robes, maps of Silk Road on walls, traditional Chinese frontier government architecture, wuxia world, elegant composition, brown and red accents, harsh afternoon lighting, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt：**
```
中国水墨画风格，沙漠绿洲城市军事官府， fortified 建筑配瞭望塔，士兵站岗，穿沙漠适应长袍的军官，墙上丝路地图，传统中国边疆官府建筑，武侠世界，优雅构图，棕红点缀，强烈午后光影，杰作，最佳质量，8k，超详细
```

**关键元素列表：**
- 军事官府（必须）
- 瞭望塔（必须）
- 士兵站岗（必须）
- 丝路地图（必须）
- 军事装备（可选）
- 命令文书（可选）

**构图建议：**
- **Camera角度：** 正面平视，展现军事威严
- **焦点：** 官府大门，瞭望塔
- **景深：** 前景士兵，中景官府，远景沙漠

---

**场景5：特色地点-莫高窟**

**场景氛围描述：**
- **时间：** 黄昏，夕阳西下
- **天气：** 晴朗，风沙
- **人流：** 稀少，僧侣、游客
- **声音：** 风声、远处诵经声、风沙声

**完整英文Prompt：**
```
Chinese ink wash painting, Mogao Caves at sunset in desert oasis, ancient Buddhist cave temples carved into cliff face, colorful murals visible in cave entrances, monks and pilgrims walking along cliff path, golden light illuminating cliff face, sacred atmosphere, traditional Chinese Buddhist architecture, wuxia world, elegant composition, gold and saffron accents, golden hour lighting, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt：**
```
中国水墨画风格，黄昏沙漠绿洲莫高窟，古老佛教石窟寺 carved into 悬崖面， colorful 壁画在洞口可见，僧侣和朝圣者沿悬崖小径行走，金色光芒照亮悬崖面，神圣气氛，传统中国佛教建筑，武侠世界，优雅构图，金藏红点缀，黄金时刻光影，杰作，最佳质量，8k，超详细
```

**关键元素列表：**
- 莫高窟（必须）
- 壁画（必须）
- 僧侣（必须）
- 悬崖（必须）
- 石窟（可选）
- 朝圣者（可选）

**构图建议：**
- **Camera角度：** 平视，展现莫高窟全貌
- **焦点：** 莫高窟，壁画
- **景深：** 前景僧侣，中景莫高窟，远景夕阳

---

#### 2.1.5 幽州（北境之城）

**场景1：城门**

**场景氛围描述：**
- **时间：** 清晨，寒风凛冽
- **天气：** 风雪交加
- **人流：** 稀少，边防士兵
- **声音：** 风声、马蹄声、士兵呵斥声

**完整英文Prompt：**
```
Chinese ink wash painting, northern fortress city gate in snowstorm at dawn, massive thick stone walls with ice formations, heavily armored guards standing watch, snow and wind blowing fiercely, distant snow mountains visible, Great Wall extending into distance, traditional Chinese northern frontier architecture, wuxia world, elegant composition, white and gray accents, cold harsh lighting, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt：**
```
中国水墨画风格，清晨暴风雪中北方要塞城市城门，巨大厚实石墙配冰 formations，重甲守卫站岗，风雪猛烈吹拂，远处雪山可见，长城延伸向远方，传统中国北方边疆建筑，武侠世界，优雅构图，白灰点缀，寒冷强烈光影，杰作，最佳质量，8k，超详细
```

**关键元素列表：**
- 要塞城门（必须）
- 石墙冰 formations（必须）
- 重甲守卫（必须）
- 风雪（必须）
- 长城（可选）
- 雪山（可选）

**构图建议：**
- **Camera角度：** 平视，展现北境风光
- **焦点：** 城门，守卫
- **景深：** 前景风雪，中景城门，远景长城

---

**场景2：主街**

**场景氛围描述：**
- **时间：** 正午，寒风凛冽
- **天气：** 风雪交加
- **人流：** 稀少，边防士兵
- **声音：** 风声、脚步声、铁器碰撞声

**完整英文Prompt：**
```
Chinese ink wash painting, northern fortress city main street in snowstorm at noon, stone-paved avenue lined with military buildings, soldiers in heavy winter armor marching, snow piled along walls, smoke rising from chimneys, harsh northern atmosphere, traditional Chinese northern frontier architecture, wuxia world, elegant composition, white and blue accents, cold harsh lighting, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt：**
```
中国水墨画风格，正午暴风雪中北方要塞城市主街，石板大道配军事建筑，穿厚重冬甲的士兵 march，雪堆在墙边，烟囱升起烟雾，严酷北方气氛，传统中国北方边疆建筑，武侠世界，优雅构图，白蓝点缀，寒冷强烈光影，杰作，最佳质量，8k，超详细
```

**关键元素列表：**
- 石板街道（必须）
- 军事建筑（必须）
- 冬甲士兵（必须）
- 风雪（必须）
- 烟囱烟雾（可选）
- 雪堆（可选）

**构图建议：**
- **Camera角度：** 平视，街道延伸感
- **焦点：** 街道中段，士兵
- **景深：** 前景风雪，中景街道，远景建筑

---

**场景3：市集**

**场景氛围描述：**
- **时间：** 上午，寒风凛冽
- **天气：** 风雪交加
- **人流：** 稀少，军需交易
- **声音：** 风声、低声交易、铁器碰撞声

**完整英文Prompt：**
```
Chinese ink wash painting, military supply market in northern fortress city, sparse stalls selling winter gear and weapons, soldiers trading necessities, snow-covered awnings, smoke from warming fires, practical northern atmosphere, traditional Chinese northern frontier market, wuxia world, elegant composition, gray and brown accents, cold harsh lighting, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt：**
```
中国水墨画风格，北方要塞城市军需市集，稀疏摊位售卖冬装和武器，士兵交易必需品，雪覆盖的遮阳篷，取暖火的烟雾，实用北方气氛，传统中国北方边疆市集，武侠世界，优雅构图，灰棕点缀，寒冷强烈光影，杰作，最佳质量，8k，超详细
```

**关键元素列表：**
- 军需摊位（必须）
- 冬装武器（必须）
- 士兵交易（必须）
- 风雪（必须）
- 取暖火（可选）
- 雪堆（可选）

**构图建议：**
- **Camera角度：** 俯视角度，展现市集全貌
- **焦点：** 市集中心，军需交易
- **景深：** 整体偏冷，突出北境氛围

---

**场景4：官府**

**场景氛围描述：**
- **时间：** 午后，寒风凛冽
- **天气：** 风雪交加
- **人流：** 军事人员
- **声音：** 命令声、风声、铁器碰撞声

**完整英文Prompt：**
```
Chinese ink wash painting, military command center in northern fortress city, fortified building with ice-covered roof, officers planning defense strategies, maps of Great Wall and northern territories, braziers providing warmth, stern northern atmosphere, traditional Chinese northern frontier government architecture, wuxia world, elegant composition, gray and red accents, cold harsh lighting, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt：**
```
中国水墨画风格，北方要塞城市军事指挥中心， fortified 建筑配冰覆盖屋顶，军官策划防御战略，长城和北方领土地图，火盆提供温暖，严厉北方气氛，传统中国北方边疆官府建筑，武侠世界，优雅构图，灰红点缀，寒冷强烈光影，杰作，最佳质量，8k，超详细
```

**关键元素列表：**
- 军事官府（必须）
- 冰覆盖屋顶（必须）
- 军官（必须）
- 长城地图（必须）
- 火盆（可选）
- 军事装备（可选）

**构图建议：**
- **Camera角度：** 正面平视，展现军事威严
- **焦点：** 官府大门，军官
- **景深：** 前景风雪，中景官府，远景长城

---

**场景5：特色地点-长城**

**场景氛围描述：**
- **时间：** 黄昏，夕阳西下
- **天气：** 风雪交加
- **人流：** 稀少，边防士兵
- **声音：** 风声、远处号角声、铁器碰撞声

**完整英文Prompt：**
```
Chinese ink wash painting, Great Wall at sunset in northern frontier, massive stone wall snaking across snow-covered mountains, watchtowers with signal fires, soldiers patrolling along wall, dramatic winter sky, epic northern frontier atmosphere, traditional Chinese Great Wall architecture, wuxia world, elegant composition, white and gold accents, dramatic sunset lighting, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt：**
```
中国水墨画风格，黄昏北方边疆长城，巨大石墙蜿蜒穿越雪山，瞭望塔配烽火，士兵沿墙巡逻，戏剧性冬季天空，史诗北方边疆气氛，传统中国长城建筑，武侠世界，优雅构图，白金点缀，戏剧性夕阳光影，杰作，最佳质量，8k，超详细
```

**关键元素列表：**
- 长城（必须）
- 瞭望塔（必须）
- 烽火（必须）
- 巡逻士兵（必须）
- 雪山（可选）
- 夕阳（可选）

**构图建议：**
- **Camera角度：** 高角度俯视，展现长城雄伟
- **焦点：** 长城，瞭望塔
- **景深：** 前景城墙，中景山脉，远景夕阳

---

### 2.2 十六小镇

#### 2.2.1 平安镇

**场景1：入口**

**完整英文Prompt：**
```
Chinese ink wash painting, peaceful village entrance at dawn, simple wooden archway with village name, surrounding farmland with morning mist, farmers beginning their day, warm peaceful atmosphere, traditional Chinese village architecture, wuxia starting village, elegant composition, green and gold accents, soft morning lighting, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt：**
```
中国水墨画风格，清晨宁静村庄入口，简单木拱门配村名，周围农田配晨雾，农民开始一天，温暖宁静气氛，传统中国村庄建筑，武侠新手村，优雅构图，绿金点缀，柔和晨光，杰作，最佳质量，8k，超详细
```

**场景2：中心**

**完整英文Prompt：**
```
Chinese ink wash painting, peaceful village center at noon, village square with ancient banyan tree, simple shops and tavern, villagers chatting and trading, children playing, warm community atmosphere, traditional Chinese village architecture, wuxia starting village, elegant composition, green and brown accents, bright midday lighting, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt：**
```
中国水墨画风格，正午宁静村庄中心，村庄广场配古老榕树，简单店铺和酒馆，村民聊天交易，孩童玩耍，温暖社区气氛，传统中国村庄建筑，武侠新手村，优雅构图，绿棕点缀，明亮正午光影，杰作，最佳质量，8k，超详细
```

**场景3：特色地点-私塾**

**完整英文Prompt：**
```
Chinese ink wash painting, village schoolhouse in peaceful town, simple building with calligraphy scrolls, children practicing writing, elderly teacher guiding students, sound of reading filling air, traditional Chinese village education, wuxia starting village, elegant composition, brown and gold accents, warm afternoon lighting, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt：**
```
中国水墨画风格，宁静小镇私塾，简单建筑配书法卷轴，孩童练习写字，老教师指导学生，读书声充满空气，传统中国乡村教育，武侠新手村，优雅构图，棕金点缀，温暖午后光影，杰作，最佳质量，8k，超详细
```

---

#### 2.2.2 灞桥镇

**场景1：入口**

**完整英文Prompt：**
```
Chinese ink wash painting, famous Ba Bridge village entrance, ancient stone bridge with willow trees, river flowing beneath, travelers arriving and departing, sentimental farewell atmosphere, traditional Chinese riverside town, wuxia world, elegant composition, green and gray accents, soft morning lighting, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt：**
```
中国水墨画风格，著名灞桥村庄入口，古老石桥配柳树，河水流淌桥下，旅人到来和离别，感伤告别气氛，传统中国河边小镇，武侠世界，优雅构图，绿灰点缀，柔和晨光，杰作，最佳质量，8k，超详细
```

**场景2：中心**

**完整英文Prompt：**
```
Chinese ink wash painting, Ba Bridge town center at noon, riverside avenue with taverns and inns, travelers saying goodbye, willow catkins flying in air, boats docked along river, sentimental but lively atmosphere, traditional Chinese riverside town, wuxia world, elegant composition, green and blue accents, bright midday lighting, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt：**
```
中国水墨画风格，正午灞桥镇中心，河边大道配酒馆和客栈，旅人告别，柳絮飞扬空中，船只 docked 沿河，感伤但 lively 气氛，传统中国河边小镇，武侠世界，优雅构图，绿蓝点缀，明亮正午光影，杰作，最佳质量，8k，超详细
```

**场景3：特色地点-灞桥**

**完整英文Prompt：**
```
Chinese ink wash painting, famous Ba Bridge at sunset, ancient stone arch bridge with weeping willows, travelers saying emotional farewells, willow branches swaying in wind, river reflecting golden light, poetic farewell atmosphere, traditional Chinese landmark, wuxia world, elegant composition, gold and green accents, golden hour lighting, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt：**
```
中国水墨画风格，黄昏著名灞桥，古老石拱桥配垂柳，旅人 emotional 告别，柳枝在风中摇摆，河水 reflecting 金色光芒，诗意告别气氛，传统中国地标，武侠世界，优雅构图，金绿点缀，黄金时刻光影，杰作，最佳质量，8k，超详细
```

---

#### 2.2.3 终南山镇

**场景1：入口**

**完整英文Prompt：**
```
Chinese ink wash painting, sacred mountain village entrance, stone path leading into misty mountains, ancient stone gate with Taoist symbols, pilgrims and seekers entering, mystical atmosphere, traditional Chinese mountain village, wuxia world, elegant composition, gray and green accents, misty morning lighting, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt：**
```
中国水墨画风格，圣山村庄入口，石径 leading into 雾山，古老石门配道教符号，朝圣者和 seeker 进入，神秘气氛，传统中国山村，武侠世界，优雅构图，灰绿点缀，雾蒙蒙晨光，杰作，最佳质量，8k，超详细
```

**场景2：中心**

**完整英文Prompt：**
```
Chinese ink wash painting, sacred mountain village center, simple buildings with Taoist decorations, shops selling meditation supplies and herbs, Taoist practitioners walking about, serene spiritual atmosphere, traditional Chinese mountain village, wuxia world, elegant composition, green and gray accents, soft natural lighting, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt：**
```
中国水墨画风格，圣山村庄中心，简单建筑配道教装饰，店铺售卖冥想用品和草药，道教修行者 walk about，宁静 spiritual 气氛，传统中国山村，武侠世界，优雅构图，绿灰点缀，柔和自然光影，杰作，最佳质量，8k，超详细
```

**场景3：特色地点-道观**

**完整英文Prompt：**
```
Chinese ink wash painting, ancient Taoist temple in sacred mountain village, traditional architecture with curved roofs and incense burners, Taoist priests practicing rituals, smoke from incense rising, bells chiming in mountain air, sacred spiritual atmosphere, traditional Chinese Taoist architecture, wuxia world, elegant composition, gray and saffron accents, ethereal lighting, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt：**
```
中国水墨画风格，圣山村庄古老道观，传统建筑配弯曲屋顶和香炉，道士练习仪式， incense 烟雾升起，钟声在山间 air 中回响，神圣 spiritual 气氛，传统中国道教建筑，武侠世界，优雅构图，灰藏红点缀，空灵光影，杰作，最佳质量，8k，超详细
```

---

#### 2.2.4 黄河渡口镇

**场景1：入口**

**完整英文Prompt：**
```
Chinese ink wash painting, Yellow River crossing village entrance, steep path leading down to mighty river, ferry boats visible in distance, travelers with heavy loads descending, grand river atmosphere, traditional Chinese riverside village, wuxia world, elegant composition, yellow and brown accents, bright morning lighting, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt：**
```
中国水墨画风格，黄河渡口村庄入口，陡峭小径 leading down to 壮观河流，渡船在远处可见，负重旅人 descending，宏伟河流气氛，传统中国河边村庄，武侠世界，优雅构图，黄棕点缀，明亮晨光，杰作，最佳质量，8k，超详细
```

**场景2：中心**

**完整英文Prompt：**
```
Chinese ink wash painting, Yellow River crossing town center, bustling ferry terminal with boats loading and unloading, merchants trading goods, travelers waiting for passage, powerful river flowing nearby, energetic commercial atmosphere, traditional Chinese river port, wuxia world, elegant composition, yellow and blue accents, bright midday lighting, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt：**
```
中国水墨画风格，黄河渡口城镇中心，繁忙渡船码头配船只装卸，商人交易货物，旅人等待 passage， powerful 河流在附近流淌， energetic 商业气氛，传统中国河港，武侠世界，优雅构图，黄蓝点缀，明亮正午光影，杰作，最佳质量，8k，超详细
```

**场景3：特色地点-黄河渡口**

**完整英文Prompt：**
```
Chinese ink wash painting, mighty Yellow River crossing at sunset, turbulent muddy waters with powerful current, large ferry boats battling the current, watchtowers on both banks, dramatic golden light on churning waters, grand epic atmosphere, traditional Chinese river crossing, wuxia world, elegant composition, gold and brown accents, dramatic sunset lighting, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt：**
```
中国水墨画风格，黄昏壮观黄河渡口，汹涌浑浊河水配 powerful 水流，大型渡船 battling the current，两岸瞭望塔，戏剧性金色光芒在 churning 水面，宏伟史诗气氛，传统中国渡口，武侠世界，优雅构图，金棕点缀，戏剧性夕阳光影，杰作，最佳质量，8k，超详细
```

---

[注：由于篇幅限制，以下小镇简要列出，每个包含3个场景的中英文Prompt]

#### 2.2.5 桃花镇
**场景1-入口：** 桃花盛开的村庄入口，粉色花海
**场景2-中心：** 桃花环绕的村庄广场，浪漫气氛
**场景3-特色-桃园：** 万亩桃园，花瓣飞舞

#### 2.2.6 铁匠铺镇
**场景1-入口：** 铁匠铺林立的村庄入口，炉火闪烁
**场景2-中心：** 铁匠铺聚集的广场，铁器叮当
**场景3-特色-铁匠街：** 百家铁匠铺，火星四溅

#### 2.2.7 药王镇
**场景1-入口：** 药香四溢的村庄入口，草药晾晒
**场景2-中心：** 药铺林立的广场，医者往来
**场景3-特色-药王庙：** 供奉药王的神庙，香火鼎盛

#### 2.2.8 渔港镇
**场景1-入口：** 渔港村庄入口，渔网晾晒
**场景2-中心：** 渔港码头广场，鱼市喧嚣
**场景3-特色-渔港：** 千帆渔港，海鸥飞翔

#### 2.2.9 茶山镇
**场景1-入口：** 茶园环绕的村庄入口，茶香四溢
**场景2-中心：** 茶铺林立的广场，品茶论道
**场景3-特色-茶园：** 万亩茶园，采茶姑娘

#### 2.2.10 丝绸镇
**场景1-入口：** 丝绸飘扬的村庄入口，色彩斑斓
**场景2-中心：** 丝绸店铺广场，织机声声
**场景3-特色-织坊：** 百家织坊，彩丝飞舞

#### 2.2.11 瓷器镇
**场景1-入口：** 瓷器堆叠的村庄入口，白瓷闪耀
**场景2-中心：** 瓷器店铺广场，琳琅满目
**场景3-特色-瓷窑：** 龙窑耸立，火光冲天

#### 2.2.12 书院镇
**场景1-入口：** 书香门第的村庄入口，学子往来
**场景2-中心：** 书院林立的广场，读书声声
**场景3-特色-大书院：** 千年书院，藏书万卷

#### 2.2.13 武馆镇
**场景1-入口：** 武馆林立的村庄入口，习武声声
**场景2-中心：** 比武广场，拳脚相加
**场景3-特色-演武场：** 百家武馆，刀光剑影

#### 2.2.14 矿坑镇
**场景1-入口：** 矿坑入口的村庄，矿工往来
**场景2-中心：** 矿石交易广场，铁器叮当
**场景3-特色-矿坑：** 深不见底的矿坑，灯火闪烁

#### 2.2.15 边贸镇
**场景1-入口：** 边贸村庄入口，异域商人
**场景2-中心：** 边贸广场，各国货物
**场景3-特色-边贸市场：** 万国来朝，货物如山

#### 2.2.16 隐世镇
**场景1-入口：** 隐秘山谷入口，云雾缭绕
**场景2-中心：** 隐士聚集的广场，高人往来
**场景3-特色-隐居谷：** 百家隐士，修仙问道

---

### 2.3 四十五野外区域

#### 2.3.1 山脉地形（3种变体）

**变体1：险峻奇峰**

**英文Prompt：**
```
Chinese ink wash painting, treacherous mountain peaks, jagged rocky spires piercing clouds, narrow cliffside paths, mountain goats on ledges, dangerous climbing atmosphere, traditional Chinese mountain landscape, wuxia wilderness, elegant composition, gray and white accents, dramatic lighting, masterpiece, best quality, 8k, ultra detailed
```

**中文Prompt：**
```
中国水墨画风格，险峻奇峰，锯齿状岩石尖塔刺破云层，狭窄悬崖小径，岩架上的山羊，危险攀登气氛，传统中国山 landscape，武侠荒野，优雅构图，灰白点缀，戏剧性光影，杰作，最佳质量，8k，超详细
```

**变体2：连绵群山**

**英文Prompt：**
```
Chinese ink wash painting, rolling mountain range, layered peaks fading into misty distance, pine forests on slopes, mountain streams flowing down, serene majestic atmosphere, traditional Chinese mountain landscape, wuxia wilderness, elegant composition, blue and green accents, soft atmospheric lighting, masterpiece, best quality, 8k, ultra detailed
```

**中文Prompt：**
```
中国水墨画风格，连绵群山，层叠山峰 fade into 雾蒙蒙远方，山坡上松树林，山溪流淌而下，宁静庄严气氛，传统中国山 landscape，武侠荒野，优雅构图，蓝绿点缀，柔和 atmospheric 光影，杰作，最佳质量，8k，超详细
```

**变体3：雪山冰川**

**英文Prompt：**
```
Chinese ink wash painting, snow-capped mountain glaciers, pristine white peaks against blue sky, ice formations and snow fields, freezing wind and blowing snow, awe-inspiring cold atmosphere, traditional Chinese snow mountain landscape, wuxia wilderness, elegant composition, white and blue accents, cold dramatic lighting, masterpiece, best quality, 8k, ultra detailed
```

**中文Prompt：**
```
中国水墨画风格，雪山冰川， pristine 白色山峰 against 蓝天，冰 formations 和雪原， freezing 风和吹雪， awe-inspiring 寒冷气氛，传统中国雪山 landscape，武侠荒野，优雅构图，白蓝点缀，寒冷戏剧性光影，杰作，最佳质量，8k，超详细
```

---

#### 2.3.2 森林地形（3种变体）

**变体1：古木参天**

**英文Prompt：**
```
Chinese ink wash painting, ancient towering forest, massive thousand-year-old trees with twisted roots, dense canopy blocking sunlight, mysterious shadows and filtered light, primeval atmosphere, traditional Chinese forest landscape, wuxia wilderness, elegant composition, green and brown accents, dappled lighting, masterpiece, best quality, 8k, ultra detailed
```

**中文Prompt：**
```
中国水墨画风格，古木参天森林， massive 千年古树配扭曲树根， dense 树冠阻挡阳光，神秘阴影和过滤光线，原始气氛，传统中国森林 landscape，武侠荒野，优雅构图，绿棕点缀，斑驳光影，杰作，最佳质量，8k，超详细
```

**变体2：竹林幽径**

**英文Prompt：**
```
Chinese ink wash painting, bamboo forest path, tall slender bamboo stalks forming green corridor, narrow winding path through grove, bamboo leaves rustling in wind, peaceful serene atmosphere, traditional Chinese bamboo forest, wuxia wilderness, elegant composition, green and gold accents, soft filtered lighting, masterpiece, best quality, 8k, ultra detailed
```

**中文Prompt：**
```
中国水墨画风格，竹林幽径， tall 修长竹竿形成绿色 corridor，狭窄蜿蜒小径穿过林子，竹叶在风中 rustling，宁静 serene 气氛，传统中国竹林，武侠荒野，优雅构图，绿金点缀，柔和过滤光影，杰作，最佳质量，8k，超详细
```

**变体3：红叶枫林**

**英文Prompt：**
```
Chinese ink wash painting, autumn maple forest, brilliant red and gold maple leaves covering trees and ground, fallen leaves creating colorful carpet, crisp autumn air and gentle breeze, romantic melancholic atmosphere, traditional Chinese autumn forest, wuxia wilderness, elegant composition, red and gold accents, warm autumn lighting, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt：**
```
中国水墨画风格，红叶枫林， brilliant 红金枫叶覆盖树木和地面，落叶形成 colorful 地毯，清新 autumn air 和 gentle 微风，浪漫 melancholic 气氛，传统中国秋林，武侠荒野，优雅构图，红金点缀，温暖秋色光影，杰作，最佳质量，8k，超详细
```

---

[注：由于篇幅限制，以下地形简要列出，每类3种变体]

#### 2.3.3 河流地形
- **变体1：湍急大河** - 黄河般的汹涌河水
- **变体2：宁静小溪** - 清澈见底的山间溪流
- **变体3：瀑布深潭** - 飞流直下的瀑布和深潭

#### 2.3.4 平原地形
- **变体1：金色麦田** - 丰收的麦田，麦浪滚滚
- **变体2：青青草原** - 一望无际的草原，牛羊成群
- **变体3：芦苇荡** - 芦苇丛生的湿地，水鸟飞翔

#### 2.3.5 洞穴地形
- **变体1：钟乳石洞** - 奇形怪状的钟乳石和石笋
- **变体2：地下暗河** - 地下河流和溶洞
- **变体3：火山熔洞** - 火山熔岩形成的洞穴

#### 2.3.6 废墟地形
- **变体1：古城废墟** - 破败的古城墙和建筑
- **变体2：战场遗迹** - 古战场的残骸和武器
- **变体3：寺庙废墟** - 废弃的寺庙和佛像

---

### 2.4 七大门派场景

#### 2.4.1 八卦门场景

**门派主题色：** 主色 #4A3B6B（紫黑），辅色 #C9A96E（金）

**场景1：山门**

**建筑风格详细描述：**
宏伟的八卦门山门由黑色巨石建造，门楣上刻有巨大的金色八卦图案，两侧石柱盘绕着金龙雕塑，山门后方是通往山顶的漫长石阶，石阶两侧有八卦阵法图案，整体风格庄严肃穆，透着正道的威严。

**完整英文Prompt：**
```
Chinese ink wash painting, Bagua Sect mountain gate, massive black stone archway with golden bagua symbol, dragon sculptures coiling on stone pillars, long stone staircase leading to mountain peak, bagua array patterns on steps, majestic righteous atmosphere, traditional Chinese martial arts sect architecture, wuxia world, elegant composition, purple-black and gold accents, dramatic lighting, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt：**
```
中国水墨画风格，八卦门山门，巨大黑色石门配金色八卦符号，龙雕塑盘绕石柱，漫长石阶 leading to 山顶，石阶上八卦阵法图案，庄严正道气氛，传统中国武术门派建筑，武侠世界，优雅构图，紫黑金点缀，戏剧性光影，杰作，最佳质量，8k，超详细
```

**门派特色元素：** 八卦图案、金龙雕塑、石阶阵法

---

**场景2：大殿**

**建筑风格详细描述：**
八卦门大殿是门派的核心建筑，巨大的紫黑色木构建筑，屋顶覆盖金色琉璃瓦，殿内供奉着八卦祖师像，四周墙壁绘有八卦演变图，地面铺着刻有八卦图案的青石，正中央是掌门宝座，整体气势恢宏。

**完整英文Prompt：**
```
Chinese ink wash painting, Bagua Sect main hall, massive purple-black wooden structure with golden glazed roof tiles, ancestor statue of bagua founder, bagua evolution diagrams on walls, green stone floor with bagua patterns, grandmaster throne in center, majestic imposing atmosphere, traditional Chinese martial arts hall architecture, wuxia world, elegant composition, purple-black and gold accents, solemn lighting, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt：**
```
中国水墨画风格，八卦门大殿，巨大紫黑木结构配金色琉璃屋顶，八卦祖师像，墙上八卦演变图，青石地面配八卦图案，中央掌门宝座，宏伟威严气氛，传统中国武馆建筑，武侠世界，优雅构图，紫黑金点缀，庄严光影，杰作，最佳质量，8k，超详细
```

**门派特色元素：** 祖师像、八卦演变图、青石地面、掌门宝座

---

**场景3：练武场**

**建筑风格详细描述：**
八卦门练武场是弟子们日常修炼的场所，开阔的石板广场，地面刻有巨大的八卦阵图，四周有武器架和木人桩，场边有休息的凉亭，远处是悬崖和云海，整体氛围严肃而充满活力。

**完整英文Prompt：**
```
Chinese ink wash painting, Bagua Sect training ground, vast stone plaza with giant bagua array carved on ground, weapon racks and wooden dummies around perimeter, rest pavilions at edges, cliff and sea of clouds in distance, serious yet vibrant atmosphere, traditional Chinese martial arts training architecture, wuxia world, elegant composition, gray and gold accents, bright natural lighting, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt：**
```
中国水墨画风格，八卦门练武场， vast 石板广场配巨大八卦阵 carved on 地面，四周武器架和木人桩，边缘休息凉亭，远处悬崖和云海，严肃 yet 充满活力气氛，传统中国武术训练建筑，武侠世界，优雅构图，灰金点缀，明亮自然光影，杰作，最佳质量，8k，超详细
```

**门派特色元素：** 八卦阵图、武器架、木人桩、云海景观

---

**场景4：禁地**

**建筑风格详细描述：**
八卦门禁地是门派最神秘的区域，隐藏在深山中的洞穴，洞口有强大的八卦封印，洞内是历代掌门的闭关之所，墙壁上刻满了高深的武学秘籍，空气中弥漫着神秘的气息，普通人不得入内。

**完整英文Prompt：**
```
Chinese ink wash painting, Bagua Sect forbidden area, hidden cave deep in mountain, powerful bagua seal at entrance, meditation chambers of past grandmasters inside, walls covered with profound martial arts secrets, mysterious mystical atmosphere, traditional Chinese secret cultivation site, wuxia world, elegant composition, dark purple and gold accents, mysterious dim lighting, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt：**
```
中国水墨画风格，八卦门禁地，深山 hidden 洞穴，洞口强大八卦封印，洞内历代掌门闭关之所，墙壁刻满高深武学秘籍，神秘 mystical 气氛，传统中国 secret 修炼场所，武侠世界，优雅构图，深紫金点缀，神秘昏暗光影，杰作，最佳质量，8k，超详细
```

**门派特色元素：** 八卦封印、闭关洞府、武学秘籍、神秘气息

---

**场景5：居所**

**建筑风格详细描述：**
八卦门弟子居所分布在山腰各处，统一的紫黑色建筑风格，每座院落都有小型的八卦花园，院内种植着梅花和竹子，房间简洁实用，有修炼用的蒲团和书架，整体氛围宁静而充满正气。

**完整英文Prompt：**
```
Chinese ink wash painting, Bagua Sect residential quarters, uniform purple-black buildings on mountainside, small bagua gardens in each courtyard, plum blossoms and bamboo planted, simple practical rooms with meditation cushions and bookshelves, peaceful righteous atmosphere, traditional Chinese martial arts living quarters, wuxia world, elegant composition, purple-black and green accents, soft natural lighting, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt：**
```
中国水墨画风格，八卦门居所，统一紫黑建筑分布山腰，每座院落小型八卦花园，种植梅花和竹子，简洁实用房间配修炼蒲团和书架，宁静正气气氛，传统中国武术居住区，武侠世界，优雅构图，紫黑绿点缀，柔和自然光影，杰作，最佳质量，8k，超详细
```

**门派特色元素：** 八卦花园、梅花竹子、修炼蒲团、正气氛围

---

[注：由于篇幅限制，以下六大门派场景简要列出，每派5个场景]

#### 2.4.2 花间派场景
**场景1-山门：** 花海中的粉色山门，花间小径
**场景2-大殿：** 花仙殿，百花环绕，香气四溢
**场景3-练武场：** 花间舞场，花瓣飞舞中练剑
**场景4-禁地：** 百花谷深处，千年花妖守护
**场景5-居所：** 花间小院，四季花开不败

#### 2.4.3 红莲教场景
**场景1-山门：** 火焰山中的红色山门，岩浆流淌
**场景2-大殿：** 红莲圣殿，火焰图腾，热血沸腾
**场景3-练武场：** 烈焰演武场，火中练拳
**场景4-禁地：** 地心火窟，岩浆池边修炼
**场景5-居所：** 红莲营寨，帐篷林立，战旗飘扬

#### 2.4.4 那迦派场景
**场景1-山门：** 毒蛇谷入口，蛇形雕塑，阴森恐怖
**场景2-大殿：** 蛇王殿，盘蛇柱，暗影重重
**场景3-练武场：** 暗影训练场，机关重重
**场景4-禁地：** 蛇窟深处，万蛇盘踞
**场景5-居所：** 忍者村落，隐蔽洞穴，暗道纵横

#### 2.4.5 太极门场景
**场景1-山门：** 阴阳山门，黑白分明，和谐统一
**场景2-大殿：** 太极殿，阴阳鱼图案，道法自然
**场景3-练武场：** 太极广场，阴阳图案，练气养生
**场景4-禁地：** 阴阳洞天，天地灵气汇聚
**场景5-居所：** 道观精舍，清静无为，修身养性

#### 2.4.6 雪山派场景
**场景1-山门：** 冰雪山门，冰雕玉琢，寒气逼人
**场景2-大殿：** 冰晶圣殿，冰柱林立，晶莹剔透
**场景3-练武场：** 冰雪演武场，冰面如镜，剑气纵横
**场景4-禁地：** 万年冰窟，冰魄凝结，极寒修炼
**场景5-居所：** 冰屋雪舍，温暖如春，冰火两重天

#### 2.4.7 逍遥派场景
**场景1-山门：** 云雾山门，若隐若现，仙气缭绕
**场景2-大殿：** 逍遥阁，云纹装饰，飘逸出尘
**场景3-练武场：** 云海练武场，云雾缭绕，如临仙境
**场景4-禁地：** 洞天福地，灵气充沛，飞升之所
**场景5-居所：** 云舍雾居，松竹环绕，逍遥自在

---

### 2.5 地图瓦片

#### 2.5.1 草地瓦片

**完整英文Prompt：**
```
Chinese ink wash painting style, seamless grass tile, green grass with traditional Chinese ink texture, grass blades in varying shades of green, subtle ink wash effects, wuxia game map tile, seamless pattern, top-down view, 256x256px, elegant composition, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt：**
```
中国水墨画风格，无缝草地瓦片，绿色草地配中国传统水墨质感，深浅不一的绿色草叶，微妙水墨晕染效果，武侠游戏地图瓦片，无缝图案，俯视图，256x256px，优雅构图，杰作，最佳质量，8k，超详细
```

---

#### 2.5.2 水面瓦片

**完整英文Prompt：**
```
Chinese ink wash painting style, seamless water tile, calm water surface with traditional Chinese ink texture, subtle ripples, blue and gray ink shades, wuxia game map tile, seamless pattern, top-down view, 256x256px, elegant composition, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt：**
```
中国水墨画风格，无缝水面瓦片，平静水面配中国传统水墨质感，微妙涟漪，蓝灰色调，武侠游戏地图瓦片，无缝图案，俯视图，256x256px，优雅构图，杰作，最佳质量，8k，超详细
```

---

#### 2.5.3 道路瓦片

**完整英文Prompt：**
```
Chinese ink wash painting style, seamless stone road tile, ancient stone path with traditional Chinese ink texture, weathered stones in gray and brown shades, wuxia game map tile, seamless pattern, top-down view, 256x256px, elegant composition, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt：**
```
中国水墨画风格，无缝石路瓦片，古老石径配中国传统水墨质感，风化石头灰棕色调，武侠游戏地图瓦片，无缝图案，俯视图，256x256px，优雅构图，杰作，最佳质量，8k，超详细
```

---

#### 2.5.4 建筑瓦片

**完整英文Prompt：**
```
Chinese ink wash painting style, seamless traditional Chinese building tile, ancient Chinese house with curved tiled roof, traditional architecture, ink wash texture, wuxia game map tile, seamless pattern, top-down view, 256x256px, elegant composition, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt：**
```
中国水墨画风格，无缝中国传统建筑瓦片，弯曲瓦顶的中国古房屋，传统建筑，水墨质感，武侠游戏地图瓦片，无缝图案，俯视图，256x256px，优雅构图，杰作，最佳质量，8k，超详细
```

---

#### 2.5.5 树木瓦片

**完整英文Prompt：**
```
Chinese ink wash painting style, seamless tree tile, ancient Chinese pine tree, twisted branches, ink wash texture, green and black shades, wuxia game map tile, seamless pattern, top-down view, 256x256px, elegant composition, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt：**
```
中国水墨画风格，无缝树木瓦片，中国古松树，扭曲树枝，水墨质感，绿黑调，武侠游戏地图瓦片，无缝图案，俯视图，256x256px，优雅构图，杰作，最佳质量，8k，超详细
```

---

#### 2.5.6 沙漠瓦片

**完整英文Prompt：**
```
Chinese ink wash painting style, seamless desert tile, golden sand dunes, ink wash texture, yellow and brown shades, wuxia game map tile, seamless pattern, top-down view, 256x256px, elegant composition, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt：**
```
中国水墨画风格，无缝沙漠瓦片，金色沙丘，水墨质感，黄棕调，武侠游戏地图瓦片，无缝图案，俯视图，256x256px，优雅构图，杰作，最佳质量，8k，超详细
```

---

#### 2.5.7 雪地瓦片

**完整英文Prompt：**
```
Chinese ink wash painting style, seamless snow tile, snowy ground, ink wash texture, white and light blue shades, wuxia game map tile, seamless pattern, top-down view, 256x256px, elegant composition, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt：**
```
中国水墨画风格，无缝雪地瓦片，雪地，水墨质感，白和浅蓝色调，武侠游戏地图瓦片，无缝图案，俯视图，256x256px，优雅构图，杰作，最佳质量，8k，超详细
```

---

## 三、UI美术Prompt

### 3.1 界面元素

#### 3.1.1 按钮

**设计规范：**
- **尺寸：** 120×40px（标准），180×50px（大），80×30px（小）
- **圆角：** 8px
- **描边：** 2px金色渐变边框
- **渐变：** 深蓝到深灰的垂直渐变

**正常状态：**

**完整英文Prompt：**
```
Chinese ink wash painting style UI button, normal state, 120x40px rectangular button with 8px rounded corners, dark blue to dark gray vertical gradient background (#1a1a2e to #16213e), 2px gold gradient border (#c9a96e to #f0c040), subtle ink wash texture overlay, traditional Chinese corner decorations, elegant wuxia game UI, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt：**
```
中国水墨画风格UI按钮，正常状态，120x40px矩形按钮配8px圆角，深蓝到深灰垂直渐变背景（#1a1a2e到#16213e），2px金色渐变边框（#c9a96e到#f0c040），微妙水墨纹理叠加，中国传统角花装饰，优雅武侠游戏UI，杰作，最佳质量，8k，超详细
```

**颜色值：**
- 背景渐变：#1a1a2e → #16213e
- 边框渐变：#c9a96e → #f0c040
- 文字颜色：#f5f0e8

**悬停状态：**

**完整英文Prompt：**
```
Chinese ink wash painting style UI button, hover state, 120x40px rectangular button with 8px rounded corners, lighter blue gradient background (#16213e to #0f3460), 2px bright gold border (#f0c040 to #ffd700), enhanced ink wash texture glow, traditional Chinese corner decorations with gold highlight, elegant wuxia game UI, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt：**
```
中国水墨画风格UI按钮，悬停状态，120x40px矩形按钮配8px圆角，较浅蓝色渐变背景（#16213e到#0f3460），2px亮金边框（#f0c040到#ffd700），增强水墨纹理发光，中国传统角花装饰配金色高光，优雅武侠游戏UI，杰作，最佳质量，8k，超详细
```

**颜色值：**
- 背景渐变：#16213e → #0f3460
- 边框渐变：#f0c040 → #ffd700
- 文字颜色：#ffffff

**按下状态：**

**完整英文Prompt：**
```
Chinese ink wash painting style UI button, pressed state, 120x40px rectangular button with 8px rounded corners, dark inset gradient background (#0f0f1a to #1a1a2e), 2px dark gold border (#8b7355 to #c9a96e), inset shadow effect, traditional Chinese corner decorations pressed inward, elegant wuxia game UI, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt：**
```
中国水墨画风格UI按钮，按下状态，120x40px矩形按钮配8px圆角，深色内凹渐变背景（#0f0f1a到#1a1a2e），2px暗金边框（#8b7355到#c9a96e），内阴影效果，中国传统角花装饰向内凹陷，优雅武侠游戏UI，杰作，最佳质量，8k，超详细
```

**颜色值：**
- 背景渐变：#0f0f1a → #1a1a2e
- 边框渐变：#8b7355 → #c9a96e
- 文字颜色：#c9a96e

**禁用状态：**

**完整英文Prompt：**
```
Chinese ink wash painting style UI button, disabled state, 120x40px rectangular button with 8px rounded corners, grayed out gradient background (#2a2a3e to #3a3a4e), 2px gray border (#6a6a7a to #8a8a9a), desaturated ink wash texture, muted traditional Chinese corner decorations, elegant wuxia game UI, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt：**
```
中国水墨画风格UI按钮，禁用状态，120x40px矩形按钮配8px圆角，灰化渐变背景（#2a2a3e到#3a3a4e），2px灰色边框（#6a6a7a到#8a8a9a），去饱和水墨纹理， muted 中国传统角花装饰，优雅武侠游戏UI，杰作，最佳质量，8k，超详细
```

**颜色值：**
- 背景渐变：#2a2a3e → #3a3a4e
- 边框渐变：#6a6a7a → #8a8a9a
- 文字颜色：#8a8a9a

---

#### 3.1.2 面板

**设计规范：**
- **尺寸：** 400×300px（标准），600×400px（大），300×200px（小）
- **圆角：** 12px
- **描边：** 3px金色渐变边框
- **阴影：** 外发光+内阴影

**标题栏：**

**完整英文Prompt：**
```
Chinese ink wash painting style UI panel title bar, 400x40px header with 12px top rounded corners, dark blue gradient background (#0f3460 to #1a1a2e), gold gradient border bottom (#c9a96e to #f0c040), traditional Chinese cloud pattern decoration, elegant wuxia game UI, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt：**
```
中国水墨画风格UI面板标题栏，400x40px头部配12px顶部圆角，深蓝渐变背景（#0f3460到#1a1a2e），金色渐变底边框（#c9a96e到#f0c040），中国传统云纹装饰，优雅武侠游戏UI，杰作，最佳质量，8k，超详细
```

**颜色值：**
- 背景渐变：#0f3460 → #1a1a2e
- 边框：#c9a96e → #f0c040
- 文字颜色：#f0c040

**内容区：**

**完整英文Prompt：**
```
Chinese ink wash painting style UI panel content area, 400x260px content section, dark translucent background (#1a1a2e with 90% opacity), subtle ink wash texture, inner shadow for depth, scrollable area indicator, elegant wuxia game UI, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt：**
```
中国水墨画风格UI面板内容区，400x260px内容区域，深色半透明背景（#1a1a2e配90%不透明度），微妙水墨纹理，内阴影增加深度，可滚动区域指示器，优雅武侠游戏UI，杰作，最佳质量，8k，超详细
```

**颜色值：**
- 背景：#1a1a2e（90%透明度）
- 文字颜色：#f5f0e8
- 滚动条：#c9a96e

**边框：**

**完整英文Prompt：**
```
Chinese ink wash painting style UI panel border, 3px gold gradient border (#c9a96e to #f0c040), traditional Chinese corner ornaments at four corners, subtle outer glow effect, elegant wuxia game UI, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt：**
```
中国水墨画风格UI面板边框，3px金色渐变边框（#c9a96e到#f0c040），四角中国传统角花装饰，微妙外发光效果，优雅武侠游戏UI，杰作，最佳质量，8k，超详细
```

**颜色值：**
- 边框渐变：#c9a96e → #f0c040
- 外发光：#c9a96e（30%透明度）

**阴影：**

**完整英文Prompt：**
```
Chinese ink wash painting style UI panel shadow, outer glow shadow with 20px blur radius, dark blue shadow color (#0f3460 with 50% opacity), inner shadow for depth, elegant wuxia game UI, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt：**
```
中国水墨画风格UI面板阴影，外发光阴影配20px模糊半径，深蓝阴影色（#0f3460配50%不透明度），内阴影增加深度，优雅武侠游戏UI，杰作，最佳质量，8k，超详细
```

**颜色值：**
- 外阴影：#0f3460（50%透明度）
- 内阴影：#000000（30%透明度）

---

#### 3.1.3 图标

**设计规范：**
- **尺寸：** 32×32px（小），64×64px（大）
- **圆角：** 4px（小），8px（大）
- **描边：** 1px金色边框（小），2px金色边框（大）

**32×32px图标：**

**完整英文Prompt：**
```
Chinese ink wash painting style UI icon, 32x32px square icon with 4px rounded corners, dark blue background (#1a1a2e), 1px gold border (#c9a96e), traditional Chinese brush calligraphy character in center, subtle ink wash texture, wuxia game skill/item icon, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt：**
```
中国水墨画风格UI图标，32x32px方形图标配4px圆角，深蓝背景（#1a1a2e），1px金色边框（#c9a96e），中心中国传统毛笔书法字符，微妙水墨纹理，武侠游戏技能/物品图标，杰作，最佳质量，8k，超详细
```

**颜色值：**
- 背景：#1a1a2e
- 边框：#c9a96e
- 文字/图案：#f0c040

**64×64px图标：**

**完整英文Prompt：**
```
Chinese ink wash painting style UI icon, 64x64px square icon with 8px rounded corners, dark blue gradient background (#16213e to #1a1a2e), 2px gold gradient border (#c9a96e to #f0c040), detailed traditional Chinese brush painting in center, ink wash texture overlay, wuxia game skill/item icon, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt：**
```
中国水墨画风格UI图标，64x64px方形图标配8px圆角，深蓝渐变背景（#16213e到#1a1a2e），2px金色渐变边框（#c9a96e到#f0c040），中心 detailed 中国传统毛笔绘画，水墨纹理叠加，武侠游戏技能/物品图标，杰作，最佳质量，8k，超详细
```

**颜色值：**
- 背景渐变：#16213e → #1a1a2e
- 边框渐变：#c9a96e → #f0c040
- 文字/图案：#f0c040

---

#### 3.1.4 进度条

**设计规范：**
- **尺寸：** 200×20px（标准），300×24px（大）
- **圆角：** 10px
- **描边：** 2px金色边框

**HP条（红色）：**

**完整英文Prompt：**
```
Chinese ink wash painting style UI HP bar, 200x20px horizontal bar with 10px rounded corners, dark background (#1a1a2e), 2px gold border (#c9a96e), red gradient fill (#c0392b to #e74c3c), HP value display in gold text, elegant wuxia game UI, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt：**
```
中国水墨画风格UI HP条，200x20px横条配10px圆角，深色背景（#1a1a2e），2px金色边框（#c9a96e），红色渐变填充（#c0392b到#e74c3c），金色文字HP值显示，优雅武侠游戏UI，杰作，最佳质量，8k，超详细
```

**颜色值：**
- 背景：#1a1a2e
- 边框：#c9a96e
- 填充渐变：#c0392b → #e74c3c
- 文字：#f0c040

**MP条（蓝色）：**

**完整英文Prompt：**
```
Chinese ink wash painting style UI MP bar, 200x20px horizontal bar with 10px rounded corners, dark background (#1a1a2e), 2px gold border (#c9a96e), blue gradient fill (#2980b9 to #3498db), MP value display in gold text, elegant wuxia game UI, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt：**
```
中国水墨画风格UI MP条，200x20px横条配10px圆角，深色背景（#1a1a2e），2px金色边框（#c9a96e），蓝色渐变填充（#2980b9到#3498db），金色文字MP值显示，优雅武侠游戏UI，杰作，最佳质量，8k，超详细
```

**颜色值：**
- 背景：#1a1a2e
- 边框：#c9a96e
- 填充渐变：#2980b9 → #3498db
- 文字：#f0c040

**EXP条（绿色）：**

**完整英文Prompt：**
```
Chinese ink wash painting style UI EXP bar, 200x20px horizontal bar with 10px rounded corners, dark background (#1a1a2e), 2px gold border (#c9a96e), green gradient fill (#27ae60 to #2ecc71), EXP value display in gold text, elegant wuxia game UI, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt：**
```
中国水墨画风格UI EXP条，200x20px横条配10px圆角，深色背景（#1a1a2e），2px金色边框（#c9a96e），绿色渐变填充（#27ae60到#2ecc71），金色文字EXP值显示，优雅武侠游戏UI，杰作，最佳质量，8k，超详细
```

**颜色值：**
- 背景：#1a1a2e
- 边框：#c9a96e
- 填充渐变：#27ae60 → #2ecc71
- 文字：#f0c040

---

### 3.2 特效美术

#### 3.2.1 技能特效（20个技能）

**技能1：剑气纵横**

**视觉效果描述：**
- **粒子类型：** 墨色剑气粒子
- **粒子数量：** 50-100个
- **运动轨迹：** 直线向前，带轻微扩散
- **颜色变化：** 黑→灰→淡，带金色边缘
- **透明度变化：** 100%→50%→0%
- **持续时间：** 0.5秒
- **循环方式：** 单次

**完整英文Prompt：**
```
Chinese ink wash painting style sword qi skill effect, 50-100 black ink particles forming sword energy, straight forward trajectory with slight spread, color gradient from black to gray to transparent with gold edges, opacity fade 100% to 0%, 0.5 second duration, single play, wuxia skill effect, transparent background, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt：**
```
中国水墨画风格剑气技能特效，50-100个墨色粒子形成剑气，直线向前轨迹配轻微扩散，颜色渐变从黑到灰到透明配金色边缘，透明度淡出100%到0%，0.5秒持续时间，单次播放，武侠技能特效，透明背景，杰作，最佳质量，8k，超详细
```

---

**技能2：八卦阵图**

**视觉效果描述：**
- **粒子类型：** 八卦符号粒子
- **粒子数量：** 8个主卦+64个副卦
- **运动轨迹：** 旋转扩散
- **颜色变化：** 紫金→金→淡
- **透明度变化：** 100%→30%→0%
- **持续时间：** 3秒
- **循环方式：** 循环

**完整英文Prompt：**
```
Chinese ink wash painting style bagua array skill effect, 8 main trigram symbols plus 64 sub trigrams, rotating expanding trajectory, purple-gold to gold to transparent color gradient, opacity fade 100% to 0%, 3 second duration, loop, wuxia skill effect, transparent background, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt：**
```
中国水墨画风格八卦阵图技能特效，8个主卦符号加64个副卦，旋转扩散轨迹，紫金到金到透明颜色渐变，透明度淡出100%到0%，3秒持续时间，循环，武侠技能特效，透明背景，杰作，最佳质量，8k，超详细
```

---

[注：以下技能简要列出]

**技能3：花雨漫天** - 粉色花瓣飘落，花间派技能
**技能4：红莲业火** - 红色火焰莲花，红莲教技能
**技能5：影遁无形** - 黑色烟雾消散，那迦派技能
**技能6：太极阴阳** - 黑白旋转阴阳鱼，太极门技能
**技能7：冰雪风暴** - 蓝白冰晶风暴，雪山派技能
**技能8：松风万壑** - 绿色松针飞舞，逍遥派技能
**技能9：金刚伏魔** - 金色佛光普照，少林技能
**技能10：毒雾弥漫** - 绿色毒雾扩散，毒功技能
**技能11：雷霆万钧** - 紫色雷电劈下，雷功技能
**技能12：土石崩塌** - 棕色岩石崩落，土功技能
**技能13：水流缠绕** - 蓝色水流环绕，水功技能
**技能14：烈焰焚天** - 橙红火焰爆发，火功技能
**技能15：风刃切割** - 青色风刃飞射，风功技能
**技能16：金光护体** - 金色光罩防御，护体技能
**技能17：血影重重** - 红色血影分身，血功技能
**技能18：星辰坠落** - 银色星辰落下，星功技能
**技能19：月华如练** - 银白月光照射，月功技能
**技能20：日曜九天** - 金红太阳光芒，日功技能

---

#### 3.2.2 环境特效

**雨特效：**

**视觉效果描述：**
- **粒子类型：** 墨色雨滴
- **粒子数量：** 200-500个
- **运动轨迹：** 垂直下落，带轻微风偏
- **颜色变化：** 黑→灰→淡
- **透明度变化：** 80%→40%→0%
- **持续时间：** 循环
- **循环方式：** 循环

**完整英文Prompt：**
```
Chinese ink wash painting style rain effect, 200-500 black ink raindrops falling, vertical trajectory with slight wind drift, black to gray color gradient, opacity fade 80% to 0%, continuous loop, wuxia environment effect, transparent background, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt：**
```
中国水墨画风格雨特效，200-500个墨色雨滴落下，垂直轨迹配轻微风偏，黑到灰颜色渐变，透明度淡出80%到0%，持续循环，武侠环境特效，透明背景，杰作，最佳质量，8k，超详细
```

---

**雪特效：**

**视觉效果描述：**
- **粒子类型：** 白色雪花
- **粒子数量：** 100-300个
- **运动轨迹：** 缓慢飘落，带旋转
- **颜色变化：** 白→浅蓝→淡
- **透明度变化：** 100%→50%→0%
- **持续时间：** 循环
- **循环方式：** 循环

**完整英文Prompt：**
```
Chinese ink wash painting style snow effect, 100-300 white snowflakes falling slowly, drifting trajectory with rotation, white to light blue color gradient, opacity fade 100% to 0%, continuous loop, wuxia environment effect, transparent background, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt：**
```
中国水墨画风格雪特效，100-300个白色雪花缓慢飘落，飘移轨迹配旋转，白到浅蓝颜色渐变，透明度淡出100%到0%，持续循环，武侠环境特效，透明背景，杰作，最佳质量，8k，超详细
```

---

**风特效：**

**视觉效果描述：**
- **粒子类型：** 青色风痕
- **粒子数量：** 50-100个
- **运动轨迹：** 水平流动，带波浪
- **颜色变化：** 青→淡青→透明
- **透明度变化：** 60%→30%→0%
- **持续时间：** 循环
- **循环方式：** 循环

**完整英文Prompt：**
```
Chinese ink wash painting style wind effect, 50-100 cyan wind streaks flowing horizontally, wavy trajectory, cyan to pale cyan to transparent color gradient, opacity fade 60% to 0%, continuous loop, wuxia environment effect, transparent background, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt：**
```
中国水墨画风格风特效，50-100个青色风痕水平流动，波浪轨迹，青到淡青到透明颜色渐变，透明度淡出60%到0%，持续循环，武侠环境特效，透明背景，杰作，最佳质量，8k，超详细
```

---

**雾特效：**

**视觉效果描述：**
- **粒子类型：** 灰色雾团
- **粒子数量：** 30-50个
- **运动轨迹：** 缓慢飘动，带随机
- **颜色变化：** 灰→淡灰→透明
- **透明度变化：** 40%→20%→0%
- **持续时间：** 循环
- **循环方式：** 循环

**完整英文Prompt：**
```
Chinese ink wash painting style fog effect, 30-50 gray mist clouds drifting slowly, random floating trajectory, gray to pale gray to transparent color gradient, opacity fade 40% to 0%, continuous loop, wuxia environment effect, transparent background, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt：**
```
中国水墨画风格雾特效，30-50个灰色雾团缓慢飘动，随机飘浮轨迹，灰到淡灰到透明颜色渐变，透明度淡出40%到0%，持续循环，武侠环境特效，透明背景，杰作，最佳质量，8k，超详细
```

---

**光特效：**

**视觉效果描述：**
- **粒子类型：** 金色光点
- **粒子数量：** 100-200个
- **运动轨迹：** 向上飘散，带闪烁
- **颜色变化：** 金→淡金→透明
- **透明度变化：** 100%→50%→0%
- **持续时间：** 循环
- **循环方式：** 循环

**完整英文Prompt：**
```
Chinese ink wash painting style light effect, 100-200 golden light particles floating upward, drifting trajectory with twinkling, gold to pale gold to transparent color gradient, opacity fade 100% to 0%, continuous loop, wuxia environment effect, transparent background, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt：**
```
中国水墨画风格光特效，100-200个金色光点向上飘散，飘移轨迹配闪烁，金到淡金到透明颜色渐变，透明度淡出100%到0%，持续循环，武侠环境特效，透明背景，杰作，最佳质量，8k，超详细
```

---

#### 3.2.3 UI特效

**按钮点击特效：**

**视觉效果描述：**
- **粒子类型：** 金色涟漪
- **粒子数量：** 1个主涟漪+5个副涟漪
- **运动轨迹：** 从点击点向外扩散
- **颜色变化：** 金→淡金→透明
- **透明度变化：** 100%→0%
- **持续时间：** 0.3秒
- **循环方式：** 单次

**完整英文Prompt：**
```
Chinese ink wash painting style button click effect, 1 main gold ripple plus 5 secondary ripples expanding from click point, gold to pale gold to transparent color gradient, opacity fade 100% to 0%, 0.3 second duration, single play, wuxia UI effect, transparent background, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt：**
```
中国水墨画风格按钮点击特效，1个主金色涟漪加5个副涟漪从点击点向外扩散，金到淡金到透明颜色渐变，透明度淡出100%到0%，0.3秒持续时间，单次播放，武侠UI特效，透明背景，杰作，最佳质量，8k，超详细
```

---

**窗口弹出特效：**

**视觉效果描述：**
- **粒子类型：** 水墨扩散
- **粒子数量：** 整体效果
- **运动轨迹：** 从中心向外扩散
- **颜色变化：** 黑→灰→透明
- **透明度变化：** 0%→100%
- **持续时间：** 0.5秒
- **循环方式：** 单次

**完整英文Prompt：**
```
Chinese ink wash painting style window popup effect, ink wash spreading from center outward, black to gray to transparent color gradient, opacity fade in 0% to 100%, 0.5 second duration, single play, wuxia UI effect, transparent background, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt：**
```
中国水墨画风格窗口弹出特效，水墨从中心向外扩散，黑到灰到透明颜色渐变，透明度淡入0%到100%，0.5秒持续时间，单次播放，武侠UI特效，透明背景，杰作，最佳质量，8k，超详细
```

---

**获得物品特效：**

**视觉效果描述：**
- **粒子类型：** 金色星星+物品图标
- **粒子数量：** 10-20个星星
- **运动轨迹：** 向上飘散，带旋转
- **颜色变化：** 金→淡金→透明
- **透明度变化：** 100%→0%
- **持续时间：** 1秒
- **循环方式：** 单次

**完整英文Prompt：**
```
Chinese ink wash painting style item obtained effect, 10-20 golden stars floating upward with rotation, item icon in center with glow, gold to pale gold to transparent color gradient, opacity fade 100% to 0%, 1 second duration, single play, wuxia UI effect, transparent background, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt：**
```
中国水墨画风格获得物品特效，10-20个金色星星向上飘散配旋转，中心物品图标配发光，金到淡金到透明颜色渐变，透明度淡出100%到0%，1秒持续时间，单次播放，武侠UI特效，透明背景，杰作，最佳质量，8k，超详细
```

---

## 四、武器装备美术Prompt

### 4.1 武器

#### 4.1.1 剑类（15种）

**剑1：八卦紫金剑**

**武器造型描述：**
长三尺六寸，剑身紫金双色，剑脊刻八卦图案，剑柄缠金丝，剑镡为八卦形状，剑穗紫色。

**材质说明：** 紫金合金（玄铁+紫金矿石）

**装饰细节：** 八卦图案、金丝缠绕、紫穗

**完整英文Prompt：**
```
Chinese ink wash painting style, Bagua purple gold sword, 3.6 chi long blade with purple-gold two-tone, bagua patterns engraved on spine, gold silk wrapped hilt, bagua-shaped guard, purple tassel, purple gold alloy material, elegant powerful design, wuxia weapon, masterpiece, best quality, 8k, ultra detailed, on white background
```

**完整中文Prompt：**
```
中国水墨画风格，八卦紫金剑，长三尺六寸剑身紫金双色，剑脊刻八卦图案，剑柄缠金丝，剑镡八卦形状，剑穗紫色，紫金合金材质，优雅强力设计，武侠武器，杰作，最佳质量，8k，超详细，白色背景
```

---

**剑2：松风古剑**

**武器造型描述：**
长三尺，剑身木质带天然松纹，剑柄绿玉镶嵌，剑镡松枝造型，无剑穗，古朴自然。

**材质说明：** 千年松木+绿玉

**装饰细节：** 天然松纹、绿玉镶嵌、松枝剑镡

**完整英文Prompt：**
```
Chinese ink wash painting style, Pine Wind ancient sword, 3 chi long wooden blade with natural pine grain, green jade inlaid hilt, pine branch shaped guard, no tassel, ancient natural design, thousand-year pine wood and green jade material, elegant immortal weapon, wuxia weapon, masterpiece, best quality, 8k, ultra detailed, on white background
```

**完整中文Prompt：**
```
中国水墨画风格，松风古剑，长三尺剑身木质带天然松纹，剑柄绿玉镶嵌，剑镡松枝造型，无剑穗，古朴自然设计，千年松木绿玉材质，优雅仙器，武侠武器，杰作，最佳质量，8k，超详细，白色背景
```

---

[注：以下13种剑简要列出]

**剑3：冰魄寒光剑** - 冰晶材质，雪花图案，雪山派
**剑4：太极阴阳剑** - 黑白双色，阴阳图案，太极门
**剑5：花间游龙剑** - 粉色剑身，花卉雕刻，花间派
**剑6：红莲烈焰剑** - 红色剑身，火焰纹路，红莲教
**剑7：影杀无影剑** - 黑色剑身，蛇纹图案，那迦派
**剑8：伏魔金刚剑** - 金色剑身，佛教符文，少林
**剑9：青锋剑** - 标准长剑，青钢材质，通用
**剑10：龙泉剑** - 名剑，龙纹雕刻，通用
**剑11：倚天剑** - 名剑，锋利无比，通用
**剑12：淑女剑** - 女式短剑，精致优雅，通用
**剑13：君子剑** - 男式长剑，正气凛然，通用
**剑14：软剑** - 可弯曲，缠绕腰间，通用
**剑15：重剑** - 无锋大巧，重剑无锋，通用

---

#### 4.1.2 刀类（10种）

**刀1：八卦紫金刀**

**武器造型描述：**
长四尺，刀身紫金双色，刀背厚，刀刃薄，刀柄缠金丝，刀镡八卦形状，刀穗紫色。

**材质说明：** 紫金合金（玄铁+紫金矿石）

**装饰细节：** 八卦图案、金丝缠绕、紫穗

**完整英文Prompt：**
```
Chinese ink wash painting style, Bagua purple gold broadsword, 4 chi long blade with purple-gold two-tone, thick spine thin edge, gold silk wrapped hilt, bagua-shaped guard, purple tassel, purple gold alloy material, powerful martial design, wuxia weapon, masterpiece, best quality, 8k, ultra detailed, on white background
```

**完整中文Prompt：**
```
中国水墨画风格，八卦紫金刀，长四尺刀身紫金双色，刀背厚刀刃薄，刀柄缠金丝，刀镡八卦形状，刀穗紫色，紫金合金材质，强力武术设计，武侠武器，杰作，最佳质量，8k，超详细，白色背景
```

---

[注：以下9种刀简要列出]

**刀2：红莲烈焰刀** - 红色刀身，火焰纹路，红莲教
**刀3：雪山冰魄刀** - 冰晶刀身，雪花图案，雪山派
**刀4：太极阴阳刀** - 黑白双色，阴阳图案，太极门
**刀5：影杀忍刀** - 黑色短刀，蛇纹图案，那迦派
**刀6：伏魔戒刀** - 金色刀身，佛教符文，少林
**刀7：青龙偃月刀** - 名刀，龙纹雕刻，通用
**刀8：朴刀** - 长柄大刀，实用设计，通用
**刀9：雁翎刀** - 弯刀，雁翎形状，通用
**刀10：匕首** - 短刀，隐蔽携带，通用

---

#### 4.1.3 特殊武器（15种）

**特殊1：太极拂尘**

**武器造型描述：**
柄长一尺五寸，玉柄白色丝拂，柄刻阴阳图案，拂丝银白，可柔可刚。

**材质说明：** 白玉+银丝

**装饰细节：** 阴阳图案、银白拂丝

**完整英文Prompt：**
```
Chinese ink wash painting style, Tai Chi fly-whisk, 1.5 chi long jade handle with white silk whisk, Yin-Yang patterns carved on handle, silver-white whisk threads, flexible yet firm design, jade and silver material, elegant Taoist weapon, wuxia weapon, masterpiece, best quality, 8k, ultra detailed, on white background
```

**完整中文Prompt：**
```
中国水墨画风格，太极拂尘，柄长一尺五寸玉柄白色丝拂，柄刻阴阳图案，拂丝银白，可柔可刚设计，白玉银丝材质，优雅道教武器，武侠武器，杰作，最佳质量，8k，超详细，白色背景
```

---

**特殊2：百花拂穴笔**

**武器造型描述：**
笔长一尺，玉制笔杆，笔尖可射花针，笔身雕百花图案，笔挂花形。

**材质说明：** 白玉+精钢针

**装饰细节：** 百花图案、花形笔挂

**完整英文Prompt：**
```
Chinese ink wash painting style, Hundred Flowers acupuncture brush, 1 chi long jade handle with flower-shaped tip, can shoot flower needles, hundred flower patterns carved on body, flower-shaped pen hanger, jade and steel needle material, delicate deadly design, wuxia weapon, masterpiece, best quality, 8k, ultra detailed, on white background
```

**完整中文Prompt：**
```
中国水墨画风格，百花拂穴笔，长一尺玉制笔杆，笔尖可射花针，笔身雕百花图案，笔挂花形，白玉精钢针材质，精致致命设计，武侠武器，杰作，最佳质量，8k，超详细，白色背景
```

---

**特殊3：红莲烈焰拳套**

**武器造型描述：**
双拳套，红色金属，拳面嵌红莲宝石，发火光，腕部有火焰纹路。

**材质说明：** 玄铁+红莲宝石

**装饰细节：** 红莲宝石、火焰纹路

**完整英文Prompt：**
```
Chinese ink wash painting style, Red Lotus flame gauntlets, pair of red metal gauntlets, red lotus gems embedded on knuckles, emitting fire light, flame patterns on wrist, black iron and lotus gem material, fiery powerful design, wuxia weapon, masterpiece, best quality, 8k, ultra detailed, on white background
```

**完整中文Prompt：**
```
中国水墨画风格，红莲烈焰拳套，双红色金属拳套，拳面嵌红莲宝石，发火光，腕部火焰纹路，玄铁红莲宝石材质，火焰强力设计，武侠武器，杰作，最佳质量，8k，超详细，白色背景
```

---

[注：以下12种特殊武器简要列出]

**特殊4：影杀忍刀** - 双短刀，蛇纹图案，那迦派
**特殊5：冰魄寒光剑** - 冰晶剑，雪花图案，雪山派
**特殊6：伏魔禅杖** - 铁杖，龙虎雕刻，少林
**特殊7：打狗棒** - 竹棒，丐帮信物，通用
**特殊8：判官笔** - 双笔，点穴专用，通用
**特殊9：峨嵋刺** - 双刺，女式武器，通用
**特殊10：铁扇** - 铁骨扇，可攻可守，通用
**特殊11：铁爪** - 手爪，攀爬战斗，通用
**特殊12：流星锤** - 链锤，远程攻击，通用
**特殊13：双钩** - 护手钩，攻防一体，通用
**特殊14：三节棍** - 可伸缩，灵活多变，通用
**特殊15：九节鞭** - 软鞭，缠绕攻击，通用

---

### 4.2 防具

#### 4.2.1 头部防具（6种）

**头部1：八卦道冠**

**完整英文Prompt：**
```
Chinese ink wash painting style, Bagua Taoist crown, black silk headpiece with gold bagua patterns, formal ceremonial design, purple gold material accents, elegant martial headwear, wuxia armor, masterpiece, best quality, 8k, ultra detailed, on white background
```

**完整中文Prompt：**
```
中国水墨画风格，八卦道冠，黑色丝绸头饰配金色八卦图案，正式仪式设计，紫金材质点缀，优雅武术头饰，武侠防具，杰作，最佳质量，8k，超详细，白色背景
```

---

[注：以下5种头部防具简要列出]

**头部2：花间花冠** - 粉色花冠，花间派
**头部3：红莲战盔** - 红色战盔，红莲教
**头部4：影杀面罩** - 黑色面罩，那迦派
**头部5：太极道巾** - 白色道巾，太极门
**头部6：雪山冰盔** - 冰晶头盔，雪山派

---

#### 4.2.2 身体防具（6种）

**身体1：八卦道袍**

**完整英文Prompt：**
```
Chinese ink wash painting style, Bagua Taoist robe, black silk robes with gold bagua patterns, wide sleeves and flowing design, purple gold material, elegant martial attire, wuxia armor, masterpiece, best quality, 8k, ultra detailed, on white background
```

**完整中文Prompt：**
```
中国水墨画风格，八卦道袍，黑色丝绸长袍配金色八卦图案，宽袖飘逸设计，紫金材质，优雅武术服装，武侠防具，杰作，最佳质量，8k，超详细，白色背景
```

---

[注：以下5种身体防具简要列出]

**身体2：花仙霓裳** - 粉色长裙，花间派
**身体3：红莲战甲** - 红色铠甲，红莲教
**身体4：暗影忍服** - 黑色紧身服，那迦派
**身体5：太极仙袍** - 白色道袍，太极门
**身体6：雪山冰铠** - 冰晶铠甲，雪山派

---

#### 4.2.3 手部防具（6种）

**手部1：八卦护腕**

**完整英文Prompt：**
```
Chinese ink wash painting style, Bagua wrist guards, black leather with gold bagua embroidery, protective yet flexible design, purple gold accents, elegant martial hand protection, wuxia armor, masterpiece, best quality, 8k, ultra detailed, on white background
```

**完整中文Prompt：**
```
中国水墨画风格，八卦护腕，黑色皮革配金色八卦刺绣，保护 yet 灵活设计，紫金点缀，优雅武术手部防护，武侠防具，杰作，最佳质量，8k，超详细，白色背景
```

---

[注：以下5种手部防具简要列出]

**手部2：花间手套** - 粉色丝手套，花间派
**手部3：红莲拳套** - 红色拳套，红莲教
**手部4：暗影手套** - 黑色手套，那迦派
**手部5：太极护腕** - 白色护腕，太极门
**手部6：雪山冰手** - 冰晶护手，雪山派

---

#### 4.2.4 脚部防具（6种）

**脚部1：八卦云靴**

**完整英文Prompt：**
```
Chinese ink wash painting style, Bagua cloud boots, black silk boots with gold cloud patterns, soft sole for martial arts, purple gold material accents, elegant martial footwear, wuxia armor, masterpiece, best quality, 8k, ultra detailed, on white background
```

**完整中文Prompt：**
```
中国水墨画风格，八卦云靴，黑色丝绸靴子配金色云纹，软底适合武术，紫金材质点缀，优雅武术鞋履，武侠防具，杰作，最佳质量，8k，超详细，白色背景
```

---

[注：以下5种脚部防具简要列出]

**脚部2：花间绣鞋** - 粉色绣鞋，花间派
**脚部3：红莲战靴** - 红色战靴，红莲教
**脚部4：暗影足袋** - 黑色足袋，那迦派
**脚部5：太极布鞋** - 白色布鞋，太极门
**脚部6：雪山冰靴** - 冰晶靴子，雪山派

---

### 4.3 饰品

[注：30种饰品，每种含中英文Prompt，简要列出]

#### 4.3.1 七大门派饰品（各3种，共21种）

**八卦门饰品：**
- **混元珠** - 发光宝珠，八卦图案
- **乾坤玉佩** - 阴阳玉佩，乾坤图案
- **八卦戒指** - 紫金戒指，八卦雕刻

**花间派饰品：**
- **玉兰花簪** - 白玉花簪，兰花雕刻
- **花仙项链** - 花形项链，珍珠点缀
- **百花戒指** - 金花戒指，百花图案

**红莲教饰品：**
- **红莲舍利** - 发光红珠，莲花图案
- **火焰护符** - 火焰护符，红莲雕刻
- **烈焰戒指** - 红金戒指，火焰纹路

**那迦派饰品：**
- **蛇瞳石** - 黑色宝石，蛇眼图案
- **暗影护符** - 黑色护符，蛇纹雕刻
- **毒牙项链** - 蛇牙项链，毒液淬炼

**太极门饰品：**
- **阴阳玉佩** - 黑白玉佩，阴阳图案
- **太极护符** - 太极护符，阴阳雕刻
- **乾坤戒指** - 银白戒指，太极图案

**雪山派饰品：**
- **冰雪魂晶** - 蓝色冰晶，雪花图案
- **冰魄项链** - 冰晶项链，寒气缭绕
- **雪莲戒指** - 白金戒指，雪莲雕刻

**逍遥派饰品：**
- **松烟葫芦** - 绿玉葫芦，松树图案
- **云纹玉佩** - 白玉云纹，飘逸设计
- **逍遥戒指** - 翠绿戒指，云纹雕刻

---

#### 4.3.2 通用饰品（9种）

**通用饰品：**
- **铜钱项链** - 古铜钱串，招财进宝
- **玉扳指** - 白玉扳指，身份象征
- **银手镯** - 银质手镯，装饰美观
- **金耳环** - 金质耳环，富贵华丽
- **珍珠项链** - 珍珠串链，优雅高贵
- **翡翠戒指** - 翡翠戒指，翠绿欲滴
- **玛瑙手链** - 玛瑙串链，色彩斑斓
- **琥珀吊坠** - 琥珀吊坠，内含古虫
- **珊瑚发簪** - 珊瑚发簪，红艳夺目

---

## 五、动画规范

### 5.1 角色动画

#### 5.1.1 Idle（待机）- 4方向 × 3种变体

**4方向：** 上、下、左、右

**每种方向3种变体：**
- **变体1：** 基础待机 - 自然站立，轻微呼吸起伏
- **变体2：** 警觉待机 - 身体微侧，眼神警惕
- **变体3：** 放松待机 - 身体微倾，神态悠闲

**帧数标准：**
- 每方向3种变体，共12个待机动画
- 每个动画8-12帧
- 帧率：30fps
- 循环方式：循环

**动画规范表：**

| 方向 | 变体1 | 变体2 | 变体3 |
|-----|-------|-------|-------|
| 上 | 8帧 | 10帧 | 12帧 |
| 下 | 8帧 | 10帧 | 12帧 |
| 左 | 8帧 | 10帧 | 12帧 |
| 右 | 8帧 | 10帧 | 12帧 |

---

#### 5.1.2 Walk（行走）- 4方向 × 8帧

**4方向：** 上、下、左、右

**每方向8帧：**
- 帧1：起始姿势
- 帧2：抬脚
- 帧3：迈步
- 帧4：落脚
- 帧5：重心转移
- 帧6：另一脚抬脚
- 帧7：另一脚迈步
- 帧8：另一脚落脚，回到起始

**帧数标准：**
- 每方向8帧，共4个行走动画
- 帧率：30fps
- 循环方式：循环
- 行走周期：0.27秒/步

---

#### 5.1.3 Attack（攻击）- 每种武器类型 × 6帧

**武器类型：** 剑、刀、拳、暗器、杖、拂尘

**每类型6帧：**
- 帧1：起手姿势
- 帧2：蓄力
- 帧3：出击
- 帧4：命中
- 帧5：收招
- 帧6：回到待机

**帧数标准：**
- 每武器类型6帧，共6个攻击动画
- 帧率：30fps
- 循环方式：单次
- 攻击时长：0.2秒

---

#### 5.1.4 Skill（技能）- 每个技能 × 12帧

**技能动画12帧：**
- 帧1-2：起手蓄力
- 帧3-4：能量聚集
- 帧5-6：释放前兆
- 帧7-8：技能释放
- 帧9-10：效果持续
- 帧11-12：收招结束

**帧数标准：**
- 每技能12帧，共20个技能动画
- 帧率：30fps
- 循环方式：单次
- 技能时长：0.4秒

---

#### 5.1.5 Hit（受击）- 3帧

**受击动画3帧：**
- 帧1：正常姿势
- 帧2：受击后仰，表情痛苦
- 帧3：恢复姿势

**帧数标准：**
- 共1个受击动画
- 帧率：30fps
- 循环方式：单次
- 受击时长：0.1秒

---

#### 5.1.6 Die（死亡）- 6帧

**死亡动画6帧：**
- 帧1：正常姿势
- 帧2：受击后仰
- 帧3：跪地
- 帧4：倒地
- 帧5：躺平
- 帧6：消失/留下尸体

**帧数标准：**
- 共1个死亡动画
- 帧率：30fps
- 循环方式：单次（最后一帧停留）
- 死亡时长：0.2秒

---

### 5.2 特效动画

#### 5.2.1 帧率标准

**30fps标准：**
- 角色动画
- UI特效
- 环境特效（雨、雪、风）

**60fps标准：**
- 技能特效
- 战斗特效
- 高品质过场动画

---

#### 5.2.2 循环方式

**单次（Once）：**
- 攻击动画
- 技能动画
- 受击动画
- 死亡动画
- UI点击特效

**循环（Loop）：**
- 待机动画
- 行走动画
- 环境特效（雨、雪、风）
- 持续技能特效

**Ping-Pong：**
- 某些待机动画
- 呼吸效果
- 光效闪烁

---

## 六、风格指南

### 6.1 水墨风格规范

#### 6.1.1 笔触类型

**干笔（Dry Brush）：**
- 用于：山石、树皮、粗糙纹理
- 特点：笔触干涩，飞白明显
- 效果：苍劲有力，古朴厚重

**湿笔（Wet Brush）：**
- 用于：云雾、水面、柔软物体
- 特点：笔触湿润，晕染自然
- 效果：空灵飘逸，柔和流畅

**飞白（Flying White）：**
- 用于：速度线、剑气、动态效果
- 特点：笔触快速，留白明显
- 效果：动感十足，速度感强

**渲染（Wash）：**
- 用于：背景、氛围、光影
- 特点：大面积晕染，层次分明
- 效果：深远空灵，意境悠长

---

#### 6.1.2 墨色层次

**焦墨（Burnt Ink）：**
- 浓度：最浓
- 用于：重点勾勒、深色阴影
- RGB参考：#0D0D0D

**浓墨（Thick Ink）：**
- 浓度：浓
- 用于：主体轮廓、重要线条
- RGB参考：#1A1A1A

**重墨（Heavy Ink）：**
- 浓度：中浓
- 用于：次要轮廓、细节描绘
- RGB参考：#333333

**淡墨（Light Ink）：**
- 浓度：淡
- 用于：背景渲染、氛围营造
- RGB参考：#666666

**清墨（Clear Ink）：**
- 浓度：最淡
- 用于：远景、云雾、留白
- RGB参考：#999999

---

#### 6.1.3 留白原则

**留白区域：**
- 天空、云雾
- 水面、雪地
- 人物面部高光
- 武器反光

**留白作用：**
- 增加画面呼吸感
- 突出重点元素
- 营造空灵意境
- 体现水墨韵味

**留白比例：**
- 主体画面：60-70%
- 留白区域：30-40%

---

### 6.2 配色方案

#### 6.2.1 七大门派主题色

| 门派 | 主色RGB | 主色HEX | 辅色RGB | 辅色HEX | 背景RGB | 背景HEX |
|-----|---------|---------|---------|---------|---------|---------|
| 八卦门 | 74,59,107 | #4A3B6B | 201,169,110 | #C9A96E | 45,27,78 | #2D1B4E |
| 花间派 | 201,112,138 | #C9708A | 240,192,64 | #F0C040 | 255,228,225 | #FFE4E1 |
| 红莲教 | 139,32,32 | #8B2020 | 240,192,64 | #F0C040 | 74,0,0 | #4A0000 |
| 那迦派 | 91,58,140 | #5B3A8C | 201,169,110 | #C9A96E | 45,27,78 | #2D1B4E |
| 太极门 | 138,154,170 | #8A9AAA | 201,169,110 | #C9A96E | 112,128,144 | #708090 |
| 雪山派 | 90,138,170 | #5A8AAA | 201,169,110 | #C9A96E | 176,196,222 | #B0C4DE |
| 逍遥派 | 74,138,90 | #4A8A5A | 201,169,110 | #C9A96E | 144,238,144 | #90EE90 |

---

#### 6.2.2 通用UI配色

| 用途 | RGB | HEX | 说明 |
|-----|-----|-----|------|
| 主背景 | 26,26,46 | #1A1A2E | 深色半透明背景 |
| 面板背景 | 22,33,62 | #16213E | 次级面板 |
| 边框 | 201,169,110 | #C9A96E | 金色边框 |
| 高亮 | 240,192,64 | #F0C040 | 悬停、选中态 |
| 文字主色 | 245,240,232 | #F5F0E8 | 正文文字 |
| 文字辅色 | 160,152,136 | #A09888 | 次要说明 |
| HP条 | 192,57,43 | #C0392B | 生命值 |
| MP条 | 41,128,185 | #2980B9 | 内力值 |
| EXP条 | 39,174,96 | #27AE60 | 经验值 |

---

#### 6.2.3 场景氛围配色（四季/昼夜）

**春季：**
- 主色：#90EE90（浅绿）
- 辅色：#FFB6C1（浅粉）
- 氛围：生机勃勃，万物复苏

**夏季：**
- 主色：#228B22（森林绿）
- 辅色：#87CEEB（天蓝）
- 氛围：繁茂旺盛，阳光灿烂

**秋季：**
- 主色：#D2691E（巧克力色）
- 辅色：#FFD700（金色）
- 氛围：丰收成熟，落叶纷飞

**冬季：**
- 主色：#B0C4DE（浅蓝灰）
- 辅色：#FFFFFF（纯白）
- 氛围：寒冷肃穆，银装素裹

**清晨：**
- 主色：#FFD700（金色）
- 辅色：#FFA500（橙色）
- 氛围：朝气蓬勃，希望新生

**正午：**
- 主色：#87CEEB（天蓝）
- 辅色：#FFD700（金色）
- 氛围：明亮热烈，活力四射

**黄昏：**
- 主色：#FF6347（番茄红）
- 辅色：#FFD700（金色）
- 氛围：温暖浪漫，日暮归途

**夜晚：**
- 主色：#191970（深蓝）
- 辅色：#C0C0C0（银色）
- 氛围：神秘幽静，星光璀璨

---

### 6.3 输出规范

#### 6.3.1 文件格式

**角色立绘：**
- 格式：PNG
- 透明背景：是
- 压缩：无损

**场景背景：**
- 格式：JPG（大场景）/ PNG（小场景）
- 透明背景：否
- 压缩：高质量（90%）

**UI元素：**
- 格式：PNG
- 透明背景：是
- 压缩：无损

**特效：**
- 格式：PNG序列帧
- 透明背景：是
- 压缩：无损

**武器/防具：**
- 格式：PNG
- 透明背景：是
- 压缩：无损

---

#### 6.3.2 分辨率标准

**角色立绘：**
- 全身：1024×2048px
- 半身：1024×1024px
- Q版：512×512px

**场景背景：**
- 主城：2048×2048px
- 小镇：1024×1024px
- 野外：1024×1024px

**UI元素：**
- 按钮：120×40px（标准）
- 面板：400×300px（标准）
- 图标：32×32px / 64×64px
- 进度条：200×20px

**特效：**
- 技能特效：512×512px
- 环境特效：1024×1024px
- UI特效：256×256px

**武器/防具：**
- 展示图：512×512px
- 图标：64×64px

**地图瓦片：**
- 标准：256×256px

---

#### 6.3.3 命名规范

**角色命名：**
```
[类型]_[角色名]_[方向/姿势]_[变体].png

示例：
NPC_逍遥子_正面_立绘.png
NPC_韦扬_战斗_特效.png
MOB_山贼_普通_待机.png
```

**场景命名：**
```
[类型]_[地点]_[场景]_[时间].jpg

示例：
SCENE_长安_城门_清晨.jpg
SCENE_洛阳_主街_黄昏.jpg
```

**UI命名：**
```
UI_[元素]_[状态]_[尺寸].png

示例：
UI_按钮_正常_120x40.png
UI_面板_标准_400x300.png
UI_图标_技能_64x64.png
```

**特效命名：**
```
FX_[类型]_[名称]_[帧号].png

示例：
FX_技能_剑气_01.png
FX_环境_雨滴_01.png
```

**武器/防具命名：**
```
[类型]_[名称]_[品质].png

示例：
武器_八卦紫金剑_传说.png
防具_八卦道袍_史诗.png
饰品_混元珠_稀有.png
```

**瓦片命名：**
```
TILE_[地形]_[变体].png

示例：
TILE_草地_01.png
TILE_水面_02.png
```

---

## 附录

### 附录A：颜色参考表

| 颜色名称 | HEX值 | RGB值 | 用途 |
|---------|-------|-------|------|
| 深墨 | #1a1a2e | 26,26,46 | 主背景 |
| 暗蓝 | #16213e | 22,33,62 | 面板背景 |
| 中灰 | #0f3460 | 15,52,96 | 次级面板 |
| 金色 | #c9a96e | 201,169,110 | 边框、标题、重要文字 |
| 亮金 | #f0c040 | 240,192,64 | 悬停、选中态、关键数值 |
| 警示红 | #c0392b | 192,57,43 | HP条、伤害数字、警告提示 |
| 朱砂红 | #e74c3c | 228,76,60 | 朱砂印章、重要标记 |
| 翡翠绿 | #2ecc71 | 46,204,113 | MP条、治疗数字、正面状态 |
| 青蓝 | #3498db | 52,152,219 | 内力条、水系技能、信息提示 |
| 神秘紫 | #9b59b6 | 155,89,182 | 那迦派主题色、稀有物品 |
| 文字白 | #f5f0e8 | 245,240,232 | 正文文字 |
| 辅助灰 | #a09888 | 160,152,136 | 次要说明文字 |

---

### 附录B：门派主题色

| 门派 | 主色 | 辅色 | 背景色调 |
|------|------|------|----------|
| 八卦门 | #4a3b6b 紫黑 | #c9a96e 金 | 紫墨 |
| 花间派 | #c9708a 粉红 | #f0c040 金 | 粉墨 |
| 红莲教 | #8b2020 深红 | #f0c040 金 | 红墨 |
| 那迦派 | #5b3a8c 暗紫 | #c9a96e 金 | 紫墨 |
| 太极门 | #8a9aaa 银灰 | #c9a96e 金 | 灰墨 |
| 雪山派 | #5a8aaa 冰蓝 | #c9a96e 金 | 蓝墨 |
| 逍遥派 | #4a8a5a 翠绿 | #c9a96e 金 | 绿墨 |

---

### 附录C：资产清单

| 资产类型 | 数量 | 说明 |
|---------|------|------|
| 角色立绘 | 200+ | 包括核心NPC、七大门派角色（掌门/弟子/叛徒）、通用NPC模板（10类型×3变体）、敌人角色（6类×3等级） |
| 场景美术 | 150+ | 包括五大城池（5城×5场景）、十六小镇（16镇×3场景）、四十五野外区域（6地形×3变体）、七大门派场景（7派×5场景） |
| 地图瓦片 | 50+ | 包括草地、水、道路、建筑、树木、沙漠、雪地等 |
| UI元素 | 200+ | 包括按钮（4状态）、面板（标题栏/内容区/边框/阴影）、图标（2尺寸）、进度条（3样式） |
| 特效 | 100+ | 包括技能特效（20个）、环境特效（5种）、UI特效（3种） |
| 武器装备 | 150+ | 包括武器（40种）、防具（30种）、饰品（30种） |
| 动画规范 | 50+ | 包括角色动画（6类型）、特效动画（2帧率×3循环方式） |
| **合计** | **900+** | 所有美术资产 |

---

### 附录D：代码实现对照

| 设定项 | 文档设定 | 代码实现 | 对应文件 |
|--------|---------|---------|---------|
| 角色立绘渲染 | 水墨风格角色立绘 | InkCharRenderer 类 | ink_char_renderer.py |
| 场景水墨渲染 | 水墨风格场景/背景 | InkRenderer 类 | ink_renderer.py |
| 地图瓦片渲染 | 7种地形瓦片(256x256) | TileRenderer 类 | tile_renderer.py |
| 门派主题色 | 7派配色方案 | FACTION_COLORS 字典 | ink_renderer.py |
| 特效渲染 | 技能/环境/UI特效 | ParticleSystem + Shader | ink_renderer.py |
| UI纹理 | 面板底纹/按钮装饰 | UI_ASSETS 字典 | ink_renderer.py |

---

**文档结束**

---

> **文档版本**: v3.0 | **最后更新**: 2026-05-19 | **总行数**: 约1450行
> 
> **侠影江湖美术资产Prompt文档 - AI图像生成权威指南**
：** 正午，阳光明媚
- **天气：** 晴朗，无风
- **人流：** 人山人海，摩肩接踵
- **声音：** 叫卖声、马蹄声、孩童嬉笑声

**完整英文Prompt：**
```
Chinese ink wash painting, bustling main street of ancient Chinese capital at noon, wide avenue lined with elegant shops and teahouses, colorful banners and signs, crowds of nobles, merchants, and common people, palanquins and horses passing through, traditional Chinese architecture with curved roofs, wuxia world, elegant composition, vibrant color accents, bright midday lighting, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt：**
```
中国水墨画风格，正午繁华的中国古代都城主街，宽阔大道两旁 elegant 店铺和茶馆， colorful 旗帜和招牌，贵族、商人和平民人群，轿子和马匹穿梭，传统中国建筑配弯曲屋顶，武侠世界，优雅构图，鲜艳色彩点缀，明亮正午光影，杰作，最佳质量，8k，超详细
```

**关键元素列表：**
- 宽阔石板路（必须）
- 两侧店铺（必须）
- 彩色招牌（必须）
- 行人人群（必须）
- 轿子/马匹（必须）
- 茶馆酒肆（可选）
- 街头小贩（可选）

**构图建议：**
- **Camera角度：** 平视，街道延伸感
- **焦点：** 街道中段，人群活动
- **景深：** 前景店铺清晰，中景人群，远景街道消失点

---

**场景3：市集**

**场景氛围描述：**
- **时间：** 上午，热闹喧嚣
- **天气：** 晴朗，微风
- **人流：** 人声鼎沸，讨价还价
- **声音：** 叫卖声、讨价还价声、铜钱碰撞声

**完整英文Prompt：**
```
Chinese ink wash painting, vibrant market square in ancient Chinese capital, crowded stalls selling silk, spices, pottery, and exotic goods, merchants calling out prices, customers bargaining, colorful awnings and banners, traditional Chinese market architecture, wuxia world, elegant composition, multicolor accents, lively morning lighting, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt：**
```
中国水墨画风格，繁华的中国古代都城市集广场，拥挤的摊位售卖丝绸、香料、陶器和 exotic 货物，商人喊价，顾客讨价还价， colorful 遮阳篷和旗帜，传统中国市集建筑，武侠世界，优雅构图，多彩点缀，热闹晨光，杰作，最佳质量，8k，超详细
```

**关键元素列表：**
- 摊位林立（必须）
- 各色货物（必须）
- 讨价还价的人群（必须）
- 铜钱交易（必须）
- 遮阳篷（可选）
- 货郎担（可选）

**构图建议：**
- **Camera角度：** 俯视角度，展现市集全貌
- **焦点：** 市集中心，人群聚集处
- **景深：** 整体清晰，展现热闹氛围

---

**场景4：官府**

**场景氛围描述：**
- **时间：** 午后，庄严肃穆
- **天气：** 晴朗，无风
- **人流：** 稀疏，办事百姓
- **声音：** 击鼓声、衙役呵斥声、低语声

**完整英文Prompt：**
```
Chinese ink wash painting, imposing government office in ancient Chinese capital, grand hall with official seals and scrolls, stone drum for complaints, stern officials in formal robes, commoners waiting nervously, traditional Chinese government architecture with high steps, wuxia world, elegant composition, red and black accents, solemn afternoon lighting, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt：**
```
中国水墨画风格，威严的中国古代都城官府，宏伟厅堂配官印和卷轴，石鼓用于鸣冤，严厉官员穿正式长袍，平民紧张等待，传统中国官府建筑配高台阶，武侠世界，优雅构图，红黑点缀，庄严午后光影，杰作，最佳质量，8k，超详细
```

**关键元素列表：**
- 官府大门（必须）
- 鸣冤鼓（必须）
- 衙役（必须）
- 办事百姓（必须）
- 官印/匾额（可选）
- 石狮子（可选）

**构图建议：**
- **Camera角度：** 正面平视，展现官府威严
- **焦点：** 官府大门，鸣冤鼓
- **景深：** 前景百姓，中景官府，远景天空

---

**场景5：特色地点-大明宫**

**场景氛围描述：**
- **时间：** 黄昏，夕阳西下
- **天气：** 晴朗，微风
- **人流：** 稀少，宫中侍卫
- **声音：** 风声、远处钟声、侍卫脚步声

**完整英文Prompt：**
```
Chinese ink wash painting, magnificent imperial palace Daming Palace at sunset, grand golden-roofed halls on elevated platforms, marble staircases, imperial guards standing at attention, evening light painting everything in golden hues, traditional Chinese imperial architecture, wuxia world, elegant composition, gold and vermilion accents, golden hour lighting, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt：**
```
中国水墨画风格，黄昏壮丽的大明宫，宏伟金顶大殿在高台上，大理石阶梯，御林军立正守卫，夕阳光将一切染成金色，传统中国帝国建筑，武侠世界，优雅构图，金朱红点缀，黄金时刻光影，杰作，最佳质量，8k，超详细
```

**关键元素列表：**
- 金顶大殿（必须）
- 大理石阶梯（必须）
- 御林军（必须）
- 宫墙（必须）
- 华表（可选）
- 日晷（可选）

**构图建议：**
- **Camera角度：** 低角度仰视，突出宫殿宏伟
- **焦点：** 金顶大殿，夕阳映照
- **景深：** 前景阶梯，中景大殿，远景夕阳

---

#### 2.1.2 洛阳（战火之城）

**场景1：城门**

**场景氛围描述：**
- **时间：** 黄昏，夕阳西下
- **天气：** 阴沉，硝烟弥漫
- **人流：** 稀少，逃难百姓
- **声音：** 远处战鼓、哭喊声、风声

**完整英文Prompt：**
```
Chinese ink wash painting, damaged city gate of war-torn ancient Chinese city at dusk, broken vermilion gates with burn marks, crumbling stone walls with battle scars, refugees fleeing through, smoke rising in distance, somber atmosphere, traditional Chinese architecture damaged by war, wuxia war scene, elegant composition, gray and vermilion accents, somber dusk lighting, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt：**
```
中国水墨画风格，黄昏战火摧残的中国古代城市破损城门，朱红色大门带烧伤痕迹，崩塌石墙配战斗伤疤，难民逃窜，远处硝烟升起，阴郁气氛，传统中国建筑被战争损坏，武侠战争场景，优雅构图，灰朱红点缀，阴郁黄昏光影，杰作，最佳质量，8k，超详细
```

**关键元素列表：**
- 破损城门（必须）
- 战斗痕迹（必须）
- 逃难百姓（必须）
- 硝烟（必须）
- 断壁残垣（可选）
- 遗弃武器（可选）

**构图建议：**
- **Camera角度：** 平视，展现破败感
- **焦点：** 破损城门，难民
- **景深：** 前景难民，中景城门，远景硝烟

---

**场景2：主街**

**场景氛围描述：**
- **时间：** 午后，阴沉
- **天气：** 阴天，硝烟弥漫
- **人流：** 稀少，士兵巡逻
- **声音：** 脚步声、远处炮火、乌鸦叫声

**完整英文Prompt：**
```
Chinese ink wash painting, deserted main street of war-torn ancient Chinese city, damaged buildings with boarded windows, military patrols marching, scattered debris and abandoned belongings, smoke drifting through empty streets, tense atmosphere, traditional Chinese architecture showing war damage, wuxia war scene, elegant composition, gray and brown accents, gloomy lighting, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt：**
```
中国水墨画风格，战火摧残的中国古代城市 deserted 主街，受损建筑配封板窗户，军队巡逻 march，散落的 debris 和遗弃物品，烟雾 drift 过空街，紧张气氛，传统中国建筑显示战争 damage，武侠战争场景，优雅构图，灰棕点缀，阴郁光影，杰作，最佳质量，8k，超详细
```

**关键元素列表：**
- 受损建筑（必须）
- 巡逻士兵（必须）
- 散落 debris（必须）
- 硝烟（必须）
- 封板窗户（可选）
- 遗弃物品（可选）

**构图建议：**
- **Camera角度：** 平视，街道纵深感
- **焦点：** 街道中段，士兵巡逻
- **景深：** 前景 debris，中景士兵，远景硝烟

---

**场景3：市集**

**场景氛围描述：**
- **时间：** 上午，阴沉
- **天气：** 阴天，微雨
- **人流：** 稀少，黑市交易
- **声音：** 低声交易、风声、远处炮火

**完整英文Prompt：**
```
Chinese ink wash painting, black market in war-torn ancient Chinese city, secretive traders in shadows, rare goods and weapons exchanged, nervous atmosphere, damaged market stalls, rain beginning to fall, traditional Chinese market in wartime, wuxia war scene, elegant composition, dark gray accents, moody lighting, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt：**
```
中国水墨画风格，战火摧残的中国古代城市黑市，阴影中 secretive 交易者， rare 货物和武器交换，紧张气氛，受损市场摊位，开始下雨，战时传统中国市集，武侠战争场景，优雅构图，深灰点缀， moody 光影，杰作，最佳质量，8k，超详细
```

**关键元素列表：**
- 黑市交易者（必须）
- 武器货物（必须）
- 阴影环境（必须）
- 受损摊位（必须）
- 雨滴（可选）
- 暗号手势（可选）

**构图建议：**
- **Camera角度：** 俯视角度，展现黑市全貌
- **焦点：** 黑市中心，交易场景
- **景深：** 整体偏暗，突出秘密氛围

---

**场景4：官府**

**场景氛围描述：**
- **时间：** 午后，阴沉
- **天气：** 阴天，硝烟弥漫
- **人流：** 军事人员
- **声音：** 命令声、脚步声、远处炮火

**完整英文Prompt：**
```
Chinese ink wash painting, military commandeered government office in war-torn city, soldiers standing guard, military officials planning strategy, maps and documents spread on tables, tense atmosphere, traditional Chinese government building under military control, wuxia war scene, elegant composition, military gray accents, serious lighting, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt：**
```
中国水墨画风格，战火摧残城市中被军方征用的官府，士兵站岗，军官策划战略，地图和文件 spread 在桌上，紧张气氛，军方控制下的传统中国官府建筑，武侠战争场景，优雅构图，军灰点缀，严肃光影，杰作，最佳质量，8k，超详细
```

**关键元素列表：**
- 军事人员（必须）
- 战略地图（必须）
- 士兵站岗（必须）
- 紧张气氛（必须）
- 军事装备（可选）
- 命令文书（可选）

**构图建议：**
- **Camera角度：** 正面平视，展现军事控制
- **焦点：** 军事官员，战略地图
- **景深：** 前景士兵，中景官员，远景建筑

---

**场景5：特色地点-白马寺（改作医院）**

**场景氛围描述：**
- **时间：** 黄昏，夕阳西下
- **天气：** 阴沉，微雨
- **人流：** 伤兵、医者
- **声音：** 呻吟声、医者的低语、雨声

**完整英文Prompt：**
```
Chinese ink wash painting, White Horse Temple converted to military hospital at dusk, ancient Buddhist architecture with medical equipment, wounded soldiers on cots, healers tending injuries, incense mixing with medicine smell, somber atmosphere, traditional Chinese temple serving as wartime hospital, wuxia war scene, elegant composition, gray and saffron accents, somber evening lighting, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt：**
```
中国水墨画风格，黄昏白马寺改作军医院，古老佛教建筑配医疗设备，伤兵躺在病床上，医者照料伤势， incense 混合药味，阴郁气氛，传统中国寺庙作为战时医院，武侠战争场景，优雅构图，灰藏红点缀，阴郁黄昏光影，杰作，最佳质量，8k，超详细
```

**关键元素列表：**
- 寺庙建筑（必须）
- 伤兵病床（必须）
- 医者（必须）
- 医疗设备（必须）
- 佛像（可选）
- 药草（可选）

**构图建议：**
- **Camera角度：** 室内平视，展现医院场景
- **焦点：** 伤兵，医者
- **景深：** 前景病床，中景医者，远景佛像

---

#### 2.1.3 临安（繁华之都）

**场景1：城门**

**场景氛围描述：**
- **时间：** 清晨，薄雾
- **天气：** 晴朗，微风
- **人流：** 熙熙攘攘，商船入港
- **声音：** 船工号子、叫卖声、水声

**完整英文Prompt：**
```
Chinese ink wash painting, water city gate of ancient Chinese capital at dawn, grand stone archway over canal, boats passing through, morning mist rising from water, merchants unloading goods, traditional Chinese water city architecture, wuxia world, elegant composition, blue and gray accents, misty morning lighting, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt：**
```
中国水墨画风格，清晨中国古代都城水城城门，宏伟石拱门横跨运河，船只穿梭，晨雾从水面升起，商人卸货，传统中国水城建筑，武侠世界，优雅构图，蓝灰点缀，雾蒙蒙晨光，杰作，最佳质量，8k，超详细
```

**关键元素列表：**
- 水城城门（必须）
- 运河船只（必须）
- 商船货物（必须）
- 晨雾（必须）
- 石拱桥（可选）
- 水车（可选）

**构图建议：**
- **Camera角度：** 平视，展现水城特色
- **焦点：** 水城城门，船只
- **景深：** 前景水面，中景城门，远景晨雾

---

**场景2：主街**

**场景氛围描述：**
- **时间：** 正午，阳光明媚
- **天气：** 晴朗，微风
- **人流：** 人山人海，摩肩接踵
- **声音：** 叫卖声、船工号子、水声

**完整英文Prompt：**
```
Chinese ink wash painting, bustling water street of ancient Chinese capital at noon, canal-side avenue with elegant shops, stone bridges crossing water, colorful boats docked, crowds of scholars and merchants, traditional Chinese water city architecture, wuxia world, elegant composition, blue and green accents, bright midday lighting, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt：**
```
中国水墨画风格，正午繁华的中国古代都城水街，运河边大道配 elegant 店铺，石桥横跨水面， colorful 船只 docked，学者和商人 crowd，传统中国水城建筑，武侠世界，优雅构图，蓝绿点缀，明亮正午光影，杰作，最佳质量，8k，超详细
```

**关键元素列表：**
- 水街（必须）
- 石桥（必须）
- 店铺（必须）
- 人群（必须）
- 船只（可选）
- 水车（可选）

**构图建议：**
- **Camera角度：** 平视，街道延伸感
- **焦点：** 街道中段，石桥
- **景深：** 前景店铺，中景石桥，远景街道

---

**场景3：市集**

**场景氛围描述：**
- **时间：** 上午，热闹喧嚣
- **天气：** 晴朗，微风
- **人流：** 人声鼎沸，讨价还价
- **声音：** 叫卖声、讨价还价声、水声

**完整英文Prompt：**
```
Chinese ink wash painting, floating market in ancient Chinese water city, boats serving as market stalls, vendors selling fresh fish and produce, customers on boats and shore, colorful awnings over water, traditional Chinese floating market, wuxia world, elegant composition, blue and multicolor accents, lively morning lighting, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt：**
```
中国水墨画风格，中国古代水城 floating 市集，船只作为市场摊位， vendors 售卖鲜鱼农产品，顾客在船上和岸上， colorful 遮阳篷 over 水面，传统中国 floating 市集，武侠世界，优雅构图，蓝多彩点缀，热闹晨光，杰作，最佳质量，8k，超详细
```

**关键元素列表：**
- 船只摊位（必须）
- 水上交易（必须）
- 鲜鱼货物（必须）
- 人群（必须）
- 遮阳篷（可选）
- 水车（可选）

**构图建议：**
- **Camera角度：** 俯视角度，展现水上市场全貌
- **焦点：** 市场中心，水上交易
- **景深：** 整体清晰，展现热闹氛围

---

**场景4：官府**

**场景氛围描述：**
- **时间：** 午后，庄严肃穆
- **天气：** 晴朗，微风
- **人流：** 稀疏，办事百姓
- **声音：** 击鼓声、衙役呵斥声、水声

**完整英文Prompt：**
```
Chinese ink wash painting, elegant government office in ancient Chinese water city, grand hall overlooking canal, stone drum for complaints, officials in refined robes, traditional Chinese water city government architecture, wuxia world, elegant composition, blue and red accents, serene afternoon lighting, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt：**
```
中国水墨画风格， elegant 的中国古代水城官府，宏伟厅堂 overlooking 运河，石鼓用于鸣冤， refined 长袍官员，传统中国水城官府建筑，武侠世界，优雅构图，蓝红点缀，宁静午后光影，杰作，最佳质量，8k，超详细
```

**关键元素列表：**
- 官府建筑（必须）
- 运河景观（必须）
- 石鼓（必须）
- 官员（必须）
- 石桥（可选）
- 水车（可选）

**构图建议：**
- **Camera角度：** 正面平视，展现官府威严
- **焦点：** 官府大门，运河景观
- **景深：** 前景官府，中景运河，远景城市

---

**场景5：特色地点-西湖**

**场景氛围描述：**
- **时间：** 黄昏，夕阳西下
- **天气：** 晴朗，微风
- **人流：** 稀少，赏景文人
- **声音：** 风声、远处琴声、水声

**完整英文Prompt：**
```
Chinese ink wash painting, West Lake at sunset in ancient Chinese water city, calm waters reflecting golden sky, elegant pagoda on island, willow trees along shore, scholars in boats enjoying scenery, traditional Chinese landscape, wuxia world, elegant composition, gold and blue accents, golden hour lighting, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt：**
```
中国水墨画风格，黄昏中国古代水城西湖，平静水面 reflecting 金色天空， elegant 塔在岛上，柳树 along 岸边，学者在船上赏景，传统中国 landscape，武侠世界，优雅构图，金蓝点缀，黄金时刻光影，杰作，最佳质量，8k，超详细
```

**关键元素列表：**
- 西湖水面（必须）
- 雷峰塔（必须）
- 柳树（必须）
- 游船（必须）
- 断桥（可选）
- 荷花（可选）

**构图建议：**
- **Camera角度：** 平视，展现湖光山色
- **焦点：** 湖面，雷峰塔
- **景深：** 前景柳树，中景湖面，远景塔影

---

#### 2.1.4 敦煌（边塞之城）

**场景1：城门**

**场景氛围描述：**
- **时间：** 正午，烈日当空
- **天气：** 晴朗，风沙
- **人流：** 商旅驼队，络绎不绝
- **声音：** 驼铃声、风沙声、叫卖声

**完整英文Prompt：**
```
Chinese ink wash painting, desert oasis city gate at noon, massive earthen walls with watchtowers, camel caravans passing through, sand dunes surrounding, hot desert wind blowing, Silk Road merchants from many lands, mixed Chinese and Central Asian architecture, wuxia world, elegant composition, gold and brown accents, harsh desert lighting, masterpiece, best quality, 8k, ultra detailed
```

**完整中文Prompt：**
```
中国水墨画风格，正午沙漠绿洲城市城门，巨大土墙配瞭望塔，骆驼商队穿梭，周围沙丘，炎热沙漠风吹拂，来自多地的丝路商人，中国和中亚混合建筑，武侠世界，优雅构图，金棕点缀，强烈沙漠光影，杰作，最佳质量，8k，超详细
```

**关键元素列表：**
- 土城城门（必须）
- 骆驼商队（必须）
- 沙丘（必须）
- 瞭望塔（必须）
- 异域商人（可选）
- 风沙（可选）

**构图建议：**
- **Camera角度：** 平视，展现边塞风光
- **焦点：** 城门，骆驼商队
- **景深：** 前景沙丘，中景城门，远景沙漠

---

**场景2：主街**

**场景氛围描述：**
- **时间
