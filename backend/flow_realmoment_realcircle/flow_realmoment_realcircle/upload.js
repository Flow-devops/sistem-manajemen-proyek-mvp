import { createClient } from "@supabase/supabase-js";
import dotenv from "dotenv";
import fs from "fs";

dotenv.config();

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_KEY
);

// Fungsi upload gambar ke Supabase Storage
export async function uploadImage(userId, filePath, caption) {
  const fileName = `${Date.now()}_${filePath.split("/").pop()}`;
  const fileBuffer = fs.readFileSync(filePath);

  // 1️⃣ Upload ke storage Supabase
  const { data, error: uploadError } = await supabase.storage
    .from("uploads") // pastikan kamu sudah buat bucket "uploads"
    .upload(fileName, fileBuffer, {
      contentType: "image/jpeg",
    });

  if (uploadError) throw uploadError;

  // 2️⃣ Dapatkan public URL
  const { data: publicData } = supabase.storage
    .from("uploads")
    .getPublicUrl(fileName);

  // 3️⃣ Simpan metadata ke tabel posts
  const { error: insertError } = await supabase
    .from("posts")
    .insert([{ user_id: userId, caption, image_url: publicData.publicUrl }]);

  if (insertError) throw insertError;

  console.log("Upload sukses:", publicData.publicUrl);
  return publicData.publicUrl;
}
