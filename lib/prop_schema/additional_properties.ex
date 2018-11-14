defmodule PropSchema.AdditionalProperties do
  @moduledoc """
  A behaviour that is used to define additional properties not provided in the base properties provided in the module.

  ### How to Implement

  Once you have implemented the callbacks below (see `c:generate_prop/3` below), add the module that implements this behaviour as the option `additional_properties` in the `PropSchema.Executor.__using__/1` declaration.
  """

  alias PropSchema.Types

  @doc """
  Implement to define additional properties not provided in the `PropSchema.BaseProperties` module.

  ## Example

      def generate_prop(field, :float, %{positive: true, required: true}) do
        quote do
          {unquote(Atom.to_string(field)), float(min: 1)}
        end
      end
  """
  @callback generate_prop(atom(), atom(), map()) :: Types.ast_expression()
  @optional_callbacks generate_prop: 3
end
