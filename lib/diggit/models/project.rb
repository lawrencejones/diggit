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

  def owner
    gh_path.split('/').first
  end

  def repo
    gh_path.split('/').last
  end

  def keys?
    ssh_public_key.present? && encrypted_ssh_private_key.present?
  end

  def ssh_private_key
    return nil unless keys?
    Diggit::Services::Secure.
      decode(encrypted_ssh_private_key, ssh_initialization_vector)
  end

  def ssh_private_key=(private_key)
    encrypted_key, initialization_vector = Diggit::Services::Secure.
      encode(private_key)
    self.encrypted_ssh_private_key = encrypted_key
    self.ssh_initialization_vector = initialization_vector
  end

  def generate_keypair!
    key = SSHKey.generate(type: 'RSA', bits: 2048)
    self.ssh_public_key = key.ssh_public_key
    self.ssh_private_key = key.private_key
    save!
  end
end
