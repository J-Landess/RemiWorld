import { useState, type FormEvent } from "react";
import { Link, useLocation, useNavigate } from "react-router-dom";
import { getSupabase } from "../lib/supabase";

export function Login() {
  const navigate = useNavigate();
  const location = useLocation();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  const redirectTo =
    (location.state as { from?: string } | null)?.from ?? "/play";

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    setError("");
    setLoading(true);

    const supabase = getSupabase();
    if (!supabase) {
      setLoading(false);
      setError(
        "Sign-in is not configured on this server yet. Please try again later.",
      );
      return;
    }

    const { error: authError } = await supabase.auth.signInWithPassword({
      email,
      password,
    });

    setLoading(false);

    if (authError) {
      const msg = authError.message.toLowerCase();
      if (msg.includes("not confirmed") || msg.includes("confirm")) {
        setError(
          "Your email isn't confirmed yet. Check your inbox for the confirmation link, then sign in.",
        );
      } else if (msg.includes("invalid")) {
        setError(
          "We don't recognize that email and password combo. Double-check it, or create a free account.",
        );
      } else {
        setError(authError.message);
      }
    } else {
      navigate(redirectTo);
    }
  }

  return (
    <div className="page auth-page">
      <div className="auth-card glow-card">
        <span className="badge">Welcome back</span>
        <h1 className="gradient-text">Sign in</h1>
        <p className="muted">
          Jump back into Remi&apos;s World with all your progress saved.
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
              autoComplete="current-password"
              placeholder="••••••••"
            />
          </label>

          {error && <p className="auth-error">{error}</p>}

          <button type="submit" className="btn btn-primary" disabled={loading}>
            {loading ? "Signing in…" : "Sign in & play"}
          </button>
        </form>

        <p className="auth-switch">
          New here?{" "}
          <Link to="/signup">Create a free account — it only takes a sec</Link>
        </p>
      </div>
    </div>
  );
}
