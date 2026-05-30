import urllib.request
import json

req = urllib.request.Request(
    'https://api.github.com/repos/Huu-Yuu/PixelSRPG-Forge/contents/Characters_%E8%A7%92%E8%89%B2%E4%BA%BA%E7%89%A9',
    headers={'User-Agent': 'Mozilla/5.0'}
)
resp = urllib.request.urlopen(req)
data = json.loads(resp.read())
for item in data[:50]:
    print(item['name'], item['type'], item.get('size', '?'))
