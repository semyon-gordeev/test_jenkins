pipeline {
  agent any
  options {
    timeout(time: 1800, unit: 'SECONDS')
  }
  environment {
    APP = 'yourcluster'
    IMAGE_NAME = "${ENV}-${APP}"
    IMAGE_TAG = "latest"
  }
  stages {
    stage('build docker image') {
      steps {
        sh "\$(aws ecr get-login --no-include-email --region ${REGION})"
        script {
          docker.withRegistry("https://${AWS_ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${IMAGE_NAME}") {
            def backendImage = docker.build("${IMAGE_NAME}:${IMAGE_TAG}", "--pull .")
            backendImage.push()
          }
        }
      }
    }
    stage('deploy to ECS') {
      steps {
        script {
          try {
            sh '''#!/bin/bash -ex
              CLUSTER=${ENV}-${APP}
              TASK=${ENV}-${APP}-td
              FAMILY=${TASK}
              SERVICE_NAME=${ENV}-${APP}-service
              aws ecs register-task-definition --family ${FAMILY} --cli-input-json file://${WORKSPACE}/configs/ecs.json --region ${REGION}
              REVISION=`aws ecs describe-task-definition --task-definition ${TASK} --region ${REGION} | jq .taskDefinition.revision`

              DESIRED_COUNT=`aws ecs describe-services --services ${SERVICE_NAME} --cluster ${CLUSTER} --region ${REGION} | jq .services[].desiredCount`
              aws ecs update-service --cluster ${CLUSTER} --region ${REGION} --service ${SERVICE_NAME} --task-definition ${FAMILY}:${REVISION} --desired-count ${DESIRED_COUNT}

              aws ecs wait services-stable --cluster ${CLUSTER} --region ${REGION} --services ${SERVICE_NAME}
            '''
          }
          catch (exc) {
            currentBuild.result = 'UNSTABLE'
          }
        }
      }
    }
  }
//  post {
//    success {
//      slackSend color: "good", message: "SUCCESS: `${JOB_NAME}` #${BUILD_NUMBER}:\n${BUILD_URL}\nChanges: \n${getChangelog()}"
//    }
//    failure {
//      slackSend color: "danger", message: "FAILURE: `${JOB_NAME}` #${BUILD_NUMBER}:\n${BUILD_URL}"
//    }
//    unstable {
//      slackSend color: "warning", message: "MIGRATIONS FAIL: `${JOB_NAME}` #${BUILD_NUMBER}:\n${BUILD_URL}"
//    }
//  }
}

//@NonCPS
//def getChangelog() {
//    def changes = ""
//    def repo_prefixes = ["https://github.com/semyon-gordeev/test_jenkins"]
//    def changeLogSets = currentBuild.rawBuild.changeSets
//    for (int i = 0; i < changeLogSets.size(); i++) {
//        def ent = changeLogSets[i].items
//        for (int j = 0; j < ent.length; j++) {
//            changes += " - <${repo_prefixes[i]}/commit/${ent[j].commitId}|${ent[j].commitId.take(6)}> | ${ent[j].msg} [${ent[j].author}]\n"
//        }
//    }
//    if (!changes) {
//        changes = " - No changes"
//    }
//    return changes
//}