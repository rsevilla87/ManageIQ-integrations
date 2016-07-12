#
# Author: Raul Sevilla
#
# Description: Approve or deny a service provision request with the given ID
# Params:
#
#  - $evm.object["request_id"]
#  - $evm.object["reason"]
#  - $evm.object["operation"]
#

$evm.log("info", "#############################################")
$evm.log("info", "approve_deny_service_request method started")
$evm.log("info", "#############################################")
request_id = $evm.root['request_id']
req = $evm.vmdb(:ServiceTemplateProvisionRequest, request_id)

if $evm.root['operation'] == "approve"
  $evm.log("info", "Approving service provision request: #{request_id}")
  $evm.log("info", "Reason: #{$evm.root['reason']}")
  req.approve("admin", $evm.root['reason'])
elsif $evm.root['operation'] == "deny"
  $evm.log("info", "Denying service provision request: #{request_id}")
  $evm.log("info", "Reason: #{$evm.root['reason']}")
  req.deny("admin", $evm.root['reason'])
else
  $evm.log("error", "Unknown operation: #{$evm.root['operation']}")
end

