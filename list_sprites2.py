import urllib.request
import json

base_url = 'https://api.github.com/repos/Huu-Yuu/PixelSRPG-Forge/contents/'
dirs = [
    'Asset_Packs_%E7%B4%A0%E6%9D%90%E5%A5%97%E5%9B%BE',
    'Costumes_%E6%9C%8D%E8%A3%85%E6%89%AE%E6%BC%94',
    'other_%E5%85%B6%E4%BB%96%E7%B4%A0%E6%9D%903%E4%B8%87%E5%A4%9A%E5%BC%A0'
]

for d in dirs:
    print(f"\n=== {d} ===")
    try:
        req = urllib.request.Request(
            base_url + d,
            headers={'User-Agent': 'Mozilla/5.0'}
        )
        resp = urllib.request.urlopen(req)
        data = json.loads(resp.read())
        for item in data[:30]:
            print(f"  {item['name']} ({item['type']}, {item.get('size', '?')})")
    except Exception as e:
        print(f"  Error: {e}")
