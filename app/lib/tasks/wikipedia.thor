class Wikipedia < Thor
  desc "update_wikidata_id_from_wikipedia",
       "update wikidata_id from wikipedia url"

  def update_wikidata_ids_from_wikipedia_urls
    require './config/environment'
    Individual.where("wikipedia is not null and wikipedia != '' and wikidata_id is null").find_each do |i|
      i.update_wikidata_id_and_twitter
      i.save
      puts "#{i.id}; #{i.name}"
    end
  end

  desc "update_bio_from_wikidata",
       "update_bio_from_wikidata"
  def update_bio_from_wikidata
    require './config/environment'
    Individual.where("bio is null and wikidata_id is not null").find_each do |individual|
      wikidata = Wikidata::Item.find_by_id(individual.wikidata_id)
      new_bio = wikidata.description.try(:capitalize)
      if new_bio
        puts "Updating #{individual.name}'s bio: #{new_bio}; id: #{individual.id}; to_param: #{individual.to_param}"
        individual.update_attributes(bio: new_bio)
      end
    end
  end

  desc "brexit_import",
       "import Brexit supporters/detractors from wikipedia"
  # Examples:
  # thor wikipedia:brexit_import https://s3-eu-west-1.amazonaws.com/agreelist/tmp/remain.txt remain
  # thor wikipedia:brexit_import https://s3-eu-west-1.amazonaws.com/agreelist/tmp/leave.txt leave

  def brexit_import(url, remain_or_leave)
    require './config/environment'
    puts "update wikidata ids first"
    update_wikidata_ids_from_wikipedia_urls

    count = 0
    statement = Statement.find_by_hashed_id("sblrlc9vgxp7")
    extent = (remain_or_leave == "remain" ? 0 : 100)
    text = Net::HTTP.get(URI(url))
    #IO.foreach("../remain.txt") do |line|
    text.split("\n").each do |line|
      wikipedia_line = WikipediaLine.new(line: line, default_source: "https://en.wikipedia.org/wiki/Endorsements_in_the_United_Kingdom_European_Union_membership_referendum,_2016")
      wikipedia_line.read
      if wikipedia_line.wikidata_id
        count = count + 1
        puts count
        puts "@#{wikipedia_line.twitter}" if wikipedia_line.twitter
        puts wikipedia_line.wikidata_id
        puts wikipedia_line.wikipedia_url
        puts wikipedia_line.source
        puts wikipedia_line.bio if wikipedia_line.bio
        individual = Individual.where(wikidata_id: wikipedia_line.wikidata_id).first
        unless individual
          individual = Individual.create(name: wikipedia_line.label, wikidata_id: wikipedia_line.wikidata_id, wikipedia: wikipedia_line.wikipedia_url, twitter: wikipedia_line.twitter, bio: wikipedia_line.bio)
        end
        unless Agreement.exists?(statement: statement, individual: individual)
          agreement = Agreement.create(statement: statement, individual: individual, extent: extent, url: wikipedia_line.source)
          puts "agreement_id: #{agreement.id}"
        end
        puts ""
      end
    end
  end

  desc "hillary_trump_import",
       "hillary and trump import"
  def hillary_trump_import
    require './config/environment'
    hillary_or_trump_import("https://s3-eu-west-1.amazonaws.com/agreelist/tmp/clinton.txt", "clinton", "https://en.wikipedia.org/wiki/List_of_Hillary_Clinton_presidential_campaign_endorsements,_2016")
    hillary_or_trump_import("https://s3-eu-west-1.amazonaws.com/agreelist/tmp/trump.txt", "trump", "https://en.wikipedia.org/wiki/List_of_Donald_Trump_presidential_campaign_endorsements,_2016")
  end

  # Examples:
  # thor wikipedia:hillary_or_trump_import https://s3-eu-west-1.amazonaws.com/agreelist/tmp/clinton.txt clinton
  # thor wikipedia:hillary_or_trump_import https://s3-eu-west-1.amazonaws.com/agreelist/tmp/trump.txt trump
  def hillary_or_trump_import(url, remain_or_leave, default_source)
    puts "update wikidata ids first"
    update_wikidata_ids_from_wikipedia_urls

    count = 0
    statement = Statement.find_by_hashed_id("ped4besqdzdd")
    extent = (remain_or_leave == "trump" ? 0 : 100)
    text = Net::HTTP.get(URI(url))
    #IO.foreach("../remain.txt") do |line|
    text.split("\n").each do |line|
      wikipedia_line = WikipediaLine.new(line: line, default_source: default_source)
      wikipedia_line.read
      if wikipedia_line.wikidata_id
        count = count + 1
        puts count
        puts "@#{wikipedia_line.twitter}" if wikipedia_line.twitter
        puts wikipedia_line.wikidata_id
        puts wikipedia_line.wikipedia_url
        puts wikipedia_line.source
        puts wikipedia_line.bio if wikipedia_line.bio
        individual = Individual.where(wikidata_id: wikipedia_line.wikidata_id).first
        unless individual
          individual = Individual.create(name: wikipedia_line.label, wikidata_id: wikipedia_line.wikidata_id, wikipedia: wikipedia_line.wikipedia_url, twitter: wikipedia_line.twitter, bio: wikipedia_line.bio)
        end
        unless Agreement.exists?(statement: statement, individual: individual)
          agreement = Agreement.create(statement: statement, individual: individual, extent: extent, url: wikipedia_line.source)
          puts "agreement_id: #{agreement.id}"
        end
        puts ""
      end
      sleep 1
    end
  end
end