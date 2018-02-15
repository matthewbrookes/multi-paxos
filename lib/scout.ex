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
          pvalues = MapSet.put pvalues, r
          wait_for = MapSet.delete wait_for, a
          if MapSet.size(wait_for) < (MapSet.size(wait_for) / 2) do
            send leader, { :adopted, b, pvalues }
            Process.exit self(), :kill
          end
          next leader, acceptors, ballot_number, wait_for, pvalues
        else
          send leader, { :preempted, b }
          Process.exit self(), :kill
        end
    end
  end

end
