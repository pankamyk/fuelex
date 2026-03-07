defmodule Fuelex.FuelCalculatorTest do
  use ExUnit.Case, async: true

  alias Fuelex.FuelCalculator

  describe "valid_planets/0" do
    test "returns list of supported planets" do
      assert FuelCalculator.valid_planets() |> Enum.sort() == [:earth, :mars, :moon]
    end
  end

  describe "planet_gravity/1" do
    test "returns gravity for Earth" do
      assert FuelCalculator.planet_gravity(:earth) == {:ok, 9.807}
    end

    test "returns gravity for Moon" do
      assert FuelCalculator.planet_gravity(:moon) == {:ok, 1.62}
    end

    test "returns gravity for Mars" do
      assert FuelCalculator.planet_gravity(:mars) == {:ok, 3.711}
    end

    test "returns error for invalid planet" do
      assert FuelCalculator.planet_gravity(:jupiter) == {:error, :invalid_planet}
    end
  end

  describe "calculate_fuel/3" do
    test "calculates launch fuel with weight of fuel for Earth" do
      assert FuelCalculator.calculate_fuel(28801, :earth, :launch) == {:ok, 19772}
    end

    test "calculates landing fuel with weight of fuel for Earth" do
      assert FuelCalculator.calculate_fuel(28801, :earth, :land) == {:ok, 13447}
    end

    test "calculates launch fuel for Moon" do
      assert FuelCalculator.calculate_fuel(28801, :moon, :launch) == {:ok, 2024}
    end

    test "calculates landing fuel for Moon" do
      assert FuelCalculator.calculate_fuel(28801, :moon, :land) == {:ok, 1535}
    end

    test "calculates launch fuel for Mars" do
      assert FuelCalculator.calculate_fuel(28801, :mars, :launch) == {:ok, 5186}
    end

    test "calculates landing fuel for Mars" do
      assert FuelCalculator.calculate_fuel(28801, :mars, :land) == {:ok, 3874}
    end

    test "returns zero for zero mass" do
      assert FuelCalculator.calculate_fuel(0, :earth, :launch) == {:ok, 0}
      assert FuelCalculator.calculate_fuel(0, :earth, :land) == {:ok, 0}
    end
  end

  describe "calculate_total_fuel/2" do
    test "calculates total fuel for Apollo 11 mission" do
      path = [
        {:launch, :earth},
        {:land, :moon},
        {:launch, :moon},
        {:land, :earth}
      ]

      assert FuelCalculator.calculate_total_fuel(28801, path) == {:ok, 51898}
    end

    test "calculates total fuel for Mars mission" do
      path = [
        {:launch, :earth},
        {:land, :mars},
        {:launch, :mars},
        {:land, :earth}
      ]

      assert FuelCalculator.calculate_total_fuel(14606, path) == {:ok, 33388}
    end

    test "calculates total fuel for Passenger Ship mission" do
      path = [
        {:launch, :earth},
        {:land, :moon},
        {:launch, :moon},
        {:land, :mars},
        {:launch, :mars},
        {:land, :earth}
      ]

      assert FuelCalculator.calculate_total_fuel(75432, path) == {:ok, 212_161}
    end

    test "returns zero for empty path" do
      assert FuelCalculator.calculate_total_fuel(1000, []) == {:ok, 0}
    end

    test "calculates total fuel for single step" do
      assert FuelCalculator.calculate_total_fuel(28801, [{:launch, :earth}]) == {:ok, 19772}
      assert FuelCalculator.calculate_total_fuel(28801, [{:land, :earth}]) == {:ok, 13447}
    end

    test "returns error for invalid planet in path" do
      path = [{:launch, :earth}, {:land, :jupiter}]
      assert FuelCalculator.calculate_total_fuel(1000, path) == {:error, :invalid_planet}
    end
  end
end
