#
# Description: Create and attach a new OpenStack Volume to an instance
#

require "fog/openstack"
require "excon"
require "time"

Excon.defaults[:ssl_verify_peer] = false

vm = $evm.root["vm"]
ems = vm.ext_management_system

(ems.api_version == 'v2') ? (conn_ref = '/v2.0/tokens') : (conn_ref = '/v3/auth/tokens')
(ems.security_protocol == 'non-ssl') ? (proto = 'http') : (proto = 'https')
cloud_tenant = $evm.vmdb("cloud_tenant", vm["cloud_tenant_id"]).name

# Set authentication params
@connection_params = {
  openstack_auth_url: "#{proto}://#{ems.hostname}:#{ems.port}#{conn_ref}",
  openstack_username: ems.authentication_userid,
  openstack_api_key: ems.authentication_password,
  openstack_tenant: cloud_tenant
}

def check_volume_availability(volume, vol_handler)
  creation_timeout = 120
  check_period = 5
  before = Time.now()
  $evm.log("info", "Checking volume availability")
  while true
    vol_details = vol_handler.get_volume_details(volume.attributes[:id])
    if vol_details[:body]["volume"]["status"] == "available"
      break
    end
    now = Time.now()
    if now - before > creation_timeout
      $evm.log("error", "Timeout waiting volume availability")
      exit MIQ_ERROR
      break
    end
    $evm.log("info", "Volume not ready yet. Waiting #{check_period} for next status check")
    sleep check_period
  end
end


def attach_volume(volume, vm)
  $evm.log("info", "Attaching volume #{volume.attributes[:id]} to instance #{vm.name}")
  compute_handler = Fog::Compute::OpenStack.new(@connection_params)
  compute_handler.attach_volume(volume.attributes[:id], vm.ems_ref, nil)
end

vol_handler = Fog::Volume::OpenStack.new(@connection_params)
volume_type = $evm.root["dialog_volume_type"]
volume_size = $evm.root["dialog_volume_size"]
volume_name = $evm.root["dialog_volume_name"]
az_name = $evm.vmdb("AvailabilityZone", vm["availability_zone_id"]).name

# Set volume description params
volume_description = {
  :name => volume_name,
  :tenant_id => cloud_tenant,
  :size => volume_size,
  :volume_type => volume_type,
  :availability_zone => az_name
}

$evm.log("info", "Connection params: #{@connection_params}")
$evm.log("info", "Volume description #{volume_description}")

volume = vol_handler.volumes.create(volume_description)
$evm.log("info", "Volume creation response #{volume.attributes}")
check_volume_availability(volume, vol_handler)
$evm.log("info", "Volume #{volume_name} sucessfully created")
attach_volume(volume, vm)



