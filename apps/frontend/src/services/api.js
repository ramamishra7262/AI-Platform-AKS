const BASE = import.meta.env.VITE_API_URL || "";
let token = localStorage.getItem("token");

export const setToken = (t) => { token = t; localStorage.setItem("token", t); };
export const clearToken = () => { token = null; localStorage.removeItem("token"); };

const headers = (extra = {}) => ({
  "Content-Type": "application/json",
  ...(token ? { Authorization: `Bearer ${token}` } : {}),
  ...extra,
});

export const login = (email, password) =>
  fetch(`${BASE}/api/v1/auth/login`, {
    method: "POST", headers: headers(),
    body: JSON.stringify({ email, password }),
  }).then((r) => r.json());

export const register = (email, password, full_name) =>
  fetch(`${BASE}/api/v1/auth/register`, {
    method: "POST", headers: headers(),
    body: JSON.stringify({ email, password, full_name }),
  }).then((r) => r.json());

export const sendChat = (session_id, message) =>
  fetch(`${BASE}/api/v1/chat/`, {
    method: "POST", headers: headers(),
    body: JSON.stringify({ session_id, message }),
  }).then((r) => r.json());

export const uploadDocument = (file) => {
  const form = new FormData();
  form.append("file", file);
  return fetch(`${BASE}/api/ingest/upload`, {
    method: "POST", headers: { ...(token ? { Authorization: `Bearer ${token}` } : {}) },
    body: form,
  }).then((r) => r.json());
};

export const getChatHistory = (session_id) =>
  fetch(`${BASE}/api/v1/chat/history/${session_id}`, { headers: headers() }).then((r) => r.json());
