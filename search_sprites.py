import urllib.request
import json
import os

output_dir = 'E:/yxts-llm/assets/sprites/chinese_rpg'
os.makedirs(output_dir, exist_ok=True)

search_urls = [
    ('github_chinese_sprites', 'https://api.github.com/search/repositories?q=chinese+style+pixel+art+top+down+RPG+sprite&sort=stars&per_page=10'),
    ('github_wuxia_sprites', 'https://api.github.com/search/repositories?q=wuxia+pixel+game+sprite+art&sort=stars&per_page=10'),
    ('github_guofeng_sprites', 'https://api.github.com/search/repositories?q=%E5%8F%A4%E9%A3%8E+%E5%83%8F%E7%B4%A0+%E6%B8%B8%E6%88%8F+%E4%BA%BA%E7%89%A9&sort=stars&per_page=10'),
]

for name, url in search_urls:
    print(f"\n=== {name} ===")
    try:
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        resp = urllib.request.urlopen(req)
        data = json.loads(resp.read())
        if 'items' in data:
            for item in data['items'][:5]:
                print(f"  - {item['full_name']} (stars: {item['stargazers_count']})")
                print(f"    {item.get('description', 'N/A')}")
                print(f"    {item['html_url']}")
    except Exception as e:
        print(f"  Error: {e}")
