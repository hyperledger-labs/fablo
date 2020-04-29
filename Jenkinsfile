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
      stage('NPM') {
        sh "apk add --no-cache nodejs npm"
        sh "npm install"
      }
      stage("Yeoman") {
        sh "docker build --tag e2e-generate e2e-generate && docker run -v \"$WORKSPACE:/fabrikka\" e2e-generate"
      }
      stage('Test') {
        sh "CI=true npm test"
      }
      stage('Lint') {
          sh "npm run lint"
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
    } else {
      color = "#00FF00"
    }
    slackSend (color: color, message: "Build ${BUILD_TAG} finished - ${currentBuild.currentResult}\n${BUILD_URL}")
  }
}
