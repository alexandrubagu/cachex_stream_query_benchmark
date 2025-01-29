# Generate games
limit = 500_000

games = Enum.map(1..limit, fn i -> %{id: i, product_id: Enum.random(1..100)} end)

# Start cache
{:ok, _pid} = Cachex.start_link(:current_impl)
{:ok, _pid} = Cachex.start_link(:proposed_impl)

##########################
# Current Implementation #
##########################

by_id = Enum.map(games, &{{:id, &1.id}, &1})
by_product = games |> Enum.group_by(fn %{product_id: product_id} -> {:product_id, product_id} end) |> Enum.into([])

data = [{:all, games} | by_id ++ by_product]
Cachex.put_many(:current_impl, data)

###########################
# Proposed Implementation #
###########################

data = Enum.map(games, fn game -> {{game.id, game.category_id, game.product_id}, game} end)
Cachex.put_many(:proposed_impl, data)

Benchee.run(
  %{
    "current_impl.category_id" => fn ->
      id = Enum.random(1..limit)
      Cachex.get!(:current_impl, {:category_id, id})
    end,
    "proposed_impl.category_id" => fn ->
      id = Enum.random(1..limit)
      filter = {:==, {:element, 2, :key}, id}
      query = Cachex.Query.build(where: filter, output: :value)
      Cachex.stream!(:proposed_impl, query) |> Enum.to_list()
    end
  },
  time: 10,
  memory_time: 2
)
