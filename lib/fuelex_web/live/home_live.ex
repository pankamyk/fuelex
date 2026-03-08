defmodule FuelexWeb.HomeLive do
  use FuelexWeb, :live_view

  alias Fuelex.Flight
  alias Fuelex.FuelCalculator
  alias Fuelex.TravelPath

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

    travel_path =
      case changeset.valid? do
        true -> Ecto.Changeset.apply_changes(changeset)
        false -> socket.assigns.travel_path
      end

    total_fuel = calculate_total_fuel(changeset)

    {:noreply,
     socket
     |> assign(:travel_path, travel_path)
     |> assign(:form, to_form(changeset))
     |> assign(:mass_valid, changeset.valid?)
     |> assign(:total_fuel, total_fuel)}
  end

  @impl true
  def handle_event("select_planet", %{"planet" => planet_string}, socket) do
    planet = String.to_atom(planet_string)
    travel_path = socket.assigns.travel_path

    new_flight = %{
      "id" => Ecto.UUID.generate(),
      "action" => :launch,
      "planet" => planet
    }

    updated_flights = travel_path.flights ++ [new_flight]
    changeset = TravelPath.changeset(travel_path, %{flights: updated_flights})
    travel_path = Ecto.Changeset.apply_changes(changeset)
    total_fuel = calculate_total_fuel(changeset)

    {:noreply,
     socket
     |> assign(:travel_path, travel_path)
     |> assign(:form, to_form(changeset))
     |> assign(:mass_valid, changeset.valid?)
     |> assign(:total_fuel, total_fuel)}
  end

  @impl true
  def handle_event("add_destination", %{"planet" => planet_string}, socket) do
    new_planet = String.to_atom(planet_string)
    travel_path = socket.assigns.travel_path
    previous_flight = List.last(travel_path.flights)

    new_flights =
      case previous_flight.action do
        :launch ->
          [
            %Flight{
              id: Ecto.UUID.generate(),
              action: :land,
              planet: new_planet
            }
          ]

        :land ->
          [
            %Flight{
              id: Ecto.UUID.generate(),
              action: :launch,
              planet: previous_flight.planet
            },
            %Flight{
              id: Ecto.UUID.generate(),
              action: :land,
              planet: new_planet
            }
          ]
      end

    updated_flights = travel_path.flights ++ new_flights

    travel_path = %{travel_path | flights: updated_flights}
    changeset = TravelPath.changeset(travel_path, %{})
    total_fuel = calculate_total_fuel(changeset)

    {:noreply,
     socket
     |> assign(:travel_path, travel_path)
     |> assign(:form, to_form(changeset))
     |> assign(:mass_valid, changeset.valid?)
     |> assign(:total_fuel, total_fuel)}
  end

  @impl true
  def handle_event("remove_flight", %{"id" => flight_id}, socket) do
    travel_path = socket.assigns.travel_path

    updated_flights = Enum.reject(travel_path.flights, fn f -> f.id == flight_id end)
    travel_path = %{travel_path | flights: updated_flights}
    changeset = TravelPath.changeset(travel_path, %{})
    total_fuel = calculate_total_fuel(changeset)

    {:noreply,
     socket
     |> assign(:travel_path, travel_path)
     |> assign(:form, to_form(changeset))
     |> assign(:mass_valid, changeset.valid?)
     |> assign(:total_fuel, total_fuel)}
  end

  defp calculate_total_fuel(changeset) do
    travel = Ecto.Changeset.apply_changes(changeset)

    if length(travel.flights) == 0 do
      nil
    else
      path = Enum.map(travel.flights, fn f -> {f.action, f.planet} end)

      travel.spacecraft_mass
      |> FuelCalculator.calculate_total_fuel(path)
      |> case do
        {:ok, total} -> total
        {:error, _} -> nil
      end
    end
  end
end
