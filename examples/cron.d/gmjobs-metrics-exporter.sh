# call this scrip from the cron job
cd /opt/gmjobs-metrics-export 
./gmjobs-metrics-exporter -B  -l /var/log/gmjobs-metrics-exporter.log -s /var/state/gmjobs-metrics-exporter.state -u /var/state/gmjobs-metrics-exporter/gmjobs-metrics-exporter.undo-%d-%t.sql > /dev/null 2>&1
