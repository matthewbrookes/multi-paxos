# distributed algorithms, n.dulay 2 feb 18
# coursework 2, paxos made moderately complex

defmodule Client do

  def start config, client_num, replicas, monitor do
    if !config.silent, do: IO.puts "\tStarting client #{DAC.node_ip_addr()}"

    send monitor, { :keep_alive, self() }

    Process.send_after self(), :client_stop, config.client_stop
    next config, client_num, replicas, 0, monitor
  end # start

  defp next config, client_num, replicas, sent, monitor do
    # Setting client_sleep to 0 will completely overload the system
    # with lots of requests and lots of spawned rocesses.

    receive do
    :client_stop ->
      send monitor, { :client_sleep, client_num, sent }
      cond do
        config.setup === :'single' ->
          Process.sleep :infinity
        config.setup === :'docker' ->
          receive do
            :kill ->
              Process.whereis(:keep_alive) |> Process.exit(:kill)
          end
        true ->
          IO.puts "Error: Unexpected setup mode #{config.setup}"
      end

    after config.client_sleep ->
      account1 = Enum.random 1 .. config.n_accounts
      account2 = Enum.random 1 .. config.n_accounts
      amount   = Enum.random 1 .. config.max_amount
      transaction  = { :move, amount, account1, account2 }

      sent = sent + 1
      cmd = { self(), sent, transaction }

      # round robin which replicas to sent requests to
      replica = Enum.at replicas, rem(sent, length(replicas))
      send replica, { :client_request, cmd }

      if sent == config.max_requests, do: send self(), :client_stop

      # handle_reply() -- uncomment if replies are implemented
      next config, client_num, replicas, sent, monitor
    end
  end # next

  """
  defp handle_reply do  # this discards all replies received
    receive do
    { :reply, _cid, _result } -> handle_reply()
    after 0 -> true
    end # receive
  end # handle_reply
  """
end # Client
