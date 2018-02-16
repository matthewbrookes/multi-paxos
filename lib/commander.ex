# Matthew Brookes (mb5715) and Abhinav Mishra (am8315)

defmodule Commander do

  def start leader, acceptors, replicas, pvalue do
    for acceptor <- acceptors, do: send acceptor, { :p2a, self(), pvalue }
    next leader, acceptors, replicas, pvalue, MapSet.new(acceptors)
  end

  defp next leader, acceptors, replicas, { ballot_number, s, c }, wait_for do
    receive do
      { :p2b, a, b } ->
        if b == ballot_number do
          wait_for = MapSet.delete wait_for, a
          if MapSet.size(wait_for) < (length(acceptors) / 2) do
            IO.puts "Informing replicas"
            for replica <- replicas, do: send replica, { :decision, s, c }
            Process.exit self(), :kill
          end
        else
          IO.puts "Pre-empting #{inspect(ballot_number)}"
          send leader, { :preempted, b }
        end
    end
  end

end
