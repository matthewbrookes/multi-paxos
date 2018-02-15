# Matthew Brookes (mb5715) and Abhinav Mishra (am8315)

defmodule Replica do

  def start config, db, monitor do
    receive do
      { :bind, leaders } ->
        next config, db, monitor, leaders
    end

  end # start

  defp next config, db, monitor, leaders do
    next config, db, monitor, leaders
  end # next

end # Replica
