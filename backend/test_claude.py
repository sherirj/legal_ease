import requests

url = "https://api.anthropic.com/v1/messages"

headers = {
    "x-api-key": "YOUR_API_KEY_HERE",
    "anthropic-version": "2023-06-01",
    "content-type": "application/json"
}

data = {
    "model": "claude-3-haiku-20240307",
    "max_tokens": 200,
    "messages": [
        {"role": "user", "content": "Hello Claude, testing API."}
    ]
}

response = requests.post(url, json=data, headers=headers)
print("STATUS:", response.status_code)
print("RESPONSE:", response.text)
