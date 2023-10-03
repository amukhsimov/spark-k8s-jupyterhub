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
ARG base_img=bitnami/airflow-worker:2.7.1-debian-11-r14

FROM $base_img

# Reset to root to run installation tasks
USER 0

RUN adduser --uid 1001 airflow-worker

#RUN mkdir ${SPARK_HOME}/python
RUN apt-get update && \
    # Add wget to download maven jars \
    apt install software-properties-common -y && \
    apt install -y python3.9 && \
    apt install -y wget

RUN apt install -y python3.9 python3-pip wget  && \
    pip3 install --upgrade pip setuptools && \
    pip3 install numpy pandas matplotlib pyspark==3.4.1 jupyterlab==4.0.6 && \
    # Removed the .cache to save space
    rm -rf /root/.cache && rm -rf /var/cache/apt/* && \
    rm -f /usr/bin/python3 /usr/bin/python && \
    ln -s /usr/bin/python3.9 /usr/bin/python3 && \
    ln -s /usr/bin/python3.9 /usr/bin/python

RUN echo 'export PYSPARK_DRIVER_PYTHON=/usr/bin/python3.9' >> /etc/environment

# download and install apache spark
ENV SPARK_VERSION=3.4.1
ENV SPARK_HOME=/opt/spark
RUN wget https://dlcdn.apache.org/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop3.tgz && \
    mkdir $SPARK_HOME && \
    chmod 0777 $SPARK_HOME && \
    tar -xzf ./spark-${SPARK_VERSION}-bin-hadoop3.tgz -C $SPARK_HOME && \
    mv $SPARK_HOME/spark-${SPARK_VERSION}-bin-hadoop3/* $SPARK_HOME && \
    rmdir $SPARK_HOME/spark-${SPARK_VERSION}-bin-hadoop3

RUN apt update && \
    apt install -y default-jdk default-jre
ENV JAVA_HOME=/lib/jvm/default-java

# Add S3A support
RUN rm -f ${SPARK_HOME}/jars/hadoop-aws-*
RUN rm -f ${SPARK_HOME}/jars/aws-java-sdk-bundle-*
RUN wget -O ${SPARK_HOME}/jars/hadoop-aws-3.2.2.jar https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.2.2/hadoop-aws-3.2.2.jar
RUN wget -O ${SPARK_HOME}/jars/aws-java-sdk-bundle-1.12.270.jar https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.12.270/aws-java-sdk-bundle-1.12.270.jar
# Add Postgres support
RUN wget -O ${SPARK_HOME}/jars/postgresql-42.2.20.jar https://repo1.maven.org/maven2/org/postgresql/postgresql/42.2.20/postgresql-42.2.20.jar
# Add EC keys support
RUN wget -O ${SPARK_HOME}/jars/bcprov-jdk15on-1.69.jar https://repo1.maven.org/maven2/org/bouncycastle/bcprov-jdk15on/1.69/bcprov-jdk15on-1.69.jar
RUN wget -O ${SPARK_HOME}/jars/bcpkix-jdk15on-1.69.jar https://repo1.maven.org/maven2/org/bouncycastle/bcpkix-jdk15on/1.69/bcpkix-jdk15on-1.69.jar
# Add Oracle JDBC support
RUN wget -O ${SPARK_HOME}/jars/ojdbc8-23.2.0.0.jar https://repo1.maven.org/maven2/com/oracle/database/jdbc/ojdbc8/23.2.0.0/ojdbc8-23.2.0.0.jar

#WORKDIR /opt/bitnami/spark
USER 1001
ENTRYPOINT [ "/opt/bitnami/scripts/airflow-worker/entrypoint.sh" ]
CMD [ "/opt/bitnami/scripts/airflow-worker/run.sh" ]