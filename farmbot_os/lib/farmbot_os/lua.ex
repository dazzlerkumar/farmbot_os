defmodule FarmbotOS.Lua do
  @type t() :: tuple()
  @type table() :: [{any, any}]
  alias FarmbotOS.Lua.Ext.{
    Firmware,
    Info
  }

  @doc """
  Evaluates some Lua code. The code should
  return a boolean value.
  """
  def eval_assertion(str) when is_binary(str) do
    init()
    |> eval(str)
    |> case do
      {:ok, [true | _]} ->
        true

      {:ok, [false | _]} ->
        false

      {:ok, [_, reason]} when is_binary(reason) ->
        {:error, reason}

      {:ok, _data} ->
        {:error, "bad return value from expression evaluation"}

      {:error, {:lua_error, _error, _lua}} ->
        {:error, "lua runtime error evaluating expression"}

      {:error, {:badmatch, {:error, [{line, :luerl_parse, parse_error}], _}}} ->
        {:error, "failed to parse expression (line:#{line}): #{IO.iodata_to_binary(parse_error)}"}

      error ->
        error
    end
  end

  @spec init() :: t()
  def init do
    :luerl.init()
    |> set_table([:calibrate], &Firmware.calibrate/2)
    |> set_table([:emergency_lock], &Firmware.emergency_lock/2)
    |> set_table([:emergency_unlock], &Firmware.emergency_unlock/2)
    |> set_table([:find_home], &Firmware.find_home/2)
    |> set_table([:home], &Firmware.home/2)
    |> set_table([:move_absolute], &Firmware.move_absolute/2)
    |> set_table([:get_position], &Firmware.get_position/2)
    |> set_table([:get_pins], &Firmware.get_pins/2)
    |> set_table([:coordinate], &Firmware.coordinate/2)
    |> set_table([:read_status], &Info.read_status/2)
    |> set_table([:send_message], &Info.send_message/2)
    |> set_table([:version], &Info.version/2)
  end

  @spec set_table(t(), Path.t(), any()) :: t()
  def set_table(lua, path, value) do
    :luerl.set_table(path, value, lua)
  end

  @spec eval(t(), String.t()) :: {:ok, any()} | {:error, any()}
  def eval(lua, hook) when is_binary(hook) do
    :luerl.eval(hook, lua)
  end

  def unquote(:do)(lua, hook) when is_binary(hook) do
    :luerl.do(hook, lua)
  catch
    :error, {:error, reason} ->
      {{:error, reason}, lua}

    error, reason ->
      {{:error, {error, reason}}, lua}
  end
end
