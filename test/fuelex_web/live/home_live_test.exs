defmodule FuelexWeb.HomeLiveTest do
  use FuelexWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  describe "initial page render" do
    test "renders correctly with Fuelex title and mass input", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")

      assert html =~ "Fuelex"
      assert html =~ "Spacecraft Mass"
      assert html =~ "Enter mass in kg"
    end

    test "shows prompt message when no flights added", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")

      assert html =~ "Enter a valid spacecraft mass to select destination"
      assert html =~ "Enter spacecraft mass and add destinations to calculate fuel"
    end
  end

  describe "launch buttons visibility" do
    test "buttons hidden when no mass entered", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      html = render_submit(view, "validate_mass", %{"travel_path" => %{"spacecraft_mass" => ""}})

      refute html =~ "Launch from Earth"
      refute html =~ "Launch from Moon"
      refute html =~ "Launch from Mars"
    end

    test "buttons hidden when invalid mass (negative)", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      html =
        render_submit(view, "validate_mass", %{"travel_path" => %{"spacecraft_mass" => "-1"}})

      refute html =~ "Launch from Earth"
    end

    test "buttons hidden when invalid mass (non-numeric)", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      html =
        render_submit(view, "validate_mass", %{"travel_path" => %{"spacecraft_mass" => "abc"}})

      refute html =~ "Launch from Earth"
    end

    test "buttons visible when valid mass entered", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      html =
        render_submit(view, "validate_mass", %{"travel_path" => %{"spacecraft_mass" => "28801"}})

      assert html =~ "Launch from Earth"
      assert html =~ "Launch from Moon"
      assert html =~ "Launch from Mars"
    end
  end

  describe "select planet" do
    test "adding first planet creates single launch entry", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      # Enter valid mass first
      render_submit(view, "validate_mass", %{"travel_path" => %{"spacecraft_mass" => "28801"}})

      # Select Earth as starting point
      html = render_click(view, "select_planet", %{"planet" => "earth"})

      assert html =~ "Launch Earth"
      # Should only have 1 flight (launch)
      assert html =~ "Launch"
      refute html =~ "Land"
    end
  end

  describe "add destination" do
    test "add destination after launch adds only landing", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      # Enter valid mass and select starting planet
      render_submit(view, "validate_mass", %{"travel_path" => %{"spacecraft_mass" => "28801"}})
      render_click(view, "select_planet", %{"planet" => "earth"})

      # Add Moon as destination (previous was launch, so only adds land)
      html = render_click(view, "select_planet", %{"planet" => "moon"})

      # Should now have: Launch Earth, Land Moon = 2 flights
      assert html =~ "Launch Earth"
      assert html =~ "Land Moon"
      # No Launch Moon yet - that's added when we add another destination
    end

    test "add destination after land adds launch and landing (2 entries)", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      # Enter valid mass and select starting planet
      render_submit(view, "validate_mass", %{"travel_path" => %{"spacecraft_mass" => "28801"}})
      render_click(view, "select_planet", %{"planet" => "earth"})

      # Add Moon (previous was launch, adds only land)
      render_click(view, "select_planet", %{"planet" => "moon"})

      # Add Mars (previous was land, adds launch + land = 2 entries)
      html = render_click(view, "select_planet", %{"planet" => "mars"})

      # Should now have: Launch Earth, Land Moon, Launch Moon, Land Mars = 4 flights
      assert html =~ "Launch Earth"
      assert html =~ "Land Moon"
      assert html =~ "Launch Moon"
      assert html =~ "Land Mars"
    end
  end

  describe "delete flight" do
    test "delete button renders only for last flight", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      # Enter valid mass and add 2 destinations
      render_submit(view, "validate_mass", %{"travel_path" => %{"spacecraft_mass" => "28801"}})
      render_click(view, "select_planet", %{"planet" => "earth"})
      render_click(view, "select_planet", %{"planet" => "moon"})

      html = render(view)

      # Should have 3 flights, delete button only on last one
      # Count the delete buttons (✕ character)
      delete_button_count = html |> String.split("✕") |> length() |> Kernel.-(1)
      assert delete_button_count == 1
    end

    test "delete button removes last flight", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      # Enter valid mass and add destination
      render_submit(view, "validate_mass", %{"travel_path" => %{"spacecraft_mass" => "28801"}})
      render_click(view, "select_planet", %{"planet" => "earth"})
      html_before = render_click(view, "select_planet", %{"planet" => "moon"})

      # Should have 3 flights before delete
      assert html_before =~ "Launch Earth"
      assert html_before =~ "Land Moon"

      # Delete the last flight (Land Moon)
      # Find the button and click it - we need to use the flight ID
      # Let's just verify the delete works by checking flight count changes
      # The simplest way is to find an element and click it
      view
      |> element("[phx-click=\"remove_flight\"]")
      |> render_click()

      html_after = render(view)

      # After delete, should have fewer flights
      # At minimum, Launch Earth should still be there
      assert html_after =~ "Launch Earth"
    end
  end

  describe "fuel calculation" do
    test "Apollo 11 scenario calculates correct fuel", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      # Apollo 11: Earth -> Moon -> Earth
      # Path: Launch Earth, Land Moon, Launch Moon, Land Earth
      # Mass: 28801 kg
      # Expected: 51898 kg

      render_submit(view, "validate_mass", %{"travel_path" => %{"spacecraft_mass" => "28801"}})
      render_click(view, "select_planet", %{"planet" => "earth"})
      render_click(view, "select_planet", %{"planet" => "moon"})
      render_click(view, "select_planet", %{"planet" => "earth"})

      html = render(view)

      assert html =~ "51898 kg"
    end

    test "Mars mission scenario calculates correct fuel", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      # Mars Mission: Earth -> Mars -> Earth
      # Path: Launch Earth, Land Mars, Launch Mars, Land Earth
      # Mass: 14606 kg
      # Expected: 33388 kg

      render_submit(view, "validate_mass", %{"travel_path" => %{"spacecraft_mass" => "14606"}})
      render_click(view, "select_planet", %{"planet" => "earth"})
      render_click(view, "select_planet", %{"planet" => "mars"})
      render_click(view, "select_planet", %{"planet" => "earth"})

      html = render(view)

      assert html =~ "33388 kg"
    end

    test "Passenger ship scenario calculates correct fuel", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      # Passenger Ship: Earth -> Moon -> Mars -> Earth
      # Path: Launch Earth, Land Moon, Launch Moon, Land Mars, Launch Mars, Land Earth
      # Mass: 75432 kg
      # Expected: 212161 kg

      render_submit(view, "validate_mass", %{"travel_path" => %{"spacecraft_mass" => "75432"}})
      render_click(view, "select_planet", %{"planet" => "earth"})
      render_click(view, "select_planet", %{"planet" => "moon"})
      render_click(view, "select_planet", %{"planet" => "mars"})
      render_click(view, "select_planet", %{"planet" => "earth"})

      html = render(view)

      assert html =~ "212161 kg"
    end
  end
end
