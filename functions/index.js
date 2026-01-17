// ----------------- index.js -----------------
const { setGlobalOptions } = require("firebase-functions");
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const path = require("path");
require("dotenv").config({ path: path.resolve(__dirname, "touch.env") }); 

const Anthropic = require("@anthropic-ai/sdk");

// Max concurrent instances
setGlobalOptions({ maxInstances: 10 });

// Initialize Firebase Admin
if (process.env.FIRESTORE_EMULATOR_HOST) {
  console.log("🔥 Connected to Firestore Emulator at", process.env.FIRESTORE_EMULATOR_HOST);
  admin.initializeApp({ projectId: "legalease-91e62" });
} else {
  admin.initializeApp();
}

const db = admin.firestore();

// Initialize Claude API
let anthropic = null;
if (process.env.ANTHROPIC_API_KEY) {
  anthropic = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY });
  console.log("✅ Claude API key loaded successfully.");
} else {
  console.warn("⚠️ No ANTHROPIC_API_KEY found — Claude responses will be disabled.");
}

// ----------------- Legal Chatbot -----------------
exports.legalChatbot = functions.https.onRequest(async (req, res) => {
  try {
    console.log("📩 Incoming chatbot request...");
    const question = req.body?.question?.trim();

    if (!question) {
      return res.status(400).json({ error: "A valid question is required." });
    }

    console.log("🧠 Searching Firestore for related law...");
    const snapshot = await db.collection("legal_dataset").get();

    let bestDoc = null;
    let bestScore = 0;

    snapshot.forEach((doc) => {
      const { category, act, section, description, punishment } = doc.data();
      const combinedText = `${category} ${act} ${section} ${description} ${punishment}`.toLowerCase();
      const words = question.toLowerCase().split(/\s+/);
      const matches = words.filter((word) => combinedText.includes(word)).length;

      if (matches > bestScore) {
        bestScore = matches;
        bestDoc = doc.data();
      }
    });

    if (!bestDoc) {
      bestDoc = {
        description: "No relevant law found in the dataset.",
        act: "N/A",
        section: "N/A",
        punishment: "N/A",
      };
    }

    const bestMatch = `
Category: ${bestDoc.category || "N/A"}
Act: ${bestDoc.act}
Section: ${bestDoc.section}
Description: ${bestDoc.description}
Punishment: ${bestDoc.punishment}
`;

    const systemPrompt = `
You are LegalEase — a legal assistant trained on Pakistan's Constitution and laws.

Use the context below to answer clearly, referencing the law's act and section where relevant.

Context:
${bestMatch}

Rules:
- Base your answer ONLY on this context.
- If the question is unrelated, respond: "Sorry, this law is not covered in my dataset."
- Always include: "Disclaimer: This is not legal advice, only educational information."
`;

    if (!anthropic) {
      console.warn("⚠️ Skipping Claude request — no API key set.");
      return res.json({
        answer: "Claude API key not configured. Please add ANTHROPIC_API_KEY to your touch.env file.",
        context: bestMatch,
      });
    }

    const completion = await anthropic.messages.create({
      model: "claude-3-5-haiku-20241022",
      max_tokens: 800,
      system: systemPrompt,
      messages: [
        { role: "user", content: question },
      ],
    });

    const aiAnswer = completion.content?.[0]?.text || "Sorry, I couldn't process that request.";

    return res.json({
      answer: aiAnswer,
      context: bestMatch,
    });

  } catch (error) {
    console.error("❌ Error in legalChatbot:", error);

    if (error.response?.status === 401) {
      return res.status(401).json({
        error: "Invalid or unauthorized Claude API key. Please verify your ANTHROPIC_API_KEY.",
      });
    }

    return res.status(500).json({
      error: error.message || "An unexpected error occurred in the chatbot.",
    });
  }
});

// ----------------- Chat Notification -----------------
exports.notifyOnNewMessage = functions.firestore
  .document('chats/{chatId}/messages/{messageId}')
  .onCreate(async (snap, context) => {
    const message = snap.data();
    const chatId = context.params.chatId;
    if (!message) return null;

    const senderId = message.userId;
    const text = message.text || '';
    const attachmentName = message.attachmentName || null;

    const chatDoc = await admin.firestore().collection('chats').doc(chatId).get();
    const chatData = chatDoc.data() || {};
    const participants = chatData.participants || [];

    const recipients = participants.filter(uid => uid !== senderId);
    if (recipients.length === 0) return null;

    const tokens = [];
    for (const uid of recipients) {
      const userDoc = await admin.firestore().collection('users').doc(uid).get();
      const userData = userDoc.data() || {};
      if (userData.fcmTokens) tokens.push(...userData.fcmTokens);
    }

    if (tokens.length === 0) return null;

    const payload = {
      notification: {
        title: chatData.title || 'New message',
        body: attachmentName ? `${attachmentName}` : (text.length > 80 ? text.substring(0, 80) + '...' : text),
      },
      data: {
        chatId,
        messageId: context.params.messageId,
      }
    };

    try {
      return await admin.messaging().sendToDevice(tokens, payload);
    } catch (err) {
      console.error('FCM error', err);
      return null;
    }
  });

// ----------------- Update Case Status -----------------
exports.updateCaseStatus = functions.https.onCall(async (data, context) => {
  try {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be logged in.');
    }

    const { docId, status } = data;
    if (!docId || !status) {
      throw new functions.https.HttpsError('invalid-argument', 'docId and status are required.');
    }

    const bookingRef = db.collection('bookings').doc(docId);
    const bookingSnap = await bookingRef.get();
    if (!bookingSnap.exists) {
      throw new functions.https.HttpsError('not-found', 'Booking not found.');
    }

    const bookingData = bookingSnap.data();
    const lawyerId = bookingData?.lawyerId;
    if (!lawyerId) {
      throw new functions.https.HttpsError('failed-precondition', 'Booking has no assigned lawyer.');
    }

    // Update booking status
    await bookingRef.update({ status });

    // Update lawyer stats
    const lawyerRef = db.collection('lawyers').doc(lawyerId);
    const lawyerSnap = await lawyerRef.get();
    if (lawyerSnap.exists) {
      const data = lawyerSnap.data() || {};
      const totalCases = (data.totalCases || 0) + 1;
      let wonCases = data.wonCases || 0;
      let lostCases = data.lostCases || 0;

      if (status === 'Won') wonCases += 1;
      if (status === 'Lost') lostCases += 1;

      await lawyerRef.update({
        totalCases,
        wonCases,
        lostCases
      });
    }

    return { success: true, message: `Case marked as ${status}` };
  } catch (error) {
    console.error('updateCaseStatus error:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});
