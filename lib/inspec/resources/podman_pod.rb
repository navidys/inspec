#
# Copyright 2022, Navid Yaghoobi
#

require "inspec/resources/podman"

module Inspec::Resources
  class PodmanPod < Inspec.resource(1)
    include Inspec::Resources::PodmanObject

    name "podman_pod"
    supports platform: "unix"
    desc ""
    example <<~EXAMPLE
      describe podman_pod('httpd') do
        it { should exist }
        it { should be_running }
        its('id') { should_not eq '' }
        its('infra_id') { should_not eq '' }
        its('cgroup') { should eq '/libpod_parent' }
        its('containers') { should include 'ef343a06a850' }
        its('labels') { should include 'app=httpd' }
      end

      describe podman_pod(id: 'd6dba851107e') do
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

    def containers
      cntlist = []
      object_info.containers[0].each { |cnt| cntlist.append(cnt["Id"][0..11]) } if object_info.entries.length == 1
      cntlist
    end

    def labels
      object_info.labels
    end

    def cgroup
      object_info.cgroup[0] if object_info.entries.length == 1
    end

    def infra_id
      object_info.infraid[0] if object_info.entries.length == 1
    end

    def to_s
      name = @opts[:name] || @opts[:id]
      "Podman Pod #{name}"
    end

    private

    def object_info
      return @info if defined?(@info)

      opts = @opts
      @info = inspec.podman.pods.where { name == opts[:name] || (!id.nil? && !opts[:id].nil? && (id == opts[:id] || id.start_with?(opts[:id]))) }
    end
  end
end
