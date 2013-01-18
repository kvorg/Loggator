# Please edit the config files gmjobs.metrics-exporter/{site.conf,backends.conf}
# Then run this script in the installation directory - it will create the state file.
# Use the example from cron.d to create a suitable cron script. 
if [ ! -d /opt/gmjobs-metrics-export ] ; the echo "/opt/gmjobs-metrics-export not found ...\nPlease install the package or adjust the scripts if you installed to a different location." ; exit; fi
if [ ! -d /var/state ] ; the echo "Please create /var/state/ or adjust script." ; exit; fi
cd /opt/gmjobs-metrics-export 
./gmjobs-metrics-exporter -v -r -c /opt/gmjobs-metrics-export/gmjobs-metrics-exporter.rc/ -l /var/log/gmjobs-metrics-exporter.log -s /var/state/gmjobs-metrics-exporter -u /var/state/gmjobs-metrics-exporter-undo-%d-%t
