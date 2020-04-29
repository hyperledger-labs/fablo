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
  volumes:
  - name: artifacts
    emptyDir: {}
  containers:
  - name: npm
    image: node:8-jessie
    command:
    - cat
    tty: true
    volumeMounts:
    - mountPath: /artifacts
      name: artifacts
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
  runOnNewPod("front", uuid, {
    container('npm') {
      stage('NPM') {
          sh "npm install"
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
