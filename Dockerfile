FROM tomcat:8-jre8
MAINTAINER Alexandros Sigaras <als2076@med.cornell.edu>, Fedde Schaeffer <fedde@thehyve.nl>
LABEL Description="cBioPortal for Cancer Genomics"
ENV APP_NAME="cbioportal" \
    PORTAL_HOME="/cbioportal"
#======== Install Prerequisites ===============#
RUN apt-get update && apt-get install -y --no-install-recommends \
        git \
        libmysql-java \
        patch \
        python3 \
        python3-jinja2 \
        python3-mysqldb \
        python3-requests \
        maven \
        openjdk-8-jdk \
    && ln -s /usr/share/java/mysql-connector-java.jar "$CATALINA_HOME"/lib/ \
    && rm -rf $CATALINA_HOME/webapps/examples \
    && rm -rf /var/lib/apt/lists/*
#======== Configure cBioPortal ===========================#
COPY . $PORTAL_HOME
WORKDIR $PORTAL_HOME
#EXPOSE 8080

# custom stuff
COPY ./portal.properties src/main/resources/portal.properties
COPY ./log4j.properties src/main/resources/log4j.properties
COPY ./catalina_server.xml.patch /root/
RUN patch $CATALINA_HOME/conf/server.xml </root/catalina_server.xml.patch
COPY ./catalina_context.xml.patch /root/
RUN patch $CATALINA_HOME/conf/context.xml </root/catalina_context.xml.patch

#======== Build cBioPortal on Startup ===============#
CMD mvn -DskipTests clean install \
     && cp $PORTAL_HOME/portal/target/cbioportal*.war $CATALINA_HOME/webapps/cbioportal.war \
     && find $PWD/core/src/main/scripts/ -type f -executable \! -name '*.pl'  -print0 | xargs -0 -- ln -st /usr/local/bin \
     && sh $CATALINA_HOME/bin/catalina.sh run
