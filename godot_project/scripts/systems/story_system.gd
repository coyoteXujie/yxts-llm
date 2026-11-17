extends RefCounted
class_name StorySystem

var _state: Node

func _init(state: Node) -> void:
	_state = state

const DAODE_MIN := -100
const DAODE_MAX := 100
const DAODE_TIER_LABELS := {
	3: "正气凛然",
	2: "侠义心肠",
	1: "行事端正",
	0: "中立",
	-1: "行事偏激",
	-2: "歹毒狠辣",
	-3: "罪大恶极"
}
const NPC_ATTITUDE_TABLE := {
	"good": ["极度友好", "友好", "客气", "中立", "警惕", "敌视", "追杀"],
	"evil": ["敌视", "警惕", "中立", "客气", "友好", "极度友好", "崇拜"],
	"neutral": ["尊敬", "客气", "正常", "正常", "警惕", "畏惧", "恐惧"]
}

const STORY_CHOICE_DEFINITIONS := [
	{
		"id": "choice_conclave_public",
		"group": "conclave_path",
		"flag": "story_conclave_public",
		"npcs": ["苏梦瑶", "太极真人"],
		"title": "公开断令",
		"description": "把断令证据交给七派公开夜议，换取正道信任，但也会惊动暗影司。",
		"requires_completed": ["q_main_broken_token"],
		"blocks_completed": ["q_main_wulin_conclave"],
		"region_id": "luoyang",
		"event_title": "断令公议",
		"event_description": "你主张公开断令证据，七派可信之人开始以明面名义聚拢。",
		"memory": "你主张公开断令证据，愿把七派信任放在明处。",
		"daode": 4,
		"money": 0,
		"items": {}
	},
	{
		"id": "choice_conclave_secret",
		"group": "conclave_path",
		"flag": "story_conclave_secret",
		"npcs": ["苏梦瑶", "陈天行"],
		"title": "暗查旧账",
		"description": "暂不公开断令，先沿苏家旧账暗查暗影司线人，可少惊动敌人但会让七派疑心更重。",
		"requires_completed": ["q_main_broken_token"],
		"blocks_completed": ["q_main_wulin_conclave"],
		"region_id": "changan",
		"event_title": "旧账暗查",
		"event_description": "你决定暂压断令，借陈天行旧账暗查暗影司线人。",
		"memory": "你选择暂压断令，沿苏家旧账暗中追查。",
		"daode": 1,
		"money": 80,
		"items": {"item_shengji": 1}
	},
	{
		"id": "choice_conclave_betray",
		"group": "conclave_path",
		"flag": "story_conclave_betray",
		"npcs": ["赵无极", "陈天行"],
		"title": "倒戈投敌",
		"description": "把断令证据私下交给暗影司线人，换取功法与银两，七派信任就此断裂。",
		"requires_completed": ["q_main_broken_token"],
		"blocks_completed": ["q_main_wulin_conclave"],
		"region_id": "changan",
		"event_title": "倒戈投敌",
		"event_description": "你把断令证据暗送暗影司，换得一笔横财与一门邪功，七派明面上的信任再无从谈起。",
		"memory": "你选择倒戈投敌，把断令证据卖给了暗影司。",
		"daode": -10,
		"money": 300,
		"items": {"item_shengji": 2}
	},
	{
		"id": "choice_epilogue_mercy",
		"group": "epilogue_path",
		"flag": "story_epilogue_mercy",
		"npcs": ["苏梦瑶", "太极真人"],
		"title": "清算有度",
		"description": "封存旧案后只清点首恶和暗线证据，给被胁迫的小人物留一条改过路。",
		"requires_completed": ["q_main_old_case_closure"],
		"blocks_completed": ["q_main_epilogue_mercy", "q_main_epilogue_reckoning"],
		"region_id": "luoyang",
		"event_title": "清算有度",
		"event_description": "你决定把旧案清算压在首恶与铁证上，七派开始收束余波而不是扩大仇怨。",
		"memory": "你选择清算有度，愿给被胁迫的人留一条回头路。",
		"daode": 8,
		"money": 0,
		"items": {"item_dan": 1}
	},
	{
		"id": "choice_epilogue_reckoning",
		"group": "epilogue_path",
		"flag": "story_epilogue_reckoning",
		"npcs": ["陈天行", "赵无极"],
		"title": "追剿残影",
		"description": "趁暗影司总坛新破继续清剿残部，换来更干净的江湖，但会把许多旧怨翻到明面。",
		"requires_completed": ["q_main_old_case_closure"],
		"blocks_completed": ["q_main_epilogue_mercy", "q_main_epilogue_reckoning"],
		"region_id": "changan",
		"event_title": "追剿残影",
		"event_description": "你决定趁势追剿暗影司残部，武林盟与几路暗线开始连夜清查。",
		"memory": "你选择追剿残影，宁可翻出旧怨也不让暗影司残部蛰伏。",
		"daode": 2,
		"money": 160,
		"items": {"item_shengji": 1}
	},
	{
		"id": "choice_epilogue_massacre",
		"group": "epilogue_path",
		"flag": "story_epilogue_massacre",
		"npcs": ["赵无极", "陈天行"],
		"title": "赶尽杀绝",
		"description": "不分首恶从犯，连同知情百姓一并灭口，永绝后患，但血债累累。",
		"requires_completed": ["q_main_old_case_closure"],
		"blocks_completed": ["q_main_epilogue_mercy", "q_main_epilogue_reckoning"],
		"region_id": "changan",
		"event_title": "赶尽杀绝",
		"event_description": "你下令连根拔起，知情者无论首从一并灭口，江湖一时噤声，血债却记在了你头上。",
		"memory": "你选择赶尽杀绝，连知情百姓也不放过。",
		"daode": -15,
		"money": 400,
		"items": {"item_dan": 2, "item_shengji": 1}
	}
]

const ENDING_DEFINITIONS := [
	{
		"id": "ending_justice",
		"title": "正义结局 · 武林盟主",
		"description": "你正气凛然，号令群雄。七派共推你为武林盟主，断令旧案在你手中收束，受万人敬仰，江湖恩怨就此翻过新的一页。",
		"epitaph": "正气长存，盟印在手。"
	},
	{
		"id": "ending_righteous",
		"title": "正派结局 · 一代大侠",
		"description": "你侠义心肠，行走江湖多年，名垂青史。七派以礼相待，百姓传颂你的名号，旧案的余烬终成你侠名的一笔注脚。",
		"epitaph": "侠名远播，青史留痕。"
	},
	{
		"id": "ending_neutral",
		"title": "中立结局 · 隐士高人",
		"description": "你不偏不倚，亦正亦邪，最终选择归隐山林。江湖恩怨与你再无干系，你成了传说中那位逍遥自在的隐士高人。",
		"epitaph": "逍遥物外，不系名利。"
	},
	{
		"id": "ending_dark",
		"title": "邪派结局 · 魔教教主",
		"description": "你行事歹毒，威震江湖，终于坐上魔教教主的宝座。七派对你又恨又惧，暗影司残部尽归你手，江湖一时噤声。",
		"epitaph": "魔焰滔天，教令如山。"
	},
	{
		"id": "ending_evil",
		"title": "邪恶结局 · 武林公敌",
		"description": "你罪大恶极，血债累累，七派联手发出追杀令，你成了武林公敌。纵然一时得势，终究难逃群起而攻的结局。",
		"epitaph": "千夫所指，百死难赎。"
	},
	{
		"id": "ending_court",
		"title": "朝廷结局 · 鹰犬之途",
		"description": "你投效朝廷，成了江湖中的暗桩。六扇门的令牌在手，绿林好汉见你色变，七派对你又恨又忌。江湖的规矩，终究让位于庙堂的律令。",
		"epitaph": "铁令在手，江湖低头。"
	},
	{
		"id": "ending_merchant",
		"title": "商贾结局 · 富甲一方",
		"description": "你放下刀剑，操持算盘。商队遍及南北，银号开遍州府，连七派也要向你借银度日。江湖人提起你，先想到的不是武功，而是那间挂着你招牌的天下第一庄。",
		"epitaph": "银两过手，天下入彀。"
	},
	{
		"id": "ending_grandmaster",
		"title": "宗师结局 · 开宗立派",
		"description": "你穷毕生之力参悟武道，所习功法皆臻化境。你开宗立派，广收门徒，自成一脉。后世论及武学源流，皆以你这一代为分水岭，你的拳经剑谱被奉为圭臬。",
		"epitaph": "一脉开宗，百代师表。"
	}
]
const CONTEXTUAL_DIALOGUES := {
	"苏梦瑶": [
		{
			"after": "q_intro_town",
			"lines": [
				"平安镇的青石板路我走过很多次，但从没在这里找到过苏家的消息。",
				"你若愿意帮我追查洛阳旧案，花间派不会亏待你。",
				"别急，先在镇上站稳脚跟——江湖的事，不是一天能翻完的。"
			]
		},
		{
			"after": "q_clear_thugs",
			"lines": [
				"镇东的事我听说了一些——你出手很快，但那几个恶徒不过是冰山一角。",
				"背后的线还在暗处，你若想往下查，先留意洛阳方向的消息。",
				"花间派在洛阳有人，你若有需要，我可以替你递一句话。"
			]
		},
		{
			"after": "q_main_luoyang_ashes",
			"lines": [
				"洛阳旧火的线索总算有了着落，多亏你肯追查。",
				"母亲留下的玉佩花纹和断令对上了，这绝不是巧合。",
				"暗影司的人不会善罢甘休，你接下来要小心水路。"
			]
		},
		{
			"after": "q_main_after_shadow",
			"lines": [
				"苏家的账册终于翻到了最后一页，多谢你。",
				"旧案终册落印在即，但你心里要有数——有些事不是一纸文书能了的。",
				"无论最后怎么收束，花间派欠你一个人情。"
			]
		},
		{
			"after": "q_main_old_case_closure",
			"lines": [
				"旧案终册已落印，苏家冤屈总算有了一个交代。",
				"江湖的路还长，往后若需要花间派助力，你只管开口。",
				"母亲若泉下有知，该瞑目了。"
			]
		}
	],
	"陈天行": [
		{
			"after": "q_intro_town",
			"lines": [
				"平安镇的说书人见得多、讲得多，但也有些事只能在桌底下讲。",
				"洛阳旧火的事你若感兴趣，夜里来客栈，我给你讲一段外围的故事。",
				"听说你在打听暗处的事——小心，有些话传了不该传的人，你的命就不值钱了。"
			]
		},
		{
			"after": "q_clear_thugs",
			"lines": [
				"镇东那几个恶徒是被人雇的——雇他们的人出手不算大方，但也够买几条人命。",
				"你若继续追查，背后的人很快会知道你的名字。",
				"说书人有一句话送给你：江湖上的第一课，不是怎么出招，是怎么看出谁在出招。"
			]
		},
		{
			"after": "q_main_shadow_letters",
			"lines": [
				"两封密信到手了？好，暗影司的暗线终于被拽到了明面上。",
				"密信上的暗号和七派门规有关，这不是巧合，是有人故意留下破绽。",
				"接下来别走官道，暗影司的眼线盯着呢。"
			]
		},
		{
			"after": "q_main_broken_token",
			"lines": [
				"断令花纹对上了武林盟旧卷，七派夜议有了真正的证据。",
				"你做了我做不到的事——我只会说书，你却把故事变成了铁案。",
				"夜议之后，暗影司不会再安坐了，你要做好准备。"
			]
		},
		{
			"after": "q_main_old_case_closure",
			"lines": [
				"旧案终册落印了，说书人终于可以把这段故事讲完了。",
				"你选了哪条路收尾，我都知道——江湖没有不透风的墙。",
				"长安城还是老样子，但你我都知道，暗处的棋局已经翻了。"
			]
		}
	],
	"赵无极": [
		{
			"after": "q_main_broken_token",
			"lines": [
				"断令归卷，证据确凿，武林盟不能再装聋作哑了。",
				"夜议的事我在安排，七派中可信的人不多，但够用。",
				"你若想在武林盟留一条路，这时候出力是最好的时机。"
			]
		},
		{
			"after": "q_main_wulin_conclave",
			"lines": [
				"夜议成局，暗影司的幕布终于被撕开了一角。",
				"七派各怀心事，但至少在暗影司这件事上，他们站到了一起。",
				"接下来打总坛，武林盟能给的支援我会给，但你不要指望太多。"
			]
		},
		{
			"after": "q_main_old_case_closure",
			"lines": [
				"旧案终册落印，武林盟的卷宗里终于补上了这一页。",
				"你做的选择，我无权评判——江湖人各有各的规矩。",
				"若日后还需要武林盟出面，拿着这封信来找我。"
			]
		}
	],
	"玄机子": [
		{
			"after": "q_hero_trial",
			"lines": [
				"八卦门的推演之术告诉我，你命中有三条路可选。",
				"你的根骨不错，但心性才是决定你能走多远的东西。",
				"若你愿意，我可以传你几手奇门基础——走江湖用得着。"
			]
		},
		{
			"after": "q_main_sect_warnings",
			"lines": [
				"七派都收到了风声，暗影司的手伸得太长了。",
				"八卦门的阵法被外人窥过阵眼，这件事不简单。",
				"你若要查暗影司的布局，先学会看谁在故意走错步。"
			]
		},
		{
			"after": "q_main_wulin_conclave",
			"lines": [
				"夜议成局，七派终于肯把暗处的棋子摆到桌上。",
				"我已布下奇门观测阵，暗影司总坛的方位不会太远。",
				"打总坛之前，先破他们的阵眼，否则进去容易出来难。"
			]
		},
		{
			"after": "q_main_shadow_citadel",
			"lines": [
				"影司总坛暂破，暗影司的阵法根基已经动摇。",
				"但阵眼不会只有一处，残部仍在暗处收拢棋子。",
				"你若要彻底了结，就别让他们有时间重新布阵。"
			]
		}
	],
	"花如玉": [
		{
			"after": "q_main_luoyang_ashes",
			"lines": [
				"苏家旧宅的火，烧的不只是房子，是十几条人命。",
				"花间派和苏家有些旧缘，你若要查，我可以给你指路。",
				"你若闻到甜香，先闭气——那是花间的暗号，也是暗影司的陷阱。"
			]
		},
		{
			"after": "q_main_after_shadow",
			"lines": [
				"总坛余烬未灭，暗影司残部还在暗处收拢旧线。",
				"苏家旧案的最后几页，需要的不是证据，是一个了断。",
				"花间派的易容术你若用得上，尽管来找我。"
			]
		},
		{
			"after": "q_main_old_case_closure",
			"lines": [
				"旧案终册落印，花间派终于可以把这段旧事翻过去了。",
				"苏梦瑶欠你的，也是花间派欠你的，日后自有回报。",
				"你身上的甜香味淡了，看来暗影司的影子离你远了些。"
			]
		}
	],
	"烈火": [
		{
			"after": "q_main_shadow_watchers",
			"lines": [
				"暗影司的眼线被你拔掉了一只，痛快！",
				"红莲教的弟兄等这一天等了太久，血债该有个了断。",
				"打总坛的时候叫上我，我要亲手烧了他们的门。"
			]
		},
		{
			"after": "q_main_shadow_citadel",
			"lines": [
				"影司总坛破了，暗影司的火终究没有红莲的旺！",
				"残部还在逃，我带弟兄们去清剿，你先歇着。",
				"旧案的事你看着办，但血债要用血来还。"
			]
		},
		{
			"after": "q_main_old_case_closure",
			"lines": [
				"旧案终册落印了？哼，纸上的了断不算了断。",
				"红莲教的人死在暗影司手里的，可不是一纸文书能还的。",
				"你做的选择我不评，但江湖的血，迟早要还的。"
			]
		}
	],
	"蛇王": [
		{
			"after": "q_main_shadow_letters",
			"lines": [
				"密信到手了？暗影司的暗号我认得，那是那迦派旧术的变体。",
				"你追查暗影司的路子不错，但别忽略暗处还有眼睛。",
				"长安来的黑衣人换了三次靴底，走的不是官道，是水路。"
			]
		},
		{
			"after": "q_main_broken_token",
			"lines": [
				"断令归卷了，七派的证据总算齐了。",
				"暗影司的布局被人窥破，他们会狗急跳墙。",
				"你要打总坛？那迦派的毒殿里有些东西你用得上。"
			]
		},
		{
			"after": "q_main_shadow_citadel",
			"lines": [
				"影司总坛破了，暗处的棋子总算被掀了一半。",
				"残部在逃，其中几个身上的毒我会替你料理。",
				"旧案怎么收尾是你的事，但那迦派不会忘记谁帮过谁。"
			]
		}
	],
	"太极真人": [
		{
			"after": "q_main_wulin_conclave",
			"lines": [
				"夜议成局，七派总算同心了一回。",
				"推手之道在于借力打力，暗影司的攻势越急，破绽越大。",
				"你要打总坛，太极门派弟子策应，但主攻还是得靠你。"
			]
		},
		{
			"after": "q_main_shadow_citadel",
			"lines": [
				"影司总坛暂破，七派终于有了喘息之机。",
				"阴阳有消长，暗影司残部蛰伏，不代表事了。",
				"旧案的终册要落印，需要有人把最后的证据送上山。"
			]
		},
		{
			"after": "q_main_old_case_closure",
			"lines": [
				"旧案终册落印，太极门见证此事，已记入门规。",
				"你做的选择不论正邪，都是你自己的因果。",
				"江湖的路还长，年轻人，守住本心。"
			]
		}
	],
	"冰魄": [
		{
			"after": "q_main_sect_warnings",
			"lines": [
				"七派风声渐紧，雪山派也收到了暗影司的消息。",
				"雪岭的寒意已吹到山门，这不是寻常江湖风声。",
				"你若要查暗影司，先学会在冰面上分辨脚印的真假。"
			]
		},
		{
			"after": "q_main_shadow_citadel",
			"lines": [
				"影司总坛破了，暗处的寒意终于淡了些。",
				"雪山弟子参与了总坛之战，表现不错。",
				"旧案的终册要落印，雪山派不会缺席。"
			]
		},
		{
			"after": "q_main_old_case_closure",
			"lines": [
				"旧案终册落印，雪山派的冰面上终于可以清静一阵。",
				"你做的选择我不评说，但雪地不会说谎。",
				"心定则剑稳，年轻人，别让功名乱了你的剑路。"
			]
		}
	],
	"逍遥子": [
		{
			"after": "q_main_broken_token",
			"lines": [
				"断令归卷了？好，七派总算有了真正的证据。",
				"我站得远些反而看得清——暗影司的布局比你们想的深。",
				"夜议之前，你要想清楚谁该去、谁不该去。"
			]
		},
		{
			"after": "q_main_shadow_citadel",
			"lines": [
				"影司总坛破了，暗影司的棋局被掀了一半。",
				"旁观者清——残部不会散，他们会换一种方式蛰伏。",
				"旧案怎么收尾，你心里要有数。"
			]
		},
		{
			"after": "q_main_old_case_closure",
			"lines": [
				"旧案终册落印了，这一局总算有了了断。",
				"你选了哪条路收尾，我都知道——逍遥宫的消息从不是白来的。",
				"江湖的路还长，你若想歇歇，逍遥宫的棋阁随时为你开门。"
			]
		}
	],
	"西域商人": [
		{
			"after": "q_west_treasure_1",
			"lines": [
				"这古地图是我从西域一个老喇嘛手里收来的，据说藏着沙海深处的秘密。",
				"碎片一共有三块，我只拿到一块——剩下的就得靠你自己去找了。",
				"沙漠里不太平，你要小心那些蝎子，还有比蝎子更危险的人。"
			]
		},
		{
			"after": "q_west_treasure_2",
			"lines": [
				"三块碎片都凑齐了？好得很！让我把它拼起来看看……",
				"看来秘境入口就在沙漠古道最深处，这把钥匙你拿着。",
				"守门的家伙不是善茬，你要是没把握就多准备些丹药。"
			]
		},
		{
			"after": "q_west_treasure_4",
			"lines": [
				"沙漠之心……我跑西域三十年，还是头一回亲眼见到这东西。",
				"你的造化不小，这趟我没白等。以后有什么西域的生意，我第一个找你。",
				"沙漠的风吹不散缘分，后会有期，少侠。"
			]
		}
	],
	"药童": [
		{
			"after": "q_yaowang_1",
			"lines": [
				"多谢你帮我采药，这些药材够师父用一阵子了。",
				"药王谷的规矩多，师父说外人进来要先试药——你可敢一试？",
				"你放心，我配的药死不了人，最多躺两天。"
			]
		},
		{
			"after": "q_yaowang_2",
			"lines": [
				"你居然扛住了八珍玉露的药性！师父说得没错，你体质异于常人。",
				"谷外来了些毒蛛，把药田祸害得不轻，你能帮帮我吗？",
				"药王谷的灵药若是被糟蹋了，可没第二处能采到。"
			]
		},
		{
			"after": "q_yaowang_4",
			"lines": [
				"这丹方是药王谷祖师爷传下来的，你既是有缘人，就交给你了。",
				"用它炼出的九转玉露丹能生死人肉白骨——但切记，药能救人也能杀人。",
				"师父说，真正的医者不是靠药方，是靠心。"
			]
		}
	],
	"神偷": [
		{
			"after": "q_thief_1",
			"lines": [
				"哈，那捕头又派人来追我了？告诉赵德，凭他的本事抓不住我。",
				"我偷的东西都是为富不仁的家伙，劫富济贫，有什么不对？",
				"你要是想抓我，先问问我这把轻功答不答应。"
			]
		},
		{
			"after": "q_thief_2",
			"lines": [
				"你倒是有点本事，居然追到了长安。不过那几件东西已经出手了。",
				"你要那几件破玩意儿？行啊，有本事自己找回来。",
				"我在旧宅等你——你要是真能打赢我，我随你处置。"
			]
		}
	],
	"卧底": [
		{
			"after": "q_mojiao_3",
			"lines": [
				"总算等到接头的人了……我在魔教潜伏了三年，这日子不是人过的。",
				"魔教的势力比你们想的要大得多，他们在朝廷里也有人。",
				"这是分舵的令牌，你拿着它小心行事，别让弟兄们白死了。"
			]
		},
		{
			"after": "q_mojiao_5",
			"lines": [
				"分舵被破的消息已经传到总坛了，护法震怒，正召集所有精锐。",
				"你要趁他还没完全部署好就打过去，这是唯一的机会。",
				"总坛的机关我都画了图，你拿着。这一战，不是他死就是我们亡。"
			]
		}
	]
}
const DAODE_REACTIVE_LINES := {
	"苏梦瑶": {
		3: "你一身正气，连花间派的人都说你是可托之人。",
		2: "侠名远播，苏家的事多亏有你这样的侠义之人肯管。",
		-2: "你身上的戾气太重了，苏家要的不是以暴制暴。",
		-3: "你和暗影司的人有什么两样？苏家不敢沾你的边。"
	},
	"陈天行": {
		3: "你这身正气，连暗影司都怕你三分——好事。",
		2: "侠义之名传得快，说书人正好拿你当主角。",
		-2: "你身上的刀光太盛，我若不说书，怕是要替你讲几句遮掩的话。",
		-3: "你做的那些事，暗处的影子都比从前淡了——因为你就是新的影子。"
	},
	"赵无极": {
		3: "你一身正气，武林盟若得你助力，是江湖之福。",
		2: "侠名在外，武林盟的门对你随时是开的。",
		-2: "你的手段太狠了，武林盟不能明面上与你为伍。",
		-3: "你已是江湖公敌，武林盟若不拿你，便是失职。"
	},
	"玄机子": {
		3: "正气凛然之人，八卦门的阵法也会为你开一条正路。",
		2: "侠义心肠，奇门之道最喜有德者得之。",
		-2: "你身上的煞气太重，我的阵法容不下你这股戾气。",
		-3: "你已入魔道，八卦门弟子见你当以阵困之。"
	},
	"花如玉": {
		3: "你一身正气，花间派愿意把旧案托付给你。",
		2: "侠名远播，花间派的姐妹们都信你。",
		-2: "你身上的戾气太重，花间派不敢与你走得太近。",
		-3: "你和暗影司一样狠，花间派不会引狼入室。"
	},
	"烈火": {
		3: "你一身正气？哼，正道的火烧不死人，红莲的火才烧得干净。",
		2: "侠义之人，你的火不够旺，烧不穿暗影司的壳。",
		-2: "你身上的血腥味我闻到了——好，这才是该有的味道。",
		-3: "你比红莲教还狠，我服你，来，我们一起烧！"
	},
	"蛇王": {
		3: "正气凛然？那迦派不与正道中人为伍，你走吧。",
		2: "侠义之名，在那迦派听来不过是另一种伪装。",
		-2: "你身上的阴气不轻，那迦派倒可以与你谈谈。",
		-3: "你比我还会用毒——不是药毒，是心毒，那迦派欢迎你。"
	},
	"太极真人": {
		3: "你一身正气，太极门上下都看在眼里，愿与你论道。",
		2: "侠名远播，年轻人，太极门愿与你结交。",
		-2: "你身上的戾气太重，太极门不能与你为伍。",
		-3: "你已入了魔道，太极门弟子见你当拔剑。"
	},
	"冰魄": {
		3: "你一身正气，雪山派的冰面上永远留你一席之地。",
		2: "侠义之名，雪山派愿意认你这个朋友。",
		-2: "你的心不够静，雪山派不愿收一身戾气之人。",
		-3: "你身上的煞气比暴风雪还重，雪山派不欢迎你。"
	},
	"逍遥子": {
		3: "正气凛然，难得，逍遥宫的棋阁随时为你开门。",
		2: "侠名在外，逍遥宫愿意为你留一盏茶。",
		-2: "你身上的戾气不轻，逍遥宫的棋局容不下你这步棋。",
		-3: "你已是江湖的乱局，逍遥宫不愿与你对弈。"
	},
	"西域商人": {
		3: "正气凛然之人，西域商路也会为你敞开大门。",
		2: "侠义之名传遍西域，商队的伙计们都愿意给你折扣。",
		-2: "你身上的煞气太重，西域名商不敢与你交易。",
		-3: "你已成了沙匪一般的人物，西域商路不会欢迎你。"
	},
	"药童": {
		3: "你一身正气，药王谷的灵药都愿意与你亲近。",
		2: "侠名远播，药童说你是好人的时候眼睛是亮的。",
		-2: "你身上的戾气太重，药田的花都蔫了……",
		-3: "你这样的人，药王谷的丹炉容不下你的邪气。"
	},
	"神偷": {
		3: "你正气凛然？哼，正道上的人最无趣了。",
		2: "侠义之人，你我不过路数不同罢了。",
		-2: "你够狠，道上的人会给你几分面子。",
		-3: "你比我还狠，这江湖真是后浪推前浪。"
	},
	"卧底": {
		3: "你一身正气，我在魔教潜伏多年等的就是你这样的人。",
		2: "侠义之名，让我觉得这三年的卧底没有白费。",
		-2: "你身上的杀气太重，我分不清你是敌是友。",
		-3: "你和魔教中人有什么两样？我白等了三年。"
	}
}
const STORY_CHOICE_ACKNOWLEDGMENTS := {
	"story_conclave_public": {
		"苏梦瑶": "断令公议的事，七派欠你一个人情，我也算。",
		"太极真人": "公开断令是正道之举，太极门记你一功。"
	},
	"story_conclave_secret": {
		"苏梦瑶": "你沿旧账暗查暗影司线人，这条路虽慢但稳，我信你。",
		"陈天行": "暗查旧账的事我参与了，说书人嘴里也留了一半没讲。"
	},
	"story_conclave_betray": {
		"赵无极": "你把断令卖给了暗影司？武林盟的卷宗里已经写了你的名字。",
		"陈天行": "你倒戈投敌的事我知道了——说书人不讲你的故事，但暗处的人都在讲。"
	},
	"story_epilogue_mercy": {
		"苏梦瑶": "你愿意给被胁迫的人留一条回头路，苏家的事总算有了一个仁义的收束。",
		"太极真人": "清算有度，是正道该有的模样，太极门愿为你作证。"
	},
	"story_epilogue_reckoning": {
		"陈天行": "追剿残影的事干得漂亮，暗影司再想蛰伏就没那么容易了。",
		"赵无极": "你趁势追剿残部，武林盟替你记一功——但旧怨翻到明面，你也要收拾得住。"
	},
	"story_epilogue_massacre": {
		"赵无极": "你下令赶尽杀绝的事，武林盟不会替你背，江湖人也都在看。",
		"陈天行": "连知情百姓也不放过……说书人不讲这种故事，但暗处的人都在讲你。"
	}
}

func get_available_story_choices(npc_name: String = "") -> Array:
	var choices: Array = []
	for entry in STORY_CHOICE_DEFINITIONS:
		var choice: Dictionary = entry
		if not _story_choice_matches_npc(choice, npc_name):
			continue
		if not _story_choice_available(choice):
			continue
		choices.append(choice.duplicate(true))
	return choices


func choose_story_branch(choice_id: String) -> bool:
	var choice := _story_choice_by_id(choice_id)
	if choice.is_empty() or not _story_choice_available(choice):
		return false
	var group := str(choice.get("group", ""))
	var group_flag := _story_choice_group_flag(group)
	if not group.is_empty():
		_state.game_flags[group_flag] = str(choice.get("id", ""))
	var flag := str(choice.get("flag", ""))
	if not flag.is_empty():
		_state.game_flags[flag] = true
	var daode_delta := int(choice.get("daode", 0))
	if daode_delta != 0:
		change_daode(daode_delta)
	var money_delta := int(choice.get("money", 0))
	if money_delta != 0:
		_state.add_money(money_delta)
	var items: Dictionary = choice.get("items", {})
	for item_id in items.keys():
		_state.add_item(str(item_id), int(items[item_id]))
	_state._apply_story_choice_memory(choice)
	_state.append_world_event(
		"story_choice",
		str(choice.get("event_title", choice.get("title", "剧情抉择"))),
		str(choice.get("event_description", choice.get("description", ""))),
		str(choice.get("region_id", _state.current_region_id)),
		4
	)
	EventBus.player_changed.emit(_state.player)
	EventBus.quests_changed.emit()
	EventBus.emit_toast("剧情抉择：%s" % str(choice.get("title", choice_id)))
	return true


func get_story_choice_status_lines() -> Array[String]:
	var lines: Array[String] = []
	for entry in STORY_CHOICE_DEFINITIONS:
		var choice: Dictionary = entry
		var flag := str(choice.get("flag", ""))
		if not flag.is_empty() and bool(_state.game_flags.get(flag, false)):
			lines.append("%s：%s" % [str(choice.get("title", flag)), str(choice.get("description", ""))])
	return lines


func _story_choice_by_id(choice_id: String) -> Dictionary:
	for entry in STORY_CHOICE_DEFINITIONS:
		var choice: Dictionary = entry
		if str(choice.get("id", "")) == choice_id:
			return choice.duplicate(true)
	return {}


func _story_choice_matches_npc(choice: Dictionary, npc_name: String) -> bool:
	if npc_name.is_empty():
		return true
	var npcs: Array = choice.get("npcs", [])
	return npcs.has(npc_name)


func _story_choice_available(choice: Dictionary) -> bool:
	var group := str(choice.get("group", ""))
	if not group.is_empty() and not str(_state.game_flags.get(_story_choice_group_flag(group), "")).is_empty():
		return false
	var flag := str(choice.get("flag", ""))
	if not flag.is_empty() and bool(_state.game_flags.get(flag, false)):
		return false
	var required_completed: Array = choice.get("requires_completed", [])
	for quest_id in required_completed:
		if not _state.completed_quests.has(str(quest_id)):
			return false
	var blocked_completed: Array = choice.get("blocks_completed", [])
	for quest_id in blocked_completed:
		if _state.completed_quests.has(str(quest_id)):
			return false
	return true


func _story_choice_group_flag(group: String) -> String:
	return "story_choice_%s" % group


func _current_story_stage() -> String:
	if _state.completed_quests.has("q_main_epilogue_mercy"):
		return "江湖留灯"
	if _state.completed_quests.has("q_main_epilogue_reckoning"):
		return "残影清剿"
	if bool(_state.game_flags.get("story_epilogue_mercy", false)):
		return "江湖留灯"
	if bool(_state.game_flags.get("story_epilogue_reckoning", false)):
		return "残影清剿"
	if _state.completed_quests.has("q_main_old_case_closure"):
		return "旧案终册"
	if _state.completed_quests.has("q_main_after_shadow"):
		return "总坛余烬"
	if _state.completed_quests.has("q_main_shadow_citadel"):
		return "影司总坛余波"
	if _state.completed_quests.has("q_main_blood_moon"):
		return "影司总坛"
	if _state.completed_quests.has("q_main_hidden_master"):
		return "血月残印"
	if _state.completed_quests.has("q_main_wulin_conclave"):
		return "暗影司幕后主使"
	if _state.completed_quests.has("q_main_broken_token"):
		return "七派夜议"
	if _state.completed_quests.has("q_main_shadow_watchers"):
		return "断令和暗影眼线"
	if _state.completed_quests.has("q_main_shadow_letters"):
		return "七派暗号"
	if _state.completed_quests.has("q_main_faction_oath"):
		return "初入江湖·门庭初定"
	if _state.completed_quests.has("q_main_choose_path"):
		return "初入江湖·择路"
	if _state.completed_quests.has("q_hero_trial"):
		return "洛阳旧案"
	if not _state.active_quest.is_empty() and _state.active_quest != "初入平安镇":
		return _state.active_quest
	return "平安镇新来的少侠"


func change_daode(delta: int) -> void:
	if delta == 0:
		return
	var current := int(_state.player.get("daode", 0))
	var next := clampi(current + delta, DAODE_MIN, DAODE_MAX)
	if next == current:
		return
	_state.player["daode"] = next
	EventBus.player_changed.emit(_state.player)


func get_daode_tier() -> int:
	var daode := int(_state.player.get("daode", 0))
	if daode >= 80:
		return 3
	if daode >= 50:
		return 2
	if daode >= 20:
		return 1
	if daode >= -20:
		return 0
	if daode >= -50:
		return -1
	if daode >= -80:
		return -2
	return -3


func get_daode_tier_label() -> String:
	return str(DAODE_TIER_LABELS.get(get_daode_tier(), "中立"))


func get_contextual_dialogue_lines(npc_name: String) -> Array:
	if not CONTEXTUAL_DIALOGUES.has(npc_name):
		return []
	var phases: Array = CONTEXTUAL_DIALOGUES[npc_name]
	for i in range(phases.size() - 1, -1, -1):
		var phase: Dictionary = phases[i]
		var after_quest := str(phase.get("after", ""))
		if _state.completed_quests.has(after_quest):
			return phase.get("lines", [])
	return []


func get_daode_reactive_line(npc_data: Dictionary) -> String:
	var npc_name := str(npc_data.get("name", ""))
	if not DAODE_REACTIVE_LINES.has(npc_name):
		return ""
	var tier := get_daode_tier()
	if absi(tier) < 2:
		return ""
	var lines: Dictionary = DAODE_REACTIVE_LINES[npc_name]
	if lines.has(tier):
		return str(lines[tier])
	return ""


func get_story_choice_acknowledgment(npc_name: String) -> String:
	for flag in STORY_CHOICE_ACKNOWLEDGMENTS:
		if not bool(_state.game_flags.get(flag, false)):
			continue
		var acks: Dictionary = STORY_CHOICE_ACKNOWLEDGMENTS[flag]
		if acks.has(npc_name):
			return str(acks[npc_name])
	return ""


func is_main_story_completed() -> bool:
	for quest_id in GameState.EPILOGUE_QUEST_IDS:
		if _state.completed_quests.has(quest_id):
			return true
	return false


func get_ending() -> Dictionary:
	var daode := int(_state.player.get("daode", 0))
	var money := int(_state.player.get("money", 0))
	if bool(_state.game_flags.get("joined_court", false)):
		return ENDING_DEFINITIONS[5]
	if money >= 10000:
		return ENDING_DEFINITIONS[6]
	if _all_skills_mastered():
		return ENDING_DEFINITIONS[7]
	if daode >= 80:
		return ENDING_DEFINITIONS[0]
	if daode >= 50:
		return ENDING_DEFINITIONS[1]
	if daode <= -80:
		return ENDING_DEFINITIONS[4]
	if daode <= -50:
		return ENDING_DEFINITIONS[3]
	return ENDING_DEFINITIONS[2]


func _all_skills_mastered() -> bool:
	if _state.learned_skills.is_empty():
		return false
	var learned_count := 0
	var mastered_count := 0
	for skill_id in _state.learned_skills.keys():
		var level := int(_state.learned_skills[skill_id])
		if level <= 0:
			continue
		learned_count += 1
		var max_level := GameData.get_skill_max_level(str(skill_id))
		if max_level > 0 and level >= max_level:
			mastered_count += 1
	if learned_count == 0:
		return false
	return mastered_count >= learned_count and learned_count >= 4


func trigger_ending() -> void:
	if not is_main_story_completed():
		return
	if bool(_state.game_flags.get("ending_triggered", false)):
		return
	_state.game_flags["ending_triggered"] = true
	var ending := get_ending()
	_state.save_ng_plus_snapshot()
	_state.set_mode(GameState.Mode.ENDING)
	EventBus.emit_toast("结局：%s" % str(ending.get("title", "")))
	EventBus.ending_triggered.emit(ending)


func get_faction_alignment(faction_id: String) -> String:
	return str(GameData.FACTION_ALIGNMENT.get(faction_id, "neutral"))


func get_npc_attitude(npc_data: Dictionary) -> String:
	var npc_align := get_faction_alignment(str(npc_data.get("faction", "none")))
	var tier := get_daode_tier()
	var idx := clampi(3 - tier, 0, 6)
	var row: Array = NPC_ATTITUDE_TABLE.get(npc_align, NPC_ATTITUDE_TABLE["neutral"])
	return str(row[idx])


func join_faction(faction_id: String) -> bool:
	if faction_id == "none":
		return false
	if str(_state.player.get("faction", "none")) != "none" and str(_state.player.get("faction", "none")) != faction_id:
		EventBus.emit_toast("你已有门派")
		return false
	_state.player["faction"] = faction_id
	_state.game_flags["has_faction"] = true
	if faction_id == "court":
		_state.game_flags["joined_court"] = true
	var skills := GameData.get_faction_skills(faction_id)
	if not skills.is_empty():
		_state.learn_skill(str(skills[0]), 1)
	EventBus.player_changed.emit(_state.player)
	EventBus.emit_toast("拜入%s" % GameData.get_faction_name(faction_id))
	return true

