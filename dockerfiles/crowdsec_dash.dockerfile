FROM metabase/metabase

RUN mkdir /data/ 

COPY crowdsec/metabase_sqlite.zip /data/

RUN cd /data && unzip metabase_sqlite.zip -d /data/

