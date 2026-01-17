import os
import json
import numpy as np
import faiss
import requests
from dotenv import load_dotenv

# -----------------------------
# Load API key
# -----------------------------
load_dotenv()
CLAUDE_API_KEY = os.getenv("CLAUDE_API_KEY")

# -----------------------------
# Paths
# -----------------------------
DOCS_PATH = "vector_index/docs.json"
INDEX_PATH = "vector_index/faiss.index"
VECTOR_SIZE = 768  # Adjust for Claude embeddings

# -----------------------------
# Load documents
# -----------------------------
with open(DOCS_PATH, "r", encoding="utf-8") as f:
    docs = json.load(f)

# -----------------------------
# Function to get Claude embeddings
# -----------------------------
def get_embedding(text):
    url = "https://api.anthropic.com/v1/embeddings"
    headers = {
        "Authorization": f"Bearer {CLAUDE_API_KEY}",
        "Content-Type": "application/json",
    }
    payload = {
        "model": "claude-3.5-embedding",
        "input": text
    }
    response = requests.post(url, headers=headers, json=payload)
    if response.status_code == 200:
        return np.array(response.json()["embedding"], dtype="float32")
    else:
        raise Exception(f"Embedding API error: {response.text}")

# -----------------------------
# Build embeddings
# -----------------------------
embeddings = []
for doc in docs:
    emb = get_embedding(doc)
    embeddings.append(emb)

embeddings = np.array(embeddings)

# -----------------------------
# Build FAISS index
# -----------------------------
index = faiss.IndexFlatL2(VECTOR_SIZE)
index.add(embeddings)
faiss.write_index(index, INDEX_PATH)

print(f"FAISS index built with {len(docs)} documents and saved to {INDEX_PATH}")
