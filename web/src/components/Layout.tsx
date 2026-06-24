import { NavLink, Outlet, Link } from "react-router-dom";
import { useAuth } from "../context/AuthContext";
import { isSupabaseConfigured } from "../lib/supabase";
import "./Layout.css";

const navItems: { to: string; label: string; end?: boolean }[] = [
  { to: "/", label: "Home", end: true },
  { to: "/play", label: "Play" },
  { to: "/leaderboard", label: "Leaderboard" },
  { to: "/about", label: "About" },
];

export function Layout() {
  const { user, signOut } = useAuth();

  return (
    <div className="layout">
      <header className="site-header">
        <div className="header-inner">
          <NavLink to="/" className="brand" end>
            <span className="brand-icon" aria-hidden="true">
              ✦
            </span>
            <span className="brand-text">
              <span className="brand-name">Remi&apos;s World</span>
              <span className="brand-sub">Wise Men Research</span>
            </span>
          </NavLink>

          <nav className="site-nav" aria-label="Main navigation">
            <ul>
              {navItems.map(({ to, label, end }) => (
                <li key={to}>
                  <NavLink
                    to={to}
                    end={end ?? false}
                    className={({ isActive }) =>
                      isActive ? "nav-link active" : "nav-link"
                    }
                  >
                    {label}
                  </NavLink>
                </li>
              ))}

              {user ? (
                <>
                  <li>
                    <NavLink
                      to="/profile"
                      className={({ isActive }) =>
                        isActive ? "nav-link active" : "nav-link"
                      }
                    >
                      Profile
                    </NavLink>
                  </li>
                  <li>
                    <button
                      onClick={signOut}
                      className="nav-link nav-link-btn"
                    >
                      Sign out
                    </button>
                  </li>
                </>
              ) : (
                <>
                  <li>
                    <Link to="/login" className="nav-link">
                      Sign in
                    </Link>
                  </li>
                  <li>
                    <Link to="/signup" className="btn btn-primary nav-cta">
                      Sign up free
                    </Link>
                  </li>
                </>
              )}
            </ul>
          </nav>
        </div>
      </header>

      <main className="site-main">
        {!isSupabaseConfigured && (
          <div className="config-banner" role="status">
            Accounts are temporarily unavailable — the server is missing Supabase
            settings. The site will load, but sign-up and play need env vars on
            Vercel.
          </div>
        )}
        <Outlet />
      </main>

      <footer className="site-footer">
        <div className="footer-inner">
          <p>
            Remi&apos;s World — a kid-friendly adventure where learning meets
            play. ✨
          </p>
          <p className="muted">
            © {new Date().getFullYear()} Wise Men Research · Built with Godot 4
            · A real coin &amp; NFTs are on the way
          </p>
        </div>
      </footer>
    </div>
  );
}
