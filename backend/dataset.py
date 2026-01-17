import fitz  # PyMuPDF
import os
import json
import re

# -----------------------------
# Paths
# -----------------------------
PDFS_FOLDER = "C:/Users/shariyar/Desktop/legal_ease/backend/datasets/pdfs"
DOCS_FOLDER = os.path.join(os.path.dirname(PDFS_FOLDER), "vector_index")
os.makedirs(DOCS_FOLDER, exist_ok=True)
DOCS_PATH = os.path.join(DOCS_FOLDER, "docs.json")

# -----------------------------
# Keywords
# -----------------------------
punishment_keywords = [
    "compensation", "fine", "imprisonment", "death", "support",
    "injunction", "restoration", "relief", "penalty", "public apology"
]

act_keywords = [
    "Act", "PPC", "Ordinance", "Code", "PECA", "Anti", "Crimes", "Violence"
]

dataset_keywords = ["Dataset", "DATASET"]

# -----------------------------
# Helper functions
# -----------------------------
def clean_line(line: str) -> str:
    line = line.replace("\n", " ").replace("\r", " ").strip()
    line = re.sub(r"\s+", " ", line)
    return line

def is_section(line: str) -> bool:
    return bool(re.search(r"Section[s]?\s*\d+", line, re.IGNORECASE))

def is_punishment(line: str) -> bool:
    return any(word.lower() in line.lower() for word in punishment_keywords)

# -----------------------------
# Recursively find all PDFs
# -----------------------------
pdf_files = []
for root, _, files in os.walk(PDFS_FOLDER):
    for f in files:
        if f.lower().endswith(".pdf"):
            pdf_files.append(os.path.join(root, f))

if not pdf_files:
    raise FileNotFoundError(f"No PDFs found in {PDFS_FOLDER}")

# -----------------------------
# Process PDFs
# -----------------------------
all_docs = []

for PDF_PATH in pdf_files:
    print(f"Processing {PDF_PATH} ...")
    
    try:
        doc = fitz.open(PDF_PATH)
    except Exception as e:
        print(f"Failed to open {PDF_PATH}: {e}")
        continue

    text = ""
    for page in doc:
        page_text = page.get_text("text")
        page_text = re.sub(r"Page\s*\d+\s*of\s*\d+", "", page_text, flags=re.IGNORECASE)
        text += page_text + "\n"

    lines = [clean_line(line) for line in text.splitlines() if clean_line(line)]

    current_dataset = ""
    i = 0
    while i < len(lines):
        line = lines[i]

        # Detect dataset headers
        if any(kw.lower() in line.lower() for kw in dataset_keywords):
            current_dataset = line
            i += 1
            continue

        # Detect Act lines
        if any(kw.lower() in line.lower() for kw in act_keywords):
            category = lines[i-1] if i-1 >= 0 else current_dataset
            act = line
            section_lines = []
            description_lines = []
            punishment_lines = []

            j = i + 1
            while j < len(lines):
                l = lines[j]

                if is_section(l):
                    # Start of a section
                    section_lines.append(l)
                elif is_punishment(l):
                    # Start of punishment, capture all consecutive punishment lines
                    while j < len(lines) and is_punishment(lines[j]):
                        punishment_lines.append(lines[j])
                        j += 1
                    break
                else:
                    # Otherwise treat as description
                    description_lines.append(l)

                j += 1

            paragraph = {
                "Category": category.strip(),
                "Act": act.strip(),
                "Section": " ".join(section_lines).strip(),
                "Description": " ".join(description_lines).strip(),
                "Punishment": " ".join(punishment_lines).strip()
            }

            if any(paragraph.values()):  # Only keep if something exists
                all_docs.append(paragraph)

            i = j
        else:
            i += 1

# -----------------------------
# Remove duplicates across all PDFs
# -----------------------------
final_docs = []
seen = set()
for doc_item in all_docs:
    doc_tuple = tuple(doc_item.items())
    if doc_tuple not in seen:
        seen.add(doc_tuple)
        final_docs.append(doc_item)

# -----------------------------
# Save to JSON
# -----------------------------
with open(DOCS_PATH, "w", encoding="utf-8") as f:
    json.dump(final_docs, f, ensure_ascii=False, indent=2)

print(f"\nExtraction complete! {len(final_docs)} paragraphs saved to {DOCS_PATH}")
