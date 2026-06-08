export function About() {
  return (
    <div className="page page-narrow">
      <span className="badge">Research</span>
      <h1>About Wise Men Research</h1>

      <div className="card" style={{ marginTop: "1.5rem" }}>
        <h2>Our vision</h2>
        <p>
          WiseMen Research builds research technology using AI and machine learning. We also wanted to create 
          playful learning experiences for kids. Remi&apos;s
          World is technically our flagship project — a 2D adventure game where logic puzzles,
          creativity, and exploration reward curiosity rather than practiced perfection. It's based off of a 
          real kid named Remi Rose. Remi helped in the designing of Remi's World and has been the inspiration from the beginning.
          We hope you enjoy playing it as much as we enjoyed creating it!!
          
        </p>
        <p>
          This website is the home for the game, future player profiles, and
          research updates. We&apos;re building in small, deployable phases so
          something useful ships at every step. As well as creating games for lil girls,
          we are also a front runner in psychedelic research, using the latest convulutional
          neural networks to analyze brain function. We have also made a
          significant splash as Nevada's most trusted crypto engineering solution.
          Our main mission is tocombat stigmas of all types including addiction, mental health, incarceration, and more.
        </p>
      </div>

      <div className="card" style={{ marginTop: "1.25rem" }}>
        <h2>What we&apos;re studying</h2>
        <ul className="about-list">
          <li>Can game-based puzzles improve pattern recognition and persistence?</li>
          <li>How do reward loops (tokens, badges) affect motivation without pressure?</li>
          <li>What does a kid-safe path to digital ownership look like? Can they learn to manage wealth at younger ages than previous generations?</li>
        </ul>
      </div>

      <div className="card" style={{ marginTop: "1.25rem" }}>
        <h2>Built with</h2>
        <p className="muted">
          Godot 4 · React · Vite · Supabase (coming soon) · Vercel
        </p>
        <p className="muted" style={{ marginTop: "0.75rem" }}>
          Game credits and asset licenses live in the project&apos;s{" "}
          <code>CREDITS.md</code> file in the repository.
        </p>
      </div>

      <p className="muted" style={{ marginTop: "2rem", textAlign: "center" }}>
        Questions? Reach out to me personally at justin@wisemenresearch.org. 
        We are always looking for new collaborators and partners.
      </p>
    </div>
  );
}
