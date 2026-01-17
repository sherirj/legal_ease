// testChatbot.js
require("dotenv").config({ path: "./functions/touch.env" });
const fetch = require("node-fetch");

const TEST_URL = "http://127.0.0.1:5001/legalease-91e62/us-central1/legalChatbot";

async function testChatbot() {
  try {
    const apiKey = process.env.ANTHROPIC_API_KEY;
    if (!apiKey) throw new Error("Missing ANTHROPIC_API_KEY in touch.env file!");

    console.log("✅ Using API key: " + apiKey.slice(0, 10) + "...");

    const resp = await fetch(TEST_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-api-key": apiKey  // optional - if you implement verifying this header
      },
      body: JSON.stringify({
        question: "What is the punishment for theft under Pakistani law?"
      }),
    });

    const data = await resp.json();
    console.log("✅ Response from chatbot:");
    console.log(JSON.stringify(data, null, 2));

  } catch (err) {
    console.error("❌ Error testing chatbot:", err.message);
  }
}

testChatbot();
