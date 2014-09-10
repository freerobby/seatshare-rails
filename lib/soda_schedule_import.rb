class SodaScheduleImport

  attr_accessor :soda_client, :messages, :events_list

  def initialize
    self.soda_client = SodaXmlTeam::Client.new(ENV['SODA_USERNAME'], ENV['SODA_PASSWORD'])
    self.messages = []
    self.events_list = []
  end

  def run(options={})
    entity = Entity.find_by_import_key(options[:team_id])
    if entity.blank?
      self.messages << "Could not find an entity that matched #{options[:team_id]}"
      return
    end

    # Get listing for desired league
    listing = self.soda_client.get_listing({
      sandbox: ENV['SODA_ENVIRONMENT'] != 'production',
      league_id: options[:team_id].split("-")[0],
      team_id: options[:team_id],
      type: 'schedule-single-team',
      start_datetime: DateTime.parse(options[:start_datetime]),
      end_datetime: DateTime.parse(options[:end_datetime])
    })

    # See if there were any documents at all
    if listing.css('item link').length === 0
      self.messages << "No events were available for #{entity.entity_name}."
      return
    end

    # Grab the latest URI available
    latest = URI.parse(listing.css('item link').first)
    document_id = CGI.parse(latest.query)['doc-ids'].first

    # Check to see if you already have this document ID in S3
    if AWS::S3::S3Object.exists? "soda/#{document_id}", ENV['SEATSHARE_S3_BUCKET']
      if !options[:force_update]
        self.messages << "The latest schedule for #{entity.entity_name} (#{document_id}) has already been processed."
        return
      end
    end

    # Retrieve the document (this counts as using an API credit)
    schedule_document = self.soda_client.get_document({
      sandbox: ENV['SODA_ENVIRONMENT'] != 'production',
      document_id: document_id
    })

    # Cache the document to prevent re-downloads
    File.open File.join(Rails.root, 'tmp', 'soda', document_id), 'w' do |file|
      file.write schedule_document.to_s
    end

    # Store this file in S3
    File.open File.join(Rails.root, 'tmp', 'soda', document_id), 'rb' do |file|
      AWS::S3::S3Object.store "soda/#{document_id}", open(file), ENV['SEATSHARE_S3_BUCKET']
    end

    # Parse the schedule and create the events
    schedule = SodaXmlTeam::Schedule.parse_schedule(schedule_document)
    for row in schedule

      # Map in entity_id for import
      row[:entity_id] = entity.id

      # Skip the away games
      if row[:home_team_id] != options[:team_id]
        next
      end

      # Create or update the row
      self.events_list << Event.import(row)
    end

    # Done with that team
    self.messages << "#{entity.entity_name} schedule imported!"
  end

end