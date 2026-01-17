const { initializeApp } = require("firebase/app");
const {
  getFirestore,
  collection,
  addDoc,
  connectFirestoreEmulator,
} = require("firebase/firestore");

const firebaseConfig = {
  projectId: "legalease-91e62", 
};

const app = initializeApp(firebaseConfig);
const db = getFirestore(app);
connectFirestoreEmulator(db, "127.0.0.1", 8081);

const data = [
  { category: "Contract", act: "Contract Act, 1872", section: "Section 73", description: "Compensation for loss or damage", punishment: "Monetary compensation as per loss" },
  { category: "Property Dispute", act: "Transfer of Property Act, 1882", section: "Sections 5–54", description: "Transfer of immovable property", punishment: "Civil suit for possession / injunction" },
  { category: "Specific Relief", act: "Specific Relief Act, 1877", section: "Sections 5–13", description: "Relief for breach of obligations", punishment: "Injunction, restitution, performance" },
  { category: "Tort Claims", act: "Civil Procedure Code, 1908", section: "Order 20 Rule 1", description: "Civil remedies for harm", punishment: "Compensation, declaration, specific relief" },
  { category: "Defamation", act: "Defamation Ordinance, 2002", section: "Sections 3, 8", description: "Harm to reputation", punishment: "Up to PKR 100,000 + public apology" },
  { category: "Murder", act: "Pakistan Penal Code (PPC), 1860", section: "Section 302", description: "Intentional killing", punishment: "Death penalty or life imprisonment + fine" },
  { category: "Attempt to Murder", act: "PPC, 1860", section: "Section 324", description: "Attempt to cause death", punishment: "Up to 10 years + fine" },
  { category: "Theft", act: "PPC, 1860", section: "Section 378, 379", description: "Theft of movable property", punishment: "Up to 3 years + fine" },
  { category: "Rape", act: "PPC + Anti-Rape Act, 2021", section: "Section 375, 376", description: "Sexual assault", punishment: "Min 10 years to death penalty" },
  { category: "Blasphemy", act: "PPC, 1860", section: "Sections 295–298", description: "Insulting religion or prophets", punishment: "From 3 years to death penalty" },
  { category: "Cybercrime", act: "PECA (2016)", section: "Sections 20, 21, 24", description: "Cyber harassment, blackmail, defamation", punishment: "Up to 7 years imprisonment + fine" },
  { category: "Terrorism", act: "Anti-Terrorism Act, 1997", section: "Sections 6–7", description: "Use of force to coerce state/populace", punishment: "Death or life imprisonment" },
  { category: "Marriage Registration", act: "Muslim Family Laws Ordinance, 1961", section: "Section 5", description: "Nikah must be registered", punishment: "Fine up to PKR 25,000" },
  { category: "Polygamy", act: "Muslim Family Laws Ordinance, 1961", section: "Section 6", description: "Marrying again without first wife's permission", punishment: "1 year jail + fine" },
  { category: "Divorce", act: "Muslim Family Laws Ordinance, 1961", section: "Section 7", description: "Notice of divorce must be sent to chairman", punishment: "Divorce not effective until approved" },
  { category: "Child Custody", act: "Guardian and Wards Act, 1890", section: "Sections 7–25", description: "Appointment of guardian", punishment: "Court decides in child's best interest" },
  { category: "Child Marriage", act: "Child Marriage Restraint Act, 1929", section: "Section 4", description: "Marriage under age", punishment: "1 month jail + fine" },
  { category: "Maintenance", act: "West Pakistan Family Courts Act, 1964", section: "Section 5(c)", description: "Financial maintenance for wife/children", punishment: "Court-ordered monthly support" },
  { category: "Physical Abuse", act: "Domestic Violence (Sindh) Act, 2013", section: "Section 2(e), 3", description: "Bodily harm by family member", punishment: "2 years + fine + protection order" },
  { category: "Emotional Abuse", act: "Punjab DV Act, 2016", section: "Section 2(f), 3", description: "Insults, threats, emotional harm", punishment: "Restraining orders + fine" },
  { category: "Economic Abuse", act: "KPK DV Act, 2021", section: "Section 2(h), 3", description: "Controlling access to finances", punishment: "Restitution + relief" },
  { category: "Sexual Abuse", act: "PPC Section 375–376", section: "Section 375–376", description: "Coercive sexual behavior", punishment: "10 years to death penalty" },
  { category: "Dowry Violence", act: "PPC + Qisas & Diyat", section: "Section 302", description: "Killing for dowry", punishment: "Death or life imprisonment" },
  { category: "Harassment", act: "PECA + PPC", section: "Section 20, 506", description: "Threats or harassment", punishment: "2–7 years + fine" },
  { category: "Forced Eviction", act: "PPC + DV Acts", section: "Section 441", description: "Unlawful removal from home", punishment: "Imprisonment + re-entry order" },
  { category: "Acid Attack", act: "Acid Crime Prevention Act, 2011", section: "Section 336B/C", description: "Acid attack in domestic conflict", punishment: "14 years to life + PKR 1 million fine" },
];

(async () => {
  try {
    for (const item of data) {
      await addDoc(collection(db, "legal_dataset"), item);
    }
    console.log("✅ Legal dataset added successfully!");
  } catch (err) {
    console.error("❌ Error adding data:", err);
  }
})();