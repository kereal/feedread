require "http/client"
require "xml"
require "option_parser"
require "log"
require "./models"


def grab_feed(source)

  xml = HTTP::Client.get(source.url).body.gsub("content:encoded>","contentEncoded>")
  doc = source.type == "rss" ? XML.parse(xml) : XML.parse_html(xml)
  total_count = exists_count = created_count = ignored_count = 0

  doc.xpath_nodes(source.type == "rss" ? "//item" : "//entry").each do |item|
    total_count += 1

    uid = item.xpath_node(source.type == "rss" ? "guid" : "id").try(&.content)

    if Record.where(uid: uid).exists?
      exists_count += 1
      next
    end

    category = source.type == "rss" ?
        item.xpath_node("category").try(&.content) :
        item.xpath_node("category").try(&.["label"])
    category = nil if category.try(&.strip) == ""

    if source.ignored_categories_list.includes?(category)
      ignored_count += 1
      next
    end

    content = item.xpath_node("description").try(&.content) ||
              item.xpath_node("contentEncoded").try(&.content)

    pubdate = nil
    ["%a, %d %b %Y %T %z", "%a, %d %b %Y %T %^Z", "%Y-%m-%dT%T%z"].each do |format|
      begin
        pubdate = Time.parse(item.xpath_nodes(source.type == "rss" ? "pubDate" : "updated").first.content, format, Time::Location::UTC)
        break
      rescue; end
    end

    Record.create!(
      source_id: source.id,
      uid: uid,
      title: HTML.unescape(item.xpath_nodes("title").first.content),
      category: category,
      link: source.type == "rss" ? item.xpath_nodes("link").first.content : item.xpath_nodes("link").first["href"],
      content: content ? HTML.unescape(content).gsub(/(<\/?[^>]*>|\t|\n|Читать далее)/, "*").strip : nil,
      pubdate: pubdate,
      favorite: false,
      deleted: false
    )

    Log.info { "Record created: #{uid}" }
    created_count += 1

  end

  Log.info { "Total: #{total_count} / exists: #{exists_count} / ignored: #{ignored_count} / created: #{created_count}" }
  source.update!(last_parsed_at: Time.utc)

end


def grab(source_id)
  begin
    source = Source.find! source_id
    Log.info { "Grabbing source #{source.title}" }
    if ["atom", "rss"].includes?(source.type)
      grab_feed source
    else raise "Unknown source type: #{source.type}"; end
  rescue err
    Log.error { err }
  end
end


option_parser = OptionParser.parse do |parser|

  parser.banner = "Feed grabber"

  parser.on "-a", "Grab all sources" do
    Log.info { "Grabbing all sources" }
    Source.where(active: true).order(id: :asc).each {|source| grab source.id }
    exit
  end

  parser.on "-s ID", "Grab source with ID" do |source_id|
    Log.info { "Grabbing source id=#{source_id}" }
    grab(source_id)
    exit
  end

  parser.on "-l", "List sources" do
    Source.all.each do |source|
      puts "[#{source.id}] #{source.title}, url: #{source.url}"
      puts "type: #{source.type}, active: #{source.active}, last_parsed_at: #{source.last_parsed_at}"
      puts "-------------------------------------------------------------------"
    end
    exit
  end

  parser.on "-p DAYS", "Prune old records" do |days_number|
    deleted_count = 0
    Record.where(deleted: true)
          .where(:created_at, :lt, Time.local - (days_number.try(&.to_i?) || 100).days)
          .each do |r|
            r.destroy!
            deleted_count += 1
    end
    Service.all.to_a
    Log.info { "Prune old records, deleted: #{deleted_count}" }
    exit
  end

  parser.on "--debug", "Debug mode" do
    Log.setup do |c|
      backend = Log::IOBackend.new
      c.bind("*", :debug, backend)
      c.bind("db.*", :info, backend)
    end
  end

  parser.on "-h", "--help", "Show help" do
    puts parser
    exit
  end

  parser.unknown_args do |args|
    args.map{|arg| puts "Unknown argument: #{arg}" }
    exit
  end

  parser.missing_option do |arg|
    puts "Argument #{arg} require option"
    exit
  end

  # puts parser

end
