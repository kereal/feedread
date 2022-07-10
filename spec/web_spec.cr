require "./spec_helper"

Spec.before_suite {
  source = Source.create!(type: "rss", title: "test123", url: "http://", active: true)
  16.times do |i|
    Record.create!(source_id: source.id, uid: "uid #{i}", title: "title #{i}", link: "http://", favorite: false, deleted: false)
    Record.create!(source_id: source.id, uid: "uid #{i}", title: "fav #{i}", link: "http://", favorite: true, deleted: false)
  end
}

describe "Web::Kemal::App" do

  it "Responsing to /records" do
    get "/"
    response.status_message.should eq "OK"
  end

  it "Access Control header is set" do
    get "/records"
    response.headers.to_h.keys.should contain("Access-Control-Allow-Origin")
    response.headers["Access-Control-Allow-Origin"].should eq("*")
  end

  it "Records limit is working" do
    get "/records?limit=2"
    JSON.parse(response.body).size.should eq 2
    get "/records/favorites/?limit=2"
    JSON.parse(response.body).size.should eq 2
  end

  it "Records offset is working" do
    get "/records?offset=12"
    JSON.parse(response.body).size.should eq 4
    get "/records/favorites/?offset=12"
    JSON.parse(response.body).size.should eq 4
  end

  it "Records limit and offset are working together" do
    get "/records?limit=1&offset=13"
    JSON.parse(response.body).as_a.map(&.["id"]).first.should eq 5  # id=5
    get "/records/favorites/?limit=1&offset=13"
    JSON.parse(response.body).as_a.map(&.["id"]).first.should eq 6  # id=6
  end

  it "Records limit default is set" do
    get "/records"
    JSON.parse(response.body).size.should eq 10
    get "/records?limit="
    JSON.parse(response.body).size.should eq 10
    get "/records?limit=aaa3s88"
    JSON.parse(response.body).size.should eq 10
    get "/records/favorites"
    JSON.parse(response.body).size.should eq 10
    get "/records/favorites?limit="
    JSON.parse(response.body).size.should eq 10
    get "/records/favorites?limit=aaa3s88"
    JSON.parse(response.body).size.should eq 10
  end

  it "Records offset default is set" do
    all_ids = [31, 29, 27, 25, 23, 21, 19, 17, 15, 13]
    get "/records"
    JSON.parse(response.body).as_a.map(&.["id"]).should eq all_ids
    get "/records?limit="
    JSON.parse(response.body).as_a.map(&.["id"]).should eq all_ids
    get "/records?limit=aaa3s88"
    JSON.parse(response.body).as_a.map(&.["id"]).should eq all_ids
    all_ids = [32, 30, 28, 26, 24, 22, 20, 18, 16, 14]
    get "/records/favorites"
    JSON.parse(response.body).as_a.map(&.["id"]).should eq all_ids
    get "/records/favorites?limit="
    JSON.parse(response.body).as_a.map(&.["id"]).should eq all_ids
    get "/records/favorites?limit=aaa3s88"
    JSON.parse(response.body).as_a.map(&.["id"]).should eq all_ids
  end

  # get /records/favorites
  it "Records is favorite" do
    get "/records/favorites?limit=2"
    JSON.parse(response.body).as_a.map(&.["favorite"]).should eq [true, true]
  end

  # post /sources/:id/ignore_category
  it "Category is ignored" do
    source = Source.create!(type: "rss", title: "123", url: "http://", active: true)
    headers = HTTP::Headers{"Content-Type" => "application/x-www-form-urlencoded"}
    path = "/sources/#{source.try(&.id)}/ignore_category"
    post path, body: "category=TEZD", headers: headers
    Source.find(source.id).try(&.ignore_categories).should eq "TEZD"
    # repeat
    post path, body: "category=TEZD", headers: headers
    Source.find(source.id).try(&.ignore_categories).should eq "TEZD"
    # second
    post path, body: "category=SECondCATeg", headers: headers
    Source.find(source.id).try(&.ignore_categories).should eq "TEZD||SECondCATeg"
    # non exists
    post "/sources/9999/ignore_category", body: "category=aaa", headers: headers
    response.status.code.should eq 400
  end

  # delete /records/:id
  it "Record is deleted and response is correct" do
    r = Record.create!(source_id: 1.to_i64, uid: "uid", title: "title", link: "http://", favorite: false, deleted: false)
    delete "/records/#{r.id}"
    JSON.parse(response.body).as_h["deleted"].should eq true
    Record.find!(r.id).try(&.deleted).should eq true
    # non exists
    delete "/records/99999"
    response.status.code.should eq 400
  end

  # post /records/:id/favorite
  it "Record is added to favorites and response is correct" do
    r = Record.create!(source_id: 1.to_i64, uid: "uid", title: "title", link: "http://", favorite: false, deleted: false)
    post "/records/#{r.id}/favorite"
    JSON.parse(response.body).as_h["favorite"].should eq true
    Record.find!(r.id).try(&.favorite).should eq true
    # non exists
    post "/records/99999/favorite"
    response.status.code.should eq 400
  end

  # get /records/source/1
  it "Records by source filtering is working" do
    source = Source.create!(type: "rss", title: "by source", url: "http://", active: true)
    Record.create!(source_id: source.id, uid: "u0", title: "t0", link: "http://", favorite: false, deleted: false)
    Record.create!(source_id: source.id, uid: "u1", title: "t1", link: "http://", favorite: false, deleted: false)
    Record.create!(source_id: source.id, uid: "u2", title: "t2", link: "http://", favorite: false, deleted: false)
    Record.create!(source_id: source.id, uid: "u3", title: "t3", link: "http://", favorite: true, deleted: false)
    Record.create!(source_id: source.id, uid: "u4", title: "t4", link: "http://", favorite: false, deleted: true)
    get "/records/source/#{source.id}"
    JSON.parse(response.body).as_a.map(&.["title"]).should eq ["t2", "t1", "t0"]
    get "/records/source/#{source.id}?limit="
    JSON.parse(response.body).as_a.map(&.["title"]).should eq ["t2", "t1", "t0"]
    get "/records/source/asdad"
    response.body.should eq ""
    get "/records/source/999"
    response.body.should eq "[]"
    get "/records/source/#{source.id}?limit=2"
    JSON.parse(response.body).as_a.map(&.["title"]).should eq ["t2", "t1"]
  end

  # delete /sources/:id
  it "Source deletes" do
     source = Source.create!(type: "rss", title: "delete src", url: "http://", active: true)
     delete "/sources/#{source.id}"
     JSON.parse(response.body).as_h["id"].should eq source.id
     Source.find(source.id).should eq nil
     # non exists
     delete "/sources/99999"
     response.status.code.should eq 400
     # delete associated records
     source = Source.create!(type: "rss", title: "delete src + rec", url: "http://", active: true)
     Record.create!(source_id: source.id, uid: "u0", title: "t0", link: "http://", favorite: false, deleted: false)
     Record.create!(source_id: source.id, uid: "u1", title: "t1", link: "http://", favorite: true, deleted: true)
     delete "/sources/#{source.id}"
     Record.where(source_id: source.id).select.size.should eq 0
  end

  # post /sources
  it "Source creates" do
    headers = HTTP::Headers{"Content-Type" => "application/x-www-form-urlencoded"}
    post "/sources", body: "type=rss&title=testcreate&url=http://ya.ru&active=true", headers: headers
    id = JSON.parse(response.body).as_h["id"].to_s
    Source.find(id).try(&.title).should eq "testcreate"
  end

  # post /sources/:id
  it "Source updates" do
    source = Source.create!(type: "rss", title: "upd test", url: "http://", active: true)
    headers = HTTP::Headers{"Content-Type" => "application/x-www-form-urlencoded"}
    data = "type=atom&title=upd&url=https://a.ru&active=false"
    post "/sources/#{source.id}", body: data, headers: headers
    JSON.parse(response.body).as_h["id"].should eq source.id
    Source.find(source.id).try(&.to_h.values.compact[0..-3]).should eq JSON.parse(response.body).as_h.values[0..-3]
    # non exists
    post "/sources/99999", body: data, headers: headers
    response.status.code.should eq 400
  end

end


Spec.after_suite {
  Record.clear
  Source.clear
}
