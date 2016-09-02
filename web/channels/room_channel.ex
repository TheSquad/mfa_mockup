defmodule MfaMockup.RoomChannel do
  use MfaMockup.Web, :channel

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
    # :timer.send_interval(5000, :ping)
    {:ok, socket}
  end

  def handle_in("rooms:lobby", msg, socket) do
    IO.puts """
    -------------- HANDLE IN ROOMS:LOBBY ROOM CHANNEL -----------------
    msg :
    #{inspect msg}
    **************************************************
    socket :
    #{inspect socket}
    ==================================================
    """
    {:noreply, socket}
  end
  def handle_in(cmd, msg, socket) do
    IO.puts """
    -------------- HANDLE IN ROOM CHANNEL -----------------
    cmd :
    #{inspect cmd}
    **************************************************
    msg :
    #{inspect msg}
    **************************************************
    socket :
    #{inspect socket}
    ==================================================
    """
    {:noreply, socket}
  end

  def handle_info(:ping, socket) do
    push socket, "ping", %{user: "SYSTEM", body: "ping"}
    IO.puts "Sending a ping..."
    {:noreply, socket}
  end
  def handle_info(:accepted, socket) do
    push socket, "accepted", %{}
    {:noreply, socket}
  end
  def handle_info(:rejected, socket) do
    push socket, "rejected", %{}
    {:noreply, socket}
  end
  def handle_info(:timeout, socket) do
    push socket, "timeout", %{}
    {:noreply, socket}
  end
  def handle_info(p, socket) do
    IO.puts """
    -------------- HANDLE INFO ROOM CHANNEL -------------
    p :
    #{inspect p}
    **************************************************
    socket :
    #{inspect socket}
    ==================================================
    """
    {:noreply, socket}
  end
end
