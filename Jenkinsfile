pipeline {
  agent any

  tools {
    jdk   'JDK21'          // nombre EXACTO del JDK configurado en Jenkins
    maven 'Maven_3.9.x'    // nombre EXACTO de Maven configurado en Jenkins
  }

  environment {
    ART_SERVER_ID = 'artifactory-local'                 // Server ID que pusiste en "JFrog Platform Instances"
    ART_URL       = 'http://localhost:8082/artifactory' // URL de tu Artifactory
    BUILD_NAME    = 'loginapp'
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

   stage('Configurar JFrog CLI') {
  steps {
    withCredentials([usernamePassword(
      credentialsId: '0c346bf2-2966-4dce-b6fc-b09f4b55975e',
      usernameVariable: 'ART_USER',
      passwordVariable: 'ART_PASS'
    )]) {
      // Descargar jf.exe con certutil (no necesita PowerShell)
      bat '''
      if not exist jf.exe (
        certutil -urlcache -split -f ^
          https://releases.jfrog.io/artifactory/jfrog-cli/v2/jfrog-cli-windows-amd64/jf.exe jf.exe
      )
      set PATH=%CD%;%PATH%
      jf --version
      '''

      bat """
      jf c add %ART_SERVER_ID% ^
        --url %ART_URL% ^
        --user %ART_USER% ^
        --password %ART_PASS% ^
        --interactive=false
      """
      bat 'jf rt ping --server-id %ART_SERVER_ID%'
    }
  }
}

    stage('Build (Maven)') {
      steps {
        bat 'mvn -U -e -DskipTests package'
        // Publica resultados si llegan a existir (no falla si no hay)
        junit allowEmptyResults: true, testResults: '**/surefire-reports/*.xml'
        // Conserva artefactos locales en Jenkins
        archiveArtifacts artifacts: 'target/*.jar, target/*.war', fingerprint: true, onlyIfSuccessful: true
      }
    }

    stage('Publicar en Artifactory') {
      steps {
        // Lee la versión del POM
        bat '''
        for /f %%v in ('mvn help:evaluate -Dexpression=project.version -q -DforceStdout') do set POM_VERSION=%%v
        echo version=%POM_VERSION%
        '''

        // Sube JAR si existe
        bat '''
        if exist target\\*.jar (
          jf rt u "target\\*.jar" libs-release-local/loginapp/%POM_VERSION%/ --server-id %ART_SERVER_ID% --flat=true
        ) else (
          echo No se encontró JAR, se omitirá.
        )
        '''

        // Sube WAR si existe (por si el empaquetado sigue siendo WAR)
        bat '''
        if exist target\\*.war (
          jf rt u "target\\*.war" libs-release-local/loginapp/%POM_VERSION%/ --server-id %ART_SERVER_ID% --flat=true
        ) else (
          echo No se encontró WAR, se omitirá.
        )
        '''

        // (Opcional) publicar build-info
        bat '''
        jf rt build-clean
        jf rt build-collect-env %BUILD_NAME% %BUILD_NUMBER%
        jf rt build-add-dependencies %BUILD_NAME% %BUILD_NUMBER% "target\\*.jar"
        jf rt build-add-dependencies %BUILD_NAME% %BUILD_NUMBER% "target\\*.war"
        jf rt build-publish %BUILD_NAME% %BUILD_NUMBER% --server-id %ART_SERVER_ID%
        '''
      }
    }
  }

  post {
    success {
      echo "✅ Pipeline OK. Revisa Artifactory en libs-release-local/loginapp/<version>/"
    }
    failure {
      echo "❌ Falló el pipeline. Revisa la consola."
    }
  }
}
