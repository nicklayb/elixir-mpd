defmodule Mpd.Idle do
  defmacro __using__(_) do
    quote do
      alias Mpd.Handler

      def idle() do
        Handler.call_idle(self())
      end

      @impl true
      def handle_info({:tcp, port, msg}, state) when is_list(msg) do
        handle_info({:tcp, port, to_string(msg)}, state)
      end

      def handle_info({:tcp, _, "OK MPD" <> _}, state) do
        {:noreply, state}
      end

      def handle_info({:tcp, port, "changed: " <> out}, state) do
        :gen_tcp.close(port)
        [idle | _] = String.split(out, "\n")
        idle()
        {:noreply, handle_change(idle, state)}
      end

      def handle_info({:tcp_closed, _}, state) do
        idle()
        {:noreply, state}
      end

      def handle_change(_, state), do: state

      defoverridable(handle_change: 2)
    end
  end
end
