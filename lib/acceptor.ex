# Matthew Brookes (mb5715) and Abhinav Mishra (am8315)

defmodule Acceptor do
  def start config do
    next config, {-1, -1}, MapSet.new
  end

  defp next config, ballot_number, accepted do
    receive do
      { :p1a, leader, b } ->
        b_n = max b, ballot_number
        send leader, { :p1b, self(), b_n, accepted }
        next config, b_n, accepted

      { :p2a, commander, { b, _, _ } = pvalue } ->
        accepted =
          case b == ballot_number do
            true -> MapSet.put(accepted, pvalue)
            false -> accepted
          end
        send commander, { :p2b, self(), ballot_number }
        next config, ballot_number, accepted
    end
  end
end
