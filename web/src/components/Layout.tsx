import { NavLink, Outlet } from "react-router-dom";
import "./Layout.css";

const navItems: { to: string; label: string; end?: boolean }[] = [
  { to: "/", label: "Home", end: true },
  { to: "/play", label: "Play" },
  { to: "/about", label: "About" },
];

export function Layout() {
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
            </ul>
          </nav>
        </div>
      </header>

      <main className="site-main">
        <Outlet />
      </main>

      <footer className="site-footer">
        <div className="footer-inner">
          <p>
            Remi&apos;s World — a kid-friendly adventure where learning meets
            play.
          </p>
          <p className="muted">
            © {new Date().getFullYear()} Wise Men Research
          </p>
        </div>
      </footer>
    </div>
  );
}
