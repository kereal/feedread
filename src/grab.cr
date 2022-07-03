require "granite"
require "granite/adapter/sqlite"
require "http/client"
require "xml"
require "option_parser"
require "log"
require "./models"

Log.setup(:info, Log::IOBackend.new(File.new("./grab.log", "a+")))


def grab_feed(source)
  xml = HTTP::Client.get(source.url).body
  doc = source.type == "rss" ? XML.parse(xml) : XML.parse_html(xml)
  total_count = 0
  exists_count = 0
  created_count = 0
  ignored_count = 0
  doc.xpath_nodes(source.type == "rss" ? "//item" : "//entry").each do |item|
    total_count += 1
    uid = item.xpath_nodes(source.type == "rss" ? "guid" : "id").first.content
    if !item.xpath_nodes("category").empty?
      category = source.type == "rss" ?
        item.xpath_nodes("category").first.content :
        item.xpath_nodes("category").first["label"]
      category = nil if category.strip.empty?
    else category = nil end
    if Record.where(uid: uid).exists?
      exists_count += 1
      next
    end
    if source.ignored_categories_list.includes?(category)
      ignored_count += 1
      next
    end
    begin
      content = item.xpath_nodes("description").first.content
    rescue
      begin
        content = item.xpath_nodes("content:encoded").first.content
      rescue
        content = nil; end
    end
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
      content: content ? HTML.unescape(content).gsub(/<\/?[^>]*>/, "").gsub(/[\t\n]/, " ").strip : nil,
      pubdate: pubdate,
      favorite: false,
      deleted: false
    )
    puts "   Record created: #{uid}"
    Log.info { "Record created: #{uid}" }
    created_count += 1
  end
  puts "   Total: #{total_count}"
  puts "   Exists: #{exists_count}"
  puts "   Ignored: #{ignored_count}"
  puts "   Created: #{created_count}"
  Log.info { "Total: #{total_count} / exists: #{exists_count} / ignored: #{ignored_count} / created: #{created_count}" }
  source.update!(last_parsed_at: Time.utc)
end


def grab(source_id)
  source = Source.find source_id
  if source
    puts " * Grabbing source #{source.title}"
    Log.info { "Grabbing source #{source.title}" }
    if ["atom", "rss"].includes? source.type
      grab_feed source
    else
      puts "Unknown source type: #{source.type}"
      Log.error { "Unknown source type: #{source.type}" }
    end
  else
    puts "Source with id=#{source_id} not found"
    Log.error { "Source with id=#{source_id} not found" }
  end
end


option_parser = OptionParser.parse do |parser|

  parser.banner = "Feed grabber, use -h to help"

  parser.on "-a", "Grab all sources" do
    Log.info { "Grabbing all sources" }
    Source.where(active: true).order(id: :asc).each do |source|
      begin
        grab(source.id)
      rescue err
        puts " ! #{err}"
        Log.error { err }
      end
    end
    exit
  end

  parser.on "-s ID", "Grab source with ID" do |source_id|
    Log.info { "Grabbing source id=#{source_id}" }
    grab(source_id)
    exit
  end

  parser.on "-l", "List sources" do |source_id|
    Source.all.each do |source|
      puts "[#{source.id}] #{source.title}, url: #{source.url}"
      puts "type: #{source.type}, active: #{source.active}, last_parsed_at: #{source.last_parsed_at}"
      puts "-------------------------------------------------------------------"
    end
    exit
  end

  parser.on "-p", "Prune old records" do |source_id|
    count = 0
    Record.where(deleted: true)
          .where(:created_at, :lt, Time.local - 30.days)
          .each do |r|
            r.destroy!
            count += 1
    end
    Service.all.to_a
    msg = " * Prune old records\n   deleted: #{count}"
    Log.info { msg }
    puts msg
    exit
  end

  parser.on "-h", "--help", "Show help" do
    puts parser
    exit
  end

  parser.unknown_args do
    puts parser
    exit
  end

end
