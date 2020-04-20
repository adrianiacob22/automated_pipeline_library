pipeline {
   agent {
   kubernetes {
       // Rather than inline YAML, in a multibranch Pipeline you could use: yamlFile 'jenkins-pod.yaml'
       // Or, to avoid YAML:
        containerTemplate {
         metadata:
           labels:
             app: build
          spec:
           containers:
           - name: jnlp
             image: nexus.local.net:8123/jenkins-jnlp-slave:20200420
             env:
             - name: CONTAINER_ENV_VAR
               value: jnlp
           - name: maven
             image: maven:3.3.9-jdk-8-alpine
             command:
             - cat
             tty: true
             env:
             - name: CONTAINER_ENV_VAR
               value: maven
           - name: busybox
             image: busybox
             command:
             - cat
             tty: true
             env:
             - name: CONTAINER_ENV_VAR
               value: busybox
           imagePullSecrets:
           - name: docker-repo
        }
   }
   }
   stages {
       stage('Build') {
           steps {
               // Build the app.
               sh 'echo "building in $(hostname)"'
               sh 'hostname'
           }
       }
       stage('Test') {
           steps {
               sh 'echo testing'
               sh 'sleep 10'
           }
       }

   }
}
