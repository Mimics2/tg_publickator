class TelegramService
  def initialize(bot, message, user)
    @bot = bot
    @message = message
    @user = user
    @redis = Redis.new
  end

  def send_welcome_message
    text = "🎉 *Добро пожаловать в Публикатор Бот!*\n\n" \
           "🤖 *Ваш личный помощник для публикации контента*\n\n" \
           "✨ *Бесплатный период:* 7 дней\n" \
           "📊 *Тарифы после пробного периода:*\n" \
           "   • 🟢 Light - 2 поста/день\n" \
           "   • 🔵 Standard - 3 поста/день\n" \
           "   • 🟣 Premium - безлимит\n\n" \
           "💎 *Оплата звездами Telegram*\n\n" \
           "Выберите действие:"

    keyboard = [
      [
        { text: "📤 Опубликовать", callback_data: "publish_start" },
        { text: "💳 Подписка", callback_data: "subscription_info" }
      ],
      [
        { text: "📊 Статистика", callback_data: "stats" },
        { text: "ℹ️ Помощь", callback_data: "help" }
      ]
    ]

    send_message(text, keyboard)
  end

  def show_publish_options
    unless @user.can_publish_today?
      send_message("❌ Лимит публикаций исчерпан. Проверьте вашу подписку.")
      return
    end

    text = "📤 *Создание публикации*\n\nВыберите тип контента:"
    
    keyboard = [
      [
        { text: "📷 Фото", callback_data: "publish_photo" },
        { text: "🎥 Видео", callback_data: "publish_video" }
      ],
      [
        { text: "📝 Текст", callback_data: "publish_text" },
        { text: "📊 Опрос", callback_data: "publish_poll" }
      ],
      [
        { text: "⏰ Запланировать", callback_data: "publish_schedule" },
        { text: "🔙 Назад", callback_data: "main_menu" }
      ]
    ]

    send_message(text, keyboard)
  end

  def show_subscription_info
    plan = @user.subscription_plan
    free_days_left = [7 - (Time.now - @user.created_at).to_i / 1.day, 0].max
    
    text = "💳 *Информация о подписке*\n\n"
    
    if @user.free_trial_active?
      text += "🎁 *Бесплатный период:* #{free_days_left} дней осталось\n"
    elsif @user.active_subscription?
      subscription = @user.subscriptions.last
      text += "✅ *Активная подписка:* #{subscription.plan_type.capitalize}\n"
      text += "📅 *Действует до:* #{subscription.expires_at.strftime('%d.%m.%Y')}\n"
    else
      text += "❌ *Подписка не активна*\n"
    end

    text += "\n📊 *Доступные тарифы:*"

    keyboard = [
      [
        { text: "🟢 Light - 2 поста/день", callback_data: "plan_light" },
        { text: "🔵 Standard - 3 поста/день", callback_data: "plan_standard" }
      ],
      [
        { text: "🟣 Premium - безлимит", callback_data: "plan_premium" }
      ],
      [
        { text: "💎 Оплатить звездами", callback_data: "payment_stars" },
        { text: "🔙 Назад", callback_data: "main_menu" }
      ]
    ]

    send_message(text, keyboard)
  end

  def handle_payment_callback(data)
    case data
    when 'payment_stars'
      show_payment_options
    when 'payment_confirm_light'
      process_payment('light', 50) # 50 stars for light plan
    when 'payment_confirm_standard'
      process_payment('standard', 80) # 80 stars for standard
    when 'payment_confirm_premium'
      process_payment('premium', 150) # 150 stars for premium
    end
  end

  def show_payment_options
    text = "💎 *Оплата звездами Telegram*\n\n" \
           "Выберите тариф для оплаты:\n\n" \
           "🟢 *Light* (2 поста/день) - 50 ⭐\n" \
           "🔵 *Standard* (3 поста/день) - 80 ⭐\n" \
           "🟣 *Premium* (безлимит) - 150 ⭐\n\n" \
           "*Как оплатить:*\n" \
           "1. Нажмите на выбранный тариф\n" \
           "2. Подтвердите оплату\n" \
           "3. Бот отправит вам ссылку для оплаты"

    keyboard = [
      [
        { text: "🟢 Light - 50 ⭐", callback_data: "payment_confirm_light" },
        { text: "🔵 Standard - 80 ⭐", callback_data: "payment_confirm_standard" }
      ],
      [
        { text: "🟣 Premium - 150 ⭐", callback_data: "payment_confirm_premium" }
      ],
      [
        { text: "🔙 Назад", callback_data: "subscription_info" }
      ]
    ]

    send_message(text, keyboard)
  end

  private

  def send_message(text, keyboard = nil)
    params = {
      chat_id: @message.chat.id,
      text: text,
      parse_mode: 'Markdown'
    }

    if keyboard
      params[:reply_markup] = {
        inline_keyboard: keyboard
      }.to_json
    end

    @bot.api.send_message(params)
  end
end
