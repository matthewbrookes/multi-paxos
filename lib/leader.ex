# Matthew Brookes (mb5715) and Abhinav Mishra (am8315)

defmodule LeaderState do
  @enforce_keys [:config, :acceptors, :replicas, :ballot_number]
  defstruct(
    config:        Map.new,
    acceptors:     [],
    replicas:      [],
    ballot_number: nil,
    active:        false,
    proposals:     Map.new
  )
end # LeaderState

defmodule Leader do

  def start config do
    ballot_number = { 0, self() }

    receive do
      { :bind, acceptors, replicas } ->
        spawn Scout, :start, [self(), acceptors, ballot_number]

        state = %LeaderState{
          config: config,
          acceptors: acceptors,
          replicas: replicas,
          ballot_number: ballot_number
        }

        next state
    end
  end # start

  defp next state do
    receive do
      { :propose, s, c } ->
        proposals =
          if !Map.has_key? state.proposals, s do
            if state.active do
              spawn Commander,
                    :start,
                    [self(), state.acceptors, state.replicas,
                    { state.ballot_number, s ,c }]
            end
            Map.put state.proposals, s, c
          else
            state.proposals
          end

        next %{ state | proposals: proposals }

      { :adopted, b, pvals} ->
        proposals = update state.proposals, pmax MapSet.to_list(pvals)
        for { s, c } <- Map.to_list(proposals), do:
          spawn Commander,
                :start,
                [self(), state.acceptors, state.replicas, { b, s, c }]

        next %{ state | proposals: proposals, active: true, ballot_number: b }

      { :preempted, { r, _ } = b } ->
        if b > state.ballot_number do
          ballot_number = { r + 1, self() }
          spawn Scout, :start, [self(), state.acceptors, ballot_number]
          next %{ state | active: false, ballot_number: ballot_number }
        else
          next state
        end
    end
  end

  defp pmax pvalues do
    ballot_numbers = Enum.map(pvalues, fn ({ b, _, _ }) -> b end)
    max_ballot_number = Enum.max(ballot_numbers, fn -> -1 end)
    max_pvalues = Enum.filter pvalues, fn ({ b, _, _ }) -> b == max_ballot_number end
    Map.new Enum.map(max_pvalues, fn ({ _, s, c }) -> { s, c } end)
  end

  defp update x, y do
    Map.merge y, x, fn _, c, _ -> c end
  end

end
