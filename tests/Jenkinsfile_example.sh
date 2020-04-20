
pipeline {
  pod {
    containers {
      container {
        name 'database-testing'
        image 'mysql'
      }
      container {
        name 'build'
        image 'maven'
      }
      container {
        name 'deploy'
        image 'bash'
      }
    }
  }
  agent none
  stages {
    stage('build app') {
      agent {
        container {
          name 'build'
        }
      }
      steps {
        sh 'mvn clean install'
        stash 'app' 'target/*.war'
      }
    }
    stage('build app') {
      agent {
        container {
          name 'build'
        }
      }
      steps {
        unstash 'app'
        sh './deploy.sh'
      }
    }
  }
}
