pipeline {
    agent any

    options {
        timestamps()
        buildDiscarder(logRotator(numToKeepStr: '10'))
        disableConcurrentBuilds()
    }

    tools {
        // Deben coincidir con los nombres definidos en Manage Jenkins > Global Tool Configuration
        jdk   'JDK21'
        maven 'Maven_3.9.x'
    }

    environment {
        PROJECT_NAME        = 'loginapp'
        // Config Artifactory (ajusta si cambiaste nombres)
        ART_SERVER_ID       = 'artifactory-local'
        ART_RELEASE_REPO    = 'libs-release-local'
        ART_SNAPSHOT_REPO   = 'libs-snapshot-local'
    }

    stages {

        stage('Checkout') {
            steps {
                echo "=== Clonando el repositorio desde GitHub ==="
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: '*/main']],  // Cambia a '*/master' si corresponde
                    userRemoteConfigs: [[
                        url: 'https://github.com/DanielCruzCavieres/loginapp.git'
                        // credentialsId: 'github-pat'  // Descomenta si tu repo es privado
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
                    echo "=== Publicando resultados de tests ==="
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
                echo "=== Archivando artefactos generados ==="
                archiveArtifacts artifacts: 'target/**/*.jar, target/**/*.war', fingerprint: true
            }
        }

        stage('Publicar en Artifactory') {
            steps {
                script {
                    echo "=== Resolviendo versión Maven para decidir el repositorio destino ==="
                    // Obtiene la versión del POM de forma limpia
                    def raw = bat(returnStdout: true, script: 'mvn -q -DforceStdout help:evaluate -Dexpression=project.version').trim()
                    // En algunos entornos Maven imprime líneas extra; nos quedamos con la última no vacía
                    def version = raw.readLines().findAll { it?.trim() && !it.startsWith('Picked up') && !it.startsWith('WARNING') }.last().trim()
                    echo "Versión detectada: ${version}"

                    def targetRepo = version.contains('SNAPSHOT') ? env.ART_SNAPSHOT_REPO : env.ART_RELEASE_REPO
                    echo "Repositorio destino: ${targetRepo}"

                    def server = Artifactory.server(env.ART_SERVER_ID)

                    // Estructura de destino típica (puedes simplificar a solo targetRepo/)
                    // Quedará: libs-xxx-local/loginapp/<version>/<archivo>.jar
                    def uploadSpec = """{
                      "files": [
                        {
                          "pattern": "target/*.jar",
                          "target": "${targetRepo}/${env.PROJECT_NAME}/${version}/"
                        }
                      ]
                    }"""

                    echo "=== Subiendo artefactos a Artifactory ==="
                    server.upload(uploadSpec)

                    // (Opcional) Publicar Build Info en Artifactory
                    def buildInfo = Artifactory.newBuildInfo()
                    buildInfo.env.capture = true
                    server.publishBuildInfo(buildInfo)

                    echo "✅ Publicación en Artifactory completada."
                }
            }
        }
    }

    post {
        success {
            echo "✅ Pipeline completado correctamente. Build exitoso."
        }
        failure {
            echo "❌ Error en el pipeline. Revisa la consola para detalles."
        }
    }
}
