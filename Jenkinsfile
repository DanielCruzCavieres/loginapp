pipeline {
  agent any

  tools {
    jdk   'JDK21'          // ← EXACTO como aparece en Global Tool Configuration
    maven 'Maven_3.9.x'   // ← EXACTO
  }

  options { timestamps() }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Ping Artifactory') {
      steps {
        script {
          def server = rtServer(id: 'artifactory-local')  // debe coincidir con tu Server ID
          echo "Ping Artifactory: ${server.ping()}"
        }
      }
    }

    stage('Build & Deploy JAR') {
      steps {
        script {
          def resolver = rtMavenResolver(
            serverId:   'artifactory-local',
            releaseRepo: 'libs-release',        // usa tus repos virtuales
            snapshotRepo:'libs-snapshot'
          )
          def deployer = rtMavenDeployer(
            serverId:   'artifactory-local',
            releaseRepo: 'libs-release-local',
            snapshotRepo:'libs-snapshot-local'
          )
          def mvn = rtMaven(
            tool: 'Maven_3.9.11',              // ← mismo nombre de arriba
            resolverId: resolver.getId(),
            deployerId: deployer.getId()
          )

          mvn.run pom: 'pom.xml', goals: 'clean deploy -DskipTests'
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
