include_recipe "build-essential"

remote_file "#{Chef::Config[:file_cache_path]}/#{node.boost.file}" do
  source node.boost.source + node.boost.file
  mode "0644"
  action :create_if_missing
end

bash "install-boost" do
  user "root"
  cwd Chef::Config[:file_cache_path]
  code <<-EOH
  tar xzvf #{node.boost.file}
  cd #{node.boost.build_dir}
    ./bootstrap.sh && ./bjam install --prefix=#{node.boost.prefix} #{node.boost.bjam_flags}
  EOH
  not_if "test -d #{node.boost.prefix}"
end

bash "clean-boost-dir" do
  user "root"
  code <<-SH
    rm -r #{node.boost.build_dir}
  SH
  only_if "test -d #{node.boost.build_dir}"
end

if node.boost.update_bashrc then
  file "/etc/profile.d/boost.sh" do
    mode "0755"
    content <<-SH
      export LD_LIBRARY_PATH=#{node.boost.prefix}/lib:$LD_LIBRARY_PATH"
      export CPLUS_INCLUDE_PATH=#{node.boost.prefix}/include:$CPLUS_INCLUDE_PATH"
    SH
  end
end
