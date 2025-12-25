// index.js
import express from "express";
import cors from "cors";
import dotenv from "dotenv";
import { createClient } from "@supabase/supabase-js";

dotenv.config();

const app = express();
app.use(cors());
app.use(express.json());

const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_KEY);

// Basic prompts (modify as you like)
const PROMPTS = [
  "Foto sesuatu yang berwarna biru di sekitarmu.",
  "Ambil foto langit sekarang.",
  "Foto sesuatu yang membuatmu tersenyum hari ini.",
  "Ambil gambar detail (close-up) sebuah benda.",
  "Foto tekstur — pohon, kain, atau tembok.",
  "Tangkap bayangan yang menarik.",
  "Foto makanan yang kamu temui hari ini.",
  "Ambil foto pemandangan dari sudut rendah.",
  "Foto sesuatu yang berkilau.",
  "Ambil foto ruangan tempatmu sekarang."
];

function randomPrompt() {
  return PROMPTS[Math.floor(Math.random() * PROMPTS.length)];
}

// Helper: check existing quest in last 24 hours
async function getRecentQuestForUser(userId) {
  const { data, error } = await supabase
    .from("daily_quests")
    .select("*")
    .eq("user_id", userId)
    .order("created_at", { ascending: false })
    .limit(1);

  if (error) throw error;
  if (!data || !data.length) return null;
  const quest = data[0];
  const createdAt = new Date(quest.created_at);
  const hours = (Date.now() - createdAt.getTime()) / (1000 * 60 * 60);
  if (hours < 24) return quest;
  return null;
}

// GET endpoint: fetch or create new quest if older than 24h
app.get("/api/daily-quest", async (req, res) => {
  try {
    const userId = req.query.user_id;
    if (!userId) return res.status(400).json({ error: "Missing user_id" });

    const recent = await getRecentQuestForUser(userId);
    if (recent) {
      return res.json({ quest: recent, created_new: false });
    }

    const text = randomPrompt();
    const { data, error } = await supabase
      .from("daily_quests")
      .insert([{ user_id: userId, quest_text: text }])
      .select()
      .single();

    if (error) throw error;
    return res.json({ quest: data, created_new: true });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: err.message || err });
  }
});

// POST endpoint: force-create new quest for user
app.post("/api/daily-quest", async (req, res) => {
  try {
    const { user_id } = req.body;
    if (!user_id) return res.status(400).json({ error: "Missing user_id" });
    const text = randomPrompt();
    const { data, error } = await supabase
      .from("daily_quests")
      .insert([{ user_id, quest_text: text }])
      .select()
      .single();
    if (error) throw error;
    return res.json({ quest: data });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: err.message || err });
  }
});

const port = process.env.PORT || 3001;
app.listen(port, () => console.log(`DailyQuest server running on http://localhost:${port}`));
