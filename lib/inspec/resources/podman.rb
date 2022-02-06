#
# Copyright 2022, Navid Yaghoobi
#

require "inspec/resources/command"
require "inspec/utils/filter"
require "hashie/mash"

module Inspec::Resources
  class PodmanContainerFilter
    # use filtertable for containers
    filter = FilterTable.create
    filter.register_custom_matcher(:exists?) { |x| !x.entries.empty? }
    filter.register_column(:commands, field: "command")
      .register_column(:created,        field: "createdat")
      .register_column(:ids,            field: "id")
      .register_column(:images,         field: "image")
      .register_column(:pods,           field: "pod")
      .register_column(:podnames,       field: "podname")
      .register_column(:labels,         field: "labels", style: :simple)
      .register_column(:mounts,         field: "mounts")
      .register_column(:names,          field: "names")
      .register_column(:networks,       field: "networks")
      .register_column(:ports,          field: "ports")
      .register_column(:state,          field: "state")
      .register_column(:sizes,          field: "size")
      .register_column(:status,         field: "status")
      .register_custom_matcher(:running?) do |x|
        x.where { status.downcase.start_with?("up") }
      end
    filter.install_filter_methods_on_resource(self, :containers)

    attr_reader :containers
    def initialize(containers)
      @containers = containers
    end
  end

  class PodmanPodFilter
    filter = FilterTable.create
    filter.register_custom_matcher(:exists?) { |x| !x.entries.empty? }
    filter.register_column(:ids, field: "id")
      .register_column(:names,       field: "name")
      .register_column(:infraids,    field: "infraid")
      .register_column(:cgroups,     field: "cgroup")
      .register_column(:status,     field: "status")
      .register_column(:containers, field: "containers")
      .register_column(:labels,     field: "labels", style: :simple)
    filter.install_filter_methods_on_resource(self, :pods)

    attr_reader :pods
    def initialize(pods)
      @pods = pods
    end
  end

  class PodmanImageFilter
    filter = FilterTable.create
    filter.register_custom_matcher(:exists?) { |x| !x.entries.empty? }
    filter.register_column(:ids, field: "id")
      .register_column(:repositories,  field: "repository")
      .register_column(:tags,          field: "tag")
      .register_column(:sizes,         field: "size")
      .register_column(:digests,       field: "digest")
      .register_column(:created,       field: "createdat")
      .register_column(:created_since, field: "created")
    filter.install_filter_methods_on_resource(self, :images)

    attr_reader :images
    def initialize(images)
      @images = images
    end
  end

  class Podman < Inspec.resource(1)
    name "podman"
    supports platform: "unix"
    desc "
      A resource to retrieve information about podman
    "

    example <<~EXAMPLE
      describe podman.containers do
        its('image') { should_not include 'u12:latest' }
      end

    EXAMPLE

    def pods
      PodmanPodFilter.new(parse_pods)
    end

    def containers
      PodmanContainerFilter.new(parse_containers)
    end

    def images
      PodmanImageFilter.new(parse_images)
    end

    def version
      return @version if defined?(@version)

      data = {}
      cmd = inspec.command("podman version --format '{{ json . }}'")
      data = JSON.parse(cmd.stdout) if cmd.exit_status == 0
      @version = Hashie::Mash.new(data)
    rescue JSON::ParserError => _e
      Hashie::Mash.new({})
    end

    def info
      return @info if defined?(@info)

      data = {}
      cmd = inspec.command("podman info --format '{{ json . }}'")
      data = JSON.parse(cmd.stdout) if cmd.exit_status == 0
      @info = Hashie::Mash.new(data)
    rescue JSON::ParserError => _e
      Hashie::Mash.new({})
    end

    # returns information about podman objects
    def object(id)
      return @inspect if defined?(@inspect)

      data = JSON.parse(inspec.command("podman inspect #{id}").stdout)
      data = data[0] if data.is_a?(Array)
      @inspect = Hashie::Mash.new(data)
    rescue JSON::ParserError => _e
      Hashie::Mash.new({})
    end

    def to_s
      "Podman Host"
    end

    private

    def parse_json_command(labels, subcommand)
      # build command
      format = labels.map { |label| "\"#{label}\": {{json .#{label}}}" }
      raw = inspec.command("podman #{subcommand} --format '{#{format.join(", ")}}'").stdout
      output = []
      # since podman is not outputting valid json, we need to parse each row
      raw.each_line do |entry|
        # convert all keys to lower_case to work well with ruby and filter table
        row = JSON.parse(entry).map do |key, value|
          [key.downcase, value]
        end.to_h

        # ensure all keys are there
        row = ensure_keys(row, labels)

        # strip off any linked container names
        # Depending on how it was linked, the actual container name may come before
        # or after the link information, so we'll just look for the first name that
        # does not include a slash since that is not a valid character in a container name
        if row["names"]
          row["names"] = row["names"].split(",").find { |c| !c.include?("/") }
        end

        # Split labels on ',' or set to empty array
        # Allows for `podman.containers.where { labels.include?('app=redis') }`
        if row["labels"]
          labels_list = []
          row["labels"].each do |key, value|
            labels_list.append("#{key}=#{value}")
          end
          row["labels"] = labels_list
        else
          row["labels"] = []
        end

        row["ports"] = row.key?("ports") ? row["ports"].split(",") : []

        output.push(row)
      end

      output
    rescue JSON::ParserError => _e
      warn "Could not parse `podman #{subcommand}` output"
      []
    end

    def parse_pods
      labels = %w{ID Name InfraID Cgroup Containers Status Labels}
      parse_json_command(labels, "pod ps --no-trunc")
    end

    def parse_containers
      labels = %w{Command CreatedAt ID Image Pod PodName Labels Mounts Names Networks Ports State Size Status}
      parse_json_command(labels, "ps -a --size --no-trunc")
    end

    def parse_images
      labels = %w{ID Repository Tag Size Digest CreatedAt CreatedSince Size}
      parse_json_command(labels, "images -a --no-trunc")
    end

    def ensure_keys(entry, labels)
      labels.each do |key|
        entry[key.downcase] = nil unless entry.key?(key.downcase)
      end
      entry
    end

  end
end
