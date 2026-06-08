import { Link } from "react-router-dom";

export function Home() {
  return (
    <div className="page">
      <section className="hero">
        <span className="badge">Play in your browser</span>
        <h1>Welcome to Remi&apos;s World</h1>
        <p className="hero-lead">
          Solve puzzles, collect VIBE tokens, customize your avatar, and explore
          a colorful world full of friendly characters.
        </p>
        <div className="hero-actions">
          <Link to="/play" className="btn btn-primary">
            Play Remi&apos;s World
          </Link>
          <Link to="/about" className="btn btn-secondary">
            About the research
          </Link>
        </div>
      </section>

      <div className="card-grid">
        <article className="card">
          <h2>🎮 Adventure game</h2>
          <p className="muted">
            A Godot 4 2D game with missions, mini-games, and a lovable dog
            named Daisy. Play in your browser soon at{" "}
            <Link to="/play">/play</Link>.
          </p>
        </article>
        <article className="card">
          <h2>✨ VIBE tokens</h2>
          <p className="muted">
            Earn in-game currency by completing challenges. Real wallet
            integration comes much later — for now, everything stays fun and
            safe.
          </p>
        </article>
        <article className="card">
          <h2>🔬 Wise Men Research</h2>
          <p className="muted">
            Exploring how kids learn through play, creativity, and gentle
            technology. Read more on the{" "}
            <Link to="/about">About page</Link>.
          </p>
        </article>
      </div>
    </div>
  );
}
