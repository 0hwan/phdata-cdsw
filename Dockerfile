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
    apt-get install -y rpm2cpio curl sudo && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# compile and install unixODBC 2.3.4
WORKDIR /tmp
RUN curl -O http://www.unixodbc.org/unixODBC-2.3.4.tar.gz && tar -xz -f /tmp/unixODBC-2.3.4.tar.gz 
WORKDIR /tmp/unixODBC-2.3.4 
RUN CPPFLAGS="-DSIZEOF_LONG_INT=8" ./configure --prefix=/usr --libdir=/usr/lib64 --sysconfdir=/etc --enable-gui=no --enable-drivers=no --enable-iconv --with-iconv-char-enc=UTF8 --with-iconv-ucode-enc=UTF16LE --enable-stats=no 1> configure_std.log 2> configure_err.log && make 1> make_std.log 2> make_err.log && make install 1> makeinstall_std.log 2> makeinstall_err.log
WORKDIR /

# Make impala odbc available
COPY odbcinst.ini /etc/

# Give cdsw user sudo
RUN echo "cdsw    ALL=(ALL:ALL) NOPASSWD: ALL" >> /etc/sudoers
