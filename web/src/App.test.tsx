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

  it("renders the play page with game embed", () => {
    renderWithAuth(<AppRoutes />, "/play");

    expect(
      screen.getByRole("heading", { name: /play remi's world/i }),
    ).toBeInTheDocument();
    expect(screen.getByTitle(/remi's world game/i)).toBeInTheDocument();
    expect(screen.getByRole("button", { name: /fullscreen/i })).toBeInTheDocument();
  });
});
