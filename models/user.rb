class User < Sequel::Model
  plugin :timestamps
  
  one_to_many :subscriptions
  one_to_many :posts

  def active_subscription?
    subscriptions.any? { |s| s.active? && s.expires_at > Time.now }
  end

  def subscription_plan
    return 'free' unless active_subscription?
    subscriptions.last.plan_type
  end

  def can_publish_today?
    return true if subscription_plan == 'premium'
    
    posts_today = posts.where(Sequel.lit("date(created_at) = date('now')")).count
    case subscription_plan
    when 'free'
      posts_today < 1 && created_at > Time.now - 7.days
    when 'light'
      posts_today < 2
    when 'standard'
      posts_today < 3
    else
      false
    end
  end

  def free_trial_active?
    !active_subscription? && created_at > Time.now - 7.days
  end
end
