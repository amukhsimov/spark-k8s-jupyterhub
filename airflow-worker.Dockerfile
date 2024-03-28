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
ARG base_img=bitnami/airflow-worker:2.8.3-debian-12-r0

FROM $base_img

# Reset to root to run installation tasks
USER 0

#RUN mkdir ${SPARK_HOME}/python
RUN apt-get update && \
    # Add wget to download maven jars \
    apt install software-properties-common -y && \
    apt install -y nano wget sudo git

#RUN echo 'export PYSPARK_DRIVER_PYTHON=/usr/bin/python3.9' >> /etc/environment

# download and install apache spark
ENV SPARK_VERSION=3.4.2
ENV SPARK_HOME=/opt/spark
RUN wget https://dlcdn.apache.org/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop3.tgz && \
    mkdir $SPARK_HOME && \
    chmod 0777 $SPARK_HOME && \
    tar -xzf ./spark-${SPARK_VERSION}-bin-hadoop3.tgz -C $SPARK_HOME && \
    mv $SPARK_HOME/spark-${SPARK_VERSION}-bin-hadoop3/* $SPARK_HOME && \
    rmdir $SPARK_HOME/spark-${SPARK_VERSION}-bin-hadoop3

RUN apt update && \
    apt install -y default-jdk default-jre
ENV JAVA_HOME=/usr/lib/jvm/default-java

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
# Add Delta Lake support
RUN wget -O ${SPARK_HOME}/jars/delta-core_2.12-2.4.0.jar https://repo1.maven.org/maven2/io/delta/delta-core_2.12/2.4.0/delta-core_2.12-2.4.0.jar
RUN wget -O ${SPARK_HOME}/jars/delta-storage-2.4.0.jar https://repo1.maven.org/maven2/io/delta/delta-storage/2.4.0/delta-storage-2.4.0.jar
# Add Apache Hudi support
RUN wget -O ${SPARK_HOME}/jars/hudi-spark3.4-bundle_2.12-0.14.0.jar https://repo1.maven.org/maven2/org/apache/hudi/hudi-spark3.4-bundle_2.12/0.14.0/hudi-spark3.4-bundle_2.12-0.14.0.jar
# Add GreenPlum JDBC support
#RUN wget -O ${SPARK_HOME}/jars/greenplum-connector-apache-spark-scala_2.12-2.2.0.jar --no-check-certificate 'https://docs.google.com/uc?export=download&id=1BSZjsj-DH0Fpqe_sfSWIV_pG908INolS'
RUN wget -O ${SPARK_HOME}/jars/PROGRESS_DATADIRECT_JDBC_DRIVER_PIVOTAL_GREENPLUM_6.0.0+109.jar --no-check-certificate 'https://docs.google.com/uc?export=download&id=1rQgDiV0c_gCk39ipjBwnhSbd8GCNfw5Q'

RUN adduser --uid 1001 --home /home/airflow-worker airflow-worker
RUN usermod -aG sudo airflow-worker
RUN passwd -d airflow-worker
RUN chown -R airflow-worker /opt

RUN . /opt/bitnami/airflow/venv/bin/activate && \
    /opt/bitnami/airflow/venv/bin/pip3 install pyspark==3.4.2 apache-airflow-providers-apache-spark \
        apache-airflow-providers-oracle minio==7.1.17 openpyxl oracledb pandas numpy python-dotenv

#WORKDIR /opt/bitnami/spark
USER 1001
ENTRYPOINT [ "/opt/bitnami/scripts/airflow-worker/entrypoint.sh" ]
CMD [ "/opt/bitnami/scripts/airflow-worker/run.sh" ]