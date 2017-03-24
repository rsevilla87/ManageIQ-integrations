#
# Description: This method list clusters id in a given VMWare provider
#
# Author: Raul Sevilla
#

def log(level, msg)
  $evm.log(level, msg)
end

dialog_hash = {}
provider_name = $evm.object["provider_name"]
provider = $evm.vmdb(:ManageIQ_Providers_Vmware_InfraManager).find_by_name(provider_name)
log("info", "Fetching clusters from #{provider_name}")
provider.ems_clusters.each do |cluster|
  dialog_hash[cluster.id] = "#{cluster.name}"
end

$evm.object['sort_by'] = 'value'
$evm.object['sort_order'] = 'ascending'
$evm.object['required'] = true
$evm.object['values'] = dialog_hash
