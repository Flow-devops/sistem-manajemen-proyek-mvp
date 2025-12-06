import express from "express";
import { createClient } from "@supabase/supabase-js";
import cors from "cors";
import "dotenv/config";
import multer from "multer";
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

// === FIX __dirname dan __filename dulu ===
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
const upload = multer({ dest: "upload/" }); // folder lokal sementara

app.use(express.static(__dirname));
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_KEY
);

// === REGISTER API ===
app.post("/api/register", async (req, res) => {
  const { email, password, name } = req.body;
  try {
    const { data, error } = await supabase.auth.signUp({
      email,
      password,
      options: { data: { name } },
    });
    if (error) throw error;
    res.json({ message: "Register success", user: data.user });
  } catch (err) {
    const message =
      err.message || err.error_description || "Terjadi kesalahan.";

    if (message.includes("User already registered")) {
      res.status(400).json({ error: "Email sudah terdaftar, silakan login." });
    } else {
      res.status(400).json({ error: message });
    }
  }
});

// === LOGIN API ===
app.post("/api/login", async (req, res) => {
  const { email, password } = req.body;
  try {
    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password,
    });
    if (error) throw error;
    res.json({ message: "Login success", user: data.user });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

// === LOGOUT API ===
app.post("/api/logout", async (req, res) => {
  try {
    const { error } = await supabase.auth.signOut();
    if (error) throw error;
    res.json({ message: "Logout success" });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

// === UPLOAD FOTO ===
app.post("/api/uploads", upload.single("image"), async (req, res) => {
  try {
    const { user_id, caption } = req.body;
    const filePath = req.file.path;
    const fileName = `${Date.now()}_${req.file.originalname}`;
    const fileBuffer = fs.readFileSync(filePath);

    const { data, error: uploadError } = await supabase.storage
      .from("uploads")
      .upload(fileName, fileBuffer, {
        contentType: req.file.mimetype,
      });

    if (uploadError) throw uploadError;

    const { data: publicData } = supabase.storage
      .from("upload")
      .getPublicUrl(fileName);

    const { error: insertError } = await supabase.from("posts").insert([
      {
        user_id,
        caption,
        image_url: publicData.publicUrl,
      },
    ]);

    if (insertError) throw insertError;

    res.status(200).json({
      message: "Upload berhasil!",
      imageUrl: publicData.publicUrl,
    });
  } catch (err) {
    console.error(err);
    res.status(400).json({ error: err.message });
  }
});

// === GET FEED ===
app.get("/api/feed", async (req, res) => {
  try {
    const { data, error } = await supabase
      .from("posts")
      .select("*")
      .order("created_at", { ascending: false });

    if (error) throw error;
    res.status(200).json(data);
  } catch (err) {
    console.error(err);
    res.status(400).json({ error: err.message });
  }
});

app.post("/api/reset-password", async (req, res) => {
  const token = req.headers.authorization?.replace("Bearer ", "");
  const { newPassword } = req.body;
  if (!token) return res.status(400).json({ error: "Missing token" });

  await supabase.auth.setSession({
    access_token: token,
    refresh_token: token,
  });

  const { data, error } = await supabase.auth.updateUser({
    password: newPassword,
  });

  if (error) return res.status(400).json({ error });

  res.json({ message: "Password updated" });
});

app.get("/", (req, res) => {
  res.sendFile(path.join(__dirname, "app.html"));
});

const PORT = 3000;
app.listen(PORT, () =>
  console.log(`Server running on http://localhost:${PORT}`)
);
