extends Control

signal character_created(player_data)

var player_name = ""
var player_gender = "male"
var player_faction = ""
var attribute_points = 20
var attributes = {
    "strength": 10,
    "dexterity": 10,
    "intelligence": 10,
    "constitution": 10
}
var factions = ["无门无派", "八卦门", "花间派", "红莲教", "那迦派", "太极门", "雪山派"]

func _ready():
    _setup_faction_buttons()
    _update_ui()

    $BottomPanel/Back.pressed.connect(_on_back)
    $BottomPanel/Confirm.pressed.connect(_on_confirm)

    $LeftPanel/GenderButtons/Male.pressed.connect(func(): _set_gender("male"))
    $LeftPanel/GenderButtons/Female.pressed.connect(func(): _set_gender("female"))

    $RightPanel/Strength/StrMinus.pressed.connect(func(): _adjust_attr("strength", -1))
    $RightPanel/Strength/StrPlus.pressed.connect(func(): _adjust_attr("strength", 1))
    $RightPanel/Dexterity/DexMinus.pressed.connect(func(): _adjust_attr("dexterity", -1))
    $RightPanel/Dexterity/DexPlus.pressed.connect(func(): _adjust_attr("dexterity", 1))
    $RightPanel/Intelligence/IntMinus.pressed.connect(func(): _adjust_attr("intelligence", -1))
    $RightPanel/Intelligence/IntPlus.pressed.connect(func(): _adjust_attr("intelligence", 1))
    $RightPanel/Constitution/ConMinus.pressed.connect(func(): _adjust_attr("constitution", -1))
    $RightPanel/Constitution/ConPlus.pressed.connect(func(): _adjust_attr("constitution", 1))

func _setup_faction_buttons():
    for faction in factions:
        var btn = Button.new()
        btn.text = faction
        btn.pressed.connect(func(): _set_faction(faction))
        $LeftPanel/FactionButtons.add_child(btn)

func _set_gender(g):
    player_gender = g

func _set_faction(f):
    player_faction = f

func _adjust_attr(attr_name, delta):
    if delta > 0 and attribute_points > 0 and attributes[attr_name] < 30:
        attributes[attr_name] += 1
        attribute_points -= 1
    elif delta < 0 and attributes[attr_name] > 1:
        attributes[attr_name] -= 1
        attribute_points += 1
    _update_ui()

func _update_ui():
    $RightPanel/AttrPoints.text = "剩余点数: %d" % attribute_points
    $RightPanel/Strength/Value.text = str(attributes["strength"])
    $RightPanel/Dexterity/Value.text = str(attributes["dexterity"])
    $RightPanel/Intelligence/Value.text = str(attributes["intelligence"])
    $RightPanel/Constitution/Value.text = str(attributes["constitution"])

func _on_back():
    get_tree().change_scene_to_file("res://scenes/menu/menu.tscn")

func _on_confirm():
    var name = $LeftPanel/NameInput.text.strip_edges()
    if name.is_empty():
        name = "无名侠客"

    var faction_id = ""
    match player_faction:
        "八卦门": faction_id = "bagua"
        "花间派": faction_id = "flower"
        "红莲教": faction_id = "honglian"
        "那迦派": faction_id = "naja"
        "太极门": faction_id = "taiji"
        "雪山派": faction_id = "xueshan"
        _: faction_id = "none"

    var player_data = PlayerData.new()
    player_data.player_name = name
    player_data.level = 1
    player_data.gold = 100
    player_data.strength = attributes["strength"]
    player_data.dexterity = attributes["dexterity"]
    player_data.intelligence = attributes["intelligence"]
    player_data.constitution = attributes["constitution"]
    player_data.faction = faction_id
    player_data.current_zone = "pingan_town"
    player_data.position = Vector2(100, 100)

    emit_signal("character_created", player_data)
    get_tree().change_scene_to_file("res://scenes/game_world/game_world.tscn")
