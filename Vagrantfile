Vagrant.configure(2) do |config|
  config.vm.provision "shell", path: "script.sh"

# ... your existing config

  # Custom configuration for docker
  config.vm.provider "docker" do |docker, override|
#    config.vm.network "private_network", ip: "192.168.66.66"
    # docker doesnt use boxes
    override.vm.box = nil
    # this is where your Dockerfile lives
    docker.build_dir = "."

    # Make sure it sets up ssh with the Dockerfile
    # Vagrant is pretty dependent on ssh
    override.ssh.insert_key = true
    docker.has_ssh = true
    docker.name = 'ubuntu'
    docker.ports = ['22:22', '80:80', '443:443']
    # Configure Docker to allow access to more resources
    docker.privileged = true
  end

# ...

end
