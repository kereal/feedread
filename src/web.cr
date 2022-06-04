require "kemal"
require "./models"

before_all do |env|
  env.response.headers.add("Access-Control-Allow-Origin", "*")
  env.response.headers.add("Access-Control-Allow-Methods", "HEAD,GET,PUT,POST,DELETE,OPTIONS")
  env.response.content_type = "application/json"
end

options "/*" do |env|
  halt env, status_code: 200
end

get "/records" do |env|
  Record.with_sources_as_json(
    false,
    env.params.query["limit"]?.presence.try(&.to_i?)
  )
end

delete "/records/:id" do |env|
  record = Record.find env.params.url["id"]
  if record && record.update!(deleted: true)
    record.to_json
  end
end

get "/sources" do |env|
  Source.all.to_json
end

post "/sources/:id/ignore_category" do |env|
  new = env.params.body["category"]?.presence.try(&.as(String)) || next
  source = Source.find env.params.url["id"]
  if source
    if source.ignored_categories_list != [""]
      if !source.ignored_categories_list.includes?(new)
        source.update(ignore_categories: source.ignored_categories_list.push(new).join("||"))
        puts "Ban added: #{new}"
      end
    else
      source.update(ignore_categories: new)
      puts "Created ignored_categories_list"
    end
    Record.where(source_id: source.id, category: new, favorite: false).each do |record|
      puts "Destroyed: #{record.title} / #{record.category}" if record.destroy!
    end
  else
    { error: "source not found" }.to_json
  end
end

post "/records/:id/favorite" do |env|
  record = Record.find env.params.url["id"]
  if record && record.update(favorite: true)
    record.to_json
  end
end

get "/records/favorites" do |env|
  Record.with_sources_as_json(
    true,
    env.params.query["limit"]?.presence.try(&.to_i?)
  )
end


Kemal.run
