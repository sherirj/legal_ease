import os
import json
import numpy as np
import faiss
from flask import Flask, request, jsonify
from flask_cors import CORS
import requests
from dotenv import load_dotenv
import sys
from sklearn.feature_extraction.text import TfidfVectorizer

# Load API key from .env

load_dotenv()
CLAUDE_API_KEY = os.getenv("CLAUDE_API_KEY")

if not CLAUDE_API_KEY or CLAUDE_API_KEY.strip() == "":
    print("❌ CLAUDE_API_KEY not found in .env or is empty. Please add it and restart the server.")
    sys.exit(1)

print("✅ Claude API Key loaded successfully.")

# Paths (absolute)

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DATASET_DIR = os.path.join(BASE_DIR, "datasets", "vector_index")

DOCS_PATH = os.path.join(DATASET_DIR, "docs.json")
INDEX_PATH = os.path.join(DATASET_DIR, "faiss.index")
QUERY_LOG_PATH = os.path.join(DATASET_DIR, "query_log.json")
VECTOR_SIZE = 768  

os.makedirs(DATASET_DIR, exist_ok=True)

# Flask setup

app = Flask(__name__)
CORS(app)


# Load documents

if not os.path.exists(DOCS_PATH):
    print(f"❌ {DOCS_PATH} not found! Run your dataset extraction script first.")
    sys.exit(1)

with open(DOCS_PATH, "r", encoding="utf-8") as f:
    docs = json.load(f)
print(f"✅ Loaded {len(docs)} documents.")


# Initialize TF-IDF vectorizer

print("⏳ Initializing embedding model...")
vectorizer = TfidfVectorizer(max_features=VECTOR_SIZE)

doc_texts = []
for doc in docs:
    if isinstance(doc, str):
        doc_texts.append(doc)
    elif isinstance(doc, dict):
        text = doc.get('text') or doc.get('content') or doc.get('body') or str(doc)
        doc_texts.append(text)
    else:
        doc_texts.append(str(doc))

vectorizer.fit(doc_texts)
print("✅ TF-IDF vectorizer loaded and fitted.")


# Load FAISS index

if os.path.exists(INDEX_PATH):
    index = faiss.read_index(INDEX_PATH)
    print("✅ FAISS index loaded.")
else:
    index = None
    print("⚠️ FAISS index not found. Retrieval will embed queries on the fly.")


# Load query log

if os.path.exists(QUERY_LOG_PATH):
    with open(QUERY_LOG_PATH, "r", encoding="utf-8") as f:
        query_log = json.load(f)
else:
    query_log = []

# Detect Roman Urdu vs English
def detect_language(text):
    roman_urdu_keywords = ["ka", "ki", "ke", "hai", "hain", "kya", "kaun", "kis", "ko", "se"]
    text_lower = text.lower()
    matches = sum([text_lower.count(word) for word in roman_urdu_keywords])
    return "roman_urdu" if matches >= 1 else "english"

# Claude API call

def query_claude(prompt):
    url = "https://api.anthropic.com/v1/messages"
    headers = {
        "x-api-key": CLAUDE_API_KEY,
        "anthropic-version": "2023-06-01",
        "Content-Type": "application/json"
    }
    payload = {
        "model": "claude-3-5-haiku-20241022",
        "max_tokens": 500,
        "temperature": 0.2,
        "messages": [{"role": "user", "content": prompt}]
    }
    try:
        response = requests.post(url, headers=headers, json=payload, timeout=30)
        if response.status_code == 200:
            return response.json()["content"][0]["text"]
        elif response.status_code == 401:
            print("❌ Claude API key is invalid. Check your .env file.")
            print(f"Response: {response.text}")
            sys.exit(1)
        else:
            print(f"❌ Error {response.status_code}: {response.text}")
            return f"Error: {response.status_code} - {response.text}"
    except Exception as e:
        print(f"❌ Exception calling Claude API: {e}")
        return f"Error calling Claude API: {str(e)}"


# Get embedding using TF-IDF

def get_embedding(text):
    try:
        vector = vectorizer.transform([text]).toarray()[0]
        return vector.astype("float32")
    except:
        return np.zeros(VECTOR_SIZE, dtype="float32")

# Retrieve top-k documents

def retrieve(query, k=3):
    if index is None or len(docs) == 0:
        return []
    query_vector = get_embedding(query)
    query_vector = np.array([query_vector]).astype("float32")
    faiss.normalize_L2(query_vector)
    distances, indices = index.search(query_vector, k)
    results = []
    for i in indices[0]:
        if i < len(docs):
            doc = docs[i]
            if isinstance(doc, str):
                results.append(doc)
            elif isinstance(doc, dict):
                text = doc.get('text') or doc.get('content') or doc.get('body') or str(doc)
                results.append(text)
            else:
                results.append(str(doc))
    return results

# Save query log
def save_query_log(query, answer):
    global query_log
    query_log.append({"question": query, "answer": answer})
    with open(QUERY_LOG_PATH, "w", encoding="utf-8") as f:
        json.dump(query_log, f, ensure_ascii=False, indent=2)

# Flask endpoints
@app.route("/ask", methods=["POST"])
def ask():
    data = request.json
    question = data.get("question")
    if not question:
        return jsonify({"error": "No question provided"}), 400

    lang = detect_language(question)
    relevant_docs = retrieve(question)
    context_text = "\n".join(relevant_docs)

    prompt = f"""You are a professional legal assistant. Answer the following question in {'Roman Urdu' if lang=='roman_urdu' else 'English'}, clearly and concisely.
Use legal terminology where appropriate, based on the context provided.
Do not give personal opinions.

Context:
{context_text}

Question:
{question}

Answer:"""

    answer = query_claude(prompt)
    save_query_log(question, answer)
    return jsonify({"answer": answer, "language": lang, "sources": len(relevant_docs)})

@app.route("/", methods=["GET"])
def home():
    return "✅ Legal RAG Chatbot is running. Use POST /ask to ask questions."

@app.route("/health", methods=["GET"])
def health():
    return jsonify({
        "status": "healthy",
        "documents_loaded": len(docs),
        "index_loaded": index is not None,
        "query_log_entries": len(query_log)
    })

# History endpoints
@app.route("/history", methods=["GET"])
def get_history():
    global query_log
    return jsonify({"history": query_log})

@app.route("/history/clear", methods=["DELETE"])
def clear_history():
    global query_log
    query_log = []
    with open(QUERY_LOG_PATH, "w", encoding="utf-8") as f:
        json.dump(query_log, f, ensure_ascii=False, indent=2)
    return jsonify({"status": "cleared"})

# Run Flask server
if __name__ == "__main__":
    print("🚀 Starting Legal RAG Chatbot on http://127.0.0.1:5000/")
    app.run(port=5000, debug=True)
