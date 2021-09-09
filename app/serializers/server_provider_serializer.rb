# frozen_string_literal: true

class ServerProviderSerializer < ApplicationSerializer
  PROVIDER_KLASS = {
    P4ServerProvider => 'perforce',
  }.freeze

  PERMISSION = {
    nil => '',
    1 => 'Owner',
    2 => 'User',
  }.freeze

  attributes :id, :name, :url

  attribute(:type) { |server| PROVIDER_KLASS[server.type.constantize] }
  attribute(:username) { |server| server.settings(:p4_host).username }
  attribute(:permission) { |server, _params| PERMISSION[server.server_provider_permissions&.first&.permission] }
end
