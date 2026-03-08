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
    <div :if={@mass_valid} class="flex flex-wrap gap-2 mb-4">
      <button
        type="button"
        class="btn btn-outline btn-primary"
        phx-click="select_planet"
        phx-value-planet="earth"
      >
        Launch from Earth
      </button>
      <button
        type="button"
        class="btn btn-outline btn-secondary"
        phx-click="select_planet"
        phx-value-planet="moon"
      >
        Launch from Moon
      </button>
      <button
        type="button"
        class="btn btn-outline btn-accent"
        phx-click="select_planet"
        phx-value-planet="mars"
      >
        Launch from Mars
      </button>
    </div>
    """
  end

  @doc """
  Renders the flight list showing the current path with remove buttons.
  """
  attr :flights, :list, required: true

  def flight_list(assigns) do
    ~H"""
    <ul class="flex flex-col gap-2">
      <li
        :for={{flight, index} <- Enum.with_index(@flights)}
        class="flex items-center justify-between gap-2"
      >
        <div class="flex items-center gap-2">
          <span :if={flight.action == :launch} class="text-2xl">🚀</span>
          <span :if={flight.action == :land} class="text-2xl">🛬</span>
          <span class="font-medium">
            {flight.action |> Atom.to_string() |> String.capitalize()} {flight.planet
            |> Atom.to_string()
            |> String.capitalize()}
          </span>
        </div>
        <button
          :if={index == length(@flights) - 1}
          type="button"
          class="btn btn-ghost btn-xs"
          phx-click="remove_flight"
          phx-value-id={flight.id}
        >
          <span class="text-error">✕</span>
        </button>
      </li>
    </ul>
    """
  end

  @doc """
  Renders destination selector buttons for adding more planets to the flight path.
  """
  attr :mass_valid, :boolean, required: true

  def destination_selector(assigns) do
    ~H"""
    <div class="flex flex-wrap gap-2">
      <button
        type="button"
        class="btn btn-outline btn-primary btn-sm"
        phx-click="select_planet"
        phx-value-planet="earth"
        disabled={!@mass_valid}
      >
        Earth
      </button>
      <button
        type="button"
        class="btn btn-outline btn-secondary btn-sm"
        phx-click="select_planet"
        phx-value-planet="moon"
        disabled={!@mass_valid}
      >
        Moon
      </button>
      <button
        type="button"
        class="btn btn-outline btn-accent btn-sm"
        phx-click="select_planet"
        phx-value-planet="mars"
        disabled={!@mass_valid}
      >
        Mars
      </button>
    </div>
    """
  end

  @doc """
  Renders the total fuel required card.
  """
  attr :total_fuel, :any, required: true

  def fuel_card(assigns) do
    ~H"""
    <div class="card bg-base-300 mt-6">
      <div class="card-body items-center text-center">
        <h2 class="card-title">Total Fuel Required</h2>
        <p :if={@total_fuel == nil} class="text-base-content/60">
          Enter spacecraft mass and add destinations to calculate fuel
        </p>
        <p :if={@total_fuel} class="text-4xl font-bold text-primary">
          {@total_fuel} kg
        </p>
      </div>
    </div>
    """
  end
end
