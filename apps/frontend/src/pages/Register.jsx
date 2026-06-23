import { useState } from "react";
import { useNavigate, Link } from "react-router-dom";
import { register } from "../services/api.js";

export default function Register() {
  const [form, setForm] = useState({ email: "", password: "", full_name: "" });
  const [error, setError] = useState("");
  const nav = useNavigate();

  const handleSubmit = async (e) => {
    e.preventDefault();
    const data = await register(form.email, form.password, form.full_name);
    if (data.id) nav("/login");
    else setError(data.detail || "Registration failed");
  };

  return (
    <div style={styles.page}>
      <div style={styles.card}>
        <h1 style={styles.title}>Create Account</h1>
        {error && <p style={styles.error}>{error}</p>}
        <form onSubmit={handleSubmit} style={styles.form}>
          <input style={styles.input} placeholder="Full Name" value={form.full_name} onChange={e => setForm({ ...form, full_name: e.target.value })} required />
          <input style={styles.input} type="email" placeholder="Email" value={form.email} onChange={e => setForm({ ...form, email: e.target.value })} required />
          <input style={styles.input} type="password" placeholder="Password (8+ chars)" value={form.password} onChange={e => setForm({ ...form, password: e.target.value })} required minLength={8} />
          <button style={styles.btn} type="submit">Register</button>
        </form>
        <p style={{ color: "var(--text-muted)", marginTop: 16, fontSize: 13 }}>
          Have an account? <Link to="/login" style={{ color: "var(--accent)" }}>Sign in</Link>
        </p>
      </div>
    </div>
  );
}

const styles = {
  page: { display: "flex", alignItems: "center", justifyContent: "center", height: "100vh", background: "var(--bg)" },
  card: { background: "var(--bg-panel)", border: "1px solid var(--border)", borderRadius: 12, padding: "40px 36px", width: 380 },
  title: { fontSize: 22, fontWeight: 700, marginBottom: 24 },
  error: { color: "var(--danger)", fontSize: 13, marginBottom: 12 },
  form: { display: "flex", flexDirection: "column", gap: 12 },
  input: { background: "var(--bg-elevated)", border: "1px solid var(--border)", borderRadius: 8, padding: "10px 14px", color: "var(--text)", fontSize: 14, outline: "none" },
  btn: { background: "var(--accent)", color: "#fff", border: "none", borderRadius: 8, padding: "11px 0", fontSize: 14, fontWeight: 600, cursor: "pointer", marginTop: 4 },
};
