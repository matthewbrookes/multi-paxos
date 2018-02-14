# Matthew Brookes (mb5715) and Abhinav Mishra (am8315)

defmodule Leader do

  def start acceptors, replicas do
    ballot_number = { 0, self() }
    spawn Scout, :start, [self(), acceptors, ballot_number]
    next acceptors, replicas, ballot_number, false, Map.new
  end

  defp next acceptors, replicas, ballot_number, active, proposals do
    receive do
      { :propose, s, c } ->
        if !Map.has_key? s, c do
          proposals = Map.put proposals, s, c
          if active do
            spawn Commander,
                  :start,
                  [self(), acceptors, replicas, { ballot_number, s ,c }]
          end
          next acceptors, replicas, ballot_number, active, proposals
        end

      { :adopted, b, pvals} ->
        proposals = update proposals, pmax pvals
        for { s, c } <- Map.to_list(proposals), do:
          spawn Commander, :start, [self(), acceptors, replicas, { b, s, c }]
          next acceptors, replicas, b, true, proposals

      { :preempted, { r, _ } = b } ->
        if b > ballot_number do
          ballot_number = { r + 1, self() }
          spawn Scout, :start, [self(), acceptors, ballot_number]
          next acceptors, replicas, b, false, proposals
        end
    end
  end

  defp pmax pvalues do
    max_ballot_number = Enum.max Enum.map pvalues, fn ({ b, _, _ }) -> b end
    Enum.filter pvalues, fn ({b, _, _}) -> b == max_ballot_number end
  end

  defp update x, y do
    Map.merge y, x, fn _, c, _ -> c end
  end

end
