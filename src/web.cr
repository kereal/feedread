require "kemal"
require "./models"

before_all do |env|
  env.response.headers.add("Access-Control-Allow-Origin", "*")
  env.response.headers.add("Access-Control-Allow-Methods", "HEAD,GET,PUT,POST,DELETE,OPTIONS")
  env.response.content_type = "application/json"
end

limit = offset = nil

before_get do |env|
  limit = env.params.query["limit"]?.presence.try(&.to_i?) || 10
  offset = env.params.query["offset"]?.presence.try(&.to_i?) || 0
end

options "/*" do |env|
  halt env, status_code: 200
end

get "/records" do |env|
  Record.with_sources_as_json(
    false, limit, offset
  )
end

delete "/records/:id" do |env|
  record = Record.find env.params.url["id"]
  if record && record.update!(deleted: true)
    record.to_json
  else
    env.response.status_code = 400
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
      end
    else
      source.update(ignore_categories: new)
    end
    Record.where(source_id: source.id, category: new, favorite: false).each do |record|
      record.destroy!
    end
  else
    # { error: "source not found" }.to_json
    env.response.status_code = 400
  end
end

post "/records/:id/favorite" do |env|
  record = Record.find env.params.url["id"]
  if record && record.update(favorite: true)
    record.to_json
  else
    env.response.status_code = 400
  end
end

get "/records/favorites" do |env|
  Record.with_sources_as_json(
    true, limit, offset
  )
end

get "/records/source/:id" do |env|
  id = env.params.url["id"]?.presence.try(&.to_i?) || next
  Record.with_sources_as_json(
    false, limit, offset, "AND records.source_id = #{id}"
  )
end

delete "/sources/:id" do |env|
  source = Source.find env.params.url["id"]
  if source && source.destroy
    source.to_json
  else
    env.response.status_code = 400
  end
end

# create
post "/sources" do |env|
  Source.create!(env.params.body.to_h).to_json
end

# update
post "/sources/:id" do |env|
  source = Source.find env.params.url["id"]
  if source && source.update(env.params.body.to_h)
    source.to_json
  else
    env.response.status_code = 400
  end
end


Kemal.run
