import { createClient } from "@supabase/supabase-js";
import "dotenv/config";

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_KEY
);

// === REGISTER ===
export async function register(email, password, name) {
  const { data, error } = await supabase.auth.signUp({
    email,
    password,
    options: {
      data: { name },
    },
  });
  if (error) console.error(error);
  else console.log("Register success:", data.user.email);
}

// === LOGIN ===
export async function login(email, password) {
  const { data, error } = await supabase.auth.signInWithPassword({
    email,
    password,
  });
  if (error) console.error(error);
  else console.log("Login success:", data.user.email);
}

// === LOGOUT ===
export async function logout() {
  const { error } = await supabase.auth.signOut();
  if (error) console.error(error);
  else console.log("Logout success");
}
