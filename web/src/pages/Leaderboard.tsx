import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { getSupabase } from "../lib/supabase";

interface LeaderboardRow {
  rank: number;
  player_name: string;
  player_level: number;
  vibe_tokens: number;
}

const MEDALS = ["🥇", "🥈", "🥉"];

export function Leaderboard() {
  const [rows, setRows] = useState<LeaderboardRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const supabase = getSupabase();
    if (!supabase) {
      setError("Leaderboard unavailable — Supabase is not configured.");
      setLoading(false);
      return;
    }

    supabase
      .rpc("get_leaderboard", { top_n: 20 })
      .then(({ data, error: rpcError }) => {
        if (rpcError) {
          setError("Could not load the leaderboard right now.");
        } else {
          setRows((data as LeaderboardRow[]) ?? []);
        }
        setLoading(false);
      });
  }, []);

  return (
    <div className="page">
      <span className="badge badge-accent">Community</span>
      <h1 className="gradient-text">VIBE Leaderboard</h1>
      <p className="muted" style={{ maxWidth: "520px", marginBottom: "1.5rem" }}>
        The top 20 players ranked by VIBE tokens earned in-game. Earn more by
        completing missions, rescuing animals, and winning challenges!
      </p>

      {loading && (
        <div style={{ textAlign: "center", paddingTop: "2rem" }}>
          <p className="muted">Loading leaderboard…</p>
        </div>
      )}

      {error && (
        <div className="card" style={{ padding: "1.5rem", textAlign: "center" }}>
          <p className="muted">{error}</p>
          <p className="muted" style={{ fontSize: "0.85rem", marginTop: "0.5rem" }}>
            Apply <code>supabase/migrations/005_leaderboard.sql</code> to enable this.
          </p>
        </div>
      )}

      {!loading && !error && rows.length === 0 && (
        <div className="card" style={{ padding: "1.5rem", textAlign: "center" }}>
          <p className="muted">No players on the board yet — be the first! 🌟</p>
          <Link to="/play" className="btn btn-primary" style={{ marginTop: "1rem" }}>
            Play now
          </Link>
        </div>
      )}

      {rows.length > 0 && (
        <div className="card glow-card" style={{ padding: 0, overflow: "hidden" }}>
          <table style={{ width: "100%", borderCollapse: "collapse" }}>
            <thead>
              <tr style={{ borderBottom: "1px solid rgba(255,255,255,0.08)" }}>
                <th style={thStyle}>#</th>
                <th style={thStyle}>Player</th>
                <th style={{ ...thStyle, textAlign: "center" }}>Level</th>
                <th style={{ ...thStyle, textAlign: "right" }}>VIBE 💎</th>
              </tr>
            </thead>
            <tbody>
              {rows.map((row) => {
                const medal = MEDALS[row.rank - 1] ?? null;
                const isTop = row.rank <= 3;
                return (
                  <tr
                    key={row.rank}
                    style={{
                      borderBottom: "1px solid rgba(255,255,255,0.05)",
                      background: isTop
                        ? "rgba(139,92,246,0.07)"
                        : "transparent",
                    }}
                  >
                    <td style={tdStyle}>
                      {medal ? (
                        <span style={{ fontSize: "1.2rem" }}>{medal}</span>
                      ) : (
                        <span className="muted">{row.rank}</span>
                      )}
                    </td>
                    <td style={{ ...tdStyle, fontWeight: isTop ? 600 : 400 }}>
                      {row.player_name}
                    </td>
                    <td style={{ ...tdStyle, textAlign: "center" }}>
                      <span className="badge" style={{ fontSize: "0.75rem" }}>
                        Lv {row.player_level}
                      </span>
                    </td>
                    <td
                      style={{
                        ...tdStyle,
                        textAlign: "right",
                        fontWeight: 600,
                        color: "var(--accent, #a78bfa)",
                      }}
                    >
                      {row.vibe_tokens.toLocaleString()}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      )}

      <p
        className="muted"
        style={{ marginTop: "1.5rem", fontSize: "0.8rem", textAlign: "center" }}
      >
        Refreshed on page load · Only players with earned VIBE appear
      </p>
    </div>
  );
}

const thStyle: React.CSSProperties = {
  padding: "0.75rem 1.25rem",
  textAlign: "left",
  fontSize: "0.8rem",
  textTransform: "uppercase",
  letterSpacing: "0.05em",
  opacity: 0.6,
  fontWeight: 600,
};

const tdStyle: React.CSSProperties = {
  padding: "0.75rem 1.25rem",
  fontSize: "0.95rem",
};
