# distributed algorithms, n.dulay 2 feb 18
# coursework 2, paxos made moderately complex

defmodule Server do

  def start config, server_num, paxos, monitor do
    if !config.silent, do: IO.puts "\tStarting server #{DAC.node_ip_addr()}"

    send monitor, { :keep_alive, self() }

    config   = Map.put config, :server_num, server_num

    database = spawn Database, :start, [config, monitor]
    replica  = spawn Replica,  :start, [config, database, monitor]
    leader   = spawn Leader,   :start, [config]
    acceptor = spawn Acceptor, :start, [config]

    send paxos, { :config, replica, acceptor, leader }

    if config.setup === :'docker' do
      receive do
        :kill ->
          Process.whereis(:keep_alive) |> send(:kill)
        end
    end
  end # start

end # Server
