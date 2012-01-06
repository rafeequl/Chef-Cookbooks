#
# Cookbook Name:: passenger
# Recipe:: production

include_recipe "rbenv"

package "curl"
if ['ubuntu', 'debian'].member? node[:platform]
  ['libcurl4-openssl-dev','libpcre3-dev'].each do |pkg|
    package pkg
  end
end

nginx_path = node[:passenger][:production][:path]

rbenv_script "Install passenger Nginx" do
  code   %{passenger-install-nginx-module --auto --auto-download --prefix="#{nginx_path}" --extra-configure-flags="#{node[:passenger][:production][:configure_flags]}"}
  not_if "test -e #{nginx_path}"
end

rbenv_script "Set nginx path" do
  
end

log_path = node[:passenger][:production][:log_path]

directory log_path do
  mode 0755
  action :create
end

directory "#{nginx_path}/conf/conf.d" do
  mode 0755
  action :create
  recursive true
  notifies :reload, 'service[nginx]'
end

directory "#{nginx_path}/conf/sites.d" do
  mode 0755
  action :create
  recursive true
  notifies :reload, 'service[nginx]'
end

# template "#{nginx_path}/conf/nginx.conf" do
#   source "nginx.conf.erb"
#   owner "root"
#   group "root"
#   mode 0644
#   variables(
#     :log_path => log_path,
#     :passenger_root => %x(rbenv which passenger),
#     :ruby_path => %x(rbenv which ruby),
#     :passenger => node[:passenger][:production],
#     :pidfile => "#{nginx_path}/nginx.pid"
#   )
#   notifies :run, 'bash[config_patch]'
# end
# 
# cookbook_file "#{nginx_path}/sbin/config_patch.sh" do
#   owner "root"
#   group "root"
#   mode 0755
# end
# 
# bash "config_patch" do
#   # only_if "grep '##PASSENGER_ROOT##' #{nginx_path}/conf/nginx.conf"
#   user "root"
#   code "#{nginx_path}/sbin/config_patch.sh #{nginx_path}/conf/nginx.conf"
#   notifies :reload, 'service[nginx]'
# end

template "/etc/init.d/nginx" do
  source "nginx.init.erb"
  owner "root"
  group "root"
  mode 0755
  variables(
    :pidfile => "#{nginx_path}/nginx.pid",
    :nginx_path => nginx_path
  )
end

if node[:passenger][:production][:status_server]
  cookbook_file "#{nginx_path}/conf/sites.d/status.conf" do
    source "status.conf"
    mode "0644"
  end
end

service "nginx" do
  service_name "nginx"
  reload_command "#{nginx_path}/sbin/nginx -s reload"
  start_command "#{nginx_path}/sbin/nginx"
  stop_command "#{nginx_path}/sbin/nginx -s stop"
  supports [ :start, :stop, :reload, :status, :enable ]
  action [ :enable, :start ]
  pattern "nginx: master"
end
