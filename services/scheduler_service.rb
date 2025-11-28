require 'rufus-scheduler'

class SchedulerService
  def initialize
    @scheduler = Rufus::Scheduler.new
    setup_scheduled_tasks
  end

  def schedule_post(post_id, publish_time)
    @scheduler.at publish_time do
      publish_scheduled_post(post_id)
    end
  end

  private

  def setup_scheduled_tasks
    # Ежедневная проверка подписок
    @scheduler.cron '0 0 * * *' do
      check_expired_subscriptions
    end

    # Очистка старых данных
    @scheduler.cron '0 2 * * *' do
      cleanup_old_data
    end
  end

  def publish_scheduled_post(post_id)
    post = Post[post_id]
    return unless post && post.scheduled?

    TelegramService.new().publish_post(post)
    post.update(status: 'published', published_at: Time.now)
  end

  def check_expired_subscriptions
    expired_subs = Subscription.where('expires_at < ?', Time.now).where(status: 'active')
    expired_subs.update(status: 'expired')
  end

  def cleanup_old_data
    # Удаляем посты старше 30 дней
    Post.where('created_at < ?', 30.days.ago).delete
  end
end
