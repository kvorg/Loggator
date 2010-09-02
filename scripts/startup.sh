# Please edit the config files gmjobs.metrics-exporter/{site.conf,backends.conf}
# Then run this script in the installation directory - it will create the state file.
# Use the example from cron.d to create a suitable cron script. 
if [ ! -d /var/state ] ; the echo "Please create /var/state/ or adjust script." ; exit; fi
./gmjobs-metrics-exporter -v -r -l /var/log/gmjobs-metrics-exporter.log -s /var/state/gmjobs-metrics-exporter -u /var/state/gmjobs-metrics-exporter-undo-%d-%t
