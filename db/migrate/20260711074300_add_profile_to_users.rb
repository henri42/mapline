class AddProfileToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :display_name, :string, null: false
    add_column :users, :bio, :text
    add_column :users, :website_url, :string
    add_column :users, :slug, :string, null: false

    add_index :users, :slug, unique: true
  end
end
