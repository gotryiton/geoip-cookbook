#
# Cookbook Name:: geoip
# Recipe:: default
#
# Copyright 2012, Go Try It On, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

package "geoip-database" do
  action :install
end

package "geoip-bin" do
  action :install
end

package "libgeoip-dev" do
  action :install
end

directory "/var/lib/chef/periodic" do
  owner "root"
  group "root"
  recursive true
  mode 0755
  action :create
end

execute "update_geo_periodic" do
  cwd "#{Chef::Config[:file_cache_path]}"
  command <<-EOH
    touch /var/lib/chef/periodic/geoip
  EOH
  action :nothing
end

remote_file "#{Chef::Config[:file_cache_path]}/GeoLiteCity.dat.gz" do
  source node[:geoip][:download_location]
  only_if do
    !File.exists?('/var/lib/chef/periodic/geoip') ||
    File.mtime('/var/lib/chef/periodic/geoip') < Time.now - 86400
  end
end

execute "install_geoip" do
  cwd "#{Chef::Config[:file_cache_path]}"
  command <<-EOH
    gzip -d GeoLiteCity.dat.gz
    chmod 644 GeoLiteCity.dat
    mv GeoLiteCity.dat /usr/share/GeoIP/GeoIPCity.dat
  EOH
  only_if do
    File.exists?("#{Chef::Config[:file_cache_path]}/GeoLiteCity.dat.gz")
  end
  notifies :run, resources(:execute => "update_geo_periodic"), :immediately
end
