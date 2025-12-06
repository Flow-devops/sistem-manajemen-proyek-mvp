import { register, login, logout } from "./auth.js";

await register("userbaru@gmail.com", "password123", "Ajeng");
await login("userbaru@gmail.com", "password123");
await logout();
