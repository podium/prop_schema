defmodule PropSchema.ExampleStreamed do
  @moduledoc false
  import PropSchema.Stream

  defmodule Subject do
    @moduledoc false
    generate_complete_map(PropSchema.ExampleModule, PropSchema.ExampleAdditionalProperties)

    def public_complete, do: complete_example_module()
  end

  defmodule Owner do
    @moduledoc false
    generate_complete_map(PropSchema.ExampleOwner, PropSchema.ExampleAdditionalProperties)

    def public_complete, do: complete_example_owner()
  end
end
