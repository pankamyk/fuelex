defmodule FuelexWeb.HomeLive do
  use FuelexWeb, :live_view

  alias Fuelex.TravelPath
  alias Fuelex.FuelCalculator

  @impl true
  def mount(_params, _session, socket) do
    changeset = TravelPath.changeset(%{spacecraft_mass: nil, flights: []})
    form = to_form(changeset)
    {:ok, assign(socket, form: form, mass_valid: false, total_fuel: nil)}
  end

  @impl true
  def handle_event("validate_mass", %{"travel_path" => travel_params}, socket) do
    spacecraft_mass = travel_params["spacecraft_mass"]

    {mass_value, _} =
      if spacecraft_mass == "" or is_nil(spacecraft_mass) do
        {nil, ""}
      else
        Integer.parse(spacecraft_mass)
      end

    current_flights = socket.assigns.form.params["flights"] || []

    changeset =
      if is_nil(mass_value) do
        TravelPath.changeset(%{flights: current_flights})
      else
        TravelPath.changeset(%{spacecraft_mass: mass_value, flights: current_flights})
      end
      |> Map.put(:action, :validate)

    form = to_form(changeset)
    mass_valid = valid_mass?(form)
    total_fuel = calculate_total_fuel(form)
    {:noreply, assign(socket, form: form, mass_valid: mass_valid, total_fuel: total_fuel)}
  end

  @impl true
  def handle_event("select_planet", %{"planet" => planet_string}, socket) do
    planet = String.to_atom(planet_string)
    current_flights = socket.assigns.form.params["flights"] || []
    current_mass = socket.assigns.form.params["spacecraft_mass"]

    new_flight = %{
      "id" => Ecto.UUID.generate(),
      "action" => :launch,
      "planet" => planet
    }

    updated_flights = current_flights ++ [new_flight]

    changeset = TravelPath.changeset(%{spacecraft_mass: current_mass, flights: updated_flights})
    form = to_form(changeset)
    mass_valid = valid_mass?(form)
    total_fuel = calculate_total_fuel(form)

    {:noreply, assign(socket, form: form, mass_valid: mass_valid, total_fuel: total_fuel)}
  end

  @impl true
  def handle_event("add_destination", %{"planet" => planet_string}, socket) do
    current_flights = socket.assigns.form.params["flights"] || []
    current_mass = socket.assigns.form.params["spacecraft_mass"]
    new_planet = String.to_atom(planet_string)

    previous_flight = List.last(current_flights)

    new_flights =
      case previous_flight["action"] do
        :launch ->
          [
            %{
              "id" => Ecto.UUID.generate(),
              "action" => :land,
              "planet" => new_planet
            }
          ]

        :land ->
          [
            %{
              "id" => Ecto.UUID.generate(),
              "action" => :launch,
              "planet" => previous_flight["planet"]
            },
            %{
              "id" => Ecto.UUID.generate(),
              "action" => :land,
              "planet" => new_planet
            }
          ]
      end

    updated_flights = current_flights ++ new_flights

    changeset = TravelPath.changeset(%{spacecraft_mass: current_mass, flights: updated_flights})
    form = to_form(changeset)
    mass_valid = valid_mass?(form)
    total_fuel = calculate_total_fuel(form)

    {:noreply, assign(socket, form: form, mass_valid: mass_valid, total_fuel: total_fuel)}
  end

  @impl true
  def handle_event("remove_flight", %{"id" => flight_id}, socket) do
    current_flights = socket.assigns.form.params["flights"] || []
    current_mass = socket.assigns.form.params["spacecraft_mass"]

    updated_flights = Enum.reject(current_flights, fn f -> f["id"] == flight_id end)

    changeset = TravelPath.changeset(%{spacecraft_mass: current_mass, flights: updated_flights})
    form = to_form(changeset)
    mass_valid = valid_mass?(form)
    total_fuel = calculate_total_fuel(form)

    {:noreply, assign(socket, form: form, mass_valid: mass_valid, total_fuel: total_fuel)}
  end

  defp valid_mass?(form) do
    case form.params["spacecraft_mass"] do
      nil ->
        false

      "" ->
        false

      mass when is_integer(mass) and mass >= 0 ->
        true

      mass_string when is_binary(mass_string) ->
        case Integer.parse(mass_string) do
          {mass, ""} when mass >= 0 -> true
          _ -> false
        end
    end
  end

  defp calculate_total_fuel(form) do
    flights = form.params["flights"] || []

    if length(flights) == 0 do
      nil
    else
      path = Enum.map(flights, fn f -> {f["action"], f["planet"]} end)
      mass = form.params["spacecraft_mass"]

      case FuelCalculator.calculate_total_fuel(mass, path) do
        {:ok, total} -> total
        {:error, _} -> nil
      end
    end
  end
end
