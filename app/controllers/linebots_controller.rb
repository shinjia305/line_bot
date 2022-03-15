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
            per06to12 = doc.elements[xpath + 'info[2]/rainfallchance/period[2]'].text
            per12to18 = doc.elements[xpath + 'info[2]/rainfallchance/period[3]'].text
            per18to24 = doc.elements[xpath + 'info[2]/rainfallchance/period[4]'].text
            if per06to12.to_i >= min_per || per12to18.to_i >= min_per || per18to24.to_i >= min_per
              push =
                "明日は雨が降るかもしれません。\n06:00~12:00　#{per06to12}％\n12:00〜18:00　#{per12to18}％\n18:00〜24:00　#{per18to24}％"
            else
              push =
                "明日は晴れそうです。\n06:00~12:00　#{per06to12}％\n12:00〜18:00　#{per12to18}％\n18:00〜24:00　#{per18to24}％"
            end
          when /.*(明後日|あさって).*/
            per06to12 = doc.elements[xpath + 'info[3]/rainfallchance/period[2]'].text
            per12to18 = doc.elements[xpath + 'info[3]/rainfallchance/period[3]'].text
            per18to24 = doc.elements[xpath + 'info[3]/rainfallchance/period[4]'].text
            if per06to12.to_i >= min_per || per12to18.to_i >= min_per || per18to24.to_i >= min_per
              push =
                "明後日は雨が降るかもしれません。"
            else
              push =
                "明後日は晴れそうです。"
            end
          else
            per06to12 = doc.elements[xpath + 'info/rainfallchance/period[2]'].text
            per12to18 = doc.elements[xpath + 'info/rainfallchance/period[3]'].text
            per18to24 = doc.elements[xpath + 'info/rainfallchance/period[4]'].text
            if per06to12.to_i >= min_per || per12to18.to_i >= min_per || per18to24.to_i >= min_per
              push = "今日の降水確率は次の通りです。\n06:00~12:00　#{per06to12}％\n12:00〜18:00　#{per12to18}％\n18:00〜24:00　#{per18to24}％"
            else
              push = "今日は晴れそうです。\n06:00~12:00　#{per06to12}％\n12:00〜18:00　#{per12to18}％\n18:00〜24:00　#{per18to24}％"
            end
          end
        else
          push = "テキストで入力してください。\n　ex.「今日」「明日」「明後日」などです。"
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
