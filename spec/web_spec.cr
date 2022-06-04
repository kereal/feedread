require "./spec_helper"

Spec.before_suite {
  source = Source.create!(type: "rss", title: "test123", url: "http://", active: true)
  16.times do |i|
    Record.create!(source_id: source.id, uid: "uid #{i}", title: "title #{i}", link: "http://", favorite: false, deleted: false)
    Record.create!(source_id: source.id, uid: "uid #{i}", title: "fav #{i}", link: "http://", favorite: true, deleted: false)
  end
  p! Record.all.size
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

  it "Records is favorite" do
    get "/records/favorites?limit=2"
    JSON.parse(response.body).as_a.map{|r|r["favorite"]}.should eq [true, true]
  end

  it "Category is ignored" do
    source = Source.first!
    headers = HTTP::Headers{"Content-Type" => "application/x-www-form-urlencoded"}
    path = "/sources/#{source.try(&.id)}/ignore_category"
    #post path, body: "category=TEZD", headers: headers
    #JSON.parse(response.body)["error"].should eq "source not found"
    post path, body: "category=TEZD", headers: headers
    Source.find(source.id).try(&.ignore_categories).should eq "TEZD"
    # repeat
    post path, body: "category=TEZD", headers: headers
    Source.find(source.id).try(&.ignore_categories).should eq "TEZD"
    # second
    post path, body: "category=SECondCATeg", headers: headers
    Source.find(source.id).try(&.ignore_categories).should eq "TEZD||SECondCATeg"
  end

  it "Record is deleted and response is correct" do
    r = Record.create!(source_id: 1.to_i64, uid: "uid", title: "title", link: "http://", favorite: false, deleted: false)
    delete "/records/#{r.id}"
    JSON.parse(response.body).as_h["deleted"].should eq true
    Record.find!(r.id).try(&.deleted).should eq true
  end

  it "Record is added to favorites and response is correct" do
    r = Record.create!(source_id: 1.to_i64, uid: "uid", title: "title", link: "http://", favorite: false, deleted: false)
    post "/records/#{r.id}/favorite"
    JSON.parse(response.body).as_h["favorite"].should eq true
    Record.find!(r.id).try(&.favorite).should eq true
  end


end


Spec.after_suite {
  Record.all.each{ |r| r.destroy }
  Source.all.each{ |s| s.destroy }
  puts ""
  p! Record.all.size
  p! Source.all.size
}
