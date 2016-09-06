defmodule UserInfo do
  defstruct waiting_timeout: 0, status: :waiting, timer: nil
end

defmodule MfaMockup.RoomChannel do
  use MfaMockup.Web, :channel

  def startsending(socket) do
    HTTPoison.get! "http://10.132.1.104:9401/2factor_auth/ocm/%2B237699275868/42"
    {:ok, timer} = :timer.send_interval(1000, :waiting)
    socket |> assign(:user_info, %UserInfo{timer: timer, waiting_timeout: 0})
  end

  def join(topic, msg, socket) do
    IO.puts """
    -------------- JOIN ROOM CHANNEL -----------------
    topic :
    #{inspect topic}
    **************************************************
    msg :
    #{inspect msg}
    **************************************************
    socket :
    #{inspect socket}
    ==================================================
    """
    :pg2.create :mfa_callback
    :pg2.join :mfa_callback, self
    {:ok, startsending(socket)}
  end

  def leave(reason, socket) do
    IO.puts "User left channel: #{inspect reason}"
    :pg2.leave :mfa_callback, self
    {:ok, socket}
  end

  def handle_in("rooms:lobby", msg, s) do
    IO.puts """
    -------------- HANDLE IN ROOMS:LOBBY ROOM CHANNEL -----------------
    msg :
    #{inspect msg}
    **************************************************
    struct :
    #{inspect s}
    ==================================================
    """
    {:noreply, s}
  end
  def handle_in(cmd, msg, s) do
    IO.puts """
    -------------- HANDLE IN ROOM CHANNEL -----------------
    cmd :
    #{inspect cmd}
    **************************************************
    msg :
    #{inspect msg}
    **************************************************
    struct :
    #{inspect s}
    ==================================================
    """
    # {:ok, timer} = :timer.send_interval(1000, :waiting)
    # s = s |> assign(:user_info, %UserInfo{timer: timer, waiting_timeout: 0})

    {:noreply, startsending(s)}
  end

  def handle_info(:waiting, s) do
    IO.puts "Sending a ping... : #{inspect s.assigns.user_info}"

    if s.assigns.user_info.waiting_timeout >= 30 do
      :timer.cancel s.assigns.user_info.timer
      ui = %{s.assigns.user_info | timer: nil}
      s = s |> assign(:user_info, ui)
      send self, :timeout
      {:noreply, s}
    else
      ui = s.assigns.user_info
      ui = %{ui | waiting_timeout: ui.waiting_timeout + 1}
      s = s |> assign(:user_info, ui)
      push s, "waiting", %{user: "SYSTEM", body: "ping", value: ui.waiting_timeout}
      {:noreply, s}
    end
  end
  def handle_info(:accepted, s) do
    :timer.cancel s.assigns.user_info.timer
    ui = %{s.assigns.user_info | timer: nil}
    s = s |> assign(:user_info, ui)
    push s, "accepted", %{}
    {:noreply, s}
  end
  def handle_info(:rejected, s) do
    :timer.cancel s.assigns.user_info.timer
    ui = %{s.assigns.user_info | timer: nil}
    s = s |> assign(:user_info, ui)
    push s, "rejected", %{}
    {:noreply, s}
  end
  def handle_info(:timeout, s) do
    push s, "timeout", %{}
    {:noreply, s}
  end
  # def handle_info({:callback, params}, s) do
  #   {:noreply, s}
  # end
  def handle_info(p, s) do
    IO.puts """
    -------------- HANDLE INFO ROOM CHANNEL -------------
    p :
    #{inspect p}
    **************************************************
    struct :
    #{inspect s}
    ==================================================
    """
    {:noreply, s}
  end
end
