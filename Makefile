PREFIX=/opt
DIR=/gmjobs-metrics-exporter
TARGET=$(PREFIX)$(DIR)
MANIFEST=gmjobs-metrics-exporter \
README.pod \
Makefile \
lib/Loggator/Confer.pm \
lib/Loggator/Parser.pm \
lib/Loggator/utils.pm \
gmjobs-metrics-exporter.rc/backends.conf \
gmjobs-metrics-exporter.rc/site.conf \
gmjobs-metrics-exporter.rc/gm-jobs.log \
examples/ \
t \
gmjobs-metrics-exporter.rc

tar:
	tar cvjf ../gmjobs-metrics-exporter.tar.bz2 --exclude *~ --exclude \#*\# --exclude .git --transform s.^.gmjobs-metrics-exporter/. $(MANIFEST)

clean:
	rm *~ gmjobs-metrics-exporter.log gmjobs-metrics-exporter.status Loggator/*~

install:
	install -d $(TARGET)
	tar cvf - --exclude *~ --exclude \#*\# --exclude .git  $(MANIFEST) | tar xf - --no-same-owner -C $(TARGET)

all:
	echo "No default target. Use 'tar' 'clean' or 'install'.

test:
	prove
