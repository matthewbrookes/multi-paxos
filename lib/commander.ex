# Matthew Brookes (mb5715) and Abhinav Mishra (am8315)

defmodule Commander do

  def start leader, acceptors, replicas, pvalue do
    for acceptor <- acceptors, do: send acceptor, { :p2a, self(), pvalue }
    next leader, acceptors, replicas, pvalue, MapSet.new(acceptors)
  end

  defp next leader, acceptors, replicas, { ballot_number, s, c } = pvalue, wait_for do
    receive do
      { :p2b, acceptor, b } ->
        if b == ballot_number do
          wait_for = MapSet.delete wait_for, acceptor
          if MapSet.size(wait_for) < (length(acceptors) / 2) do
            for replica <- replicas, do:
              send replica, { :decision, s, c }
          else
            next leader, acceptors, replicas, pvalue, wait_for
          end
        else
          send leader, { :preempted, b }
        end
    end
  end

end
