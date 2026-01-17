/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const {setGlobalOptions} = require("firebase-functions");

// For cost control, you can set the maximum number of containers that can be
// running at the same time. This helps mitigate the impact of unexpected
// traffic spikes by instead downgrading performance. This limit is a
// per-function limit. You can override the limit for each function using the
// `maxInstances` option in the function's options, e.g.
// `onRequest({ maxInstances: 5 }, (req, res) => { ... })`.
// NOTE: setGlobalOptions does not apply to functions using the v1 API. V1
// functions should each use functions.runWith({ maxInstances: 10 }) instead.
// In the v1 API, each function can only serve one request per container, so
// this will be the maximum concurrent request count.
setGlobalOptions({maxInstances: 10});

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

/**
 * Firebase Cloud Function for LegalEase AI Chatbot
 * using DeepSeek API + Firestore context
 */

const functions = require("firebase-functions");
const admin = require("firebase-admin");
const axios = require("axios");

// Initialize Firebase Admin SDK
admin.initializeApp();
const db = admin.firestore();

// Optional: Control concurrency
functions.setGlobalOptions({ maxInstances: 10 });

// ------------------------
// LEGAL EASE CHATBOT LOGIC
// ------------------------

exports.legalChatbot = functions.https.onCall(async (data, context) => {
  const question = data?.question?.trim();

  // Validate question
  if (!question) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "A valid question is required."
    );
  }

  const snapshot = await db.collection("legal_dataset").get();

  let bestMatch = "";
  let bestScore = 0;

  snapshot.forEach((doc) => {
    const text = (doc.data().text || "").toLowerCase();
    const words = question.toLowerCase().split(/\s+/);
    const matches = words.filter((word) => text.includes(word)).length;

    if (matches > bestScore) {
      bestScore = matches;
      bestMatch = doc.data().text;
    }
  });

  if (!bestMatch) {
    bestMatch =
      "No relevant article found in the Constitution of Pakistan.";
  }

  const systemPrompt = `
You are LegalEase — a legal assistant specializing in the Constitution of Pakistan.
Use the context below to answer accurately, citing article numbers when possible.

Context:
${bestMatch}

Rules:
- Base your response ONLY on the above content.
- Be formal, neutral, and precise.
- If not found in the Constitution, politely say so.
- Always include this line:
  "Disclaimer: This is not legal advice, only educational information."
`;

  // Fetch API key from Firebase config
  const apiKey = functions.config().deepseek?.key;
  if (!apiKey) {
    throw new functions.https.HttpsError(
      "internal",
      "DeepSeek API key not configured. Run: firebase functions:config:set deepseek.key='YOUR_API_KEY'"
    );
  }

  const headers = {
    "Content-Type": "application/json",
    Authorization: `Bearer ${apiKey}`,
  };

  const body = {
    model: "deepseek-chat",
    messages: [
      { role: "system", content: systemPrompt },
      { role: "user", content: question },
    ],
  };

  try {
    const response = await axios.post(
      "https://api.deepseek.com/chat/completions",
      body,
      { headers }
    );

    const aiAnswer = response.data?.choices?.[0]?.message?.content || 
      "Sorry, I couldn't process that request.";

    return {
      answer: aiAnswer,
      context: bestMatch,
    };
  } catch (error) {
    console.error("Error from DeepSeek:", error.message);
    throw new functions.https.HttpsError(
      "internal",
      "Failed to get response from DeepSeek."
    );
  }
});
