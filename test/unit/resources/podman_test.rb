require "helper"
require "inspec/resource"
require "inspec/resources/podman"

describe "Inspec::Resources::Podman" do
  describe "podman" do
    let(:resource) { load_resource("podman") }

    it "check podman pod parsing" do
      _(resource.pods.names).must_equal %w{pod03 pod02 pod01}
      _(resource.pods.ids).must_equal %w{d1a6e563f5174bb96ad27f64c157c2fe86a620fb7edeeaa8b88641696c09f51c b178092e05439e0cbf3c9240350561de4390da376af91a4d37c9d45a0bcba31c 78f02d4cb0085817910fe8c500e5dd534616fa4d86f7ade08bdf3181d09edc49}
      _(resource.pods.cgroups).must_equal ["user.slice", "user.slice", "user.slice"]
      _(resource.pods.labels).must_equal ["key01=value01"]
    end

    it "check podman containers parsing" do
      _(resource.containers.names).must_equal %w{apache bash}
      _(resource.containers.ids).must_equal %w{5ecac88ce04d10e794c6a679d4905266b5b86f41befbaa093662412ce1838330 d72f2924b0cf525c15a6d6f7198c45718b8f73d4a7593eba8b5b6a6e7cdb395e}
      _(resource.containers.ports).must_equal [["0.0.0.0:8888->80/tcp"], []]
    end

    it "check podman images parsing" do
      _(resource.images.repositories).must_equal ["docker.io/library/httpd", "docker.io/library/bash", "k8s.gcr.io/pause"]
      _(resource.images.tags).must_equal ["latest", "latest", "3.5"]
      _(resource.images.sizes).must_equal ["148 MB", "13.5 MB", "690 kB"]
      _(resource.images.digests).must_equal %w{sha256:5cc947a200524a822883dc6ce6456d852d7c5629ab177dfbf7e38c1b4a647705 sha256:fc742d0c3d9d8f5fb2681062398c04b710cd08c46dac1a8f0a5515687018acb9 sha256:1ff6c18fbef2045af6b9c16bf034cc421a29027b800e4f9b68ae9b1cb3e9ae07}
    end

    it "check podman version parsing" do
      _(resource.version.Client.Version).must_equal "3.1.2"
      _(resource.version.Client.APIVersion).must_equal "3.1.2"
    end

    it "check podman info parsing" do
      _(resource.info.host.cgroupManager).must_equal "systemd"
      _(resource.info.host.cgroupManager).must_equal "systemd"
      _(resource.info.host.ociRuntime.name).must_equal "crun"
    end

    it "check podman object parsing" do
      _(resource.object("5ecac88ce04d").Id).must_equal "5ecac88ce04d10e794c6a679d4905266b5b86f41befbaa093662412ce1838330"
    end

    it "prints as a podman resource" do
      _(resource.to_s).must_equal "Podman Host"
    end
  end
end
