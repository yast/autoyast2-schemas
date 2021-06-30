# Copyright (c) [2021] SUSE LLC
#
# All Rights Reserved.
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of version 2 of the GNU General Public License as published
# by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, contact SUSE LLC.
#
# To contact SUSE LLC about this file by physical or electronic mail, you may
# find current contact information at www.suse.com.

require "open-uri"
require "yaml"

module Yast
  module Schema
    TARGETS_FILE = File.expand_path("../../data/targets.yml", __dir__)

    # This class reads files from a repository.
    class RepositoryReader
      attr_reader :access_token

      # @param access_token [String] OAuth access token
      def initialize(access_token)
        require "octokit" # require only when needed
        @access_token = access_token
      end

      # Download files from the repository
      #
      # @param repo_name [String] Repository name
      # @param branch    [String] Branch name
      # @param path      [String] Path name (it can be a glob expression)
      # @param to        [String] Place to write the files to
      def download_files(repo_name:, branch:, path:, to:)
        files = find_files(repo_name, branch, path)

        files.each do |file|
          puts "#{file[:download_url]}"
          download_file(file, to)
        end
      end

      private

      # Find files in the repository for the given path
      #
      # @param repo_name [String] Repository name
      # @param branch    [String] Branch name
      # @param path      [String] Path name (it can be a glob expression)
      def find_files(repo_name, branch, path)
        dirname = File.dirname(path)
        basename = File.basename(path)
        github_client.contents(repo_name, ref: branch, path: dirname).select do |file|
          File.fnmatch(basename, file[:name])
        end
      rescue Octokit::NotFound
        []
      end

      # Download a file from the repository
      #
      # @param file [String] File path
      # @param to   [String] Directory to write file. The file will be saved under a
      #                      folder named after its extension.
      def download_file(file, to)
        target = File.join(to, file[:name].split(".")[-1])
        FileUtils.mkdir_p(target) unless Dir.exist?(target)
        stream = URI.open(file[:download_url])
        IO.copy_stream(stream, File.join(target, file[:name]))
      end

      # GitHub Octokit client
      def github_client
        @github_client ||= Octokit::Client.new(access_token: access_token)
      end
    end

    # Update schema files
    class Updater
      def initialize(access_token)
        @targets = YAML.load_file(TARGETS_FILE)
        @access_token = access_token
      end

      def run(target_name = nil)
        targets =
          if target_name.nil?
            @targets.values.select { |s| s.is_a?(Hash) && s.key?("branch") }
          else
            [@targets[target_name]]
          end

        targets.each { |t| update_from_target(t) }
      end

    private

      def reader
        @reader ||= RepositoryReader.new(@access_token)
      end

      def update_from_target(target)
        target["repositories"].flatten.each do |r|
          update_from_repository(r, target["branch"], File.join("src", target["branch"]).downcase)
        end
      end

      def update_from_repository(repo, branch, to)
        repo["files"].each do |path|
          reader.download_files(
            repo_name: repo["name"], branch: branch, path: path, to: to
          )
        end
      end
    end
  end
end
