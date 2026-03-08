defmodule Fuelex.TravelPath do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :spacecraft_mass, :integer

    embeds_many :flights, Flight do
      field :action, Ecto.Enum, values: [:launch, :land]
      field :planet, Ecto.Enum, values: [:earth, :moon, :mars]
    end
  end

  def changeset(travel_path \\ %__MODULE__{}, attrs) do
    travel_path
    |> cast(attrs, [:spacecraft_mass])
    |> validate_required([:spacecraft_mass])
    |> validate_number(:spacecraft_mass, greater_than_or_equal_to: 0)
    |> cast_embed(:flights, with: &flight_changeset/2)
  end

  defp flight_changeset(flight, attrs) do
    flight
    |> cast(attrs, [:id, :action, :planet])
    |> validate_required([:action, :planet])
  end
end
