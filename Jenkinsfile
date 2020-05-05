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
    timeout(10) {
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
    slackSend (color: '#333FFF', message: "Build ${BUILD_TAG} started\n${BUILD_URL}")
  }
  runOnNewPod("fabrikka", uuid, {
    container('dind') {
      stage("Install required libs") {
        // nodejs npm - to run js tests
        // bash - to run generated scripts
        // the rest - to install docker compose (later)
        sh "apk add --no-cache nodejs npm bash python python-dev py-pip build-base libffi-dev openssl-dev"
      }
      parallel(
        failFast: false,
        'Install docker-compose': {
          stage('Install docker-compose') {
            sh "pip install docker-compose"
          }
        },
        'JS Tests': {
          stage('NPM') {
            sh "npm install"
          }
          stage("Yeoman") {
            sh "npm run test:e2e-generate"
          }
          stage('Test') {
            sh "CI=true npm run test:unit"
            sh "CI=true npm run test:e2e"
          }
          stage('Lint') {
            sh "npm run lint"
          }
        }
      )

      parallel(
        failFast: true,
        'Start network 01': {
          sh "e2e/start-network.sh"
        },
        'Test network 01': {
          stage('Wait for services') {
            sh "e2e/wait-for-network.sh"
          }
          stage('Down network') {
            sh "e2e/down-network.sh"
          }
        }
      )
    }
  })
} catch (e) {
  currentBuild.result = 'FAILURE'
}
 finally {
  node ('master') {
    if (currentBuild.result == "FAILURE") {
      color = "#FF0000"
    } else {
      color = "#00FF00"
    }
    slackSend (color: color, message: "Build ${BUILD_TAG} finished - ${currentBuild.currentResult}\n${BUILD_URL}")
  }
}
