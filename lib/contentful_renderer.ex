defmodule ContentfulRenderer do
  require Logger

  import Phoenix.HTML, only: [safe_to_string: 1, html_escape: 1, raw: 1]
  import Phoenix.HTML.Tag, only: [content_tag: 2, content_tag: 3]
  import ContentfulRenderer.SafeHelpers

  @doc """
  Renders a Contentful node, in a tree of `Map`s and `List`s, to
  HTML.

  It accepts custom renderers for each node type, passed in as
  `Keyword`s in the `options` parameter. To override the `heading-1`
  renderer, pass in:

  ```
  heading_1_node_renderer: fn node, options ->
    Phoenix.HTML.Tag.content_tag(:h1) do
      ContentfulRenderer.render_content(node, options)
    end
  end
  ```

  Renderers need to return a `Phoenix.HTML.Safe.t()` or they're treated as an
  unsafe string and HTML escaped.

  By default it renders `embedded-entry-inline` and `embedded-entry-block` as
  blank, because these usually require local knowledge about the content
  model to render usefully. When this happens, `Logger` will warn.

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
  ...> |> ContentfulRenderer.render_document()
  "<p>Paragraph 1</p><p>Paragraph 2</p>"
  ```
  """
  def render_document(document, options \\ []) do
    render_content(document, options)
    |> safe_to_string()
  end

  @doc """
  Behaves the same as `render_document/2`, but returns a
  `Phoenix.HTML.Safe.t` tuple.
  """
  def render(content, options) when is_list(content) do
    content
    |> Enum.map(&render(&1, options))
    |> join_safes()
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

        "blockquote" ->
          Keyword.get(options, :blockquote_node_renderer, &default_blockquote_node_renderer/2)

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

        "embedded-asset-block" ->
          Keyword.get(
            options,
            :embedded_asset_block_node_renderer,
            &default_embedded_asset_block_node_renderer/2
          )

        "hr" ->
          Keyword.get(options, :hr_node_renderer, &default_hr_node_renderer/2)

        "entry-hyperlink" ->
          Keyword.get(
            options,
            :entry_hyperlink_node_renderer,
            &default_entry_hyperlink_node_renderer/2
          )

        "asset-hyperlink" ->
          Keyword.get(
            options,
            :asset_hyperlink_node_renderer,
            &default_asset_hyperlink_node_renderer/2
          )

        unknown_node ->
          Logger.warn("Skipping rendering unexpected node type: #{unknown_node}")

          fn _, _ -> nil end
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
    content_tag(:p) do
      render_content(node, options)
    end
  end

  defp default_heading_1_node_renderer(node, options) do
    default_heading_node_renderer(node, options, :h1)
  end

  defp default_heading_2_node_renderer(node, options) do
    default_heading_node_renderer(node, options, :h2)
  end

  defp default_heading_3_node_renderer(node, options) do
    default_heading_node_renderer(node, options, :h3)
  end

  defp default_heading_4_node_renderer(node, options) do
    default_heading_node_renderer(node, options, :h4)
  end

  defp default_heading_5_node_renderer(node, options) do
    default_heading_node_renderer(node, options, :h5)
  end

  defp default_heading_6_node_renderer(node, options) do
    default_heading_node_renderer(node, options, :h6)
  end

  defp default_heading_node_renderer(node, options, tag) do
    attrs = heading_attributes(node, options)

    content_tag tag, attrs do
      render_content(node, options)
    end
  end

  defp default_blockquote_node_renderer(node, options) do
    content_tag(:blockquote) do
      render_content(node, options)
    end
  end

  defp default_hr_node_renderer(_node, _options) do
    content_tag(:hr) do
      nil
    end
  end

  defp default_unordered_list_node_renderer(node, options) do
    content_tag(:ul) do
      render_content(node, options)
    end
  end

  defp default_ordered_list_node_renderer(node, options) do
    content_tag(:ol) do
      render_content(node, options)
    end
  end

  defp default_list_item_node_renderer(node, options) do
    content_tag(:li) do
      render_content(node, options)
    end
  end

  defp default_hyperlink_node_renderer(node, options) do
    uri = node["data"]["uri"]

    content_tag(:a, href: uri) do
      render_content(node, options)
    end
  end

  defp default_embedded_entry_inline_node_renderer(_node, _options) do
    Logger.warn("Using null renderer for embedded-entry-inline node")

    ""
  end

  defp default_embedded_entry_block_node_renderer(_node, _options) do
    Logger.warn("Using null renderer for embedded-entry-block node")

    ""
  end

  defp default_embedded_asset_block_node_renderer(_node, _options) do
    Logger.warn("Using null renderer for embedded-asset-block node")

    ""
  end

  defp default_asset_hyperlink_node_renderer(node, options) do
    Logger.warn("Using plain text renderer for asset-hyperlink node")

    render_content(node, options)
  end

  defp default_entry_hyperlink_node_renderer(node, options) do
    Logger.warn("Using plain text renderer for entry-hyperlink node")

    render_content(node, options)
  end

  defp default_text_node_renderer(node, options) do
    render_marks = Keyword.get(options, :render_marks, true)
    escape_html = Keyword.get(options, :escape_html, true)

    text =
      Map.fetch!(node, "value")
      |> maybe_escape_html(escape_html)

    maybe_render_marks(node, text, options, render_marks)
  end

  defp default_bold_mark_renderer(text, _options) do
    content_tag(:b, text)
  end

  defp default_underline_mark_renderer(text, _options) do
    content_tag(:u, text)
  end

  defp default_code_mark_renderer(text, _options) do
    content_tag(:code, text)
  end

  defp default_italic_mark_renderer(text, _options) do
    content_tag(:i, text)
  end

  defp maybe_render_marks(_node, text, _options, false) do
    text
  end

  defp maybe_render_marks(node, text, options, true) do
    node
    |> Map.get("marks", [])
    |> render_marks(text, options)
  end

  defp maybe_escape_html(text, true) do
    text |> html_escape()
  end

  defp maybe_escape_html(text, false) do
    text |> raw
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

  defp heading_attributes(node, options) do
    case Keyword.get(options, :heading_ids, false) do
      true ->
        options =
          options
          |> Keyword.put(:render_marks, false)
          |> Keyword.put(:escape_html, false)

        id =
          node
          |> render_content(options)
          |> safe_to_string()
          |> Slug.slugify()

        [id: id]

      false ->
        []
    end
  end
end
