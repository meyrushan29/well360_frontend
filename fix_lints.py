import os
import re

frontend_lib = r"d:\App-Store-Devlopement\Well360-Frontend\lib"

def fix_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # 1. Fix .withOpacity(x) -> .withValues(alpha: x)
    new_content = re.sub(r'\.withOpacity\((.*?)\)', r'.withValues(alpha: \1)', content)
    
    # 2. Fix unnecessary braces in string interps ${var} -> $var
    # Only if it's a simple variable (no dots, no brackets)
    new_content = re.sub(r'\${([a-zA-Z0-9_]+)}', r'$\1', new_content)
    
    if new_content != content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(new_content)
        return True
    return False

count = 0
for root, dirs, files in os.walk(frontend_lib):
    for file in files:
        if file.endswith('.dart'):
            if fix_file(os.path.join(root, file)):
                count += 1

print(f"Fixed {count} files.")
