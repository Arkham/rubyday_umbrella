defmodule Rubyday.RoomChannel do
  use Rubyday.Web, :channel
  alias Rubyday.VoteMap

  def join("rooms:lobby", message, socket) do
    Process.flag(:trap_exit, true)
    send(self, {:after_join, message})
    {:ok, socket}
  end

  def join("rooms:" <> _something_else, _msg, _socket) do
    {:error, %{reason: "Can't do this"}}
  end

  def handle_info({:after_join, _msg}, socket) do
    push socket, "updated:count", get_vote_counts()
    {:noreply, socket}
  end

  def terminate(_reason, _socket) do
    :ok
  end

  def handle_in("new:vote", vote, socket) do
    do_vote(vote)
    counts = get_vote_counts()
    broadcast! socket, "updated:count", counts
    update_lcd(counts)

    {:reply, {:ok, %{vote: vote}}, socket}
  end

  defp do_vote(vote) do
    VoteMap.vote(vote["choice"], vote["user_id"])
  end

  defp get_vote_counts do
    ["ruby", "elixir"]
    |> Enum.map(fn choice ->
      {choice, VoteMap.count(choice)}
    end)
    |> Enum.into(%{})
  end

  defp update_lcd(counts) do
    LcdDisplay.write(0, 0, "Ruby:   #{counts["ruby"]}")
    LcdDisplay.write(0, 1, "Elixir: #{counts["elixir"]}")
  end
end
