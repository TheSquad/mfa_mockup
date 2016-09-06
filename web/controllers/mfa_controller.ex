defmodule MfaMockup.MfaController do
  use MfaMockup.Web, :controller

  def callback(conn, params) do
    {:ok, "confirm=" <> resp, _} = conn.private[:my_app_body]

    IO.puts "-------------------------------"
    IO.puts "Response is : #{resp}"
    IO.puts ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"

    case :pg2.get_closest_pid(:mfa_callback) do
      {:error, _} ->
        IO.puts "Pid does not exist"
        :ko
      pid ->
        IO.puts "Pid exist: #{inspect pid}"
        case resp do
          "yes" ->
            send pid, :accepted
          "no" ->
            send pid, :rejected
        end
    end
    conn |> send_resp(200, "Ok")
  end
end
