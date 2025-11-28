class Subscription < Sequel::Model
  plugin :timestamps

  many_to_one :user

  PLAN_LIMITS = {
    'free' => 1,
    'light' => 2,
    'standard' => 3,
    'premium' => 999
  }.freeze

  def active?
    status == 'active' && expires_at > Time.now
  end
end
