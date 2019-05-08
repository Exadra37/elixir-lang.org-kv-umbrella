defmodule KVServer do
  require Logger

  def accept(port) do

    # The options below mean:
    #
    # 1. `:binary` - receives data as binaries (instead of lists)
    # 2. `packet: :line` - receives data line by line
    # 3. `active: false` - blocks on `:gen_tcp.rec/2` until data is available
    # 4. `reuseaddr: true` - allows us to reuse the address if the listener crashes
    {:ok, socket} =
      :gen_tcp.listen(port, [:binary, packet: :line, active: false, reuseaddr: true])

    Logger.info("Accepting connections on port #{port}")

    loop_acceptor(socket)

  end

  defp loop_acceptor(socket) do
    {:ok, client} = :gen_tcp.accept(socket)
    {:ok, pid} = Task.Supervisor.start_child(KVServer.TaskSupervisor, fn -> serve(client) end)

    # By default a child process is linked to its parent, the one starting
    # it, thus if it crashes it will bring down the parent process to.
    #
    # Here the `loop_acceptor` is the parent process that accepts clients
    # `client` and starts a Task `pid` to serve each client request, thus if a
    # Task crashes, it will bring down the `loop_acceptor`, thus all clients,
    # and we don't want this to happen.
    #
    # TODO: I'm not sure if a fully understand this "controlling_processs" thing.
    :ok = :gen_tcp.controlling_process(client, pid)

    loop_acceptor(socket)
  end

  defp serve(socket) do
    msg =
      case read_line(socket) do
        {:ok, data} ->
          case KVServer.Command.parse(data) do
            {:ok, command} ->
              KVServer.Command.run(command)
            {:error, _} = err ->
              err
          end
        {:error, _} = err ->
          err
      end

    write_line(socket, msg)
    serve(socket)
  end

  defp read_line(socket) do
    :gen_tcp.recv(socket, 0)
  end

  defp write_line(socket, {:ok, text}) do
    :gen_tcp.send(socket, text)
  end

  defp write_line(socket, {:error, :unknown_command}) do
    # Known error write to the client
    :gen_tcp.send(socket, "UNKNOWN COMMAND\r\n")
  end

  defp write_line(socket, {:error, :closed}) do
    # The connection was closed, exit politely
    exit(:shutdown)
  end

  defp write_line(socket, {:error, error}) do
    # Unknown error; write to the client and exit
    :gen_tcp.send(socket, "ERROR\r\n")
    exit(error)
  end
end
