Jenkins Dockerfile
==================

Repo: https://github.com/jenkinsci/docker

# Quickstart

```bash
# cleanup local jenkins data
rm -rf data
mkdir data

# deploy configs
cp -rv cfg/* data

# building image
docker build --tag myjenkins:1.0 .

# running image
docker run --name jenkins \
         --detach \
         -p 8080:8080 \
         -p 50000:50000 \
         --env JAVA_OPTS="-Dcasc.jenkins.config=/var/jenkins_home/casc/ -Dhudson.footerURL=https://svensporer.net -Djenkins.install.runSetupWizard=false -Dhudson.model.UpdateCenter.never=true" \
         -v `pwd`/data:/var/jenkins_home myjenkins:1.0


# update
# create backup of data/ volume
# docker image rm myjenkins:1.0 # optional

# building image
docker build --tag myjenkins:1.1 .
docker run ...
```


# Configuration

Todo:
1. backup for `jenkins_home` on docker host
2. configure build executors
3. https, auto auth
4. alles via configuration as code
   - install plugin => export config on old system
   - slack (mattermost)
   - ldap
5. secrets via hashicorp-vault-plugin
   - https://github.com/jenkinsci/hashicorp-vault-plugin
   - https://github.com/jenkinsci/hashicorp-vault-plugin#hashicorp-vault-plugin-as-a-secret-source-for-jcasc

Notes:
- port mapping 50000 for build executors (JNLP)
- all Jenkins data in `/var/jenkins_home` (plugins, config, ...)
  - make explicit vol to manage
  - attach to other container for upgrades
  - https://docs.docker.com/storage/volumes/

## Passing JVM params

Possible system props:
https://www.jenkins.io/doc/book/managing/system-properties/

to check:
- https://www.jenkins.io/doc/book/managing/system-properties/#jenkins-install-runsetupwizard
- https://www.jenkins.io/doc/book/managing/system-properties/#jenkins-security-frameoptionspagedecorator-enabled
- https://www.jenkins.io/doc/book/managing/system-properties/#jenkins-security-ignorebasicauth

```bash
# <property>                                              # <default>
# -------------------------------------------------------------------
hudson.model.UpdateCenter.never=true                      # false
hudson.consoleTailKB=500                                  # 150
jenkins.security.ApiTokenProperty.showTokenToAdmins=true  # false
# jenkins.security.FrameOptionsPageDecorator.enabled=false  # true
jenkins.ui.refresh=true                                   # false

# usage
--env JAVA_OPTS=-Dhudson.footerURL=http://mycompany.com
```


## Logging

```bash
mkdir data
cat > data/log.properties <<EOF
handlers=java.util.logging.ConsoleHandler
jenkins.level=FINEST
java.util.logging.ConsoleHandler.level=FINEST
EOF

docker run --name myjenkins -p 8080:8080 -p 50000:50000 --env JAVA_OPTS="-Djava.util.logging.config.file=/var/jenkins_home/log.properties" -v `pwd`/data:/var/jenkins_home jenkins/jenkins:lts
```

## Reverse Proxy

`JENKINS_OPTS="--prefix=/jenkins"`

nginx reverse proxy:
https://wiki.jenkins.io/display/JENKINS/Jenkins+behind+an+NGinX+reverse+proxy


## Launch Params

force https with cert included in image:

```dockerfile
FROM jenkins/jenkins:lts

COPY https.pem /var/lib/jenkins/cert
COPY https.key /var/lib/jenkins/pk
ENV JENKINS_OPTS --httpPort=-1 --httpsPort=8083 --httpsCertificate=/var/lib/jenkins/cert --httpsPrivateKey=/var/lib/jenkins/pk
EXPOSE 8083

# slave agent port:
ENV JENKINS_SLAVE_AGENT_PORT 50001

# or as docker parameter:
# docker run --name myjenkins -p 8080:8080 -p 50001:50001 --env JENKINS_SLAVE_AGENT_PORT=50001 jenkins/jenkins:lts
#=> adds jenkins.model.Jenkins.slaveAgentPort to JAVA_OPTS
```

## Plugins

```dockerfile
FROM jenkins/jenkins:lts
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN /usr/local/bin/install-plugins.sh < /usr/share/jenkins/ref/plugins.txt
```

https://github.com/jenkinsci/slack-plugin


## Configuration as Code

https://github.com/jenkinsci/configuration-as-code-plugin
- default: $JENKINS_HOME/jenkins.yaml
- use path to allow for multiple configs?


# Plugins

## slack

```groovy
def notifySlack(String buildStatus = 'STARTED') {
    
    // Build status of null means success.
    buildStatus = buildStatus ?: 'SUCCESS'
    def color
    if (buildStatus == 'STARTED') {
        color = '#D4DADF'
    } else if (buildStatus == 'SUCCESS') {
        color = '#BDFFC3'
    } else if (buildStatus == 'UNSTABLE') {
        color = '#FFFE89'
    } else {
        color = '#FF9FA1'
    }
    def msg = "${buildStatus}: `${env.JOB_NAME}` #${env.BUILD_NUMBER}:\n${env.BUILD_URL}"
    slackSend(color: color, message: msg)
}
node {
    try {
        notifySlack()
        sh 'runbuild'
    } catch (e) {
        currentBuild.result = 'FAILURE'
        throw e
    } finally {
        notifySlack(currentBuild.result)
    }
}
```

## ansicolor

```groovy
// colorize the whole output of pipeline
pipeline {
    agent any
    options {
        ansiColor('xterm')
    }
    stages {
        stage('Build') {
            steps {
                echo '\033[34mHello\033[0m \033[33mcolorful\033[0m \033[35mworld!\033[0m'
            }
        }
    }
}
```

## Other Plugins

configure:

- jenkins: https://github.com/jenkinsci/configuration-as-code-plugin/tree/master/demos/jenkins
- matrix-auth: https://github.com/jenkinsci/configuration-as-code-plugin/tree/master/demos/global-matrix-auth
- slack: https://github.com/jenkinsci/configuration-as-code-plugin/tree/master/demos/slack
- vault: https://github.com/jenkinsci/hashicorp-vault-plugin#configuration-as-code


```
# plugins
greenballs
configuration-as-code
slack
global-slack-notifier

periodicbackup
thinBackup
greenballs
console-column-plugin

display-url-api
built-on-column
mask-passwords
```


# Administration

## Backup

Custom Jenkins backup job?
- https://medium.com/@_oleksii_/how-to-backup-and-restore-jenkins-complete-guide-62fc2f99b457
- https://github.com/luisalima/backup_jenkins_config








