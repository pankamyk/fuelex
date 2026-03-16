defmodule Fuelex.TravelPathsTest do
  use ExUnit.Case, async: true

  alias Fuelex.TravelPaths
  alias Fuelex.TravelPaths.TravelPath
  alias Fuelex.TravelPaths.Flight

  describe "add_entry/2" do
    test "adds launch to empty path" do
      travel_path = %TravelPath{flights: [], spacecraft_mass: 1000}

      result = TravelPaths.add_entry(travel_path, :moon)

      assert length(result.flights) == 1
      [flight] = result.flights
      assert flight.action == :launch
      assert flight.planet == :moon
      assert flight.id != nil
    end

    test "adds landing when last flight is launch" do
      first_flight = %Flight{id: "first", action: :launch, planet: :earth}
      travel_path = %TravelPath{flights: [first_flight], spacecraft_mass: 1000}

      result = TravelPaths.add_entry(travel_path, :moon)

      assert length(result.flights) == 2
      [_, landing] = result.flights
      assert landing.action == :land
      assert landing.planet == :moon
    end

    test "adds launch and landing when last flight is land" do
      first_flight = %Flight{id: "first", action: :launch, planet: :earth}
      second_flight = %Flight{id: "second", action: :land, planet: :moon}
      travel_path = %TravelPath{flights: [first_flight, second_flight], spacecraft_mass: 1000}

      result = TravelPaths.add_entry(travel_path, :mars)

      assert length(result.flights) == 4
      [_, _, launch, land] = result.flights
      assert launch.action == :launch
      assert launch.planet == :moon
      assert land.action == :land
      assert land.planet == :mars
    end

    test "preserves spacecraft mass" do
      travel_path = %TravelPath{flights: [], spacecraft_mass: 5000}

      result = TravelPaths.add_entry(travel_path, :mars)

      assert result.spacecraft_mass == 5000
    end
  end

  describe "remove_entry/2" do
    test "removes flight by id" do
      flight = %Flight{id: "test-id", action: :launch, planet: :earth}
      travel_path = %TravelPath{flights: [flight], spacecraft_mass: 1000}

      result = TravelPaths.remove_entry(travel_path, "test-id")

      assert result.flights == []
    end

    test "removes only matching flight id" do
      flight1 = %Flight{id: "keep", action: :launch, planet: :earth}
      flight2 = %Flight{id: "remove", action: :land, planet: :moon}
      travel_path = %TravelPath{flights: [flight1, flight2], spacecraft_mass: 1000}

      result = TravelPaths.remove_entry(travel_path, "remove")

      assert length(result.flights) == 1
      assert hd(result.flights).id == "keep"
    end

    test "returns unchanged path when id not found" do
      flight = %Flight{id: "test-id", action: :launch, planet: :earth}
      travel_path = %TravelPath{flights: [flight], spacecraft_mass: 1000}

      result = TravelPaths.remove_entry(travel_path, "non-existent")

      assert length(result.flights) == 1
    end
  end
end
