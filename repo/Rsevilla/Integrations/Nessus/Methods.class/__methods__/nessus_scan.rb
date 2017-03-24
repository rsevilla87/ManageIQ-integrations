def launch_scan(scan_id, target)
  log("info", "Launching scan #{scan_id} over #{target}")
  uri = "#{$protocol}://#{$serverurl}:#{$port}/scans/#{scan_id}/launch"
  body = {"alt_targets" => [target]}
  scan = rest_request(uri, body)
end


def check_scan(scan_id)
  log("info", "Checking if scan has finished")
  uri = "#{$protocol}://#{$serverurl}:#{$port}/scans/#{scan_id}"
  resp = rest_request(uri)
  elapsed_time = 0
  until resp["info"]["status"] != "running"
    log("info", "Scan #{scan_id} in progress")
    elapsed_time = $check_period + elapsed_time
    sleep($check_period)
    resp = rest_request(uri)
    if elapsed_time > $check_limit
      error_handler("Check timeout limit reached")
    end
  end
  return resp
end


def eval_result(scan_result)
  for threat in scan_result["vulnerabilities"]
    if threat["severity"] == $critical
      $threat_list.push(vulnerability)
    end
    $all_threats.push(threat)
  end
end


print_banner("nessus_scan method started")
check_availability
for scan in scan_list
  scan_id = get_scan_id(scan["scanname"])
  launch_scan(scan_id, target)
  scan_result = check_scan(scan_id)
  eval_result(scan_result)
  if $threat_list.length > 0
    error_handler("Critical vulnerabilities found in #{scan['scanname']}:\n#{$threat_list}")
  else
    log("info", "No critical vulnerabilities found in #{scan['scanname']}")
    $threat_list = []
  end
end
