defmodule Fuelex.FuelCalculator do
  @moduledoc """
  Calculates the required fuel for spacecraft launch and landing operations
  on various planets in the Solar System.

  This module provides functions to calculate fuel requirements based on:
  - Spacecraft mass
  - Destination planet's gravity
  - Operation type (launch or landing)

  The fuel calculation accounts for the additional fuel needed to carry
  the fuel itself, using a recursive algorithm.

  ## Supported Planets

  - Earth: 9.807 m/s²
  - Moon: 1.62 m/s²
  - Mars: 3.711 m/s²

  ## Formulas

  - Launch: `floor(mass * gravity * 0.042 - 33)`
  - Landing: `floor(mass * gravity * 0.033 - 42)`

  ## Examples

      iex> Fuelex.FuelCalculator.calculate_fuel(28801, :earth, :launch)
      {:ok, 19772}

      iex> Fuelex.FuelCalculator.calculate_fuel(28801, :earth, :land)
      {:ok, 13447}

      iex> path = [{:launch, :earth}, {:land, :moon}, {:launch, :moon}, {:land, :earth}]
      iex> Fuelex.FuelCalculator.calculate_total_fuel(28801, path)
      {:ok, 51898}
  """

  @planets %{
    earth: 9.807,
    moon: 1.62,
    mars: 3.711
  }

  @launch_coefficient 0.042
  @launch_constant 33

  @landing_coefficient 0.033
  @landing_constant 42

  @doc """
  Returns a list of supported planets.

  ## Examples

      iex> Fuelex.FuelCalculator.valid_planets()
      [:earth, :mars, :moon]
  """
  @spec valid_planets() :: [atom()]
  def valid_planets, do: Map.keys(@planets)

  @doc """
  Returns the gravity for a given planet.

  ## Examples

      iex> Fuelex.FuelCalculator.planet_gravity(:earth)
      {:ok, 9.807}

      iex> Fuelex.FuelCalculator.planet_gravity(:jupiter)
      {:error, :invalid_planet}
  """
  @spec planet_gravity(atom()) :: {:ok, float()} | {:error, :invalid_planet}
  def planet_gravity(planet) do
    case Map.fetch(@planets, planet) do
      {:ok, gravity} -> {:ok, gravity}
      :error -> {:error, :invalid_planet}
    end
  end

  @doc """
  Calculates the total fuel required for a launch or landing operation,
  accounting for the weight of the fuel itself.

  This function uses recursion to calculate additional fuel needed to carry
  the initial fuel, continuing until the additional fuel required is zero
  or negative.

  ## Examples

      iex> Fuelex.FuelCalculator.calculate_fuel(28801, :earth, :launch)
      {:ok, 19772}

      iex> Fuelex.FuelCalculator.calculate_fuel(28801, :earth, :land)
      {:ok, 13447}
  """
  @spec calculate_fuel(non_neg_integer(), atom(), :launch | :land) ::
          {:ok, non_neg_integer()} | {:error, atom()}
  def calculate_fuel(mass, planet, action)
      when is_integer(mass) and mass >= 0 and action in [:launch, :land] do
    with {:ok, gravity} <- planet_gravity(planet),
         initial_fuel <- base_fuel(mass, gravity, action) do
      {:ok, initial_fuel + calculate_recursive(initial_fuel, gravity, action)}
    end
  end

  def calculate_fuel(_mass, _planet, _action), do: {:error, :wrong_arguments}

  @doc """
  Calculates the total fuel required for an entire mission path.

  The path is a list of tuples containing the action and planet for each step.
  Each step's fuel calculation includes the weight of the spacecraft and
  all previously calculated fuel.

  ## Examples

      iex> path = [{:launch, :earth}, {:land, :moon}]
      iex> Fuelex.FuelCalculator.calculate_total_fuel(28801, path)
      {:ok, 21307}

      iex> path = [{:launch, :earth}, {:land, :moon}, {:launch, :moon}, {:land, :earth}]
      iex> Fuelex.FuelCalculator.calculate_total_fuel(28801, path)
      {:ok, 51898}
  """
  @spec calculate_total_fuel(non_neg_integer(), [{:launch | :land, atom()}]) ::
          {:ok, non_neg_integer()} | {:error, atom()}
  def calculate_total_fuel(mass, path) when is_integer(mass) and mass >= 0 and is_list(path) do
    calculate_total_fuel_reverse(mass, Enum.reverse(path))
  end

  def calculate_total_fuel(_mass, path) when is_list(path), do: {:error, :invalid_mass}
  def calculate_total_fuel(_mass, _path), do: {:error, :invalid_path}

  defp calculate_total_fuel_reverse(_mass, []), do: {:ok, 0}

  defp calculate_total_fuel_reverse(mass, [{action, planet} | rest]) do
    with {:ok, fuel} <- calculate_fuel(mass, planet, action),
         {:ok, remaining_fuel} <- calculate_total_fuel_reverse(mass + fuel, rest) do
      {:ok, fuel + remaining_fuel}
    end
  end

  defp calculate_recursive(mass, planet, action) do
    case base_fuel(mass, planet, action) do
      additional_fuel when additional_fuel > 0 ->
        additional_fuel + calculate_recursive(additional_fuel, planet, action)

      _ ->
        0
    end
  end

  defp base_fuel(mass, gravity, :launch) do
    fuel = floor(mass * gravity * @launch_coefficient - @launch_constant)
    max(0, fuel)
  end

  defp base_fuel(mass, gravity, :land) do
    fuel = floor(mass * gravity * @landing_coefficient - @landing_constant)
    max(0, fuel)
  end
end
