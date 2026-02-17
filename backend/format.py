import json
import os

# Load your current docs
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DATASET_DIR = os.path.join(BASE_DIR, "datasets", "vector_index")
DOCS_PATH = os.path.join(DATASET_DIR, "docs.json")

with open(DOCS_PATH, "r", encoding="utf-8") as f:
    raw_docs = json.load(f)

# Format each document into a coherent text block
formatted_docs = []

for doc in raw_docs:
    # Skip empty or invalid docs
    if not doc or all(not str(v).strip() or v in ["Category", "Act", "Section", "Description", "Punishment"] 
                       for v in doc.values()):
        continue
    
    # Combine all fields into a readable text block
    text_block = f"""
Category: {doc.get('Category', '').strip() or 'N/A'}
Act/Ordinance: {doc.get('Act', '').strip() or 'N/A'}
Section: {doc.get('Section', '').strip() or 'N/A'}
Description: {doc.get('Description', '').strip() or 'N/A'}
Punishment/Relief: {doc.get('Punishment', '').strip() or 'N/A'}
""".strip()
    
    # Only add if it has meaningful content
    if len(text_block) > 50:
        formatted_docs.append(text_block)

print(f"Formatted {len(formatted_docs)} documents")

# Save formatted docs
with open(DOCS_PATH, "w", encoding="utf-8") as f:
    json.dump(formatted_docs, f, ensure_ascii=False, indent=2)

print(f"✅ Saved formatted documents to {DOCS_PATH}")

# Print sample docs
print("\n📄 Sample formatted documents:\n")
for i, doc in enumerate(formatted_docs[:3]):
    print(f"--- Document {i+1} ---")
    print(doc)
    print()