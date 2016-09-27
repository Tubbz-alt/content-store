require 'rails_helper'
include ActiveSupport::Testing::TimeHelpers

describe "Fetching linked items", type: :request do
  describe "GET /incoming-links/:base_path_without_root" do
    it "returns the items linked to an item" do
      item = create(:content_item, :with_content_id, document_type: "travel_advice")
      id_1 = create(:content_item, content_id: 'ID-1', base_path: '/a', title: "A", links: { "parent" => [item.content_id] })
      id_1.reload
      id_2 = create(:content_item, content_id: 'ID-2', base_path: '/b', title: "B", links: { "parent" => [item.content_id] })
      id_2.reload

      get "/incoming-links#{item.base_path}?types[]=parent&types[]=topics"

      expect(parsed_response["parent"]).to eql([
        {
          "content_id" => "ID-1",
          "title" => "A",
          "base_path" => "/a",
          "description" => nil,
          "api_url" => "http://www.example.com/content/a",
          "web_url" => "https://www.test.gov.uk/a",
          "locale" => "en",
          "public_updated_at" => id_1.public_updated_at.as_json,
          "schema_name" => "answer",
          "document_type" => "answer",
          "links" => { "parent" => [item.content_id] },
        },
        {
          "content_id" => "ID-2",
          "title" => "B",
          "base_path" => "/b",
          "description" => nil,
          "api_url" => "http://www.example.com/content/b",
          "web_url" => "https://www.test.gov.uk/b",
          "locale" => "en",
          "public_updated_at" => id_2.public_updated_at.as_json,
          "schema_name" => "answer",
          "document_type" => "answer",
          "links" => { "parent" => [item.content_id] },
        },
      ])

      expect(parsed_response["topics"]).to eql([])
    end
  end

  describe "GET /api/incoming-links/:base_path_without_root" do
    it "is the public version of the endpoint" do
      item = create(:content_item, :with_content_id)
      create(:content_item, content_id: 'ID-1', base_path: '/a', title: "A", links: { "parent" => [item.content_id] })

      get "/api/incoming-links#{item.base_path}?types[]=parent&types[]=topics"

      expect(response).to be_successful
    end
  end

  def parsed_response
    JSON.parse(response.body)
  end
end
