FROM phusion/baseimage:0.9.22

RUN mkdir -p /home/redis

ADD ./install-basic.sh /home/redis/install-basic.sh
ADD ./install-redis.sh /home/redis/install-redis.sh
RUN sh /home/redis/install-basic.sh && sh /home/redis/install-redis.sh

ADD ./redis-supervisor.conf /etc/supervisor/conf.d/
ADD ./run-redis.sh /home/redis/run-redis.sh
RUN chmod u+x /home/redis/run-redis.sh

RUN mkdir /etc/service/redis && mkdir -p /var/log/redis/
COPY ./run.sh /etc/service/redis/run
RUN chmod +x /etc/service/redis/run
ENV TERM xterm

CMD ["/sbin/my_init"]
ENTRYPOINT [ "bash", "-c" ]
