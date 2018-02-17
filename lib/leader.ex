# Matthew Brookes (mb5715) and Abhinav Mishra (am8315)

defmodule Leader do

  def start config do
    ballot_number = { 0, self() }

    receive do
      { :bind, acceptors, replicas } ->
        spawn Scout, :start, [self(), acceptors, ballot_number]
        next config, acceptors, replicas, ballot_number, false, Map.new
    end

  end # start

  defp next config, acceptors, replicas, ballot_number, active, proposals do
    receive do
      { :propose, s, c } ->
        proposals =
          if !Map.has_key? proposals, s do
            if active do
              spawn Commander,
                    :start,
                    [self(), acceptors, replicas, { ballot_number, s ,c }]
            end
            Map.put proposals, s, c
          else
            proposals
          end

        next config, acceptors, replicas, ballot_number, active, proposals

      { :adopted, b, pvals} ->
        proposals = update proposals, pmax MapSet.to_list(pvals)
        for { s, c } <- Map.to_list(proposals), do:
          spawn Commander, :start, [self(), acceptors, replicas, { b, s, c }]

        next config, acceptors, replicas, b, true, proposals

      { :preempted, { r, _ } = b } ->
        if b > ballot_number do
          ballot_number = { r + 1, self() }
          spawn Scout, :start, [self(), acceptors, ballot_number]
          next config, acceptors, replicas, ballot_number, false, proposals
        else
          next config, acceptors, replicas, ballot_number, active, proposals
        end
    end
  end

  defp pmax pvalues do
    ballot_numbers = Enum.map(pvalues, fn ({ b, _, _ }) -> b end)
    max_ballot_number = Enum.max(ballot_numbers, fn -> -1 end)
    max_pvalues = Enum.filter pvalues, fn ({b, _, _}) -> b == max_ballot_number end
    Map.new(Enum.map(max_pvalues, fn ({b, s, c}) -> {s, {b, c}} end))
  end

  defp update x, y do
    Map.merge y, x, fn _, c, _ -> c end
  end

end
