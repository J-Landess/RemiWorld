import { GameEmbed } from "../components/GameEmbed";

export function Play() {
  return (
    <div className="page">
      <span className="badge">Play in browser</span>
      <h1>Play Remi&apos;s World</h1>
      <p className="muted" style={{ maxWidth: "540px" }}>
        The Godot game runs right here in your browser. Progress saves locally
        in this browser for now — cloud saves come in Phase 3.
      </p>

      <GameEmbed />

      <section className="card" style={{ marginTop: "1.5rem" }}>
        <h2>Prefer the Godot editor?</h2>
        <ol className="play-steps">
          <li>Install Godot 4.2+ from godotengine.org</li>
          <li>Import this repo and open <code>project.godot</code></li>
          <li>Press F5 to start at the Main Menu</li>
        </ol>
      </section>
    </div>
  );
}
