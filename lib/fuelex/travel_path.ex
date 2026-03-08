defmodule Fuelex.TravelPath do
  use Ecto.Schema
  import Ecto.Changeset

  alias Fuelex.Flight

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
