FROM mariadb:11.4

RUN mkdir /mnt/data_dump
RUN chown -R mysql:mysql /mnt/data_dump

CMD ["--transaction-isolation=READ-COMMITTED", "--log-bin=binlog", "--binlog-format=ROW","--log_bin_trust_function_creators=1"]
