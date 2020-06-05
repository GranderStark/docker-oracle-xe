FROM debian-jessie:latest

# avoid dpkg frontend dialog / frontend warnings
ENV DEBIAN_FRONTEND=noninteractive
# Prepare to install Oracle
RUN apt-get update && \
apt-get install -y libaio1 net-tools bc alien curl wget&& \
ln -s /usr/bin/awk /bin/awk && \
mkdir /var/lock/subsys

# Install Oracle
RUN mkdir /oracle_packages && cd /oracle_packages && wget  "https://yum.oracle.com/repo/OracleLinux/OL7/latest/x86_64/getPackage/oracle-database-preinstall-18c-1.0-1.el7.x86_64.rpm" && wget "https://download.oracle.com/otn-pub/otn_software/db-express/oracle-database-xe-18c-1.0-1.x86_64.rpm"
RUN cd /oracle_packages && alien -d oracle-database-preinstall-18c_1.0-2_amd64.rpm && alien -d oracle-database-xe-18c-1.0-1.x86_64.rpm && cd / && dpkg --install /oracle_packages/oracle-database-preinstall-18c_1.0-2_amd64.deb &&\
 dpkg --install /oracle_packages/oracle-database-xe-18c_1.0-2_amd64.deb && \
  rm -rf /oracle_packages && apt-get uninstall alien

ENV \
  # The only environment variable that should be changed!
  ORACLE_PASSWORD=Oracle18 \
  EM_GLOBAL_ACCESS_YN=Y \
  # DO NOT CHANGE
  ORACLE_DOCKER_INSTALL=true \
  ORACLE_SID=XE \
  ORACLE_BASE=/opt/oracle \
  ORACLE_HOME=/opt/oracle/product/18c/dbhomeXE \
  ORAENV_ASK=NO \
  RUN_FILE=runOracle.sh \
  SHUTDOWN_FILE=shutdownDb.sh \
  EM_REMOTE_ACCESS=enableEmRemoteAccess.sh \
  EM_RESTORE=reconfigureEm.sh \
  CHECK_DB_FILE=checkDBStatus.sh

COPY ./scripts/*.sh ${ORACLE_BASE}/scripts/
RUN chmod a+x ${ORACLE_BASE}/scripts/*.sh

# 1521: Oracle listener
# 5500: Oracle Enterprise Manager (EM) Express listener.
EXPOSE 1521 5500

VOLUME [ "${ORACLE_BASE}/oradata" ]

HEALTHCHECK --interval=1m --start-period=2m --retries=10 \
  CMD "$ORACLE_BASE/scripts/$CHECK_DB_FILE"

CMD exec ${ORACLE_BASE}/scripts/${RUN_FILE}