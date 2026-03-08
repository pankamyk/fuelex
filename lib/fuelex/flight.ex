defmodule Fuelex.Flight do
  use Ecto.Schema
  import Ecto.Changeset

  @allowed_planets [:earth, :moon, :mars]
  @allowed_actions [:launch, :land]

  @primary_key false
  embedded_schema do
    field :id, :string, virtual: true
    field :action, Ecto.Enum, values: @allowed_actions
    field :planet, Ecto.Enum, values: @allowed_planets
  end

  def changeset(flight \\ %__MODULE__{}, attrs) do
    flight
    |> cast(attrs, [:id, :action, :planet])
    |> validate_required([:action, :planet])
    |> validate_inclusion(:action, @allowed_actions)
    |> validate_inclusion(:planet, @allowed_planets)
  end
end
