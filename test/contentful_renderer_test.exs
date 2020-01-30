defmodule ContentfulRendererTest do
  use ExUnit.Case
  doctest ContentfulRenderer

  test "rendering a document with paragraphs and marks" do
    document = load_document("paragraphs.json")

    assert ContentfulRenderer.render(document, []) ==
             "<p>This is a first blog post to <u><b>act</b></u> as a test.</p><p>Here's some new <u>stuff</u>.</p>"
  end

  test "rendering a document with headings" do
    document = load_document("headings.json")

    assert ContentfulRenderer.render(document, []) ==
             "<h1>Heading 1</h1><h2>Heading 2</h2><h3>Heading 3</h3><h4>Heading 4</h4><h5>Heading 5</h5><h6>Heading 6</h6>"
  end

  test "rendering a document with lists" do
    document = load_document("lists.json")

    assert ContentfulRenderer.render(document, []) ==
             "<p>Unordered list:</p><ul><li><p>Paragraph list item</p></li><li><p>Inline <b>bold</b>, <u>underline</u>, <i>italic</i></p></li></ul><p>Ordered list:</p><ol><li><p>Paragraph list item</p></li><li><p>Inline <b>bold</b>, <u>underline</u>, <i>italic</i></p></li></ol><p></p>"
  end

  test "rendering a document with embeds" do
    document = load_document("embeds.json")

    assert ContentfulRenderer.render(document, []) ==
             "<p>Here's an <a href=\"http://www.example.org\">inline link</a>, and here's an embedded link:.</p>"
  end

  test "rendering a document with embeds with a custom embedded-entry-inline renderer" do
    document = load_document("embeds.json")

    renderer = fn node, _options ->
      text = node[:data][:target][:sys][:id]
      "<span>id: #{text}</span>"
    end

    assert ContentfulRenderer.render(document, embedded_entry_inline_node_renderer: renderer) ==
             "<p>Here's an <a href=\"http://www.example.org\">inline link</a>, and here's an embedded link:<span>id: 36uwIhhxw8rnyhsvr7IkZs</span>.</p>"
  end

  test "rendering a document with embeds with a custom embedded-entry-block renderer" do
    document = load_document("embeds.json")

    renderer = fn node, _options ->
      text = node[:data][:target][:sys][:id]
      "<div>id: #{text}</div>"
    end

    assert ContentfulRenderer.render(document, embedded_entry_block_node_renderer: renderer) ==
             "<p>Here's an <a href=\"http://www.example.org\">inline link</a>, and here's an embedded link:.</p><div>id: 36uwIhhxw8rnyhsvr7IkZs</div>"
  end

  defp load_document(filename) do
    json =
      Path.join([__DIR__, "documents", filename])
      |> File.read!()
      |> Poison.decode!(keys: :atoms)

    json
    |> Map.fetch!(:items)
    |> Enum.at(0)
    |> Map.fetch!(:fields)
    |> Map.fetch!(:body)
  end
end