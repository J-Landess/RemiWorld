import { render, screen } from "@testing-library/react";
import { MemoryRouter } from "react-router-dom";
import { describe, expect, it } from "vitest";
import { AppRoutes } from "./App";
import { AuthProvider } from "./context/AuthContext";

function renderWithAuth(ui: React.ReactElement, route = "/") {
  return render(
    <MemoryRouter initialEntries={[route]}>
      <AuthProvider>{ui}</AuthProvider>
    </MemoryRouter>,
  );
}

describe("App navigation", () => {
  it("renders main nav links on the home page", () => {
    renderWithAuth(<AppRoutes />);

    expect(screen.getByRole("link", { name: "Home" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: "Play" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: "About" })).toBeInTheDocument();
  });

  it("gates the play page behind a free account when logged out", async () => {
    renderWithAuth(<AppRoutes />, "/play");

    // The play page should ask logged-out visitors to create an account
    // instead of exposing the game iframe.
    expect(
      await screen.findByRole("link", { name: /create my free account/i }),
    ).toBeInTheDocument();
    expect(screen.queryByTitle(/remi's world game/i)).not.toBeInTheDocument();
  });
});
