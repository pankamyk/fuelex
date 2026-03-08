defmodule FuelexWeb.HomeLive do
  use FuelexWeb, :live_view

  alias Fuelex.FuelCalculator
  alias Fuelex.TravelPaths
  alias Fuelex.TravelPaths.TravelPath

  @impl true
  def mount(_params, _session, socket) do
    path = %TravelPath{}
    changeset = TravelPath.changeset(%{})

    {:ok,
     socket
     |> assign(:travel_path, path)
     |> assign(:form, to_form(changeset))
     |> assign(:mass_valid, false)
     |> assign(:total_fuel, nil)}
  end

  @impl true
  def handle_event("validate_mass", %{"travel_path" => travel_params}, socket) do
    changeset =
      socket.assigns.travel_path
      |> TravelPath.changeset(travel_params)
      |> Map.put(:action, :validate)

    travel_path = apply_travel_path(changeset, socket)

    {:noreply,
     socket
     |> assign(:travel_path, travel_path)
     |> assign(:form, to_form(changeset))
     |> assign(:mass_valid, changeset.valid?)
     |> assign(:total_fuel, calculate_total_fuel(changeset))}
  end

  @impl true
  def handle_event(
        "select_planet",
        %{"planet" => planet_string},
        socket = %{assigns: %{travel_path: travel_path}}
      ) do
    new_planet = String.to_existing_atom(planet_string)
    travel_path = TravelPaths.add_entry(travel_path, new_planet)
    changeset = TravelPath.changeset(travel_path, %{})

    {:noreply,
     socket
     |> assign(:travel_path, travel_path)
     |> assign(:form, to_form(changeset))
     |> assign(:mass_valid, changeset.valid?)
     |> assign(:total_fuel, calculate_total_fuel(changeset))}
  end

  @impl true
  def handle_event(
        "remove_flight",
        %{"id" => flight_id},
        socket = %{assigns: %{travel_path: travel_path}}
      ) do
    travel_path = TravelPaths.remove_entry(travel_path, flight_id)
    changeset = TravelPath.changeset(travel_path, %{})

    {:noreply,
     socket
     |> assign(:travel_path, travel_path)
     |> assign(:form, to_form(changeset))
     |> assign(:mass_valid, changeset.valid?)
     |> assign(:total_fuel, calculate_total_fuel(changeset))}
  end

  defp apply_travel_path(changeset = %{valid?: true}, _),
    do: Ecto.Changeset.apply_changes(changeset)

  defp apply_travel_path(%{valid?: false}, socket), do: socket.assigns.travel_path

  defp calculate_total_fuel(changeset = %{valid?: true}) do
    %{flights: flights, spacecraft_mass: mass} = Ecto.Changeset.apply_changes(changeset)

    case flights do
      [] ->
        nil

      flights ->
        path = Enum.map(flights, &{&1.action, &1.planet})

        mass
        |> FuelCalculator.calculate_total_fuel(path)
        |> case do
          {:ok, total} -> total
          {:error, _} -> nil
        end
    end
  end

  defp calculate_total_fuel(%{valid?: false}), do: nil
end
