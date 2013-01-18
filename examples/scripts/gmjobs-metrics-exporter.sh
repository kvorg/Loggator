if [ ! -d /opt/gmjobs-metrics-export ] ; the echo "/opt/gmjobs-metrics-export not found ...\nPlease install the package or adjust the scripts if you installed to a different location." ; exit; fi
if [ ! -d /var/state ] ; the echo "Please create /var/state/ or adjust script." ; exit; fi
cd /opt/gmjobs-metrics-export 
./gmjobs-metrics-exporter -c /opt/gmjobs-metrics-export/gmjobs-metrics-exporter.rc/ -l /var/log/gmjobs-metrics-exporter.log -s /var/state/gmjobs-metrics-exporter.state -u /var/state/gmjobs-metrics-exporter/gmjobs-metrics-exporter.undo-%d-%t.sql > /dev/null 2>&1
