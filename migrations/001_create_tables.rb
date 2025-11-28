Sequel.migration do
  up do
    create_table?(:users) do
      primary_key :id
      bigint :telegram_id, null: false, unique: true
      String :username
      String :first_name
      String :last_name
      DateTime :created_at
      DateTime :updated_at
      
      index :telegram_id
    end

    create_table?(:subscriptions) do
      primary_key :id
      foreign_key :user_id, :users
      String :plan_type, null: false
      String :status, default: 'active'
      DateTime :expires_at
      DateTime :created_at
      DateTime :updated_at
      
      index :user_id
    end

    create_table?(:posts) do
      primary_key :id
      foreign_key :user_id, :users
      String :media_type
      Text :media_url
      Text :caption
      String :status, default: 'draft'
      DateTime :scheduled_for
      DateTime :published_at
      DateTime :created_at
      
      index :user_id
      index :status
    end

    create_table?(:payments) do
      primary_key :id
      foreign_key :user_id, :users
      String :plan_type
      Integer :stars_amount
      String :status
      String :payment_hash
      DateTime :created_at
      
      index :user_id
    end
  end

  down do
    drop_table(:payments, :posts, :subscriptions, :users)
  end
end
