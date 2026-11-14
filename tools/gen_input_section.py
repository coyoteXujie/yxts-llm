#!/usr/bin/env python3
"""Generate the [input] section for project.godot from a Python action map."""
import sys
import os

KEY_MAP = {
    "W": 87, "A": 65, "S": 83, "D": 68,
    "T": 84, "E": 69, "F": 70, "B": 66,
    "J": 74, "K": 75, "M": 77,
    "UP": 4194320, "DOWN": 4194322,
    "LEFT": 4194319, "RIGHT": 4194321,
    "ENTER": 4194309, "ESCAPE": 4194305,
    "F5": 4194341, "F9": 4194345,
}

ACTIONS = [
    ("move_up",      ["W", "UP"]),
    ("move_down",    ["S", "DOWN"]),
    ("move_left",    ["A", "LEFT"]),
    ("move_right",   ["D", "RIGHT"]),
    ("interact",     ["T", "ENTER"]),
    ("enter_area",   ["E"]),
    ("attack",       ["F"]),
    ("inventory",    ["B"]),
    ("journal",      ["J"]),
    ("cultivation",  ["K"]),
    ("world_map",    ["M"]),
    ("quick_save",   ["F5"]),
    ("quick_load",   ["F9"]),
    ("ui_cancel",    ["ESCAPE"]),
]


def event_str(physical_keycode: int) -> str:
    return (
        'Object(InputEventKey,'
        '"resource_local_to_scene":false,'
        '"resource_name":"",'
        '"device":-1,'
        '"window_id":0,'
        '"alt_pressed":false,'
        '"shift_pressed":false,'
        '"ctrl_pressed":false,'
        '"meta_pressed":false,'
        '"pressed":false,'
        '"keycode":0,'
        f'"physical_keycode":{physical_keycode},'
        '"key_label":0,'
        '"unicode":0,'
        '"echo":false,'
        '"script":null)'
    )


def gen_input_section() -> str:
    lines = ["[input]", ""]
    for action_name, keys in ACTIONS:
        events = ", ".join(event_str(KEY_MAP[k]) for k in keys)
        lines.append(f'{action_name}={{')
        lines.append('"deadzone": 0.5,')
        lines.append(f'"events": [{events}]')
        lines.append("}")
        lines.append("")
    return "\n".join(lines)


def main() -> int:
    project_godot = os.path.join(
        os.path.dirname(__file__), "..", "godot_project", "project.godot"
    )
    project_godot = os.path.normpath(project_godot)

    with open(project_godot, "r", encoding="utf-8") as f:
        content = f.read()

    if "[input]" in content:
        print("[input] section already exists, aborting.", file=sys.stderr)
        return 1

    input_section = gen_input_section()
    content = content.rstrip() + "\n\n" + input_section

    with open(project_godot, "w", encoding="utf-8") as f:
        f.write(content)

    print(f"Added [input] section with {len(ACTIONS)} actions to {project_godot}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
