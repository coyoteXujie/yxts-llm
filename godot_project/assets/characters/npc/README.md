# Legacy NPC Art Assets

The current map actor uses generated, uniform map sprites from `assets/characters/generated_map_sprites/`. Those sprites are produced by `tools/generate_godot_art_assets.py` and mapped through `data/npc_sprite_assets.json`.

Current dialogue portraits are generated under `assets/characters/npc/portraits/` and mapped through `data/npc_portrait_assets.json`.

The individual PNG files in this folder are the older atlas-split art library. They are kept for later high-detail portraits, character sheets, battle poses, or optional per-NPC overrides.

Source atlases live in `atlases/`:

- `npc_town_core_atlas.png`: 平阿四、店小二、阿青、老夫子、捕快、村长、道德和尚、铁匠
- `npc_masters_core_atlas.png`: 韦扬、清照、清虚道人、白瑞德、大侠
- `npc_enemies_core_atlas.png`: 流氓、流氓头、采花大盗、神秘人
- `npc_town_extended_atlas.png`: 阎商、葛朗台、厨师、屠夫、卖花女、小商贩、平一指、何铁手、何喜、小裁缝、何裁缝、李白
- `npc_sects_extended_atlas.png`: 于红儒、方长老、楚红灯、崇儿、钟央、十三卫、美奈子、浪人甲、简明、简杰、红拂女、隐娘
- `npc_sects_enemies_extended_atlas.png`: 古松道人、仓月道人、采药道人、知客道人、史婆婆、万剑、万刃、阿秀、雪千柔、独角大盗、黑衣大盗、魔化和尚

Regenerate individual sprites with:

```bash
conda run -n yxts python tools/split_npc_atlas.py
```
