import os
import re
import glob

scenes_dir = r"e:\yxts-llm\scenes"

for filepath in glob.glob(os.path.join(scenes_dir, "*.tscn")):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Replace unique_id=6xxxxxxx with unique_id=1
    # Use a simple counter for each file
    counter = 1
    def replace_uid(match):
        nonlocal counter
        result = f'unique_id={counter}'
        counter += 1
        return result
    
    new_content = re.sub(r'unique_id=\d+', replace_uid, content)
    
    if new_content != content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"Fixed: {os.path.basename(filepath)}")
    else:
        print(f"OK: {os.path.basename(filepath)}")

print("Done!")
