defmodule Fuelex.TravelPaths.TravelPath do
  @moduledoc """
  Represents a complete travel path with spacecraft mass and a list of flights.

  This schema is used as an embedded schema for form handling in the LiveView.
  It validates the spacecraft mass and contains a list of flights representing
  the journey's path.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Fuelex.TravelPaths.Flight

  @type t :: %__MODULE__{
          spacecraft_mass: integer() | nil,
          flights: [Flight.t()]
        }

  @primary_key false
  embedded_schema do
    field :spacecraft_mass, :integer

    embeds_many :flights, Flight
  end

  def changeset(travel_path \\ %__MODULE__{}, attrs) do
    travel_path
    |> cast(attrs, [:spacecraft_mass])
    |> validate_required([:spacecraft_mass])
    |> validate_number(:spacecraft_mass, greater_than_or_equal_to: 0)
    |> cast_embed(:flights, with: &Flight.changeset/2)
  end
end
