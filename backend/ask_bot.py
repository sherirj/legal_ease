import requests

url = "http://127.0.0.1:5000/ask"

print("💬 Welcome to Legal RAG Chatbot! Type 'exit' to quit.")

while True:
    question = input("Your question: ")
    if question.lower() in ["exit", "quit"]:
        break

    response = requests.post(url, json={"question": question})
    if response.status_code == 200:
        print("\nAnswer:\n", response.json()["answer"], "\n")
    else:
        print("Error:", response.json())
