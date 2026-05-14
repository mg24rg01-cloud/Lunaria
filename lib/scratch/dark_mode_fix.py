import os
import re

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    original = content
    
    # 1. Backgrounds
    content = content.replace("backgroundColor: const Color(0xFFFFFBF9)", "backgroundColor: Theme.of(context).scaffoldBackgroundColor")
    content = content.replace("backgroundColor: Colors.white", "backgroundColor: Theme.of(context).scaffoldBackgroundColor")
    
    # 2. Container/Card colors
    content = content.replace("color: Colors.white,", "color: Theme.of(context).cardColor,")
    content = content.replace("color: Colors.white)", "color: Theme.of(context).cardColor)")
    
    # 3. Text Colors that might be hardcoded to black/grey when they should be adaptive
    # We will ignore some specific text colors unless it's easy. It's better to just fix the major blocky colors first.

    if original != content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Updated {filepath}")

def main():
    lib_dir = r"c:\Users\mg24r\.gemini\antigravity\scratch\expense_app\lib"
    for root, dirs, files in os.walk(lib_dir):
        for file in files:
            if file.endswith('.dart'):
                process_file(os.path.join(root, file))

if __name__ == '__main__':
    main()
