require 'telegram/bot'
require 'sequel'
require 'redis'
require 'json'
require 'logger'

# Подключение к БД
DB = Sequel.sqlite('bot.db')

# Модели
require_relative 'models/user'
require_relative 'models/post'
require_relative 'models/subscription'

# Сервисы
require_relative 'services/telegram_service'
require_relative 'services/payment_service'
require_relative 'services/scheduler_service'

class TelegramPublisherBot
  def initialize
    @token = ENV['TELEGRAM_BOT_TOKEN']
    @redis = Redis.new
    @logger = Logger.new('bot.log')
    @scheduler = SchedulerService.new
  end

  def run
    Telegram::Bot::Client.run(@token) do |bot|
      bot.listen do |message|
        begin
          handle_message(bot, message)
        rescue => e
          @logger.error "Error: #{e.message}"
          bot.api.send_message(
            chat_id: message.chat.id,
            text: "❌ Произошла ошибка. Попробуйте позже."
          )
        end
      end
    end
  end

  private

  def handle_message(bot, message)
    user = User.find_or_create(telegram_id: message.from.id)
    telegram_service = TelegramService.new(bot, message, user)

    case message
    when Telegram::Bot::Types::Message
      case message.text
      when '/start'
        telegram_service.send_welcome_message
      when '/publish'
        telegram_service.show_publish_options
      when '/subscription'
        telegram_service.show_subscription_info
      when '/help'
        telegram_service.show_help
      else
        handle_text_message(telegram_service, message.text)
      end
    when Telegram::Bot::Types::CallbackQuery
      handle_callback_query(telegram_service, message)
    end
  end

  def handle_text_message(service, text)
    user_state = @redis.get("user_state:#{service.user.telegram_id}")
    
    case user_state
    when 'waiting_for_media'
      service.handle_media_input(text)
    when 'waiting_for_caption'
      service.handle_caption_input(text)
    when 'waiting_for_schedule_time'
      service.handle_schedule_time(text)
    else
      service.send_default_message
    end
  end

  def handle_callback_query(service, callback)
    data = callback.data
    
    case data
    when /^publish_/
      service.handle_publish_callback(data)
    when /^subscription_/
      service.handle_subscription_callback(data)
    when /^payment_/
      service.handle_payment_callback(data)
    when /^plan_/
      service.handle_plan_selection(data)
    end
  end
end
