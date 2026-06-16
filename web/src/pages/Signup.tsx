import { useState, type FormEvent } from "react";
import { Link, useNavigate } from "react-router-dom";
import { supabase } from "../lib/supabase";

export function Signup() {
  const navigate = useNavigate();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [confirm, setConfirm] = useState("");
  const [error, setError] = useState("");
  const [notice, setNotice] = useState("");
  const [loading, setLoading] = useState(false);

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    setError("");
    setNotice("");

    if (password !== confirm) {
      setError("Your passwords don't match yet — try again.");
      return;
    }
    if (password.length < 8) {
      setError("Pick a password with at least 8 characters.");
      return;
    }

    setLoading(true);

    const { data, error: authError } = await supabase.auth.signUp({
      email,
      password,
    });

    if (authError) {
      setLoading(false);
      const msg = authError.message.toLowerCase();
      if (msg.includes("already") || msg.includes("registered")) {
        setError(
          "That email already has an account. Try signing in instead.",
        );
      } else {
        setError(authError.message);
      }
      return;
    }

    // If the project has email confirmation OFF, signUp returns a session and
    // we're logged straight in. If it's ON, there's no session yet.
    if (data.session) {
      setLoading(false);
      navigate("/play");
      return;
    }

    // No session: try to sign in immediately (works when confirmation is off
    // but the session wasn't returned for some reason).
    const { data: signInData } = await supabase.auth.signInWithPassword({
      email,
      password,
    });

    setLoading(false);

    if (signInData.session) {
      navigate("/play");
    } else {
      setNotice(
        "Almost there! We sent a confirmation link to " +
          email +
          ". Tap it, then come back and sign in to start playing.",
      );
    }
  }

  return (
    <div className="page auth-page">
      <div className="auth-card glow-card">
        <span className="badge badge-accent">Free forever</span>
        <h1 className="gradient-text">Join Remi&apos;s World</h1>
        <p className="muted">
          Create your free account to unlock the game, save your VIBE tokens,
          collect badge NFTs, and carry your progress across every device.
        </p>

        <form onSubmit={handleSubmit} className="auth-form">
          <label>
            Email
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
              autoComplete="email"
              placeholder="you@example.com"
            />
          </label>

          <label>
            Password
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
              autoComplete="new-password"
              placeholder="At least 8 characters"
            />
          </label>

          <label>
            Confirm password
            <input
              type="password"
              value={confirm}
              onChange={(e) => setConfirm(e.target.value)}
              required
              autoComplete="new-password"
              placeholder="••••••••"
            />
          </label>

          {error && <p className="auth-error">{error}</p>}
          {notice && <p className="auth-notice">{notice}</p>}

          <button type="submit" className="btn btn-primary" disabled={loading}>
            {loading ? "Creating your world…" : "Create my free account ✨"}
          </button>
        </form>

        <p className="auth-switch">
          Already a player? <Link to="/login">Sign in</Link>
        </p>
      </div>
    </div>
  );
}
