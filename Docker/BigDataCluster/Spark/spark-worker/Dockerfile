FROM bde2020/spark-worker

# Install Hadoop libraries
RUN apk update && \
    apk add wget && \
    wget -q https://archive.apache.org/dist/hadoop/common/hadoop-3.3.0/hadoop-3.3.0.tar.gz && \
    tar -xzf hadoop-3.3.0.tar.gz -C /opt && \
    rm hadoop-3.3.0.tar.gz && \
    ln -s /opt/hadoop-3.3.0/etc/hadoop /etc/hadoop

# Set Hadoop and Spark environment variables
ENV HADOOP_HOME=/opt/hadoop-3.3.0
ENV PATH=$PATH:/opt/hadoop-3.3.0/bin
ENV SPARK_HOME=/spark
ENV SPARK_MASTER_PORT=7077
