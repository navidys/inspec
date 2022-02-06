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

    it "check podman info parsing" do
      _(resource.info.host.cgroupManager).must_equal "systemd"
      _(resource.info.host.cgroupManager).must_equal "systemd"
      _(resource.info.host.ociRuntime.name).must_equal "crun"
    end

    it "check podman pod parsing" do
      _(resource.pods.names).must_equal ["pod03", "pod02", "pod01"]
      _(resource.pods.ids).must_equal ["d1a6e563f5174bb96ad27f64c157c2fe86a620fb7edeeaa8b88641696c09f51c", "b178092e05439e0cbf3c9240350561de4390da376af91a4d37c9d45a0bcba31c", "78f02d4cb0085817910fe8c500e5dd534616fa4d86f7ade08bdf3181d09edc49"]
      _(resource.pods.cgroups).must_equal ["user.slice", "user.slice", "user.slice"]
      _(resource.pods.labels).must_equal ["key01=value01"]
    end

    it "check podman containers parsing" do
      _(resource.containers.names).must_equal ["apache", "bash"]
      _(resource.containers.ids).must_equal ["5ecac88ce04d10e794c6a679d4905266b5b86f41befbaa093662412ce1838330", "d72f2924b0cf525c15a6d6f7198c45718b8f73d4a7593eba8b5b6a6e7cdb395e"]
      _(resource.containers.ports).must_equal [["0.0.0.0:8888->80/tcp"], []]
    end

    it "prints as a podman resource" do
      _(resource.to_s).must_equal "Podman Host"
    end
  end
end
