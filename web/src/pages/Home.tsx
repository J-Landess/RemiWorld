import { Link } from "react-router-dom";
import { useAuth } from "../context/AuthContext";

const characters = [
  {
    emoji: "🌸",
    name: "Remi Rose",
    desc: "Our brave, curious hero — inspired by a real little girl who helped design the whole world.",
  },
  {
    emoji: "🐶",
    name: "Daisy Doodles",
    desc: "A hidden pup who becomes your loyal companion and barks away anyone chasing you.",
  },
  {
    emoji: "🤖",
    name: "Coding Bot",
    desc: "A friendly robot who kicks things off with the very first logic puzzle, Pattern Power.",
  },
  {
    emoji: "🛍️",
    name: "Shopkeeper Rose",
    desc: "Runs the store where you spend VIBE tokens on sneakers, clips, shirts and backpacks.",
  },
  {
    emoji: "🦉",
    name: "Chess Tutor",
    desc: "A wise owl scholar who challenges you to the Knight's Jump board puzzle.",
  },
  {
    emoji: "⚽",
    name: "Coach Kick",
    desc: "A whistle-blowing soccer coach running the power-and-aim Goal Kicker game.",
  },
  {
    emoji: "🎨",
    name: "Artist Pip",
    desc: "A painter in a beret who teaches color mixing in the Rainbow Maker challenge.",
  },
  {
    emoji: "📚",
    name: "Ms. Huffy & the Riddler",
    desc: "A chasing librarian to sneak past — plus a tricky riddler guarding the aquarium.",
  },
];

const scenes = [
  {
    cls: "scene-start",
    tag: "🏡",
    name: "Start Area",
    desc: "Your colorful home base where the adventure and first missions begin.",
  },
  {
    cls: "scene-school",
    tag: "🤫",
    name: "School Interior",
    desc: "A tense stealth level — slip past Ms. Huffy and grab the leash from the locker.",
  },
  {
    cls: "scene-playground",
    tag: "🎡",
    name: "The Playground",
    desc: "A sunny park packed with four mini-game challenges and Daisy's fetch game.",
  },
  {
    cls: "scene-dogpit",
    tag: "🌅",
    name: "The Dog Pit",
    desc: "A warm sunset rescue area with its own moody soundtrack and props.",
  },
  {
    cls: "scene-aquarium",
    tag: "🐬",
    name: "City Aquarium",
    desc: "A multi-phase rescue: buy a ticket, pick an animal, ace the riddle, sneak to freedom.",
  },
  {
    cls: "scene-boston",
    tag: "🛹",
    name: "Road to Boston",
    desc: "A fast skate run with real background music — keep your balance and go!",
  },
];

const tracks = [
  { name: "Start Area Theme", desc: "Gentle, hopeful exploration music." },
  { name: "Playground Bounce", desc: "Upbeat and playful for the park." },
  { name: "Dog Pit Sunset", desc: "Warm, moody atmosphere at dusk." },
  { name: "Road Run", desc: "High-energy beat for the skate run." },
];

export function Home() {
  const { user } = useAuth();

  return (
    <div className="page">
      {/* Hero */}
      <section className="hero">
        <div className="hero-sparkles" aria-hidden="true">
          <span className="hero-sparkle s1">✦</span>
          <span className="hero-sparkle s2">✨</span>
          <span className="hero-sparkle s3">⭐</span>
          <span className="hero-sparkle s4">💫</span>
          <span className="hero-sparkle s5">✦</span>
          <span className="hero-sparkle s6">🌟</span>
        </div>

        <span className="badge badge-accent hero-eyebrow">
          Play free in your browser
        </span>
        <h1 className="gradient-text">Welcome to Remi&apos;s World</h1>
        <p className="hero-lead">
          Solve clever puzzles, rescue animals, collect VIBE tokens, customize
          your avatar, and explore a magical world full of friendly characters
          — all in one cozy little adventure.
        </p>
        <div className="hero-actions">
          <Link to={user ? "/play" : "/signup"} className="btn btn-primary">
            {user ? "Play now ✨" : "Sign up free & play ✨"}
          </Link>
          <a href="#characters" className="btn btn-secondary">
            Meet the world
          </a>
        </div>
      </section>

      {/* Why */}
      <section className="section">
        <div className="card-grid">
          <article className="card glow-card feature-card">
            <span className="feature-icon">🎮</span>
            <h3>A real adventure</h3>
            <p className="muted">
              A Godot 4 game with missions, mini-games, stealth levels, and a
              lovable dog named Daisy — playable right in your browser.
            </p>
          </article>
          <article className="card glow-card feature-card">
            <span className="feature-icon">✨</span>
            <h3>Earn VIBE tokens</h3>
            <p className="muted">
              Complete challenges to earn in-game currency and rare badge NFTs.
              Everything stays fun, safe, and kid-friendly.
            </p>
          </article>
          <article className="card glow-card feature-card">
            <span className="feature-icon">☁️</span>
            <h3>Saved forever</h3>
            <p className="muted">
              Your free account keeps your tokens, badges, and progress safe in
              the cloud — pick up on any device, anytime.
            </p>
          </article>
        </div>
      </section>

      {/* Characters */}
      <section className="section" id="characters">
        <div className="section-head">
          <h2 className="gradient-text">Meet the characters</h2>
          <p>A whole cast of friends (and a few tricksters) to meet along the way.</p>
        </div>
        <div className="character-grid">
          {characters.map((c) => (
            <div key={c.name} className="card character">
              <span className="character-emoji" aria-hidden="true">
                {c.emoji}
              </span>
              <div>
                <h3>{c.name}</h3>
                <p>{c.desc}</p>
              </div>
            </div>
          ))}
        </div>
      </section>

      {/* Scenes */}
      <section className="section">
        <div className="section-head">
          <h2 className="gradient-text">Worlds to explore</h2>
          <p>Six hand-built scenes — each with its own look, music, and challenges.</p>
        </div>
        <div className="scene-grid">
          {scenes.map((s) => (
            <div key={s.name} className={`scene ${s.cls}`}>
              <span className="scene-tag" aria-hidden="true">
                {s.tag}
              </span>
              <h3>{s.name}</h3>
              <p>{s.desc}</p>
            </div>
          ))}
        </div>
      </section>

      {/* Music */}
      <section className="section">
        <div className="section-head">
          <h2 className="gradient-text">An original soundtrack</h2>
          <p>
            Every area has its own music, plus a full library of sound effects —
            barks, whistles, paint strokes, cheers, and more.
          </p>
        </div>
        <div className="music-list">
          {tracks.map((t) => (
            <div key={t.name} className="card music-row">
              <span className="music-note" aria-hidden="true">
                🎵
              </span>
              <div>
                <h4>{t.name}</h4>
                <p>{t.desc}</p>
              </div>
            </div>
          ))}
        </div>
      </section>

      {/* Roadmap / future */}
      <section className="section">
        <div className="section-head">
          <h2 className="gradient-text">What&apos;s coming next</h2>
          <p>
            Remi&apos;s World is just getting started. Here&apos;s the magic
            we&apos;re building toward.
          </p>
        </div>
        <div className="roadmap">
          <div className="card glow-card roadmap-card is-featured">
            <span className="rm-emoji" aria-hidden="true">
              💎
            </span>
            <span className="rm-tag">Coming soon</span>
            <h3>A real VIBE coin</h3>
            <p>
              The VIBE tokens you earn in-game are designed to become a real
              coin one day — always parent-approved. Kids never connect wallets;
              grown-ups handle the on-chain part.
            </p>
          </div>
          <div className="card glow-card roadmap-card is-featured">
            <span className="rm-emoji" aria-hidden="true">
              🏅
            </span>
            <span className="rm-tag">Coming soon</span>
            <h3>Collectible NFTs</h3>
            <p>
              Your badges — Pattern Star, Golden Cleats, Best Friend and more —
              are built to launch as real, ownable NFT collectibles down the
              road.
            </p>
          </div>
          <div className="card glow-card roadmap-card">
            <span className="rm-emoji" aria-hidden="true">
              🌴
            </span>
            <span className="rm-tag">Special edition</span>
            <h3>Hawaii Beach Game</h3>
            <p>
              Players from Hawaii unlock an exclusive beach adventure — sun,
              surf, and a special island level made just for our 808 ohana. 🤙
            </p>
          </div>
          <div className="card glow-card roadmap-card">
            <span className="rm-emoji" aria-hidden="true">
              🏗️
            </span>
            <span className="rm-tag">More room to come</span>
            <h3>New worlds</h3>
            <p>
              A daycare escape, a nail salon, a restaurant, a coding lab, and
              more are on the drawing board — the world keeps growing.
            </p>
          </div>
        </div>
      </section>

      {/* Final CTA */}
      <section className="cta-band glow-card">
        <h2 className="gradient-text">Ready to play?</h2>
        <p>
          Create your free account and step into Remi&apos;s World in seconds.
          No cost, no catch — just fun.
        </p>
        <div className="hero-actions">
          <Link to={user ? "/play" : "/signup"} className="btn btn-primary">
            {user ? "Jump back in ✨" : "Sign up free & play ✨"}
          </Link>
          <Link to="/about" className="btn btn-ghost">
            About the research
          </Link>
        </div>
      </section>
    </div>
  );
}
