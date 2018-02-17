# Matthew Brookes (mb5715) and Abhinav Mishra (am8315)

defmodule Scout do

  def start leader, acceptors, ballot_number do
    for acceptor <- acceptors, do:
      send acceptor, { :p1a, self(), ballot_number }
    next leader, acceptors, ballot_number, MapSet.new(acceptors), MapSet.new
  end

  defp next leader, acceptors, ballot_number, wait_for, pvalues do
    receive do
      { :p1b, a, b, r } ->
        if b == ballot_number do
          pvalues = MapSet.union pvalues, r
          wait_for = MapSet.delete wait_for, a
          if MapSet.size(wait_for) < (length(acceptors) / 2) do
            send leader, { :adopted, b, pvalues }
          else
            next leader, acceptors, ballot_number, wait_for, pvalues
          end
        else
          send leader, { :preempted, b }
          Process.exit self(), :kill
        end
    end
  end

end
