class LinebotsController < ApplicationController
  require 'line/bot'
  require 'open-uri'
  require 'kconv'
  require 'rexml/document'

  def callback
    body = request.body.read
    signature = request.env['HTTP_X_LINE_SIGNATURE']
    unless client.validate_signature(body, signature)
      return head :bad_request
    end
    events = client.parse_events_from(body)
    events.each { |event|
      case event
      when Line::Bot::Event::Message
        case event.type
        when Line::Bot::Event::MessageType::Text
          input = event.message['text']
          url  = "https://www.drk7.jp/weather/xml/44.xml"
          xml  = URI.open( url ).read.toutf8
          doc = REXML::Document.new(xml)
          xpath = 'weatherforecast/pref/area[2]/'
          min_per = 30
          case input
          when /.*(明日|あした).*/
            weather = doc.elements[xpath + 'info[2]/weather'].text
            weather_detail = doc.elements[xpath + 'info[2]/weather_detail'].text
            from06to12 = doc.elements[xpath + 'info[2]/rainfallchance/period[2]'].text
            from12to18 = doc.elements[xpath + 'info[2]/rainfallchance/period[3]'].text
            from18to24 = doc.elements[xpath + 'info[2]/rainfallchance/period[4]'].text

            chance_of_rain = [from06to12, from12to18, from18to24]
            maximum_chance_of_rain = chance_of_rain.max

            if maximum_chance_of_rain.to_i >= 80
              word = "今のところ雨が降りそうです。傘を持って行った方が良いかもしれません。"
            elsif maximum_chance_of_rain.to_i >= 50
              word = "今のところ場所によっては曇ったり、雨が降ったりしそうです。折り畳み傘があると良いかもしれません。"
            else
              word = "今のところ傘の必要はなさそうです。"
            end
            push = "明日の天気予報をお知らせします。\n\n明日の天気:\n#{weather}\n\n明日の天気詳細:\n#{weather_detail}\n\n明日の降水確率:\n06:00〜12:00　#{from06to12}％\n12:00〜18:00　#{from12to18}％\n18:00〜24:00　#{from18to24}％\n\n#{word}"
          when /.*(明後日|あさって).*/
            weather = doc.elements[xpath + 'info[3]/weather'].text
            from06to12 = doc.elements[xpath + 'info[3]/rainfallchance/period[2]'].text
            from12to18 = doc.elements[xpath + 'info[3]/rainfallchance/period[3]'].text
            from18to24 = doc.elements[xpath + 'info[3]/rainfallchance/period[4]'].text

            chance_of_rain = [from06to12, from12to18, from18to24]
            maximum_chance_of_rain = chance_of_rain.max
            push = "明後日の天気予報をお知らせします。\n\n明後日の天気:\n#{weather}\n\n明後日の降水確率:\n06:00〜12:00　#{from06to12}％\n12:00〜18:00　#{from12to18}％\n18:00〜24:00　#{from18to24}％"
          else
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
          end
        else
          push = "テキストで入力してください。\n例えば「今日」「明日」「明後日」などを入力できます。"
        end
        message = {
          type: 'text',
          text: push
        }
        client.reply_message(event['replyToken'], message)
      when Line::Bot::Event::Follow
        line_id = event['source']['userId']
        User.create(line_id: line_id)
      when Line::Bot::Event::Unfollow
        line_id = event['source']['userId']
        User.find_by(line_id: line_id).destroy
      end
    }
    head :ok
  end

  private

  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
    }
  end
end
