# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

#ARG base_img=spark:latest
ARG base_img=bitnami/spark:3.4.1

FROM $base_img
WORKDIR /

# Reset to root to run installation tasks
USER 0

RUN adduser --uid 1001 spark

RUN apt update && \
    apt install -y build-essential zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev libssl-dev libreadline-dev libffi-dev libsqlite3-dev wget libbz2-dev
RUN wget https://www.python.org/ftp/python/3.10.12/Python-3.10.12.tgz && \
    tar -xf Python-3.10.*.tgz && \
    cd Python-3.10.*/ && \
    ./configure --prefix=/usr/local --enable-optimizations --enable-shared LDFLAGS="-Wl,-rpath /usr/local/lib" && \
    make -j$(nproc) && make altinstall && \
    ln -s /usr/local/bin/python3.10 /usr/bin/python3.10
#RUN mkdir ${SPARK_HOME}/python
RUN apt update && apt install software-properties-common gnupg -y && \
    apt install -y wget

RUN echo 'export PYSPARK_DRIVER_PYTHON=/usr/bin/python3.10' >> /etc/environment

COPY python/pyspark ${SPARK_HOME}/python/pyspark
COPY python/lib ${SPARK_HOME}/python/lib
# Add S3A support
RUN rm ${SPARK_HOME}/jars/hadoop-aws-*
RUN rm ${SPARK_HOME}/jars/aws-java-sdk-bundle-*
RUN wget -O ${SPARK_HOME}/jars/hadoop-aws-3.2.2.jar https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.2.2/hadoop-aws-3.2.2.jar
RUN wget -O ${SPARK_HOME}/jars/aws-java-sdk-bundle-1.12.270.jar https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.12.270/aws-java-sdk-bundle-1.12.270.jar
# Add Postgres support
RUN wget -O ${SPARK_HOME}/jars/postgresql-42.2.20.jar https://repo1.maven.org/maven2/org/postgresql/postgresql/42.2.20/postgresql-42.2.20.jar
# Add EC keys support
RUN wget -O ${SPARK_HOME}/jars/bcprov-jdk15on-1.69.jar https://repo1.maven.org/maven2/org/bouncycastle/bcprov-jdk15on/1.69/bcprov-jdk15on-1.69.jar
RUN wget -O ${SPARK_HOME}/jars/bcpkix-jdk15on-1.69.jar https://repo1.maven.org/maven2/org/bouncycastle/bcpkix-jdk15on/1.69/bcpkix-jdk15on-1.69.jar

WORKDIR /opt/bitnami/spark
USER 1001
ENTRYPOINT [ "/opt/bitnami/scripts/spark/entrypoint.sh" ]
CMD [ "/opt/bitnami/scripts/spark/run.sh" ]