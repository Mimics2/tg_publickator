require './bot'
require 'sinatra'

set :port, ENV['PORT'] || 3000
set :bind, '0.0.0.0'

# Инициализация базы данных при старте
def init_database
  require 'sequel'
  
  DB = if ENV['DATABASE_URL']
    Sequel.connect(ENV['DATABASE_URL'])
  else
    Sequel.sqlite('bot.db')
  end
  
  # Проверяем и создаем таблицы если нужно
  begin
    DB.tables
  rescue => e
    puts "Database setup needed: #{e.message}"
    require_relative 'migrations/001_create_tables'
    Sequel::Migrator.run(DB, "migrations")
  end
end

# Вебхук для Railway
post '/webhook' do
  request.body.rewind
  data = JSON.parse(request.body.read)
  
  bot = TelegramPublisherBot.new
  bot.process_update(data)
  
  status 200
end

get '/' do
  '🤖 Telegram Publisher Bot is running!'
end

get '/health' do
  status 200
  { status: 'ok', time: Time.now }.to_json
end

# Инициализация при старте
init_database

# Запуск бота в отдельном потоке
Thread.new do
  begin
    puts "🤖 Starting Telegram Bot..."
    bot = TelegramPublisherBot.new
    bot.run
  rescue => e
    puts "Bot error: #{e.message}"
    sleep 5
    retry
  end
end
