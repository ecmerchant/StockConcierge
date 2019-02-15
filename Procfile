web: bundle exec puma -t 5:5 -p ${PORT:-3000} -e ${RACK_ENV:-development}
worker: TERM_CHILD=1 QUEUES=* rake environment resque:work
