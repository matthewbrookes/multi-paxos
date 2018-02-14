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
    end
  end

end
