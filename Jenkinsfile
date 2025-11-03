pipeline {
  agent any

  tools {
    jdk   'JDK21'          // nombre EXACTO del JDK configurado en Jenkins
    maven 'Maven_3.9.x'    // nombre EXACTO de Maven configurado en Jenkins
  }

  environment {
    ART_SERVER_ID = 'artifactory-local'                 // Server ID en "JFrog Platform Instances"
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
          credentialsId: '0c346bf2-2966-4dce-b6fc-b09f4b55975e',  // <-- tu ID real
          usernameVariable: 'ART_USER',
          passwordVariable: 'ART_PASS'
        )]) {
          // Descarga robusta de jf.exe (detecta arquitectura, prueba dos mirrors, usa curl o certutil)
          bat '''
          @echo off
          setlocal enabledelayedexpansion

          set ARCH32_URL_REPO=https://repo.jfrog.org/artifactory/jfrog-cli/v2/jfrog-cli-windows-386/jf.exe
          set ARCH64_URL_REPO=https://repo.jfrog.org/artifactory/jfrog-cli/v2/jfrog-cli-windows-amd64/jf.exe
          set ARCH32_URL_REL=https://releases.jfrog.io/artifactory/jfrog-cli/v2/jfrog-cli-windows-386/jf.exe
          set ARCH64_URL_REL=https://releases.jfrog.io/artifactory/jfrog-cli/v2/jfrog-cli-windows-amd64/jf.exe

          set "DLURL="
          if /I "%PROCESSOR_ARCHITECTURE%"=="AMD64" set "DLURL=!ARCH64_URL_REPO!"
          if /I "%PROCESSOR_ARCHITEW6432%"=="AMD64" set "DLURL=!ARCH64_URL_REPO!"
          if not defined DLURL set "DLURL=!ARCH32_URL_REPO!"

          if exist jf.exe del /f /q jf.exe

          echo Descargando JFrog CLI desde: !DLURL!
          where curl >NUL 2>&1
          if %errorlevel%==0 (
            curl -L -o jf.exe "!DLURL!" || curl -L -o jf.exe "!DLURL:repo.jfrog.org=releases.jfrog.io!"
          ) else (
            certutil -urlcache -split -f "!DLURL!" jf.exe || certutil -urlcache -split -f "!DLURL:repo.jfrog.org=releases.jfrog.io!" jf.exe
          )

          if not exist jf.exe (
            echo ERROR: No se pudo descargar jf.exe
            exit /b 1
          )

          set PATH=%CD%;%PATH%
          .\\jf.exe --version || (
            echo Binario x64 no compatible. Probando 32-bit...
            del /f /q jf.exe
            where curl >NUL 2>&1
            if %errorlevel%==0 (
              curl -L -o jf.exe "!ARCH32_URL_REPO!" || curl -L -o jf.exe "!ARCH32_URL_REL!"
            ) else (
              certutil -urlcache -split -f "!ARCH32_URL_REPO!" jf.exe || certutil -urlcache -split -f "!ARCH32_URL_REL!" jf.exe
            )
            if not exist jf.exe (
              echo ERROR: No se pudo obtener el binario 32-bit.
              exit /b 1
            )
            .\\jf.exe --version || ( echo ERROR: jf.exe sigue sin correr. ; exit /b 1 )
          )

          jf c add %ART_SERVER_ID% ^
            --url %ART_URL% ^
            --user %ART_USER% ^
            --password %ART_PASS% ^
            --interactive=false

          jf rt ping --server-id %ART_SERVER_ID%
          '''
        }
      }
    }

    stage('Build (Maven)') {
      steps {
        bat 'mvn -U -e -DskipTests package'
        junit allowEmptyResults: true, testResults: '**/surefire-reports/*.xml'
        archiveArtifacts artifacts: 'target/*.jar, target/*.war', fingerprint: true, onlyIfSuccessful: true
      }
    }

    stage('Publicar en Artifactory') {
      steps {
        bat '''
        for /f %%v in ('mvn help:evaluate -Dexpression=project.version -q -DforceStdout') do set POM_VERSION=%%v
        echo version=%POM_VERSION%
        '''

        bat '''
        if exist target\\*.jar (
          jf rt u "target\\*.jar" libs-release-local/loginapp/%POM_VERSION%/ --server-id %ART_SERVER_ID% --flat=true
        ) else (
          echo No se encontro JAR, se omitira.
        )
        '''

        bat '''
        if exist target\\*.war (
          jf rt u "target\\*.war" libs-release-local/loginapp/%POM_VERSION%/ --server-id %ART_SERVER_ID% --flat=true
        ) else (
          echo No se encontro WAR, se omitira.
        )
        '''

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
