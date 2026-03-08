defmodule Fuelex.TravelPaths do
  alias Fuelex.TravelPaths.Flight

  def add_entry(travel_path, planet) do
    last_flight = fetch_last_flight(travel_path)
    new_flights = handle_new_flight_cases(last_flight, planet)
    flights = travel_path.flights ++ new_flights

    %{travel_path | flights: flights}
  end

  def remove_entry(travel_path, flight_id) do
    flights = Enum.reject(travel_path.flights, &(&1.id == flight_id))

    %{travel_path | flights: flights}
  end

  defp handle_new_flight_cases(last_flight, planet) do
    case last_flight.action do
      nil ->
        [generate_flight(:launch, planet)]

      :launch ->
        [generate_flight(:land, planet)]

      :land ->
        [
          generate_flight(:launch, last_flight.planet),
          generate_flight(:land, planet)
        ]
    end
  end

  defp fetch_last_flight(%{flights: []}), do: %Flight{}
  defp fetch_last_flight(%{flights: list}), do: List.last(list)

  defp generate_flight(action, planet) do
    %Flight{
      id: Ecto.UUID.generate(),
      action: action,
      planet: planet
    }
  end
end
