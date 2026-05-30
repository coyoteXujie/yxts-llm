import os

# Delete all corrupted portrait files
portrait_dir = 'E:/yxts-llm/assets/portraits'
if os.path.exists(portrait_dir):
    for f in os.listdir(portrait_dir):
        filepath = os.path.join(portrait_dir, f)
        if os.path.isfile(filepath):
            os.remove(filepath)
            print(f'Deleted: {f}')
    print('All portraits cleaned')
else:
    print('Portrait dir not found')
