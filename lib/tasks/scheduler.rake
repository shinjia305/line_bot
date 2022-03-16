desc "This task is called by the Heroku scheduler add-on"
task :update_feed => :environment do
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

  weather_detail = doc.elements[xpath + 'info/weather_detail'].text
  from06to12 = doc.elements[xpath + 'info/rainfallchance/period[2]'].text
  from12to18 = doc.elements[xpath + 'info/rainfallchance/period[3]'].text
  from18to24 = doc.elements[xpath + 'info/rainfallchance/period[4]'].text

  chance_of_rain_of_today = [from06to12, from12to18, from18to24]
  maximum_chance_of_rain_of_today = chance_of_rain_of_today.max

  case maximum_chance_of_rain_of_today
  when maximum_chance_of_rain_of_today > '40' then
    word = "今日は雲が多く、雨が降るかもしれません。折り畳み傘を持っていってください。"
  when maximum_chance_of_rain_of_today > '70' then
    word = "今日は雨が降るので、傘を持って行ってください"
  end

  push = "今日の天気:\n#{weather_detail}\n降水確率:\n06:00~12:00　#{from06to12}％\n12:00〜18:00　#{from12to18}％\n18:00〜24:00　#{from18to24}％\n#{word}"
  user_ids = User.all.pluck(:line_id)
  message = {
    type: 'text',
    text: push
  }
  response = client.multicast(user_ids, message)

  "OK"
end


# task :update_feed_of_tomorrow_info => :environment do
#   require 'line/bot'
#   require 'open-uri'
#   require 'kconv'
#   require 'rexml/document'

#   client ||= Line::Bot::Client.new { |config|
#     config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
#     config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
#   }

#   url  = "https://www.drk7.jp/weather/xml/44.xml"
#   xml  = URI.open( url ).read.toutf8
#   doc = REXML::Document.new(xml)
#   xpath = 'weatherforecast/pref/area[2]/'

#   per06to12 = doc.elements[xpath + 'info[2]/rainfallchance/period[2]'].text
#   per12to18 = doc.elements[xpath + 'info[2]/rainfallchance/period[3]'].text
#   per18to24 = doc.elements[xpath + 'info[2]/rainfallchance/period[4]'].text

#   min_per = 30
#   if per06to12.to_i >= min_per || per12to18.to_i >= min_per || per18to24.to_i >= min_per
#     word1 = "明日は雨が降るかもしれません。"

#     mid_per = 70
#     if per06to12.to_i >= mid_per || per12to18.to_i >= mid_per || per18to24.to_i >= mid_per
#       word2 = "明日は雨が降りそうです。傘を忘れずに持って行ってください。"
#     else
#       word3 = "明日は雨が降るかもしれません。折りたたみ傘を持って行ってください。"
#     end

#     push = "#{word1}\n#{word3}\n降水確率は以下の通りです。\n06:00~12:00　#{per06to12}％\n12:00〜18:00　#{per12to18}％\n18:00〜24:00　#{per18to24}％\n#{word2}"
#     user_ids = User.all.pluck(:line_id)
#     message = {
#       type: 'text',
#       text: push
#     }
#     response = client.multicast(user_ids, message)
#   end
#   "OK"
# end

