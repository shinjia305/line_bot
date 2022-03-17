desc "update wether info of today"
task :seed_today_info => :environment do
  require 'line/bot'
  require 'open-uri'
  require 'kconv'
  require 'rexml/document'

  client ||= Line::Bot::Client.new { |config|
    config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
    config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
  }

  url = "https://www.drk7.jp/weather/xml/44.xml"
  xml = URI.open( url ).read.toutf8
  doc = REXML::Document.new(xml)
  xpath = 'weatherforecast/pref/area[2]/'

  weather = doc.elements[xpath + 'info/weather'].text
  weather_detail = doc.elements[xpath + 'info/weather_detail'].text
  from06to12 = doc.elements[xpath + 'info/rainfallchance/period[2]'].text
  from12to18 = doc.elements[xpath + 'info/rainfallchance/period[3]'].text
  from18to24 = doc.elements[xpath + 'info/rainfallchance/period[4]'].text

  chance_of_rain = [from06to12, from12to18, from18to24]
  maximum_chance_of_rain = chance_of_rain.max

  if maximum_chance_of_rain.to_i >= 70
    word = "雨が降りそうです。傘を持って行ってください。"
  elsif maximum_chance_of_rain.to_i >= 40
    word = "曇ったり、雨が降ったりしそうです。折り畳み傘を持って行ってください。"
  else
    word = "傘は必要なさそうです。"
  end

  push = "今日の天気をお知らせします。\n\n今日の天気:\n#{weather}\n\n今日の天気詳細:\n#{weather_detail}\n\n今日の降水確率:\n06:00〜12:00　#{from06to12}％\n12:00〜18:00　#{from12to18}％\n18:00〜24:00　#{from18to24}％\n\n#{word}"

  user_ids = User.all.pluck(:line_id)
  message = {
    type: 'text',
    text: push
  }
  response = client.multicast(user_ids, message)

  "OK"
end

desc "update wether info of tomorrow"
task :seed_tomorrow_info => :environment do
  require 'line/bot'
  require 'open-uri'
  require 'kconv'
  require 'rexml/document'

  client ||= Line::Bot::Client.new { |config|
    config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
    config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
  }

  url  = "https://www.drk7.jp/weather/xml/44.xml"
  xml  = URI.open( url ).read.toutf8
  doc = REXML::Document.new(xml)
  xpath = 'weatherforecast/pref/area[2]/'

  weather = doc.elements[xpath + 'info[2]/weather'].text
  weather_detail = doc.elements[xpath + 'info[2]/weather_detail'].text
  from06to12 = doc.elements[xpath + 'info[2]/rainfallchance/period[2]'].text
  from12to18 = doc.elements[xpath + 'info[2]/rainfallchance/period[3]'].text
  from18to24 = doc.elements[xpath + 'info[2]/rainfallchance/period[4]'].text

  chance_of_rain = [from06to12, from12to18, from18to24]
  maximum_chance_of_rain = chance_of_rain.max

  if maximum_chance_of_rain.to_i >= 80
    word = "雨が降りそうです。傘を持って行った方が良いかもしれません。"
  elsif maximum_chance_of_rain.to_i >= 50
    word = "曇ったり、雨が降ったりしそうです。折り畳み傘があると良いかもしれません。"
  else
    word = "今のところ傘の必要はなさそうです。"
  end

  push = "明日の天気予報をお知らせします。\n\n明日の天気:\n#{weather}\n\n明日の天気詳細:\n#{weather_detail}\n\n明日の降水確率:\n06:00〜12:00　#{from06to12}％\n12:00〜18:00　#{from12to18}％\n18:00〜24:00　#{from18to24}％\n\n#{word}"
  puts push
  user_ids = User.all.pluck(:line_id)
  message = {
    type: 'text',
    text: push
  }
  response = client.multicast(user_ids, message)

  "OK"
end

