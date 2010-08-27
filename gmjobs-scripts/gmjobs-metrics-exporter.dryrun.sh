cd /opt/gmjobs-metrics-export
./gmjobs-metrics-exporter -c /opt/gmjobs-metrics-export/gmjobs-metrics-exporter.rc/ -l /var/log/gmjobs-metrics-exporter.log -s /var/state/gmjobs-metrics-exporter.state -u /var/state/gmjobs-metrics-exporter/gmjobs-metrics-exporter.undo-%d-%t.sql --nocommit > /dev/null 2>&1
