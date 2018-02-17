# Matthew Brookes (mb5715) and Abhinav Mishra (am8315)

defmodule ReplicaState do
  @enforce_keys [:config, :db, :leaders, :monitor]
  defstruct(
    config:    Map.new,
    db:        nil,
    decisions: Map.new,
    leaders:   [],
    monitor:   nil,
    proposals: Map.new,
    requests:  [],
    s_in:      1,
    s_out:     1
  )
end # ReplicaState


defmodule Replica do

  def start config, db, monitor do
    receive do
      { :bind, leaders } ->
        replica_state = %ReplicaState{
          config:  config,
          db:      db,
          leaders: leaders,
          monitor: monitor
        }

        next replica_state
    end

  end # start

  defp next state do
    receive do
    { :client_request, cmd } ->
      send state.monitor, { :client_request, state.config.server_num }
      new_state = propose %{ state | requests: [cmd | state.requests] }
      next new_state

    { :decision, slot, cmd } ->
      new_state = %{ state | decisions: Map.put(state.decisions, slot, cmd) }
      new_state = propose(decide new_state)
      next new_state
    end # receive
  end # next

  defp propose state do
    window = state.config.window_size
    new_state =
      if state.s_in < state.s_out + window and !Enum.empty? state.requests do
        new_state =
          if !Map.has_key? state.decisions, state.s_in do
            [ c | requests ] = state.requests
            for leader <- state.leaders, do: send leader, { :propose, state.s_in, c }
            %{ state | proposals: Map.put(state.proposals, state.s_in, c), requests: requests }
          else
            state
          end

        propose %{ new_state | s_in: new_state.s_in + 1 }
      else
        state
      end # if

    new_state
  end # propose

  defp decide state do
    new_state =
      if Map.has_key? state.decisions, state.s_out do
        c1 = Map.get state.decisions, state.s_out

        new_state =
          if Map.has_key? state.proposals, state.s_out do
              c2 = Map.get state.proposals, state.s_out
              proposals = Map.delete state.proposals, state.s_out
              requests =
                if c1 !== c2 do
                  [c2 | state.requests]
                else
                  state.requests
                end

              %{ state | proposals: proposals, requests: requests }
          else
            state
          end

        execute new_state, c1
        decide %{ new_state | s_out: new_state.s_out + 1 }
      else
        state
      end

    new_state
  end # decide

  defp execute state, { client, id, transaction } = command do
    decisions_list = Map.to_list state.decisions
    cmds = Enum.filter(decisions_list, fn({ s, _ }) -> s < state.s_out end)
    cmds = Enum.map(cmds, fn({ _, cmd }) -> cmd end)

    if !Enum.member? cmds, command do
        send state.db, { :execute, transaction }
        send client, { :response, id, :ok }
    end
  end # execute

end # Replica
