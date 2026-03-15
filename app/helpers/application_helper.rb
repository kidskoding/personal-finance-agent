module ApplicationHelper
  def render_markdown(text)
    return "".html_safe if text.blank?

    renderer = Redcarpet::Render::HTML.new(hard_wrap: true, safe_links_only: true)
    markdown = Redcarpet::Markdown.new(
      renderer,
      autolink: true,
      tables: true,
      fenced_code_blocks: true,
      strikethrough: true
    )

    html = markdown.render(text)
    sanitize(html, tags: %w[p br strong em ul ol li h1 h2 h3 h4 h5 h6 blockquote code pre table thead tbody tr th td a hr s del], attributes: %w[href])
  end
end
