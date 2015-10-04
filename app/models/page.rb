class Page

  class NotFound < StandardError; end

  YAML_BOUNDARY = "---".freeze

  attr_reader :name, :path

  def self.all(basepath = Rails.root.join('pages'))
    basepath.
      children.
      select { |path| path.fnmatch('*.md') }.
      map { |path| new(path.basename('.md'), basepath) }.
      reject { |page| page.empty? || page.hidden? }
  end

  def self.home
    new 'home'
  end

  def initialize(name, basepath = Rails.root.join('pages'))
    @name = name.to_s
    @path = basepath.join("#{name}.md")
    raise NotFound, "unable to find page with name #{name.inspect}" unless @path.exist?
  end
  # TODO: Catch expected errors and wrap in something that controller can catch

  def to_param
    name
  end

  def title
    metadata.fetch(:title, name.titleize)
  end

  # TODO: Move to presenter/view class
  def to_html
    HeadingLinker.new(markdown_doc).link_headings!
    CodeHighlighter.new(markdown_doc).highlight!
    markdown_doc.to_html
  end

  def tags
    metadata.fetch(:tags, [])
  end

  def mtime
    path.mtime
  end

  def hidden?
    metadata.fetch(:hidden, false)
  end

  def empty?
    path.size.zero? || metadata.empty?
  end

private

  def metadata
    @metadata ||= if content.lines.first.rstrip == YAML_BOUNDARY
                    YAML.load(content).symbolize_keys
                  else
                    {}
                  end
  end

  def content
    @content ||= path.read
  end

  def markdown
    @markdown ||= begin
                    if content.lines.first.rstrip == YAML_BOUNDARY
                      _, _, markdown = content.split(YAML_BOUNDARY, 3)
                    else
                      markdown = content
                    end

                    RDiscount.new(markdown, :smart, :autolink)
                  end
  end

  def markdown_doc
    @markdown_doc ||= Nokogiri::HTML.fragment(markdown.to_html)
  end

end

