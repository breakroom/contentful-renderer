defmodule ContentfulRenderer do
  require Logger

  @doc """
  Renders a Contentful node, in a tree of `Map`s and `List`s, to
  HTML.

  It accepts custom renderers for each node type, passed in as
  `Keyword`s in the `options` parameter. To override the `heading-1` renderer, pass in:

  ```
  heading_1_node_renderer: fn node, options ->
    "<h1>\#{ContentfulRenderer.render_content(node, options)\}</h1>"
  end
  ```

  By default it renders `embedded-entry-inline` and
  `embedded-entry-block` as blank, because these usually require
  local knowledge about the content model to render usefully. When
  this happens, `Logger` will warn.

  ## Examples

  ```
  iex> %{
  ...>   "content" => [
  ...>     %{
  ...>       "content" => [
  ...>         %{
  ...>           "data" => %{},
  ...>           "marks" => [],
  ...>           "nodeType" => "text",
  ...>           "value" => "Paragraph 1"
  ...>         }
  ...>       ],
  ...>       "data" => %{},
  ...>       "nodeType" => "paragraph"
  ...>     },
  ...>     %{
  ...>       "content" => [
  ...>         %{
  ...>           "data" => %{},
  ...>           "marks" => [],
  ...>           "nodeType" => "text",
  ...>           "value" => "Paragraph 2"
  ...>         }
  ...>       ],
  ...>       "data" => %{},
  ...>       "nodeType" => "paragraph"
  ...>     }
  ...>   ],
  ...>   "data" => %{},
  ...>   "nodeType" => "document"
  ...> }
  ...> |> ContentfulRenderer.render()
  "<p>Paragraph 1</p><p>Paragraph 2</p>"
  ```
  """
  def render(node, options \\ [])

  def render(content, options) when is_list(content) do
    content
    |> Enum.map(&render(&1, options))
    |> Enum.join("")
  end

  def render(%{"nodeType" => nodeType} = node, options) do
    renderer =
      case nodeType do
        "document" ->
          &render_content/2

        "paragraph" ->
          Keyword.get(options, :paragraph_node_renderer, &default_paragraph_node_renderer/2)

        "text" ->
          Keyword.get(options, :text_node_renderer, &default_text_node_renderer/2)

        "heading-1" ->
          Keyword.get(options, :heading_1_node_renderer, &default_heading_1_node_renderer/2)

        "heading-2" ->
          Keyword.get(options, :heading_2_node_renderer, &default_heading_2_node_renderer/2)

        "heading-3" ->
          Keyword.get(options, :heading_3_node_renderer, &default_heading_3_node_renderer/2)

        "heading-4" ->
          Keyword.get(options, :heading_4_node_renderer, &default_heading_4_node_renderer/2)

        "heading-5" ->
          Keyword.get(options, :heading_5_node_renderer, &default_heading_5_node_renderer/2)

        "heading-6" ->
          Keyword.get(options, :heading_6_node_renderer, &default_heading_6_node_renderer/2)

        "unordered-list" ->
          Keyword.get(
            options,
            :unordered_list_node_renderer,
            &default_unordered_list_node_renderer/2
          )

        "ordered-list" ->
          Keyword.get(
            options,
            :ordered_list_node_renderer,
            &default_ordered_list_node_renderer/2
          )

        "list-item" ->
          Keyword.get(
            options,
            :list_item_node_renderer,
            &default_list_item_node_renderer/2
          )

        "hyperlink" ->
          Keyword.get(options, :hyperlink_node_renderer, &default_hyperlink_node_renderer/2)

        "embedded-entry-inline" ->
          Keyword.get(
            options,
            :embedded_entry_inline_node_renderer,
            &default_embedded_entry_inline_node_renderer/2
          )

        "embedded-entry-block" ->
          Keyword.get(
            options,
            :embedded_entry_block_node_renderer,
            &default_embedded_entry_block_node_renderer/2
          )
      end

    renderer.(node, options)
  end

  @doc """
  Renders the content inside a node. Useful if you've overriden a
  renderer, but you don't want to replement how the renderer walks
  into the content.
  """
  def render_content(node, options \\ []) do
    node
    |> Map.get("content", [])
    |> render(options)
  end

  defp default_paragraph_node_renderer(node, options) do
    "<p>#{render_content(node, options)}</p>"
  end

  defp default_heading_1_node_renderer(node, options) do
    "<h1>#{render_content(node, options)}</h1>"
  end

  defp default_heading_2_node_renderer(node, options) do
    "<h2>#{render_content(node, options)}</h2>"
  end

  defp default_heading_3_node_renderer(node, options) do
    "<h3>#{render_content(node, options)}</h3>"
  end

  defp default_heading_4_node_renderer(node, options) do
    "<h4>#{render_content(node, options)}</h4>"
  end

  defp default_heading_5_node_renderer(node, options) do
    "<h5>#{render_content(node, options)}</h5>"
  end

  defp default_heading_6_node_renderer(node, options) do
    "<h6>#{render_content(node, options)}</h6>"
  end

  defp default_unordered_list_node_renderer(node, options) do
    "<ul>#{render_content(node, options)}</ul>"
  end

  defp default_ordered_list_node_renderer(node, options) do
    "<ol>#{render_content(node, options)}</ol>"
  end

  defp default_list_item_node_renderer(node, options) do
    "<li>#{render_content(node, options)}</li>"
  end

  defp default_hyperlink_node_renderer(node, options) do
    uri = node["data"]["uri"]
    "<a href=\"#{uri}\">#{render_content(node, options)}</a>"
  end

  defp default_embedded_entry_inline_node_renderer(_node, _options) do
    Logger.warn("Using null renderer for embedded-entry-inline node")

    ""
  end

  defp default_embedded_entry_block_node_renderer(_node, _options) do
    Logger.warn("Using null renderer for embedded-entry-block node")

    ""
  end

  defp default_text_node_renderer(node, options) do
    text = Map.fetch!(node, "value")

    node
    |> Map.get("marks", [])
    |> render_marks(text, options)
  end

  defp default_bold_mark_renderer(text, _options) do
    "<b>#{text}</b>"
  end

  defp default_underline_mark_renderer(text, _options) do
    "<u>#{text}</u>"
  end

  defp default_code_mark_renderer(text, _options) do
    "<code>#{text}</code>"
  end

  defp default_italic_mark_renderer(text, _options) do
    "<i>#{text}</i>"
  end

  defp render_marks(marks, text, options) do
    marks
    |> Enum.reduce(
      text,
      fn mark, text_acc ->
        type = Map.fetch!(mark, "type")

        case type do
          "bold" ->
            default_bold_mark_renderer(text_acc, options)

          "underline" ->
            default_underline_mark_renderer(text_acc, options)

          "code" ->
            default_code_mark_renderer(text_acc, options)

          "italic" ->
            default_italic_mark_renderer(text_acc, options)
        end
      end
    )
  end
end
