import os

directory = '/home/devops/super-app/backend/app/services'
exclude_file = 'massage_service.py'

def process_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    new_content = content.replace('"verification_status": "pending"', '"verification_status": "approved"')
    new_content = new_content.replace('is_active=False', 'is_active=True')

    if new_content != content:
        with open(filepath, 'w') as f:
            f.write(new_content)
        print(f"Updated: {os.path.basename(filepath)}")

for filename in os.listdir(directory):
    if filename.endswith('.py') and filename != exclude_file:
        filepath = os.path.join(directory, filename)
        process_file(filepath)
