# Matthew Brookes (mb5715) and Abhinav Mishra (am8315)

defmodule MonitorState do
  @enforce_keys [:paxos, :config]
  defstruct(
    paxos:        nil,
    config:       Map.new,
    clock:        0,
    updates:      Map.new,
    requests:     Map.new,
    transactions: Map.new,
    clients:      Map.new
  )
end # MonitorState

defmodule Monitor do

  def start config, paxos do
    Process.send_after self(), :print, config.print_after
    state = %MonitorState{
      paxos: paxos,
      config: config
    }
    next state
  end # start

  defp next state do
    receive do
      { :client_sleep, client_num, sent } ->
        if !state.config.silent, do:
          IO.puts "\nClient #{client_num} going to sleep, sent = #{sent}"

        clients = Map.put state.clients, client_num, sent
        next %{ state | clients: clients }

      { :db_update, db, seqnum, transaction } ->
        { :move, amount, from, to } = transaction

        done = Map.get state.updates, db, 0

        if seqnum != done + 1  do
          IO.puts "  ** error db #{db}: seq #{seqnum} expecting #{done+1}"
          System.halt
        end

        transactions =
          case Map.get state.transactions, seqnum do
            nil ->
              # IO.puts "db #{db} seq #{seqnum} #{done}"
              Map.put state.transactions, seqnum, %{ amount: amount, from: from, to: to }

            t -> # already logged - check transaction
              if amount != t.amount or from != t.from or to != t.to do
                IO.puts " ** error db #{db}.#{done} [#{amount},#{from},#{to}] " <>
                  "= log #{done}/#{Map.size state.transactions} [#{t.amount},#{t.from},#{t.to}]"
                System.halt
              end
              state.transactions
          end # case

          updates = Map.put state.updates, db, seqnum
          next %{ state | updates: updates, transactions: transactions }

      { :client_request, server_num } ->  # requests by replica
        seen = Map.get state.requests, server_num, 0
        requests = Map.put state.requests, server_num, seen + 1
        next %{ state | requests: requests }

      :print ->
        clock = state.clock + state.config.print_after

        if !state.config.silent do
          print_stats clock, state.updates, state.requests
        end

        if Map.size(state.clients) === state.config.n_clients do
          total_messages = Enum.sum(for { _, sent } <- state.clients, do: sent)

          halt = Enum.all?(
            (for { _, num_updates } <- state.updates, do:
              num_updates === total_messages),
            fn(x) -> x end
          )

          if halt do
            print_stats clock, state.updates, state.requests
            send state.paxos, :success
          end
        end

        Process.send_after self(), :print, state.config.print_after
        next %{ state | clock: clock }

      _ ->
        IO.puts "monitor: unexpected message"
        System.halt
    end # receive
  end # next

  defp print_stats clock, updates, requests do
    sorted = updates |> Map.to_list |> List.keysort(0)
    IO.puts "\ntime = #{clock}  updates done = #{inspect sorted}"
    sorted = requests |> Map.to_list |> List.keysort(0)
    IO.puts "time = #{clock} requests seen = #{inspect sorted}"
  end

end # Monitor
