import urllib.request
import json
import os

# Download PixelSRPG-Forge character sprites
base_url = "https://github.com/Huu-Yuu/PixelSRPG-Forge/raw/main/"
output_dir = "E:/yxts-llm/assets/sprites/pixel_srpg"

os.makedirs(output_dir, exist_ok=True)

# List some common character sprite files that might exist in the repo
files_to_try = [
    "Asset_Packs_%E7%B4%A0%E6%9D%90%E5%A5%97%E5%9B%BE/2D Pixel Dungeon Asset Pack.zip",
]

for f in files_to_try:
    print(f"Checking: {f}")
    url = "https://api.github.com/repos/Huu-Yuu/PixelSRPG-Forge/contents/" + f
    try:
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        resp = urllib.request.urlopen(req)
        data = json.loads(resp.read())
        print(f"  Found: {data.get('name', 'unknown')}, size: {data.get('size', '?')}")
        if 'download_url' in data:
            print(f"  Download URL: {data['download_url']}")
    except Exception as e:
        print(f"  Error: {e}")

# Let's also look for other open-source Chinese-style sprite repos
search_queries = [
    "chinese+ancient+pixel+art+game+sprite",
    "wuxia+rpg+character+sprite+sheet",
    "asian+style+top+down+rpg+sprite",
]

for q in search_queries:
    print(f"\nSearching GitHub for: {q}")
    url = f"https://api.github.com/search/repositories?q={q}&sort=stars&per_page=5"
    try:
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        resp = urllib.request.urlopen(req)
        data = json.loads(resp.read())
        if 'items' in data:
            for item in data['items']:
                print(f"  - {item['full_name']} (stars: {item['stargazers_count']})")
                print(f"    {item.get('description', 'N/A')[:100]}")
                print(f"    {item['html_url']}")
    except Exception as e:
        print(f"  Error: {e}")
