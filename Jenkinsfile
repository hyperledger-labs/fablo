@Library('sml-common')

def podTemplateYaml() {
  def serviceAccount = "jenkins"

  return """
apiVersion: v1
kind: Pod
spec:
  metadata:
    namespace: building
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: cloud.google.com/gke-nodepool
            operator: In
            values:
            - building-pool
    podAntiAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
      - topologyKey: "kubernetes.io/hostname"
        labelSelector:
          matchExpressions:
          - key: jenkins
            operator: In
            values:
            - slave
  tolerations:
  - key: "building"
    operator: "Equal"
    value: "true"
    effect: "NoSchedule"
  containers:
  - name: dind
    image: docker:18.09-dind
    securityContext:
        privileged: true
        runAsUser: 0
"""
}

def runOnNewPod(String labelBase, String uuid, Closure closure) {
  def label = "${labelBase}-${uuid}"
  podTemplate(label: label, yaml: podTemplateYaml()) {
    timeout(20) {
      node(label) {
        try {
          ansiColor('xterm') {
            stage("Initialize") {
              checkout scm
              dockerTag = getDockerTag()
            }

            closure()
          }
        } catch (e) {
          currentBuild.result = 'FAILED'
          throw e
        }
      }
    }
  }
}

String getDockerTag() {
  return sh(script: 'git describe --always --tags', returnStdout: true)?.trim()
}

def uuid = UUID.randomUUID().toString()

try {
  node ('master') {
    slackSend (color: '#aaaaaa', message: "🏭 Fabrikka tests started <${BUILD_URL}|${BUILD_TAG}>")
  }
  runOnNewPod("fabrikka", uuid, {
    container('dind') {

      stage("Install libs") {
        sh "apk add --no-cache nodejs npm docker-cli"
        sh "npm install"
      }
      stage ("Generate sample network") {
        sh "./fabrikka.sh build"
        sh "./fabrikka.sh generate samples/fabrikkaConfig-1org-1channel-1chaincode.json __jenkinstmp__"
        sh "ls -lh __jenkinstmp__/*"
      }
      stage('Test generators') {
        sh "CI=true npm run test:e2e"
      }
      stage('Lint') {
        sh "npm run lint"
      }

      stage("Test simple network") {
        try {
          sh "e2e-network/test-01-simple.sh"
        } finally {
          archiveArtifacts artifacts: 'e2e-network/test-01-simple.sh.logs/*', fingerprint: true
        }
      }

      stage("Test RAFT network (2 orgs)") {
        try {
          sh "e2e-network/test-02-raft-2orgs.sh"
        } finally {
          archiveArtifacts artifacts: 'e2e-network/test-02-raft-2orgs.sh.logs/*', fingerprint: true
        }
      }

    }
  })
} catch (e) {
  currentBuild.result = 'FAILURE'
}
 finally {
  node ('master') {
    if (currentBuild.result == "FAILURE") {
      color = "#FF0000"
      slackSend (color: '#df000f', message: "🛑 Fabrikka tests failed <${BUILD_URL}|${BUILD_TAG}>")
    } else {
      color = "#00FF00"
      slackSend (color: '#0bbd00', message: "🏭 Fabrikka tests succeeded <${BUILD_URL}|${BUILD_TAG}>")
    }
  }
}
