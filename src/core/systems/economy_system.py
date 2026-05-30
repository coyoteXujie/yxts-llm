#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
经济系统 - Economy System
完整的买卖、拍卖、黑市、物价波动系统

特色:
1. 商店系统 - 各类商店、商品买卖
2. 拍卖行 - 稀有物品竞拍
3. 黑市 - 违禁物品、特殊交易
4. 物价波动 - 供需影响价格
5. 钱庄 - 存取款、利息
"""

import math
import random
from typing import List, Dict, Optional, Tuple, Set
from dataclasses import dataclass, field
from enum import Enum, auto
from datetime import datetime


class ShopType(Enum):
    """商店类型"""
    GENERAL = "general"      # 杂货铺
    WEAPON = "weapon"        # 兵器铺
    ARMOR = "armor"          # 防具铺
    MEDICINE = "medicine"    # 药铺
    HERBAL = "herbal"        # 草药店
    FOOD = "food"            # 食肆
    TEAHOUSE = "teahouse"    # 茶馆
    INN = "inn"              # 客栈
    BLACKMARKET = "black"    # 黑市


class ItemRarity(Enum):
    """物品稀有度"""
    COMMON = 1      # 普通
    UNCOMMON = 2    # 优秀
    RARE = 3        # 稀有
    EPIC = 4        # 史诗
    LEGENDARY = 5   # 传说


@dataclass
class ShopItem:
    """商店物品"""
    item_id: str
    name: str
    base_price: int
    current_price: int
    stock: int
    max_stock: int
    rarity: ItemRarity = ItemRarity.COMMON
    is_buyable: bool = True
    is_sellable: bool = True
    restock_rate: float = 0.1  # 每日补货率
    
    # 价格波动
    demand: float = 1.0        # 需求系数
    supply: float = 1.0        # 供给系数


@dataclass
class Shop:
    """商店"""
    shop_id: str
    name: str
    shop_type: ShopType
    location: str             # 所在城市
    
    items: List[ShopItem] = field(default_factory=list)
    
    # 商店属性
    buy_price_rate: float = 0.5   # 收购价格比例
    sell_price_rate: float = 1.0  # 出售价格比例
    
    # 声望折扣
    reputation_discount: float = 0.0
    
    # 特殊商品
    special_items: List[str] = field(default_factory=list)
    
    def get_item(self, item_id: str) -> Optional[ShopItem]:
        for item in self.items:
            if item.item_id == item_id:
                return item
        return None
        
    def buy_price(self, item: ShopItem) -> int:
        """获取购买价格"""
        base = item.current_price * self.sell_price_rate
        discount = base * self.reputation_discount
        return int(base - discount)
        
    def sell_price(self, item: ShopItem) -> int:
        """获取出售价格"""
        return int(item.current_price * self.buy_price_rate)


@dataclass
class AuctionItem:
    """拍卖物品"""
    item_id: str
    name: str
    rarity: ItemRarity
    starting_price: int
    current_bid: int
    current_bidder: Optional[str] = None
    end_time: datetime = field(default_factory=datetime.now)
    
    # 拍卖信息
    seller: str = ""
    description: str = ""


@dataclass
class BankAccount:
    """钱庄账户"""
    balance: int = 0
    interest_rate: float = 0.001  # 日利率
    last_interest_time: datetime = field(default_factory=datetime.now)
    
    def calculate_interest(self) -> int:
        """计算利息"""
        now = datetime.now()
        days = (now - self.last_interest_time).days
        if days > 0:
            interest = int(self.balance * self.interest_rate * days)
            return interest
        return 0


class EconomySystem:
    """经济系统"""
    
    def __init__(self):
        self.shops: Dict[str, Shop] = {}
        self.auction_items: List[AuctionItem] = []
        self.bank = BankAccount()
        
        # 玩家资金
        self._gold: int = 100
        self.silver: int = 0
        
        # 玩家引用
        self._player_ref = None
        
        # 市场价格记忆
        self.price_history: Dict[str, List[Tuple[datetime, int]]] = {}
        
        # 初始化商店
        self._init_shops()
        
    def _init_shops(self) -> None:
        """初始化商店"""
        # 洛阳城商店
        self.shops["luoyang_general"] = Shop(
            "luoyang_general", "永兴杂货铺", ShopType.GENERAL, "luoyang",
            items=[
                ShopItem("torch", "火把", 10, 10, 50, 100),
                ShopItem("rope", "绳索", 15, 15, 30, 50),
                ShopItem("water_skin", "水囊", 8, 8, 40, 80),
            ]
        )
        
        self.shops["luoyang_weapon"] = Shop(
            "luoyang_weapon", "铁匠老张", ShopType.WEAPON, "luoyang",
            items=[
                ShopItem("iron_sword", "铁剑", 200, 200, 5, 10, ItemRarity.UNCOMMON),
                ShopItem("steel_blade", "钢刀", 350, 350, 3, 8, ItemRarity.RARE),
                ShopItem("wood_staff", "木棍", 50, 50, 20, 30),
            ]
        )
        
        self.shops["luoyang_medicine"] = Shop(
            "luoyang_medicine", "回春堂", ShopType.MEDICINE, "luoyang",
            items=[
                ShopItem("minor_heal", "金创药", 30, 30, 50, 100),
                ShopItem("major_heal", "小还丹", 100, 100, 20, 40, ItemRarity.UNCOMMON),
                ShopItem("antidote", "解毒丹", 50, 50, 30, 50),
            ]
        )
        
        self.shops["luoyang_inn"] = Shop(
            "luoyang_inn", "悦来客栈", ShopType.INN, "luoyang",
            items=[
                ShopItem("rest", "住宿休息", 20, 20, 999, 999),
                ShopItem("meal", "酒菜", 10, 10, 999, 999),
            ]
        )
        
        # 黑市
        self.shops["blackmarket"] = Shop(
            "blackmarket", "暗巷黑市", ShopType.BLACKMARKET, "hidden",
            items=[
                ShopItem("poison", "毒药", 200, 200, 5, 10, ItemRarity.RARE),
                ShopItem("hidden_weapon", "暗器", 150, 150, 10, 20, ItemRarity.UNCOMMON),
                ShopItem("secret_manual", "秘籍残页", 500, 500, 2, 5, ItemRarity.EPIC),
            ],
            sell_price_rate=1.5  # 黑市价格更高
        )
        
    def link_player(self, player) -> None:
        """链接玩家对象，同步金币"""
        self._player_ref = player
        if player and hasattr(player, 'money'):
            self._gold = player.money
    
    @property
    def gold(self) -> int:
        """获取金币（优先从玩家读取）"""
        if self._player_ref:
            return self._player_ref.money
        return self._gold
    
    @gold.setter
    def gold(self, value: int) -> None:
        """设置金币（同时更新玩家）"""
        self._gold = value
        if self._player_ref:
            self._player_ref.money = value
    
    def add_gold(self, amount: int) -> None:
        """增加金币"""
        self.gold += amount
        
    def buy_item(self, shop_id: str, item_id: str, quantity: int = 1) -> Tuple[bool, str]:
        """购买物品"""
        shop = self.shops.get(shop_id)
        if not shop:
            return False, "商店不存在"
            
        item = shop.get_item(item_id)
        if not item:
            return False, "物品不存在"
            
        if item.stock < quantity:
            return False, "库存不足"
            
        total_price = shop.buy_price(item) * quantity
        if self.gold < total_price:
            return False, f"银两不足，需要 {total_price} 两"
            
        # 执行购买
        self.gold -= total_price
        item.stock -= quantity
        
        # 更新需求
        item.demand += 0.1 * quantity
        self._update_price(item)
        
        return True, f"购买成功，花费 {total_price} 两"
        
    def sell_item(self, shop_id: str, item_id: str, quantity: int = 1,
                 item_base_price: int = 100) -> Tuple[bool, str]:
        """出售物品"""
        shop = self.shops.get(shop_id)
        if not shop:
            return False, "商店不存在"
            
        item = shop.get_item(item_id)
        if not item:
            # 创建临时物品
            item = ShopItem(item_id, item_id, item_base_price, item_base_price, 0, 100)
            shop.items.append(item)
            
        total_price = shop.sell_price(item) * quantity
        self.gold += total_price
        item.stock += quantity
        
        # 更新供给
        item.supply += 0.1 * quantity
        self._update_price(item)
        
        return True, f"出售成功，获得 {total_price} 两"
        
    def _update_price(self, item: ShopItem) -> None:
        """更新价格"""
        # 供需影响价格
        supply_demand_ratio = item.supply / max(0.1, item.demand)
        price_factor = 1.0 / supply_demand_ratio
        price_factor = max(0.5, min(2.0, price_factor))  # 限制在0.5-2.0
        
        item.current_price = int(item.base_price * price_factor)
        
    def restock_daily(self) -> None:
        """每日补货"""
        for shop in self.shops.values():
            for item in shop.items:
                if item.stock < item.max_stock:
                    restock = int((item.max_stock - item.stock) * item.restock_rate)
                    item.stock = min(item.max_stock, item.stock + restock)
                    
                # 价格回归
                item.demand = max(1.0, item.demand * 0.95)
                item.supply = max(1.0, item.supply * 0.95)
                self._update_price(item)
                
    def deposit(self, amount: int) -> Tuple[bool, str]:
        """存款"""
        if amount > self.gold:
            return False, "银两不足"
            
        self.gold -= amount
        self.bank.balance += amount
        return True, f"存入 {amount} 两"
        
    def withdraw(self, amount: int) -> Tuple[bool, str]:
        """取款"""
        if amount > self.bank.balance:
            return False, "存款不足"
            
        self.bank.balance -= amount
        self.gold += amount
        return True, f"取出 {amount} 两"
        
    def collect_interest(self) -> int:
        """收取利息"""
        interest = self.bank.calculate_interest()
        if interest > 0:
            self.bank.balance += interest
            self.bank.last_interest_time = datetime.now()
        return interest
        
    def add_auction_item(self, item: AuctionItem) -> None:
        """添加拍卖物品"""
        self.auction_items.append(item)
        
    def bid_auction(self, item_index: int, bid_amount: int,
                   bidder: str) -> Tuple[bool, str]:
        """竞拍"""
        if item_index >= len(self.auction_items):
            return False, "拍卖物品不存在"
            
        item = self.auction_items[item_index]
        
        if bid_amount <= item.current_bid:
            return False, "出价必须高于当前价格"
            
        if bid_amount > self.gold:
            return False, "银两不足"
            
        # 退还前一个竞拍者
        if item.current_bidder:
            # (实际实现需要管理玩家资金)
            pass
            
        item.current_bid = bid_amount
        item.current_bidder = bidder
        
        return True, f"出价成功: {bid_amount} 两"
        
    def check_auction_end(self) -> List[AuctionItem]:
        """检查拍卖结束"""
        now = datetime.now()
        ended = []
        
        for item in self.auction_items[:]:
            if now >= item.end_time:
                ended.append(item)
                self.auction_items.remove(item)
                
        return ended


class ReputationSystem:
    """江湖声望系统"""
    
    def __init__(self):
        # 门派声望
        self.faction_reputation: Dict[str, int] = {}
        
        # 正邪值 (-100 到 100)
        self._alignment: int = 0  # 0=中立, 正=正派, 负=邪派
        
        # 玩家引用
        self._player_ref = None
        
        # 江湖名望
        self.fame: int = 0
        
        # 关系网
        self.relationships: Dict[str, int] = {}  # NPC ID -> 好感度
        
        # 称号
        self.titles: List[str] = []
        self.current_title: str = "江湖新人"
        
    def link_player(self, player) -> None:
        """链接玩家对象，同步正邪值"""
        self._player_ref = player
        if player and hasattr(player, 'daode'):
            self._alignment = player.daode
    
    @property
    def alignment(self) -> int:
        """获取正邪值（优先从玩家读取）"""
        if self._player_ref:
            return self._player_ref.daode
        return self._alignment
    
    @alignment.setter
    def alignment(self, value: int) -> None:
        """设置正邪值（同时更新玩家）"""
        self._alignment = value
        if self._player_ref:
            self._player_ref.daode = value
        
    def get_faction_standing(self, faction: str) -> str:
        """获取门派声望等级"""
        rep = self.faction_reputation.get(faction, 0)
        
        if rep >= 1000:
            return "掌门亲传"
        elif rep >= 500:
            return "门派长老"
        elif rep >= 200:
            return "门派弟子"
        elif rep >= 50:
            return "外门弟子"
        elif rep >= 0:
            return "中立"
        elif rep >= -50:
            return "门派仇人"
        else:
            return "不死不休"
            
    def add_faction_reputation(self, faction: str, amount: int) -> None:
        """增加门派声望"""
        current = self.faction_reputation.get(faction, 0)
        self.faction_reputation[faction] = current + amount
        
    def get_alignment_name(self) -> str:
        """获取正邪名称"""
        if self.alignment >= 80:
            return "侠之大者"
        elif self.alignment >= 50:
            return "正派侠客"
        elif self.alignment >= 20:
            return "行侠仗义"
        elif self.alignment >= -20:
            return "亦正亦邪"
        elif self.alignment >= -50:
            return "旁门左道"
        elif self.alignment >= -80:
            return "邪派高手"
        else:
            return "魔头"
            
    def modify_alignment(self, amount: int) -> None:
        """修改正邪值"""
        self.alignment = max(-100, min(100, self.alignment + amount))
        
    def get_relationship(self, npc_id: str) -> int:
        """获取NPC好感度"""
        return self.relationships.get(npc_id, 0)
        
    def modify_relationship(self, npc_id: str, amount: int) -> None:
        """修改NPC好感度"""
        current = self.relationships.get(npc_id, 0)
        self.relationships[npc_id] = max(-100, min(100, current + amount))
        
    def get_relationship_name(self, npc_id: str) -> str:
        """获取关系名称"""
        rep = self.get_relationship(npc_id)
        
        if rep >= 90:
            return "生死之交"
        elif rep >= 70:
            return "莫逆之交"
        elif rep >= 50:
            return "知心好友"
        elif rep >= 30:
            return "好友"
        elif rep >= 10:
            return "相识"
        elif rep >= -10:
            return "路人"
        elif rep >= -30:
            return "有过节"
        elif rep >= -50:
            return "仇人"
        elif rep >= -70:
            return "死敌"
        else:
            return "不死不休"
            
    def add_fame(self, amount: int) -> None:
        """增加名望"""
        self.fame += amount
        
        # 检查称号
        self._check_titles()
        
    def _check_titles(self) -> None:
        """检查并更新称号"""
        title_list = [
            (0, "江湖新人"),
            (100, "小有名气"),
            (300, "声名鹊起"),
            (600, "名震一方"),
            (1000, "威震江湖"),
            (2000, "一代宗师"),
            (5000, "武林神话"),
        ]
        
        for fame_req, title in title_list:
            if self.fame >= fame_req and title not in self.titles:
                self.titles.append(title)
                
    def get_shop_discount(self, faction: str) -> float:
        """获取商店折扣"""
        standing = self.get_faction_standing(faction)
        
        discounts = {
            "掌门亲传": 0.3,
            "门派长老": 0.2,
            "门派弟子": 0.15,
            "外门弟子": 0.1,
            "中立": 0.0,
            "门派仇人": -0.2,
            "不死不休": -0.5,
        }
        
        return discounts.get(standing, 0.0)
