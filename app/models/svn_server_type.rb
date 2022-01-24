# frozen_string_literal: true

class SvnServerType < ServerType
  include EncryptedToken

  def self.bare_repo(repository = nil, username = nil, password = nil)
    puts "SVN BARE REPO : #{repository.inspect}"
    if username.present? && password.present?
      repo_token = password
    elsif repository.present? && repository.settings(:svn_host).username.present?
      username = repository.settings(:svn_host).username
      repo_token = repository.token
    else
      username = settings(:svn_host).username
      repo_token = token
    end

    Travis::VcsProxy::Repositories::Svn.new(repository, username, repo_token)
  end

  def commit_info_from_webhook(payload)
    return unless payload.key?(:change_root) && payload.key?(:username)

    bare_repo.commit_info(payload[:change_root], payload[:username], id)
  end

  def provider_type
    'svn'
  end

  def host_type
    :svn_host
  end

  def default_branch
    'trunk'
  end
end
