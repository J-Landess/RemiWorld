export function Play() {
  return (
    <div className="page">
      <span className="badge">Coming in Phase 2</span>
      <h1>Play Remi&apos;s World</h1>
      <p className="muted" style={{ maxWidth: "540px" }}>
        The browser version of the game will be embedded here. For now, you can
        run the game locally in Godot 4 — open <code>project.godot</code> and
        press F5.
      </p>

      <div className="play-placeholder card">
        <div className="play-placeholder-inner">
          <span className="play-icon" aria-hidden="true">
            🎮
          </span>
          <h2>Game embed placeholder</h2>
          <p className="muted">
            Phase 2 will export the Godot project to WebAssembly and load it at{" "}
            <code>/game</code>.
          </p>
        </div>
      </div>

      <section className="card" style={{ marginTop: "1.5rem" }}>
        <h2>Local play (today)</h2>
        <ol className="play-steps">
          <li>Install Godot 4.2+ from godotengine.org</li>
          <li>Import this repo and open <code>project.godot</code></li>
          <li>Press F5 to start at the Main Menu</li>
        </ol>
      </section>
    </div>
  );
}
