require "granite"
require "granite/adapter/sqlite"

dbname = ENV.fetch("KEMAL_ENV", nil)=="test" ? "feedread_test" : "feedread"

Granite::Connections << Granite::Adapter::Sqlite.new(name: "sqlite3", url: "sqlite3://#{dbname}.sqlite3")

class Record < Granite::Base
  connection sqlite3
  table records
  belongs_to source : Source
  column id : Int64, primary: true
  column source_id : Int64
  column uid : String
  column title : String
  column category : String?
  column link : String
  column content : String?
  column pubdate : Time?
  column favorite : Bool
  column deleted : Bool
  column created_at : Time?
  validate_not_blank :title
  validate_not_blank :uid

  def self.per_page
    10
  end

  def self.with_sources_as_json(favorites = false, limit = self.per_page)
    limit ||= self.per_page
    records = Record.all("JOIN sources source ON records.source_id = source.id
      WHERE records.deleted = ? AND records.favorite = ?
      ORDER BY records.id DESC LIMIT ?", [false, favorites, limit])
    JSON.build do |json|
      json.array do
        records.each do |record|
          json.object do
            json.field "id", record.id
            json.field "title", record.title
            json.field "category", record.category
            json.field "link", record.link
            json.field "content", record.content
            json.field "pubdate", record.pubdate
            json.field "favorite", record.favorite
            json.field "source_title", record.source.title
            json.field "source_id", record.source.id
          end
        end
      end
    end
  end

end


class Source < Granite::Base
  connection sqlite3
  table sources
  has_many :records, class_name: Record, foreign_key: :source_id
  column id : Int64, primary: true
  column type : String
  column title : String
  column ignore_categories : String?
  column url : String
  column active : Bool
  column last_parsed_at : Time?
  column created_at : Time?
  validate_not_blank :title
  validate_not_blank :type
  validate_not_blank :url
  def ignored_categories_list
    cats = self.ignore_categories || ""
    cats.split("||")
  end
end
