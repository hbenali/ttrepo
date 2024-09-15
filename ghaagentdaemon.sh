#!/bin/bash -u
getMavenPid() {
    ps -ef | grep /usr/share/maven | grep -v grep | awk '{print $2}' | sort | tail -1 || echo ""
}
echo "Forwarding SSH Port to Jenkins agent"
ssh-keygen -y -f ~/.ssh/id* >> ~/.ssh/authorized_keys
chmod 0600 ~/.ssh/authorized_keys
ssh -g -N ${AGENT_HOST} -R ${AGENT_FORWARD_PORT}:localhost:22 &
SSH_PID=$!
trap "kill -9 ${SSH_PID}" EXIT
echo "Connected"
echo "Waiting for maven execution..."
count=0
try=${MAVEN_WAIT_TIMEOUT:-300}
mvnoutputfile="/tmp/mvnout"
while [ $count -lt $try ] && [ -z $(getMavenPid()) ]; do
    sleep 5
    count=$(( $count + 1 ))
done
if [ $count -ge $try ]; then 
  echo "Error! Cound not build maven project! Abort"
  exit 1
fi
echo "OK Maven is running"
wait $(getMavenPid())
echo "mvn build is finished! Stopping ssh agent..."
kill -9 ${SSH_PID}
exit 0