pipeline {
   agent {
   kubernetes {
       // Rather than inline YAML, in a multibranch Pipeline you could use: yamlFile 'jenkins-pod.yaml'
       // Or, to avoid YAML:
      yamlFile 'kubernetes/podtemplate.yml'
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
