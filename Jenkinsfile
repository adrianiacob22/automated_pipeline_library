pipeline {
   agent {
   kubernetes {
       // Rather than inline YAML, in a multibranch Pipeline you could use: yamlFile 'jenkins-pod.yaml'
       // Or, to avoid YAML:
        containerTemplate {
           name 'shell'
            image 'ubuntu'
            command 'sleep'
            args '50'
        }
       // Can also wrap individual steps:
       // container('shell') {
       //     sh 'hostname'
       // }
       defaultContainer 'shell'
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
