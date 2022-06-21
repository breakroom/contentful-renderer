defmodule ContentfulRenderer.SafeHelpers do
  @moduledoc false
  import Phoenix.HTML, only: [html_escape: 1, raw: 1]

  def join_safes(list) when is_list(list) do
    list
    |> Enum.map(&make_safe/1)
    |> flatten_safes()
  end

  defp make_safe({:safe, _str} = safe) do
    safe
  end

  defp make_safe(str) do
    html_escape(str)
  end

  defp flatten_safes(safes) do
    safes
    |> Enum.reduce(raw([]), fn {:safe, str}, {:safe, acc} ->
      raw(acc ++ [str])
    end)
  end
end
