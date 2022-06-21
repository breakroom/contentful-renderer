defmodule ContentfulRendererTest do
  use ExUnit.Case
  doctest ContentfulRenderer

  import Phoenix.HTML.Tag, only: [content_tag: 2]

  test "rendering a document with paragraphs and marks" do
    document = load_document("paragraphs.json")

    assert ContentfulRenderer.render_document(document, []) ==
             "<p>This is a first blog post to <u><b>act</b></u> as a test.</p><p>Here&#39;s some new <u>stuff</u>.</p>"
  end

  test "rendering a document with headings" do
    document = load_document("headings.json")

    assert ContentfulRenderer.render_document(document, []) ==
             "<h1>Heading 1</h1><h2>Heading 2</h2><h3>Heading 3</h3><h4>Heading 4</h4><h5>Heading 5</h5><h6>Heading 6</h6>"
  end

  test "rendering a document with headings and heading_ids enabled" do
    document = load_document("headings_with_marks.json")

    assert ContentfulRenderer.render_document(document, heading_ids: true) ==
             "<h1 id=\"heading-1-including-containing-bold-italic-underline-and-bold-and-italic-combined\">Heading 1 (including &amp;) containing <b>bold</b>, <i>italic</i>, <u>underline</u> and <i><b>bold and italic combined</b></i></h1><h2 id=\"heading-2\">Heading 2</h2><h3 id=\"heading-3\">Heading 3</h3><p></p>"
  end

  test "rendering a document with lists" do
    document = load_document("lists.json")

    assert ContentfulRenderer.render_document(document, []) ==
             "<p>Unordered list:</p><ul><li><p>Paragraph list item</p></li><li><p>Inline <b>bold</b>, <u>underline</u>, <i>italic</i></p></li></ul><p>Ordered list:</p><ol><li><p>Paragraph list item</p></li><li><p>Inline <b>bold</b>, <u>underline</u>, <i>italic</i></p></li></ol><p></p>"
  end

  test "rendering a document with embeds" do
    document = load_document("embeds.json")

    assert ContentfulRenderer.render_document(document, []) ==
             "<p>Here&#39;s an <a href=\"http://www.example.org\">inline link</a>, and here&#39;s an embedded link:.</p>"
  end

  test "rendering a document with embeds with a custom embedded-entry-inline renderer" do
    document = load_document("embeds.json")

    renderer = fn node, _options ->
      text = node["data"]["target"]["sys"]["id"]

      content_tag(:span) do
        "id: #{text}"
      end
    end

    assert ContentfulRenderer.render_document(document,
             embedded_entry_inline_node_renderer: renderer
           ) ==
             "<p>Here&#39;s an <a href=\"http://www.example.org\">inline link</a>, and here&#39;s an embedded link:<span>id: 36uwIhhxw8rnyhsvr7IkZs</span>.</p>"
  end

  test "rendering a document with embeds with a custom embedded-entry-block renderer" do
    document = load_document("embeds.json")

    renderer = fn node, _options ->
      text = node["data"]["target"]["sys"]["id"]

      content_tag(:div) do
        "id: #{text}"
      end
    end

    assert ContentfulRenderer.render_document(document,
             embedded_entry_block_node_renderer: renderer
           ) ==
             "<p>Here&#39;s an <a href=\"http://www.example.org\">inline link</a>, and here&#39;s an embedded link:.</p><div>id: 36uwIhhxw8rnyhsvr7IkZs</div>"
  end

  test "rendering a document with special characters" do
    document = load_document("special_characters.json")

    assert ContentfulRenderer.render_document(document, []) ==
             "<p>Some &amp; (ampersands), 😬 (emoji), ☃ (unicode snowman) and &lt;script&gt;alert(&quot;alert&quot;);&lt;/script&gt; (script tags)</p>"
  end

  test "rendering a document with an asset-hyperlink node" do
    document = load_document("asset_hyperlink.json")

    assert ContentfulRenderer.render_document(document, []) == "<p>Blah this is a test</p>"
  end

  test "rendering a document with an entry-hyperlink node" do
    document = load_document("entry_hyperlink.json")

    assert ContentfulRenderer.render_document(document, []) == "<p>This is a test link</p>"
  end

  test "rendering a document with an table node" do
    document = load_document("table.json")

    assert ContentfulRenderer.render_document(document, []) ==
             "<table><tr><th><p>Column 1</p></th><th><p>Column 2</p></th></tr><tr><td><p>Foo</p></td><td><p>Bar</p></td></tr><tr><td><p>Baz</p></td><td><p>Wossit</p></td></tr></table><p></p>"
  end

  defp load_document(filename) do
    json =
      Path.join([__DIR__, "documents", filename])
      |> File.read!()
      |> Poison.decode!()

    json
    |> Map.fetch!("items")
    |> Enum.at(0)
    |> Map.fetch!("fields")
    |> Map.fetch!("body")
  end
end
