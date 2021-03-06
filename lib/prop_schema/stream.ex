defmodule PropSchema.Stream do
  @moduledoc """
  Reads the `prop_schema` information from the provided module. Then it constructs a series of private functions to
  include in a test module according to provided field requirements and other considerations declared in the schema.
  """

  alias PropSchema.Generator
  require Generator

  @doc """
  Creates the quoted fixed_map expression like you would find in the property tests but can be used at your discretion.

  ## Example

      defmodule Test do
        require PropSchema.Stream
        PropSchema.Stream.generate_complete_map(PropSchema.ExampleModule, :complete_example_module, PropSchema.ExampleAdditionalProperties)

        def get_ten(), do: Enum.take(complete_example_module(), 10)
      end
  """
  @spec generate_complete_map(atom(), atom(), atom()) :: Macro.t()
  defmacro generate_complete_map(mod, name, additional_props \\ nil)

  defmacro generate_complete_map(mod, name, additional_props) when is_atom(name) do
    schema = Macro.expand_once(mod, __ENV__).__prop_schema__()
    adds = Macro.expand_once(additional_props, __ENV__)

    quote do
      defp unquote({name, [context: Elixir], Elixir}) do
        unquote(Generator.generate_complete_map(schema, adds))
      end
    end
  end

  @doc """
  Creates the quoted fixed_map expression but with the specified `missing_prop` excluded.

  ## Example

      defmodule Test do
        require PropSchema.Stream
        PropSchema.Stream.generate_incomplete_map(PropSchema.ExampleModule, :incomplete_example_module, :test_int, PropSchema.ExampleAdditionalProperties)

        def get_ten(excluded), do: excluded |> incomplete_example_module() |> Enum.take(10)
      end
  """
  @spec generate_incomplete_map(atom(), atom(), atom(), atom()) :: Macro.t()
  defmacro generate_incomplete_map(mod, name, excluded, additional_props \\ nil)

  defmacro generate_incomplete_map(mod, name, excluded, additional_props) when is_atom(name) do
    schema = Macro.expand_once(mod, __ENV__)
    adds = Macro.expand_once(additional_props, __ENV__)
    quoted_map(name, schema, excluded, adds)
  end

  @doc """
  Scans the schema and calls `generate_incomplete_map/4` for each field as the `missing_prop`

  ## Example

        defmodule Test do
          require PropSchema.Stream
          PropSchema.Stream.generate_all_incomplete_maps(PropSchema.ExampleModule, :incomplete_example_module, PropSchema.ExampleAdditionalProperties)

          def get_ten(excluded), do: excluded |> incomplete_example_module() |> Enum.take(10)
        end
  """
  @spec generate_all_incomplete_maps(atom(), atom(), atom()) :: Macro.t()
  defmacro generate_all_incomplete_maps(mod, name, additional_props \\ nil)

  defmacro generate_all_incomplete_maps(mod, name, additional_props) when is_atom(name) do
    schema = Macro.expand_once(mod, __ENV__)
    adds = Macro.expand_once(additional_props, __ENV__)
    quoted = Enum.map(schema.__prop_schema__(), &quoted_map(name, schema, &1, adds))
    {:__block__, [], quoted}
  end

  defp quoted_map(name, schema, {excluded, _}, additional_props),
    do: quoted_map(name, schema, excluded, additional_props)

  defp quoted_map(name, schema, excluded, additional_props) do
    quote do
      defp unquote(name)(unquote(excluded)) do
        unquote(
          Generator.generate_incomplete_map(excluded, schema.__prop_schema__(), additional_props)
        )
      end
    end
  end
end
