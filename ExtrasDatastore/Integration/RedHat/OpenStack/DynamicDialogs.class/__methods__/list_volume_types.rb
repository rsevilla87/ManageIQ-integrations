#
# Description: List volume types available in the provider where the VM is deployed
#
require "excon"
require 'fog/openstack'

vm = $evm.root["vm"]
ems = vm.ext_management_system

(ems.api_version == 'v2') ? (conn_ref = '/v2.0/tokens') : (conn_ref = '/v3/auth/tokens')
(ems.security_protocol == 'non-ssl') ? (proto = 'http') : (proto = 'https')
$evm.log("info", "#{vm.attributes}")
cloud_tenant = $evm.vmdb("cloud_tenant", vm["cloud_tenant_id"]).name
Excon.defaults[:ssl_verify_peer] = false
@connection_params = {
  openstack_auth_url: "#{proto}://#{ems.hostname}:#{ems.port}#{conn_ref}",
  openstack_username: ems.authentication_userid,
  openstack_api_key: ems.authentication_password,
  openstack_tenant: cloud_tenant
}


$evm.log("info", @connection_params)


vol = Fog::Volume::OpenStack.new(@connection_params)
values = {}
$evm.log("info", "Listing volume types")
vol.list_volume_types.data[:body]["volume_types"].each do |vt|
  if vt["os-volume-type-access:is_public"]
    values[vt["id"]] = vt["name"]
  end
end

$evm.log("info", "VALUES: #{values}")
$evm.object['default_value'] = values.first[0]
$evm.object["values"] = values
$evm.log(:info, "Dynamic values: #{$evm.object['values']}")




