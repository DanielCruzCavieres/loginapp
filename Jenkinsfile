pipeline {
  agent any
  tools { 
    jdk 'jdk21'                 // o el nombre exacto que registraste
    maven 'Maven_3.9.x'         // idem
  }

  options { timestamps() }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Ping Artifactory') {
      steps {
        script {
          def server = rtServer(id: 'artifactory-local')
          echo "Ping Artifactory: ${server.ping()}"
        }
      }
    }

    stage('Build & Deploy JAR') {
      steps {
        script {
          def server   = rtServer(id: 'artifactory-local')

          // Resolver: desde dónde bajar deps
          def resolver = rtMavenResolver(
            serverId: 'artifactory-local',
            releaseRepo: 'libs-release',        // virtual o remoto si usas uno
            snapshotRepo: 'libs-snapshot'       // virtual/remoto equivalente
          )

          // Deployer: a dónde subir tu JAR
          def deployer = rtMavenDeployer(
            serverId: 'artifactory-local',
            releaseRepo: 'libs-release-local',
            snapshotRepo: 'libs-snapshot-local'
          )

          def mvn = rtMaven(
            tool: 'Maven_3.9.x',
            resolverId: resolver.getId(),
            deployerId: deployer.getId()
          )

          // Construye y publica (usa distribución release/snapshot según tu versión)
          mvn.run pom: 'pom.xml', goals: 'clean deploy -DskipTests'

          // (Opcional) publica build-info
          rtPublishBuildInfo(serverId: 'artifactory-local')
        }
      }
    }
  }

  post {
    success { echo '✅ JAR desplegado en Artifactory.' }
    failure { echo '❌ Falló el pipeline. Revisa la consola.' }
  }
}
