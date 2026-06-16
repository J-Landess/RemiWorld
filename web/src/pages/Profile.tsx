import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { getSupabase } from "../lib/supabase";
import { useAuth } from "../context/AuthContext";

interface ProfileRow {
  player_name: string;
  player_level: number;
  player_xp: number;
  vibe_tokens: number;
  display_name: string | null;
}

export function Profile() {
  const { user, signOut } = useAuth();
  const [profile, setProfile] = useState<ProfileRow | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!user) return;

    const supabase = getSupabase();
    if (!supabase) {
      setLoading(false);
      return;
    }

    supabase
      .from("profiles")
      .select("player_name, player_level, player_xp, vibe_tokens, display_name")
      .eq("id", user.id)
      .single()
      .then(({ data, error }) => {
        if (!error && data) setProfile(data as ProfileRow);
        setLoading(false);
      });
  }, [user]);

  if (loading) {
    return (
      <div className="page" style={{ textAlign: "center", paddingTop: "4rem" }}>
        <p className="muted">Loading profile…</p>
      </div>
    );
  }

  const displayEmail = user?.email ?? "Player";
  const name = profile?.player_name || profile?.display_name || displayEmail;

  return (
    <div className="page">
      <div className="profile-card">
        <div className="profile-header">
          <div className="profile-avatar" aria-hidden="true">
            {name.charAt(0).toUpperCase()}
          </div>
          <div>
            <h1>{name}</h1>
            <p className="muted">{user?.email}</p>
          </div>
        </div>

        {profile ? (
          <div className="profile-stats">
            <div className="stat">
              <span className="stat-label">Level</span>
              <span className="stat-value">{profile.player_level}</span>
            </div>
            <div className="stat">
              <span className="stat-label">XP</span>
              <span className="stat-value">{profile.player_xp}</span>
            </div>
            <div className="stat">
              <span className="stat-label">VIBE tokens</span>
              <span className="stat-value">{profile.vibe_tokens}</span>
            </div>
          </div>
        ) : (
          <p className="muted">
            Play the game to start building your profile.
          </p>
        )}

        <div className="profile-actions">
          <Link to="/play" className="btn btn-primary">
            Play now
          </Link>
          <button onClick={signOut} className="btn btn-secondary">
            Sign out
          </button>
        </div>
      </div>
    </div>
  );
}
