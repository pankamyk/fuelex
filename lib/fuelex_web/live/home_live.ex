defmodule FuelexWeb.HomeLive do
  @moduledoc """
  LiveView for the Fuelex homepage.

  Allows users to:
  - Enter spacecraft mass
  - Build a flight path by selecting planets
  - View total fuel required for the journey

  The LiveView manages the state of the travel path, validates user input,
  and calculates the total fuel consumption based on the configured path.
  """

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

  @doc """
  Renders planet selector buttons for the initial launch selection.
  """
  attr :mass_valid, :boolean, required: true

  def planet_selector(assigns) do
    ~H"""
    <div>
      <h2 class="text-lg font-semibold mb-2">
        Select Launch Location <span>🚀</span>
      </h2>
      <div :if={@mass_valid} class="flex gap-2 mb-2">
        <.select_planet_btn planet="earth" />
        <.select_planet_btn planet="moon" />
        <.select_planet_btn planet="mars" />
      </div>
    </div>
    """
  end

  @doc """
  Renders the flight list showing the current path with remove buttons.
  """
  attr :flights, :list, required: true

  def flight_list(assigns) do
    ~H"""
    <div class="mt-2">
      <h3 class="text-md font-semibold mb-2">Flight Path</h3>
      <ul class="flex flex-col gap-2">
        <li
          :for={{flight, index} <- Enum.with_index(@flights)}
          class="flex items-center justify-between bg-slate-200/5 border-slate-200/10 border-1 py-1 px-2 rounded-sm gap-2"
        >
          <div>
            <div class="flex items-center gap-2">
              <span :if={flight.action == :launch} class="text-2xl">🚀</span>
              <span :if={flight.action == :land} class="text-2xl">🛬</span>
              <span class="font-medium text-shadow-lg">
                {display_atom(flight.action)} {display_atom(flight.planet)}
              </span>
            </div>
            <span class="text-xs text-shadow-md">{get_planet_gravity(flight.planet)} m/s²</span>
          </div>
          <button
            :if={index == length(@flights) - 1}
            type="button"
            class="btn btn-xs btn-ghost hover:bg-slate-200/10 hover:border-slate-200/15 shadow-none"
            phx-click="remove_flight"
            phx-value-id={flight.id}
          >
            <span class="text-base-content">✕</span>
          </button>
        </li>
      </ul>
    </div>
    """
  end

  @doc """
  Renders planet selector button.
  """
  attr :planet, :string, required: true
  attr :disabled, :boolean, default: nil

  def select_planet_btn(assigns) do
    ~H"""
    <button
      type="button"
      class="btn flex-1 bg-slate-800/25 hover:bg-slate-800/35"
      phx-click="select_planet"
      phx-value-planet={@planet}
      disabled={@disabled}
    >
      {String.capitalize(@planet)}
    </button>
    """
  end

  @doc """
  Renders destination selector buttons for adding more planets to the flight path.
  """
  attr :mass_valid, :boolean, required: true

  def destination_selector(assigns) do
    ~H"""
    <div>
      <h2 class="text-lg font-semibold mb-2">
        Select Destination <span>🛬</span>
      </h2>
      <div class="flex gap-2">
        <.select_planet_btn planet="earth" disabled={!@mass_valid} />
        <.select_planet_btn planet="moon" disabled={!@mass_valid} />
        <.select_planet_btn planet="mars" disabled={!@mass_valid} />
      </div>
      <div class="divider my-2"></div>
    </div>
    """
  end

  @doc """
  Renders the total fuel required card.
  """
  attr :total_fuel, :any, required: true

  def fuel_card(assigns) do
    ~H"""
    <div class="card bg-slate-600/25 backdrop-blur-xs border-1 border-slate-600/35 shadow-xl my-6 w-100">
      <div class="card-body items-center text-center">
        <h2 class="card-title text-shadow-lg text-xl">Total Fuel Required</h2>
        <p :if={@total_fuel == nil} class="text-base-content/90 text-shadow-lg">
          Enter spacecraft mass and add destinations to calculate fuel mass required
        </p>
        <p :if={@total_fuel} class="text-4xl font-bold text-orange-200 text-shadow-lg">
          {@total_fuel} kg
        </p>
      </div>
    </div>
    """
  end

  defp display_atom(property), do: property |> Atom.to_string() |> String.capitalize()

  defp get_planet_gravity(planet) do
    case FuelCalculator.planet_gravity(planet) do
      {:ok, value} -> value
      _ -> nil
    end
  end
end
