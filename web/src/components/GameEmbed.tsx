import { useCallback, useEffect, useRef, useState } from "react";
import type { Session } from "@supabase/supabase-js";
import "./GameEmbed.css";

const GAME_URL = "/game/index.html";

interface GameEmbedProps {
  /** Pass the active Supabase session so the game can use cloud saves. */
  session?: Session | null;
}

/** Sends the session to the Godot iframe via postMessage. */
function sendSessionToGame(
  iframe: HTMLIFrameElement,
  session: Session | null,
) {
  const payload = session
    ? {
        type: "remiworld_session",
        access_token: session.access_token,
        refresh_token: session.refresh_token,
        expires_at: session.expires_at ?? 0,
        token_type: session.token_type,
        user: {
          id: session.user.id,
          email: session.user.email ?? "",
        },
      }
    : { type: "remiworld_session_clear" };

  iframe.contentWindow?.postMessage(JSON.stringify(payload), "*");
}

export function GameEmbed({ session }: GameEmbedProps) {
  const containerRef = useRef<HTMLDivElement>(null);
  const iframeRef = useRef<HTMLIFrameElement>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(false);
  const [isFullscreen, setIsFullscreen] = useState(false);

  // Re-send session whenever it changes (e.g. user logs in while game is open)
  useEffect(() => {
    const iframe = iframeRef.current;
    if (!iframe || loading) return;
    sendSessionToGame(iframe, session ?? null);
  }, [session, loading]);

  const handleLoad = useCallback(() => {
    setLoading(false);
    setError(false);
    // Send initial session immediately after the game frame finishes loading
    if (iframeRef.current) {
      sendSessionToGame(iframeRef.current, session ?? null);
    }
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [session]);

  const handleError = useCallback(() => {
    setLoading(false);
    setError(true);
  }, []);

  const toggleFullscreen = useCallback(async () => {
    const el = containerRef.current;
    if (!el) return;

    if (!document.fullscreenElement) {
      await el.requestFullscreen();
      setIsFullscreen(true);
    } else {
      await document.exitFullscreen();
      setIsFullscreen(false);
    }
  }, []);

  useEffect(() => {
    const onFullscreenChange = () => {
      setIsFullscreen(Boolean(document.fullscreenElement));
    };
    document.addEventListener("fullscreenchange", onFullscreenChange);
    return () =>
      document.removeEventListener("fullscreenchange", onFullscreenChange);
  }, []);

  return (
    <div className="game-embed" ref={containerRef}>
      <div className="game-embed-toolbar">
        <p className="game-embed-hint muted">
          Click inside the game, then use keyboard (WASD, E, B, Esc).
        </p>
        <button
          type="button"
          className="btn btn-secondary game-embed-fullscreen"
          onClick={toggleFullscreen}
        >
          {isFullscreen ? "Exit fullscreen" : "Fullscreen"}
        </button>
      </div>

      <div className="game-embed-frame-wrap card">
        {loading && !error && (
          <div className="game-embed-loading" aria-live="polite">
            <span className="game-embed-spinner" aria-hidden="true" />
            <p>Loading Remi&apos;s World…</p>
            <p className="muted">First load can take a little while.</p>
          </div>
        )}

        {error && (
          <div className="game-embed-error">
            <p>Could not load the game.</p>
            <p className="muted">
              Run{" "}
              <code>./scripts/build/export-web.sh</code> from the repo root,
              then refresh.
            </p>
          </div>
        )}

        <iframe
          ref={iframeRef}
          src={GAME_URL}
          title="Remi's World game"
          className={`game-embed-iframe${loading ? " is-loading" : ""}`}
          allow="fullscreen"
          onLoad={handleLoad}
          onError={handleError}
        />
      </div>
    </div>
  );
}
