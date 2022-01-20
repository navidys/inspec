#
# Copyright 2022, Navid Yaghoobi
#

require "inspec/resources/podman"

module Inspec::Resources
  class PodmanContainer < Inspec.resource(1)
    include Inspec::Resources::PodmanObject

    name "podman_container"
    supports platform: "unix"
    desc ""
    example <<~EXAMPLE
      describe podman_container('httpd') do
        it { should exist }
        it { should be_running }
        its('id') { should_not eq '' }
        its('pod') { should_not eq '' }
        its('pod_name') { should eq 'webserver' }
        its('image') { should eq 'docker.io/library/httpd:latest' }
        its('repo') { should eq 'docker.io/library/httpd' }
        its('tag') { should eq 'latest' }
        its('ports') { should eq ['0.0.0.0:8888-8889->80-81/tcp'] }
        its('command') { should eq 'httpd-foreground' }
        its('labels') { should include 'app=httpd' }
      end

      describe podman_container(id: '09fcd7469847') do
        it { should exist }
        it { should be_running }
      end
    EXAMPLE

    def initialize(opts = {})
      # if a string is provided, we expect it is the name
      if opts.is_a?(String)
        @opts = { name: opts }
      else
        @opts = opts
      end
    end

    def running?
      status.downcase.start_with?("up") if object_info.entries.length == 1
    end

    def status
      object_info.status[0] if object_info.entries.length == 1
    end

    def labels
      object_info.labels
    end

    def ports
      object_info.ports[0] if object_info.entries.length == 1
    end

    def pod
      object_info.pod[0] if object_info.entries.length == 1
    end

    def pod_name
      object_info.podname[0] if object_info.entries.length == 1
    end

    def command
      if object_info.entries.length == 1
        cmd = ""
      else
        cmd = object_info.commands[0]
      end
      cmd
    end

    def image
      object_info.image[0] if object_info.entries.length == 1
    end

    def repo
      parse_components_from_image(image)[:repo] if object_info.entries.size == 1
    end

    def tag
      parse_components_from_image(image)[:tag] if object_info.entries.size == 1
    end

    def to_s
      name = @opts[:name] || @opts[:id]
      "Podman Container #{name}"
    end

    private

    def object_info
      return @info if defined?(@info)

      opts = @opts
      @info = inspec.podman.containers.where { names == opts[:name] || (!id.nil? && !opts[:id].nil? && (id == opts[:id] || id.start_with?(opts[:id]))) }
    end
  end
end
