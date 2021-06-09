class AddDeviseSecurityToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :decidim_users, :password_changed_at, :datetime
    add_index :decidim_users, :password_changed_at
  end
end
