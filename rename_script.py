import os
import sys

def replace_in_file(filepath, replacements):
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
            
        new_content = content
        for old, new in replacements.items():
            new_content = new_content.replace(old, new)
            
        if content != new_content:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(new_content)
            print(f"Updated {filepath}")
    except Exception as e:
        pass

def main():
    directory = r"e:\zip_link_ repo\Share_App"
    
    replacements = {
        "filesharing": "ziplink",
        "FileSharing": "ZipLink",
        "fileServing": "zipLinking", # Just in case
        "fileSharingApp": "ziplinkApp",
        "File Share Server": "ZipLink Server"
    }

    for root, dirs, files in os.walk(directory):
        if '.git' in root or '.dart_tool' in root or 'build' in root:
            continue
        for file in files:
            if file.endswith(('.dart', '.yaml', '.xml', '.plist', '.json', '.xcconfig', '.pbxproj')):
                filepath = os.path.join(root, file)
                replace_in_file(filepath, replacements)

if __name__ == '__main__':
    main()
