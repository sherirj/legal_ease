const admin = require("firebase-admin");
const serviceAccount = require("./service_account_key.json"); 
const legalDataset = require("./legal_dataset.json");      


admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();


async function upload() {
  for (const item of legalDataset) {
    try {
      await db.collection("legal_dataset").doc(item.id).set({
        category: item.category,
        act: item.act,
        section: item.section,
        description: item.description,
        punishment: item.punishment
      });
      console.log(`Uploaded ${item.id}`);
    } catch (err) {
      console.error(`Error uploading ${item.id}:`, err);
    }
  }
  console.log("All data uploaded!");
}

// Run the upload
upload().catch(console.error);