#
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

FROM docker.repository.cloudera.com/cdsw/engine:2

# Install kudu repo
RUN curl -o /etc/apt/sources.list.d/cloudera.list http://archive.cloudera.com/kudu/ubuntu/xenial/amd64/kudu/cloudera.list
RUN ls -al /etc/apt/sources.list.d/
RUN apt-get update
RUN apt-get -y --allow-unauthenticated install libkuduclient0 libkuduclient-dev

# Install some prereqs
RUN apt-get update && \
    apt-get install -y rpm2cpio curl sudo ksh && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# compile and install unixODBC 2.3.4
WORKDIR /tmp
RUN curl -O http://www.unixodbc.org/unixODBC-2.3.4.tar.gz && tar -xz -f /tmp/unixODBC-2.3.4.tar.gz 
WORKDIR /tmp/unixODBC-2.3.4 
RUN CPPFLAGS="-DSIZEOF_LONG_INT=8" ./configure --prefix=/usr --libdir=/usr/lib64 --sysconfdir=/etc --enable-gui=no --enable-drivers=no --enable-iconv --with-iconv-char-enc=UTF8 --with-iconv-ucode-enc=UTF16LE --enable-stats=no 1> configure_std.log 2> configure_err.log && make 1> make_std.log 2> make_err.log && make install 1> makeinstall_std.log 2> makeinstall_err.log

# install teradata drivers
ADD tdicu1610_16.10.00.00-2_all.deb /tmp/tdicu1610_16.10.00.00-2_all.deb
ADD tdodbc1610_16.10.00.02-2_all.deb /tmp/tdodbc1610_16.10.00.02-2_all.deb
RUN dpkg -i /tmp/tdicu1610_16.10.00.00-2_all.deb
# teradata odbc README file specifies running the tdodbc installer using the korn shell:
RUN /bin/ksh -c 'dpkg -i /tmp/tdodbc1610_16.10.00.02-2_all.deb'

# create folders
RUN mkdir /opt/teradata/client/ODBC_32 && mkdir /opt/teradata/client/ODBC_64

# create symlinks
RUN ln -s /opt/teradata/client/16.10/lib64 /opt/teradata/client/ODBC_64/lib && ln -s /opt/teradata/client/16.10/odbc_64/locale /opt/teradata/client/ODBC_64/locale && ln -s /opt/teradata/client/16.10/include /opt/teradata/client/ODBC_64/include && ln -s /opt/teradata/client/16.10/lib /opt/teradata/client/ODBC_32/lib && ln -s /opt/teradata/client/16.10/odbc_32/locale /opt/teradata/client/ODBC_32/locale && ln -s /opt/teradata/client/16.10/include /opt/teradata/client/ODBC_32/include && ln -s /opt/teradata/client/16.10/include /opt/teradata/client/16.10/odbc_64/include && ln -s /opt/teradata/client/16.10/lib64 /opt/teradata/client/16.10/odbc_64/lib && ln -s /opt/teradata/client/16.10/include /opt/teradata/client/16.10/odbc_32/include && ln -s /opt/teradata/client/16.10/lib /opt/teradata/client/16.10/odbc_32/lib && ln -s /opt/teradata/client/16.10/lib/ivtrc27.so /opt/teradata/client/16.10/lib/odbctrac.so && ln -s /opt/teradata/client/16.10/lib64/ddtrc27.so /opt/teradata/client/16.10/lib64/odbctrac.so && ln -s /opt/teradata/client/16.10/etc/.ttupath_1610_bash.env /opt/teradata/client/etc/ttu_bash.env && ln -s /opt/teradata/client/16.10/etc/.ttupath_1610_csh.env /opt/teradata/client/etc/ttu_csh.env && rm /usr/lib64/libodbcinst.so && ln -s /opt/teradata/client/16.10/lib64/libodbcinst.so /usr/lib64/libodbcinst.so && rm /usr/lib64/libodbc.so && ln -s /opt/teradata/client/16.10/lib64/libodbc.so /usr/lib64/libodbc.so

# create environment variables
ENV ODBCINI=/opt/teradata/client/16.10/odbc_64/odbc.ini LD_LIBRARY_PATH=/opt/teradata/client/ODBC_64/lib

# create odbc files
ADD etc_odbc.ini /etc/odbc.ini
ADD 1610_odbc32_odbc.ini /opt/teradata/client/16.10/odbc_32/odbc.ini
ADD 1610_odbc64_odbc.ini /opt/teradata/client/16.10/odbc_64/odbc.ini
ADD odbc32_odbc.ini /opt/teradata/client/ODBC_32/odbc.ini
ADD odbc64_odbc.ini /opt/teradata/client/ODBC_64/odbc.ini
ADD etc_odbcinst.ini /etc/odbcinst.ini
ADD 1610_odbc32_odbcinst.ini /opt/teradata/client/16.10/odbc_32/odbcinst.ini
ADD 1610_odbc64_odbcinst.ini /opt/teradata/client/16.10/odbc_64/odbcinst.ini
ADD odbc32_odbcinst.ini /opt/teradata/client/ODBC_32/odbcinst.ini
ADD odbc64_odbcinst.ini /opt/teradata/client/ODBC_64/odbcinst.ini
ADD genuine_TTU /opt/teradata/client/16.10/.genuine_TTU
RUN touch /opt/teradata/client/16.10/ttu_softlinks_yes_1610 && touch /opt/teradata/client/16.10/ttu_updateETC_1610
RUN chmod 4111 /opt/teradata/client/16.10/.genuine_TTU

# Give cdsw user sudo
RUN echo "cdsw    ALL=(ALL:ALL) NOPASSWD: ALL" >> /etc/sudoers

# install teradata python library
#RUN pip2 install teradata
#RUN pip3 install teradata

# Install Oracle basic driver and odbc driver v12.2
ADD instantclient-odbc-linux.x64-12.2.0.1.0.zip /tmp/instantclient-odbc-linux.x64-12.2.0.1.0.zip
ADD instantclient-basic-linux.x64-12.2.0.1.0.zip /tmp/instantclient-basic-linux.x64-12.2.0.1.0.zip
RUN unzip /tmp/instantclient-odbc-linux.x64-12.2.0.1.0.zip -d /opt/oracle/
RUN unzip /tmp/instantclient-basic-linux.x64-12.2.0.1.0.zip -d /opt/oracle/
RUN ln -s /opt/oracle/instantclient_12_2/libclntsh.so.12.1 /opt/oracle/instantclient_12_2/libclntsh.so && ln -s /opt/oracle/instantclient_12_2/libocci.so.12.1 /opt/oracle/instantclient_12_2/libocci.so
RUN apt-get install libaio1
ENV LD_LIBRARY_PATH=/opt/oracle/instantclient_12_2:$LD_LIBRARY_PATH
RUN /opt/oracle/instantclient_12_2/odbc_update_ini.sh / /opt/oracle/instantclient_12_2 "Oracle 12c ODBC driver" OracleODBC-12c /etc/odbc.ini


