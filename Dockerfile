FROM python:3.10-bullseye as spark-base

ARG SPARK_VERSION=3.3.3

#Install tools required by the OS
RUN apt-get update && \
        apt-get install -y --no-install-recommends \
         sudo \
         curl \
         vim  \
            unzip \
         rsync \
            openjdk-11-jdk \
         build-essential \
            software-properties-common \
            ssh && \
        apt-get clean && \
        rm -rf /var/lib/apt/lists/*


#Setup the directories for our Spark and Hadoop installations
ENV SPARK_HOME=${SPARK_HOME:-"/opt/spark"}
ENV HADOOP_HOME=${HADOOP_HOME:-"/opt/hadoop"}

RUN mkdir -p ${SPARK_HOME} && mkdir -p ${HADOOP_HOME}
WORKDIR ${SPARK_HOME}

#dowloand and install spark
RUN curl http://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop3.tgz -o spark-${SPARK_VERSION}-bin-hadoop3.tgz \
&& tar -xvf spark-${SPARK_VERSION}-bin-hadoop3.tgz --directory /opt/spark --strip-components 1 \
&& rm -rf spark-${SPARK_VERSION}-bin-hadoop3.tgz


FROM spark-base as pyspark

#install python deps
COPY requirements/requirements.txt .
RUN  pip install --upgrade pip && pip install -r requirements.txt

#Setup spark related environment varibles
ENV PATH="/opt/spark/sbin:/opt/spark/bin:${PATH}"
ENV SPARK_MASTER="spark://spark-master:7077"
ENV SPARK_MASTER_HOST spark-master
ENV SPARK_MASTER_PORT 7077
ENV PYSPARK_PYTHON python3

#Copy the default configurations into $SPARK_HOME/conf
COPY conf/spark-defaults.conf "$SPARK_HOME/conf"

RUN chmod u+x /opt/spark/sbin/* && \
     chmod u+x /opt/spark/bin/*

ENV PYTHONPATH=$SPARK_HOME/python/:$PYTHONPATH

#Copy appropriate entrypoint script
COPY entrypoint.sh .
RUN chmod +x ./entrypoint.sh

ENTRYPOINT ["./entrypoint.sh"]