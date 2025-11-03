pipeline {
    agent any

    options {
        timestamps()
        buildDiscarder(logRotator(numToKeepStr: '10'))
        disableConcurrentBuilds()
    }

    tools {
        jdk   'JDK21'         // Debe existir en Global Tool Configuration
        maven 'Maven_3.9.x'   // Debe existir en Global Tool Configuration
    }

    environment {
        PROJECT_NAME      = 'loginapp'
        ART_SERVER_ID     = 'artifactory-local'     // el Server ID que configuraste
        ART_RELEASE_REPO  = 'libs-release-local'
        ART_SNAPSHOT_REPO = 'libs-snapshot-local'
    }

    stages {
        stage('Ping Artifactory') {
            steps {
                script {
                    // Toma la instancia que ya registraste en Manage Jenkins → Configure System
                    def server = rtServer(id: env.ART_SERVER_ID)
                    def ok = server.ping()
                    echo "Ping Artifactory: ${ok}"
                }
            }
        }

        stage('Checkout') {
            steps {
                echo "=== Clonando el repositorio desde GitHub ==="
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: '*/main']], // cambia a '*/master' si corresponde
                    userRemoteConfigs: [[
                        url: 'https://github.com/DanielCruzCavieres/loginapp.git'
                        // credentialsId: 'github-pat'
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
                    // Obtiene version del POM (filtrando ruido)
                    def raw = bat(returnStdout: true, script: 'mvn -q -DforceStdout help:evaluate -Dexpression=project.version').trim()
                    def version = raw.readLines().findAll{ it?.trim() && !it.startsWith('Picked up') && !it.startsWith('WARNING') }.last().trim()
                    echo "Versión detectada: ${version}"

                    def targetRepo = version.contains('SNAPSHOT') ? env.ART_SNAPSHOT_REPO : env.ART_RELEASE_REPO
                    echo "Repositorio destino: ${targetRepo}"

                    def server = rtServer(id: env.ART_SERVER_ID)

                    // Sube todos los JAR desde target/ a: <repo>/<proyecto>/<version>/
                    def uploadSpec = """{
                      "files": [
                        {
                          "pattern": "target/*.jar",
                          "target": "${targetRepo}/${env.PROJECT_NAME}/${version}/"
                        }
                      ]
                    }"""

                    echo "=== Subiendo artefactos a Artifactory ==="
                    server.upload(spec: uploadSpec)

                    // (Opcional) Publicar Build Info
                    def buildInfo = rtBuildInfo()           // build-info vacío
                    server.publishBuildInfo(buildInfo)

                    echo "✅ Publicación en Artifactory completada."
                }
            }
        }
    }

    post {
        success { echo "✅ Pipeline completado correctamente. Build exitoso." }
        failure { echo "❌ Error en el pipeline. Revisa la consola para detalles." }
    }
}
