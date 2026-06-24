import { Link } from "react-router-dom";
import { GameEmbed } from "../components/GameEmbed";
import { useAuth } from "../context/AuthContext";

export function Play() {
  const { user, session, loading } = useAuth();

  if (loading) {
    return (
      <div className="page" style={{ textAlign: "center", paddingTop: "4rem" }}>
        <p className="muted">Loading…</p>
      </div>
    );
  }

  if (!user) {
    return (
      <div className="page auth-page">
        <div className="play-gate glow-card">
          <span className="badge badge-accent">Members only</span>
          <h1 className="gradient-text">Play Remi&apos;s World</h1>
          <p className="muted play-gate-lead">
            The game lives behind a free account so your VIBE tokens, badges,
            and progress are always saved — and so we can grow a real community
            of players. Sign up takes about ten seconds.
          </p>
          <div className="hero-actions">
            <Link to="/signup" className="btn btn-primary">
              Create my free account ✨
            </Link>
            <Link to="/login" className="btn btn-ghost">
              I already have one
            </Link>
          </div>
          <ul className="play-gate-perks">
            <li>☁️ Cloud saves across every device</li>
            <li>🏅 Keep every badge NFT you earn</li>
            <li>💎 Be first in line for the VIBE coin launch</li>
          </ul>
        </div>
      </div>
    );
  }

  return (
    <div className="page">
      <span className="badge">Now playing</span>
      <h1 className="gradient-text">Play Remi&apos;s World</h1>
      <p className="muted" style={{ maxWidth: "560px" }}>
        The Godot game runs right here in your browser. Click inside the game,
        then use your keyboard to explore. Have fun, {user.email}!
      </p>

      <GameEmbed session={session} />

      <section className="card glow-card" style={{ marginTop: "1.5rem" }}>
        <h2>Prefer the Godot editor?</h2>
        <ol className="play-steps">
          <li>Install Godot 4.2+ from godotengine.org</li>
          <li>
            Import this repo and open <code>project.godot</code>
          </li>
          <li>Press F5 to start at the Main Menu</li>
        </ol>
      </section>
    </div>
  );
}
