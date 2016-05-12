require 'sshkey'
require_relative '../services/secure'

class Project < ActiveRecord::Base
  validates_presence_of :gh_path
  validates_format_of :gh_path, with: %r{\A[^\/]+\/[^\/]+\z}
  validate do |project|
    keys = [project.ssh_public_key.present?, project.encrypted_ssh_private_key.present?]
    unless keys.all? || keys.none?
      project.errors[:base] << 'Must set both public & private ssh keys in tandem'
    end
  end

  extend Diggit::Services::Secure::ActiveRecordHelpers
  encrypted_field :ssh_private_key, iv: :ssh_initialization_vector
  encrypted_field :gh_token, iv: :gh_token_initialization_vector

  def keys?
    ssh_public_key.present? && encrypted_ssh_private_key.present?
  end

  def generate_keypair!
    key = SSHKey.generate(type: 'RSA', bits: 2048, comment: 'bot@diggit-repo.com')
    self.ssh_public_key = key.ssh_public_key
    self.ssh_private_key = key.private_key
    save!
  end
end
