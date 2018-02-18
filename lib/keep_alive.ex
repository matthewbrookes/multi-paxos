# Matthew Brookes (mb5715) and Abhinav Mishra (am8315)

defmodule KeepAlive do
  def start do
    Process.register self(), :keep_alive

    receive do
      :kill ->
        "Multi-paxos is great!"
    end
  end
end
