namespace :data_hygiene do
  namespace :content_ids do
    desc "Generate a report of content items with duplicate content_ids"
    task full_report: [:environment] do
      DataHygiene::DuplicateReport.new.full
    end

    desc "Generate a report of content_id duplicates among items with an EN locale"
    task en_locale: [:environment] do
      DataHygiene::DuplicateReport.new.scoped_to(locale: "en")
    end
  end
end
