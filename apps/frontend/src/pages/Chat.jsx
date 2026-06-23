import { useState, useRef, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import ReactMarkdown from "react-markdown";
import { sendChat, uploadDocument, clearToken } from "../services/api.js";

const SESSION_ID = "session-" + Date.now();

export default function Chat() {
  const [messages, setMessages] = useState([]);
  const [input, setInput] = useState("");
  const [loading, setLoading] = useState(false);
  const [uploading, setUploading] = useState(false);
  const [uploadStatus, setUploadStatus] = useState("");
  const bottomRef = useRef(null);
  const fileRef = useRef(null);
  const nav = useNavigate();

  useEffect(() => { bottomRef.current?.scrollIntoView({ behavior: "smooth" }); }, [messages]);

  const send = async () => {
    if (!input.trim() || loading) return;
    const userMsg = { role: "user", content: input };
    setMessages(m => [...m, userMsg]);
    setInput(""); setLoading(true);
    try {
      const data = await sendChat(SESSION_ID, userMsg.content);
      setMessages(m => [...m, { role: "assistant", content: data.answer || "No response", sources: data.sources }]);
    } catch {
      setMessages(m => [...m, { role: "assistant", content: "Error: Could not reach API." }]);
    } finally { setLoading(false); }
  };

  const handleUpload = async (e) => {
    const file = e.target.files[0];
    if (!file) return;
    setUploading(true); setUploadStatus("Uploading...");
    try {
      const data = await uploadDocument(file);
      setUploadStatus(data.status === "processing" ? `Processing ${file.name}...` : `Done: ${file.name}`);
    } catch { setUploadStatus("Upload failed"); }
    finally { setUploading(false); }
  };

  return (
    <div style={s.shell}>
      {/* Sidebar */}
      <aside style={s.sidebar}>
        <div style={s.sidebarTitle}>Enterprise GenAI</div>
        <button style={s.uploadBtn} onClick={() => fileRef.current?.click()} disabled={uploading}>
          {uploading ? "Uploading..." : "+ Upload Document"}
        </button>
        <input ref={fileRef} type="file" accept=".pdf" style={{ display: "none" }} onChange={handleUpload} />
        {uploadStatus && <p style={s.uploadStatus}>{uploadStatus}</p>}
        <div style={{ flex: 1 }} />
        <button style={s.logoutBtn} onClick={() => { clearToken(); nav("/login"); }}>Sign Out</button>
      </aside>

      {/* Chat area */}
      <div style={s.main}>
        <div style={s.messages}>
          {messages.length === 0 && (
            <div style={s.empty}>
              <h2>Ask your enterprise documents</h2>
              <p style={{ color: "var(--text-muted)", marginTop: 8 }}>Upload PDFs in the sidebar, then ask questions.</p>
            </div>
          )}
          {messages.map((m, i) => (
            <div key={i} style={{ ...s.msg, alignSelf: m.role === "user" ? "flex-end" : "flex-start" }}>
              <div style={{ ...s.bubble, background: m.role === "user" ? "var(--accent)" : "var(--bg-elevated)" }}>
                <ReactMarkdown>{m.content}</ReactMarkdown>
                {m.sources?.length > 0 && (
                  <div style={s.sources}>
                    {m.sources.map((src, j) => (
                      <span key={j} style={s.sourceTag}>{src.filename}</span>
                    ))}
                  </div>
                )}
              </div>
            </div>
          ))}
          {loading && <div style={{ ...s.msg, alignSelf: "flex-start" }}><div style={{ ...s.bubble, background: "var(--bg-elevated)" }}>Thinking...</div></div>}
          <div ref={bottomRef} />
        </div>

        <div style={s.composer}>
          <input
            style={s.composerInput}
            value={input}
            onChange={e => setInput(e.target.value)}
            onKeyDown={e => e.key === "Enter" && send()}
            placeholder="Ask a question about your documents..."
            disabled={loading}
          />
          <button style={s.sendBtn} onClick={send} disabled={loading || !input.trim()}>Send</button>
        </div>
      </div>
    </div>
  );
}

const s = {
  shell: { display: "flex", height: "100vh", background: "var(--bg)" },
  sidebar: { width: 240, background: "var(--bg-panel)", borderRight: "1px solid var(--border)", display: "flex", flexDirection: "column", padding: 16, gap: 12 },
  sidebarTitle: { fontSize: 15, fontWeight: 700, color: "var(--text)", paddingBottom: 12, borderBottom: "1px solid var(--border)" },
  uploadBtn: { background: "var(--accent)", color: "#fff", border: "none", borderRadius: 8, padding: "9px 12px", fontSize: 13, fontWeight: 600, cursor: "pointer" },
  uploadStatus: { fontSize: 12, color: "var(--text-muted)", wordBreak: "break-word" },
  logoutBtn: { background: "transparent", color: "var(--text-muted)", border: "1px solid var(--border)", borderRadius: 8, padding: "8px 12px", fontSize: 13, cursor: "pointer" },
  main: { flex: 1, display: "flex", flexDirection: "column" },
  messages: { flex: 1, overflowY: "auto", padding: "24px 32px", display: "flex", flexDirection: "column", gap: 12 },
  empty: { margin: "auto", textAlign: "center", color: "var(--text)" },
  msg: { maxWidth: "70%", display: "flex", flexDirection: "column" },
  bubble: { borderRadius: 12, padding: "10px 14px", fontSize: 14, lineHeight: 1.6 },
  sources: { marginTop: 8, display: "flex", flexWrap: "wrap", gap: 4 },
  sourceTag: { fontSize: 11, background: "rgba(59,130,246,0.2)", color: "var(--accent)", borderRadius: 4, padding: "2px 6px" },
  composer: { borderTop: "1px solid var(--border)", padding: "14px 32px", display: "flex", gap: 10, background: "var(--bg-panel)" },
  composerInput: { flex: 1, background: "var(--bg-elevated)", border: "1px solid var(--border)", borderRadius: 8, padding: "10px 14px", color: "var(--text)", fontSize: 14, outline: "none" },
  sendBtn: { background: "var(--accent)", color: "#fff", border: "none", borderRadius: 8, padding: "0 24px", fontWeight: 600, cursor: "pointer", fontSize: 14 },
};
