# Matthew Brookes (mb5715) and Abhinav Mishra (am8315)

defmodule Acceptor do
  def start config do
    next config, -1, MapSet.new
  end

  defp next config, ballot_number, accepted do
    receive do
      { :p1a, leader, b } ->
        if b > ballot_number do
          send leader, { :p1b, self(), b, accepted }
        else
          send leader, { :p1b, self(), ballot_number, accepted }
        end
        next config, ballot_number, accepted

      { :p2a, leader, { b, _, _ } = pvalue } ->
        accepted =
          case b == ballot_number do
            true -> MapSet.put(accepted, pvalue)
            false -> accepted
          end
        send leader, { :p2b, self(), ballot_number }
        next config, ballot_number, accepted
    end
  end
end
