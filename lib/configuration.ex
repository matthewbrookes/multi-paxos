# Matthew Brookes (mb5715) and Abhinav Mishra (am8315)

defmodule Configuration do

  def version 1 do # configuration 1
    %{
      debug_level:  0,      # debug level
      docker_delay: 5_000,  # time (ms) to wait for containers to start up

      window_size:  100,    # window size for the replica
      max_requests: 500,    # max requests each client will make
      client_sleep: 5,      # time (ms) to sleep before sending new request
      client_stop:  10_000, # time (ms) to stop sending further requests
      n_accounts:   100,    # number of active bank accounts
      max_amount:   1000,   # max amount moved between accounts

      print_after:  1_000   # monitor print interval  msecs
    }
  end

  def version 2 do # same as version 1 with higher debug level
    config = version 1
    Map.put config, :debug_level, 1
  end

  def version 3 do # configuration 3
  end

end # module -----------------------
