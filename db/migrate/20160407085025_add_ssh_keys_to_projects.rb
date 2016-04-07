class AddSshKeysToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :ssh_public_key, :text
    add_column :projects, :encrypted_ssh_private_key, :binary
    add_column :projects, :ssh_initialization_vector, :binary
  end
end
