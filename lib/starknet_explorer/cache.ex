defmodule StarknetExplorer.IndexCache do
  use Agent

  def start_link(_) do
    blocks_mainnet = StarknetExplorer.Data.many_blocks_with_txs("mainnet")
    blocks_testnet = StarknetExplorer.Data.many_blocks_with_txs("testnet")

    Agent.start_link(
      fn ->
        %{
          "mainnet" => blocks_mainnet,
          "testnet" => blocks_testnet
        }
      end,
      name: __MODULE__
    )
  end

  def latest_blocks(network) do
    Agent.get(__MODULE__, fn state -> state[Atom.to_string(network)] end)
  end

  def add_block(block_number, network) do
    Agent.update(__MODULE__, fn state ->
      ## We fetch from the database here just to make the map keys atoms instead of strings
      ## Yes, really.
      network_string = Atom.to_string(network)
      block = block_number |> StarknetExplorer.Block.get_by_num(network_string)

      new_blocks =
        state[network_string]
        |> List.insert_at(0, block)
        |> maybe_delete_last_block()
        |> Enum.sort(fn block_1, block_2 ->
          block_1.number > block_2.number
        end)

      Map.put(state, network_string, new_blocks)
    end)
  end

  defp maybe_delete_last_block(blocks) do
    if length(blocks) > 15 do
      List.delete_at(blocks, length(blocks) - 1)
    else
      blocks
    end
  end
end
