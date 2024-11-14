FROM bde2020/hadoop-base:2.0.0-hadoop3.2.1-java8

LABEL maintainer="Grayson Morris <grayson.r.morris@gmail.com>"

# Copy all JAR files to the applications directory
COPY *.jar /opt/hadoop/applications/

# Set default environment variables (can be overridden at runtime)
ENV JAR_FILEPATH="/opt/hadoop/applications/default.jar"
ENV CLASS_TO_RUN="DefaultClass"
ENV PARAMS="/input /output"

ADD run.sh /run.sh
RUN chmod a+x /run.sh

CMD ["/run.sh"]
