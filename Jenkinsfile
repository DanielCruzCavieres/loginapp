pipeline {
  agent any

  tools {
    jdk   'JDK21'          // <-- usa el nombre exacto que tengas en Jenkins
    maven 'Maven_3.9.x'    // <-- idem
  }

  environment {
    ART_SERVER_ID = 'artifactory-local'               // Server ID configurado en Jenkins
    ART_URL       = 'http://localhost:8082/artifactory'
    // Credentials en Jenkins > Credentials, tipo Username/Password, id: artifactory-admin
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Configurar JFrog CLI') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'artifactory-admin',
                                          usernameVariable: 'ART_USER',
                                          passwordVariable: 'ART_PASS')]) {
          // Ver versión del CLI (debug)
          bat 'jf --version'
          // Añadir/actualizar la config del servidor en JFrog CLI (no interactivo)
          bat """
          jf c add %ART_SERVER_ID% ^
            --url %ART_URL% ^
            --user %ART_USER% ^
            --password %ART_PASS% ^
            --interactive=false
          """
          // Ping
          bat 'jf rt ping --server-id %ART_SERVER_ID%'
        }
      }
    }

    stage('Build JAR (Maven)') {
      steps {
        bat 'mvn -U -e -DskipTests package'
        // (Opcional) publicar tests si existieran, sin fallar si no hay
        junit allowEmptyResults: true, testResults: '**/surefire-reports/*.xml'
      }
    }

    stage('Publicar en Artifactory') {
      steps {
        // Obtener la versión del POM en una variable de entorno
        bat '''
        for /f %%v in ('mvn help:evaluate -Dexpression=project.version -q -DforceStdout') do set POM_VERSION=%%v
        echo version=%POM_VERSION%
        '''
        // Subir el JAR
        bat 'jf rt u "target\\*.jar" libs-release-local/loginapp/%POM_VERSION%/ --server-id %ART_SERVER_ID% --flat=true'

        // (Opcional) publicar build-info
        bat '''
        jf rt build-clean
        jf rt build-collect-env loginapp %BUILD_NUMBER%
        jf rt build-add-dependencies loginapp %BUILD_NUMBER% "target\\*.jar"
        jf rt build-publish loginapp %BUILD_NUMBER% --server-id %ART_SERVER_ID%
        '''
      }
    }
  }

  post {
    success {
      echo "✅ Pipeline OK. Artefacto publicado en Artifactory bajo libs-release-local/loginapp/<version>/"
    }
    failure {
      echo "❌ Falló el pipeline. Revisa la consola."
    }
  }
}
