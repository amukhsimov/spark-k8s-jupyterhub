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
ARG base_img=bitnami/git:2.42.0-debian-11-r29

FROM $base_img

# Reset to root to run installation tasks
USER 0
RUN git config --global http.sslVerify false
ADD apexbank.corp.crt /usr/local/share/ca-certificates/apexbank.corp.crt
RUN chmod 644 /usr/local/share/ca-certificates/apexbank.corp.crt
RUN update-ca-certificates
