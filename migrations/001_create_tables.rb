Sequel.migration do
  up do
    create_table(:users) do
      primary_key :id
      bigint :telegram_id, null: false, unique: true
      string :username
      string :first_name
      string :last_name
      datetime :created_at
      datetime :updated_at
    end

    create_table(:subscriptions) do
      primary_key :id
      foreign_key :user_id, :users
      string :plan_type, null: false
      string :status, default: 'active'
      datetime :expires_at
      datetime :created_at
      datetime :updated_at
    end

    create_table(:posts) do
      primary_key :id
      foreign_key :user_id, :users
      string :media_type
      text :media_url
      text :caption
      string :status, default: 'draft'
      datetime :scheduled_for
      datetime :published_at
      datetime :created_at
    end

    create_table(:payments) do
      primary_key :id
      foreign_key :user_id, :users
      string :plan_type
      integer :stars_amount
      string :status
      string :payment_hash
      datetime :created_at
    end
  end

  down do
    drop_table(:payments, :posts, :subscriptions, :users)
  end
end	
