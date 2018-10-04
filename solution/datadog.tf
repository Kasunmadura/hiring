resource "datadog_monitor" "cpumonitor" {
  name = "cpu monitor ${aws_instance.base.id}"
  type = "metric alert"
  message = "CPU usage alert"
  query = "avg(last_1m):avg:system.cpu.system{host:${aws_instance.phpapp.*.id}} by {host} > 10"
  new_host_delay = 30 # just so we can generate an alert quickly
}
