pipeline {
    agent any

    options {
        timestamps()
        buildDiscarder(logRotator(numToKeepStr: '10'))
        disableConcurrentBuilds()
    }

    tools {
        // Deben coincidir con los nombres definidos en Manage Jenkins > Tools
        jdk 'JDK21'
        maven 'Maven_3.9.x'
    }

    environment {
        PROJECT_NAME = "loginapp"
    }

    stages {

        stage('Checkout') {
            steps {
                echo "=== Clonando el repositorio desde GitHub ==="
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: '*/main']],  // Cambia a '*/master' si tu rama es master
                    userRemoteConfigs: [[
                        url: 'https://github.com/DanielCruzCavieres/loginapp.git'
                        // credentialsId: 'github-pat'  // Descomenta si el repo fuera privado
                    ]]
                ])
            }
        }

        stage('Compilación y Test') {
            steps {
                echo "=== Ejecutando compilación Maven ==="
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
                echo "=== Empaquetando el proyecto ==="
                bat 'mvn -U -e -DskipTests package'
            }
        }

        stage('Archivar Artefactos') {
            steps {
                echo "=== Archivando artefactos generados ==="
                archiveArtifacts artifacts: 'target/**/*.jar, target/**/*.war', fingerprint: true
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
