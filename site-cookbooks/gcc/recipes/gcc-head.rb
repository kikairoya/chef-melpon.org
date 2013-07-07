include_recipe "build-essential"
include_recipe "gcc::depends"

build_user = "gccbuilder"
build_home = "/home/" + build_user
build_sh = build_home + "/build.sh"
build_gcc = build_home + "/gcc"
build_dir = build_home + "/build"
git_repo = "git://gcc.gnu.org/git/gcc.git"

user build_user do
  action :create
  home build_home
  supports :manage_home => true
  shell "/bin/bash"
end

package "git" do
  action :install
end

# Download from: https://gist.github.com/mikesmullin/5660466
# monkey-patch Chef Git Provider
# to raise the default ShellOut timeout setting
# because this repo can take over 10min
# to clone from github.com
class ::Chef::Provider::Git
  def clone # based on opscode/chef commit b86c5b06
    converge_by("clone from #{@new_resource.repository} into #{@new_resource.destination}") do
      remote = @new_resource.remote

      args = []
      args << "-o #{remote}" unless remote == 'origin'
      args << "--depth #{@new_resource.depth}" if @new_resource.depth

      timeout = 10000 # i believe these are seconds

      Chef::Log.info "#{@new_resource} cloning repo #{@new_resource.repository} to #{@new_resource.destination} with timeout #{timeout}"

      clone_cmd = "git clone #{args.join(' ')} #{@new_resource.repository} #{Shellwords.escape @new_resource.destination}"
      shell_out!(clone_cmd, run_options(:log_level => :info, :timeout => timeout))
    end
  end
end

git build_gcc do
  repository git_repo
  action :sync
  user "gccbuilder"
  group "gccbuilder"
end

file build_sh do
  mode "0755"
  user "root"
  group "root"
  content <<-SH
  echo "test"
  set -e
  echo "test2"
  cd #{build_gcc}
  sudo -u gccbuilder git checkout master
  sudo -u gccbuilder git pull --rebase

  sudo -u gccbuilder rm -rf #{build_dir}
  sudo -u gccbuilder mkdir #{build_dir}
  cd #{build_dir}

  sudo -u gccbuilder #{build_gcc}/configure --prefix=#{node["gcc-head"]["prefix"]} #{node["gcc-head"]["flags"]}
  sudo -u gccbuilder nice make -j2
  make install
  SH
end

# build gcc-head every day
cron "update_gcc_head" do
  action :create
  minute "0"
  hour "4"
  command build_sh
end

# test building
bash "test building gcc-head" do
  action :run
  user "root"
  code build_sh
  not_if "test -e #{node["gcc-head"]["prefix"] + "/bin/gcc"}"
end