defmodule Mix.Tasks.PropSchema.Print do
  use Mix.Task
  alias Mix.Tasks.Compile
  alias PropSchema.TestHarness
  require Logger
  require TestHarness

  @moduledoc """
    Prints the property tests generated for the given module. Use `--help` to see usage directions.

  ## Example

        prop_schema "example" do
          prop_field(:example_string, :string, string_type: :alphanumeric, required: true)
          prop_field(:example_int, :integer, postive: true, required: false)
          field(:example_float, :float)
        end

    Will generate:

        property("valid changeset") do
          check(all(map <- StreamData.fixed_map([{"example_int", StreamData.one_of([StreamData.integer(), StreamData.constant(nil)])}, {"example_string", StreamData.string(:alphanumeric, min_length: 1)}]))) do
            changeset = PropSchema.ExampleModule.changeset(struct(PropSchema.ExampleModule), map)
            (fn changeset ->
              if(not(changeset.valid?())) do
                Logger.error("Test will fail because: \#{inspect(changeset.errors())}")
              end
              assert(changeset.valid?())
            end).(changeset)
          end

        property("valid changeset - missing example_int") do
          check(all(map <- StreamData.fixed_map([{"example_string", StreamData.string(:alphanumeric, min_length: 1)}]))) do
            changeset = PropSchema.ExampleModule.changeset(struct(PropSchema.ExampleModule), map)
            (fn changeset ->
              if(not(changeset.valid?())) do
                Logger.error("Test will fail because: \#{inspect(changeset.errors())}")
              end
              assert(changeset.valid?())
            end).(changeset)
          end
        end

        property("invalid changeset - missing example_string") do
          check(all(map <- StreamData.fixed_map([{"example_int", StreamData.one_of([StreamData.integer(), StreamData.constant(nil)])}]))) do
            changeset = PropSchema.ExampleModule.changeset(struct(PropSchema.ExampleModule), map)
            (fn changeset ->
              if(changeset.valid?()) do
                Logger.error("Test will fail because: No errors")
              end
              refute(changeset.valid?())
            end).(changeset)
          end
        end
  """

  @shortdoc """

    Usage: `mix prop_schema.print <module> [options]`

    Where `module` is the PropSchema module for which tests will be generated.

    Options:

      output_path         Will output the results to a file at the given path. If file doesn't exist, it will be created
      additional_props    A module where the custom properties you have written are found. Make sure the compiler will
                            actually compile the module for the dev environemnt.
      filters             A module where the custom filters you have written are found. Make sure the compiler will
                            actually compile the module for the dev environemnt.
  """

  def run(args) do
    {parsed, argv} = parse_args(args)
    print_help(parsed)
    Compile.run(args)
    module = get_module(argv)
    additional = get_additional(parsed)
    filters = get_filters(parsed)

    module
    |> get_prop_tests(additional, filters)
    |> Enum.map(&Macro.to_string(&1))
    |> Enum.join("\n\n")
    |> output(module, parsed)
  end

  defp parse_args(args) do
    {parsed, argv, errors} =
      OptionParser.parse(args,
        strict: [
          help: :boolean,
          output_path: :string,
          additional_props: :string,
          filters: :string
        ]
      )

    Enum.each(errors, fn error -> Logger.warn("Erroneous option given: #{inspect(error)}") end)
    {parsed, argv}
  end

  defp get_module(argv) do
    case Enum.at(argv, 0) do
      nil ->
        nil

      name ->
        String.to_existing_atom("Elixir." <> name)
    end
  end

  defp get_additional(parsed) do
    case Keyword.get(parsed, :additional_props) do
      nil ->
        nil

      additional ->
        String.to_existing_atom("Elixir." <> additional)
    end
  end

  defp get_filters(parsed) do
    case Keyword.get(parsed, :filters) do
      nil ->
        nil

      additional ->
        String.to_existing_atom("Elixir." <> additional)
    end
  end

  defp get_prop_tests(module, additional, filters) do
    List.flatten([
      TestHarness.__create_prop_test__(
        module,
        :all_fields,
        module.__prop_schema__(),
        additional,
        filters
      ),
      TestHarness.__create_prop_test__(
        module,
        module.__prop_schema__(),
        additional,
        filters
      )
    ])
  end

  defp print_help(parsed) do
    if Keyword.get(parsed, :help, false) do
      Logger.info(@shortdoc)
      exit(:normal)
    end
  end

  defp output(tests, module, parsed) do
    case Keyword.get(parsed, :output_path) do
      nil ->
        Logger.info("Generated tests for #{module}:\n #{tests}")

      path ->
        File.write(path, tests)
    end
  end
end
