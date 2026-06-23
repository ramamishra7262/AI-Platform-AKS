import { useState } from "react";
import { useNavigate, Link } from "react-router-dom";
import { login, setToken } from "../services/api.js";

export default function Login() {
  const [email, setEmail] = useState(""), [password, setPassword] = useState(""), [error, setError] = useState("");
  const nav = useNavigate();

  const handleSubmit = async (e) => {
    e.preventDefault();
    const data = await login(email, password);
    if (data.access_token) { setToken(data.access_token); nav("/"); }
    else setError(data.detail || "Login failed");
  };

  return (
    <div style={styles.page}>
      <div style={styles.card}>
        <h1 style={styles.title}>Enterprise GenAI</h1>
        <p style={styles.subtitle}>Sign in to your account</p>
        {error && <p style={styles.error}>{error}</p>}
        <form onSubmit={handleSubmit} style={styles.form}>
          <input style={styles.input} type="email" placeholder="Email" value={email} onChange={e => setEmail(e.target.value)} required />
          <input style={styles.input} type="password" placeholder="Password" value={password} onChange={e => setPassword(e.target.value)} required />
          <button style={styles.btn} type="submit">Sign In</button>
        </form>
        <p style={{ color: "var(--text-muted)", marginTop: 16, fontSize: 13 }}>
          No account? <Link to="/register" style={{ color: "var(--accent)" }}>Register</Link>
        </p>
      </div>
    </div>
  );
}

const styles = {
  page: { display: "flex", alignItems: "center", justifyContent: "center", height: "100vh", background: "var(--bg)" },
  card: { background: "var(--bg-panel)", border: "1px solid var(--border)", borderRadius: 12, padding: "40px 36px", width: 380 },
  title: { fontSize: 22, fontWeight: 700, color: "var(--text)", marginBottom: 6 },
  subtitle: { color: "var(--text-muted)", fontSize: 14, marginBottom: 24 },
  error: { color: "var(--danger)", fontSize: 13, marginBottom: 12 },
  form: { display: "flex", flexDirection: "column", gap: 12 },
  input: { background: "var(--bg-elevated)", border: "1px solid var(--border)", borderRadius: 8, padding: "10px 14px", color: "var(--text)", fontSize: 14, outline: "none" },
  btn: { background: "var(--accent)", color: "#fff", border: "none", borderRadius: 8, padding: "11px 0", fontSize: 14, fontWeight: 600, cursor: "pointer", marginTop: 4 },
};
