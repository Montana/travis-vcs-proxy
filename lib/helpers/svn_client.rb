# frozen_string_literal: true

require 'uri'
require 'tempfile'

module Travis
  module VcsProxy
    class SvnClient
      attr_accessor :username, :ssh_key, :password, :url

      def exec(repo, cmd)
        return `svn --username #{@username} --password #{@password} #{cmd}` if @password

        ssh_file = ::Tempfile.new('sshkey')
        ssh_file.write(@ssh_key)
        ENV['SVN_SSH'] = "ssh -i #{ssh_file.path}"
        if assembla?
          ENV['SVN_SSH'] = "ssh -i #{ssh_file.path} -o SendEnv=REPO_NAME -l svn"
        end
        ssh_file.close
        ENV['REPO_NAME'] = repo
        `svn #{cmd}`
      ensure
        ssh_file&.unlink
      end

      def ls(repo, branch = nil)
        res = exec(repo, "ls #{repository_path(repo)}/#{get_branch(branch)}")
        return [] unless res

        res.split("\n")
      end

      def branches(repo)
        res = exec(repo, "ls #{repository_path(repo)}/branches")
        return [] unless res

        res.split("\n")
      end

      def content(repo, file, branch: nil, revision: nil)
        params = "-r #{revision}" if revision
        exec(repo, "cat #{repository_path(repo)}/#{get_branch(branch)}/#{file} #{params}")
      end

      def log(repo, file, branch: nil, revision: nil, format: nil)
        params = ''
        params += '--xml' if format
        params += "-r #{revision}" if revision
        exec(repo, "log #{repository_path(repo)}/#{get_branch(branch)}/#{file} #{params}")
      end

      private

      def repository_path(repo)
        return "#{url}/#{repo}" unless assembla?

        url
      end

      def url
        return @url if @password

        u = URI(@url)
        "svn+ssh://#{@username}@#{u.host}#{u.path}" unless assembla?
        "svn+ssh://#{u.host}"
      end

      def assembla?
        @assembla ||= URI(@url).host.include? 'assembla'
      end

      def repository_name
        URI(@url)&.path.split('/').last
      end

      def get_branch(branch)
        branch ? '/branches/' + branch : 'trunk'
      end
    end
  end
end