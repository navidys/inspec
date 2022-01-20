require "helper"
require "inspec/resource"
require "inspec/resources/podman"

describe "Inspec::Resources::Podman" do
  describe "podman" do
    let(:resource) { load_resource("podman") }

    it "check podman version parsing" do
      _(resource.version.Client.Version).must_equal "3.1.2"
      _(resource.version.Client.APIVersion).must_equal "3.1.2"
    end

    it "prints as a podman resource" do
      _(resource.to_s).must_equal "Podman Host"
    end
  end
end
