# migration pra adicionar a coluna username na tabela users
class AddUsernameToUsers < ActiveRecord::Migration
  def change
    add_column :users, :username, :string
  end
end
