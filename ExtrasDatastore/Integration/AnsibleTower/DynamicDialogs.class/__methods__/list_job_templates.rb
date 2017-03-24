#
# Description: List available job templates in Ansible Tower
#
# Author: Raul Sevilla
#

def log(level, msg)
  $evm.log(level, msg)
end

dialog_hash = {}
$evm.vmdb("ManageIQ_Providers_ConfigurationManager").all.each do |tower|
  log("info", "Fetching job templates from #{tower.name}")
  tower.configuration_scripts.each do |template|
    dialog_hash[template.name] = template.name
  end
end

$evm.object['sort_by'] = 'value'
$evm.object['sort_order'] = 'ascending'
$evm.object['required'] = true
$evm.object['values'] = dialog_hash
