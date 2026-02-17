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
    print("❌ CLAUDE_API_KEY not found in .env or is empty.")
    sys.exit(1)

print("✅ Claude API Key loaded successfully.")

# Paths
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DATASET_DIR = os.path.join(BASE_DIR, "datasets", "vector_index")

DOCS_PATH = os.path.join(DATASET_DIR, "docs.json")
INDEX_PATH = os.path.join(DATASET_DIR, "faiss.index")
QUERY_LOG_PATH = os.path.join(DATASET_DIR, "query_log.json")

os.makedirs(DATASET_DIR, exist_ok=True)

# Flask setup
app = Flask(__name__)
CORS(app)

# Load documents
if not os.path.exists(DOCS_PATH):
    print(f"❌ {DOCS_PATH} not found!")
    sys.exit(1)

with open(DOCS_PATH, "r", encoding="utf-8") as f:
    docs = json.load(f)

# Filter out empty/invalid docs
docs = [d for d in docs if d and isinstance(d, (str, dict))]
print(f"✅ Loaded {len(docs)} documents.")

# Initialize TF-IDF vectorizer
print("⏳ Initializing TF-IDF vectorizer...")
vectorizer = TfidfVectorizer(max_features=5000, lowercase=True, stop_words='english')

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
vectors = vectorizer.transform(doc_texts).toarray().astype("float32")
VECTOR_SIZE = vectors.shape[1]  # Get actual vector dimension

print(f"✅ TF-IDF vectorizer fitted. Vector dimension: {VECTOR_SIZE}")

# Load or create FAISS index
if os.path.exists(INDEX_PATH):
    index = faiss.read_index(INDEX_PATH)
    print(f"✅ FAISS index loaded ({index.ntotal} vectors).")
else:
    print("⏳ Building FAISS index from documents...")
    index = faiss.IndexFlatL2(VECTOR_SIZE)
    faiss.normalize_L2(vectors)
    index.add(vectors)
    faiss.write_index(index, INDEX_PATH)
    print(f"✅ FAISS index created with {index.ntotal} vectors.")

# Load query log
if os.path.exists(QUERY_LOG_PATH):
    with open(QUERY_LOG_PATH, "r", encoding="utf-8") as f:
        query_log = json.load(f)
else:
    query_log = []

# Detect language
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
        else:
            print(f"❌ Claude API Error {response.status_code}")
            return f"Error: {response.status_code}"
    except Exception as e:
        print(f"❌ Exception: {e}")
        return f"Error: {str(e)}"

# Get embedding
def get_embedding(text):
    try:
        vector = vectorizer.transform([text]).toarray()[0]
        return vector.astype("float32")
    except:
        return np.zeros(VECTOR_SIZE, dtype="float32")

# Retrieve documents with debugging
def retrieve(query, k=5, min_score=0.25):
    """Retrieve top-k documents with similarity scoring"""
    if index is None or len(docs) == 0:
        return [], []
    
    query_vector = get_embedding(query)
    query_vector = np.array([query_vector]).astype("float32")
    faiss.normalize_L2(query_vector)
    
    distances, indices = index.search(query_vector, k)
    
    results = []
    scores = []
    
    for dist, idx in zip(distances[0], indices[0]):
        if idx < len(docs):
            # Lower distance = higher similarity in L2
            similarity_score = 1 / (1 + dist)  # Convert distance to similarity (0-1)
            
            if similarity_score >= min_score:
                doc = docs[idx]
                if isinstance(doc, str):
                    results.append(doc)
                    scores.append(similarity_score)
                elif isinstance(doc, dict):
                    text = doc.get('text') or doc.get('content') or doc.get('body') or str(doc)
                    results.append(text)
                    scores.append(similarity_score)
    
    return results, scores

# Save query log
def save_query_log(query, answer, sources, grounded):
    global query_log
    query_log.append({
        "question": query,
        "answer": answer,
        "sources": sources,
        "grounded": grounded
    })
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
    relevant_docs, scores = retrieve(question, k=5, min_score=0.20)
    
    # If no relevant documents found
    if not relevant_docs:
        if lang == "roman_urdu":
            answer = (
                "Mujhe afsos hai, lekin mojooda dataset mein is sawal ka "
                "koi mustanad qanooni jawab mojood nahi hai."
            )
        else:
            answer = (
                "I'm sorry, but the provided dataset does not contain relevant "
                "information to answer this question."
            )
        save_query_log(question, answer, 0, False)
        return jsonify({
            "answer": answer,
            "language": lang,
            "sources": 0,
            "grounded": False,
            "scores": []
        })
    
    context_text = "\n\n".join(relevant_docs)

    prompt = f"""You are a professional legal assistant for Pakistani law. Answer ONLY based on the provided context.
If the context does not contain the answer, state explicitly that this information is not in the dataset.
Use legal terminology. Do not give personal opinions or use outside knowledge.

Answer in {'Roman Urdu' if lang=='roman_urdu' else 'English'}.

Context:
{context_text}

Question:
{question}

Answer:"""

    answer = query_claude(prompt)
    save_query_log(question, answer, len(relevant_docs), True)
    
    return jsonify({
        "answer": answer,
        "language": lang,
        "sources": len(relevant_docs),
        "grounded": True,
        "similarity_scores": [float(s) for s in scores]
    })

@app.route("/", methods=["GET"])
def home():
    return "✅ Legal RAG Chatbot is running. Use POST /ask to ask questions."

@app.route("/health", methods=["GET"])
def health():
    return jsonify({
        "status": "healthy",
        "documents_loaded": len(docs),
        "index_vectors": index.ntotal if index else 0,
        "vector_dimension": VECTOR_SIZE,
        "query_log_entries": len(query_log)
    })

@app.route("/history", methods=["GET"])
def get_history():
    return jsonify({"history": query_log})

@app.route("/history/clear", methods=["DELETE"])
def clear_history():
    global query_log
    query_log = []
    with open(QUERY_LOG_PATH, "w", encoding="utf-8") as f:
        json.dump(query_log, f, ensure_ascii=False, indent=2)
    return jsonify({"status": "cleared"})

@app.route("/debug/sample-questions", methods=["GET"])
def sample_questions():
    """Return sample questions from dataset and outside"""
    inside = [
        "What is the punishment for murder?",
        "What are the sections for rape under Pakistani law?",
        "What is the punishment for theft?",
        "What does the Domestic Violence Act cover?",
        "What is dowry violence?"
    ]
    outside = [
        "How do I cook a pizza?",
        "What is the weather today?",
        "Tell me about the history of the United States",
        "How do I learn machine learning?",
        "What are the best movies of 2024?"
    ]
    return jsonify({
        "inside_dataset": inside,
        "outside_dataset": outside
    })

if __name__ == "__main__":
    print("🚀 Starting Legal RAG Chatbot on http://127.0.0.1:5000/")
    app.run(port=5000, debug=True)