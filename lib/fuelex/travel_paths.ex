defmodule Fuelex.TravelPaths do
  @moduledoc """
  Provides functions for manipulating travel paths.

  This module contains helper functions for adding and removing flights
  from a travel path. It handles the logic of generating appropriate
  launch/landing sequences based on the current path state.
  """

  alias Fuelex.TravelPaths.Flight

  @doc """
  Adds a new flight entry to the travel path based on the destination planet.

  The function determines whether to add just a landing or both a launch
  and landing based on the previous flight's action:
  - If no previous flight: adds a launch
  - If previous was launch: adds only landing
  - If previous was land: adds both launch (from previous planet) and landing

  ## Examples

      iex> travel_path = %TravelPath{flights: [], spacecraft_mass: 1000}
      iex> TravelPaths.add_entry(travel_path, :moon)
      %TravelPath{flights: [%Flight{action: :launch, planet: :moon, ...}], spacecraft_mass: 1000}

  """
  @spec add_entry(TravelPath.t(), atom()) :: TravelPath.t()
  def add_entry(travel_path, planet) do
    last_flight = fetch_last_flight(travel_path)
    new_flights = handle_new_flight_cases(last_flight, planet)
    flights = travel_path.flights ++ new_flights

    %{travel_path | flights: flights}
  end

  @doc """
  Removes a flight from the travel path by its ID.

  Typically used to remove the last flight in the path.

  ## Examples

      iex> travel_path = %TravelPath{flights: [flight], spacecraft_mass: 1000}
      iex> TravelPaths.remove_entry(travel_path, flight.id)
      %TravelPath{flights: [], spacecraft_mass: 1000}

  """
  @spec remove_entry(TravelPath.t(), String.t()) :: TravelPath.t()
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
