pipeline {
    agent any

    options {
        timestamps()
        buildDiscarder(logRotator(numToKeepStr: '10'))
        disableConcurrentBuilds()
    }

    tools {
        jdk   'JDK21'
        maven 'Maven_3.9.x'
    }

    environment {
        PROJECT_NAME      = 'loginapp'
        ART_URL           = 'http://localhost:8082/artifactory'
        ART_RELEASE_REPO  = 'libs-release-local'
        ART_SNAPSHOT_REPO = 'libs-snapshot-local'
        // ID del credential en Jenkins (Username/Password)
        ART_CRED_ID       = 'artifactory-admin'
    }

    stages {
        stage('Checkout') {
            steps {
                echo "=== Clonando el repositorio desde GitHub ==="
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: '*/main']],
                    userRemoteConfigs: [[
                        url: 'https://github.com/DanielCruzCavieres/loginapp.git'
                    ]]
                ])
            }
        }

        stage('Compilación y Test') {
            steps {
                echo "=== Ejecutando compilación Maven (tests) ==="
                bat 'mvn -U -e clean test'
            }
            post {
                always {
                    junit allowEmptyResults: true, testResults: '**/target/surefire-reports/*.xml'
                }
            }
        }

        stage('Empaquetar (Package)') {
            steps {
                echo "=== Empaquetando el proyecto (skip tests) ==="
                bat 'mvn -U -e -DskipTests package'
            }
        }

        stage('Archivar Artefactos') {
            steps {
                archiveArtifacts artifacts: 'target/**/*.jar, target/**/*.war', fingerprint: true
            }
        }

        stage('Publicar en Artifactory (REST)') {
            steps {
                withCredentials([usernamePassword(credentialsId: env.ART_CRED_ID, usernameVariable: 'ART_USER', passwordVariable: 'ART_PASS')]) {
                    script {
                        // 1) Resolver versión Maven
                        def raw = bat(returnStdout: true, script: 'mvn -q -DforceStdout help:evaluate -Dexpression=project.version').trim()
                        def version = raw.readLines()
                            .findAll { it?.trim() && !it.startsWith('Picked up') && !it.startsWith('WARNING') }
                            .last().trim()
                        echo "Versión detectada: ${version}"

                        // 2) Elegir repo
                        def targetRepo = version.contains('SNAPSHOT') ? env.ART_SNAPSHOT_REPO : env.ART_RELEASE_REPO
                        echo "Repositorio destino: ${targetRepo}"

                        // 3) Encontrar JAR y subirlo con curl
                        //    (en Windows, extraemos nombre del archivo con variables de batch)
                        bat """
                        setlocal EnableDelayedExpansion
                        for %%f in (target\\*.jar) do (
                          set JAR=%%f
                          set JAR_NAME=%%~nxf
                        )
                        echo JAR local: %JAR%
                        echo Nombre: %JAR_NAME%

                        curl -u %ART_USER%:%ART_PASS% -X PUT -T "%JAR%" ^
                          "${ART_URL}/${targetRepo}/${PROJECT_NAME}/${version}/%JAR_NAME%"

                        endlocal
                        """
                    }
                }
            }
        }
    }

    post {
        success { echo "✅ Pipeline completado y artefacto publicado en Artifactory." }
        failure { echo "❌ Error en el pipeline. Revisa la consola para detalles." }
    }
}
