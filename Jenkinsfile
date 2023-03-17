@Library('mss-sharedlibrary') _

pipeline {
  //agent any
  //kubectl -n default create deploy node-app --image siddharth67/node-service:v1
  //kubectl -n default expose deploy node-app --name node-service --port 5000
   agent{
      label "node01"
       }

       options {
         buildDiscarder logRotator( artifactDaysToKeepStr: '1', artifactNumToKeepStr: '1', daysToKeepStr: '1', numToKeepStr: '1')
         timestamps()
         //skipDefaultCheckout(true)
        }

     parameters {
          choice choices: ['main', 'mss-warmart-prod', 'owasp_zap_scanning', 'slack_success_failed_demo', 'lab_mutation_Test', 'walmart-dev-mss', 'dependencyCheckTrivyOpenContest'], description: 'This is choice paramerized job', name: 'BranchName'
          string defaultValue: 'Eghosa DevOps', description: 'please developer select the person\' name', name: 'personName'
        }

  tools{
      maven 'demo-maven:3.8.6'
      }

 environment {
            DEPLOY = "${env.BRANCH_NAME == "python-dramed" || env.BRANCH_NAME == "master" ? "true" : "false"}"
            NAME = "${env.BRANCH_NAME == "python-dramed" ? "example" : "example-staging"}"
            VERSION = "${env.BUILD_ID}"
            REGISTRY = 'eagunuworld/mongodb-springboot-app'
            imageName = "eagunuworld/mongodb-springboot-app:${BUILD_ID}"
            REGISTRY_CREDENTIAL = 'eagunuworld_dockerhub_creds'
            deploymentName = "mss-warmart-prod-pod"
            conName = "mss-warmart-prod-con"
            svcName = "mss-warmart-prod-svc"
            svcPort = "30005"
            jenkinsURL = "http://34.125.84.141"
            serverURL = "http://34.174.188.235"
          }

  stages {
    stage('Build Artifact - Maven') {
      steps {
         //cleanWs()
        sh "mvn clean package -DskipTests=true"
        archiveArtifacts 'target/*.jar' 
      }
    }

    stage('SonarQube - SAST') {
      steps {
        withSonarQubeEnv('sonarQube') {
          sh "mvn clean package sonar:sonar -Dsonar.projectKey=mss-warmart-prod -Dsonar.host.url=http://34.125.175.232:9000 -Dsonar.login=sqp_0da2b86135cf6f23388b6642a6aa68d64f8ac183"
         }
        // timeout(time: 2, unit: 'MINUTES') {
        //   script {
        //     waitForQualityGate abortPipeline: true
        //   }
        // }
      }
    }

   stage('CodesVulnerabilityScanning') {    //(Pit mutation) is a plugin in jenkis and plugin was added in pom.xml line 68
      steps {
         parallel(
               "PitMutationTestReport": {
                    sh "mvn org.pitest:pitest-maven:mutationCoverage"  //section 3 video
                  },
                  "DependencyCheckReport": {
                      sh "ls -lart"    //OWASP Dependency check plugin is required via jenkins
                   },
                 "EnvironmentVariables": {
                  sh "printenv"
               }
             )
         }
      }

  stage('ScanningBasedPushImage') {  
      steps {
         parallel(
               "ScanningAppImage": {
                 withCredentials([string(credentialsId: 'eagunuworld_dockerhub_creds', variable: 'eagunuworld_dockerhub_creds')])  {
                   sh "docker login -u eagunuworld -p ${eagunuworld_dockerhub_creds} "
                   sh 'docker build -t ${REGISTRY}:${VERSION} .'
                }
                sh 'docker push ${REGISTRY}:${VERSION}' 
               },
                "BasedImage": {
                sh "sudo rm -rf trivy"
                }
             )
         }
      }

  //  stage('Push Docker Image To DockerHub') {
  //       steps {
  //           withCredentials([string(credentialsId: 'eagunuworld_dockerhub_creds', variable: 'eagunuworld_dockerhub_creds')])  {
  //             sh "docker login -u eagunuworld -p ${eagunuworld_dockerhub_creds} "
  //             sh 'docker build -t ${REGISTRY}:${VERSION} .'
  //               }
  //               sh 'docker push ${REGISTRY}:${VERSION}'
  //           }
  //         }

    stage('ManifestK8SVulnerabilitYScanning') {  
      steps {
         parallel(
               "ScanningAppImage": {
                    sh "bash trivy-k8s-scan.sh" 
                  },
                  "ScanningDeploymentFile": {
                    sh 'docker run --rm -v $(pwd):/project openpolicyagent/conftest test --policy opa-k8s-security.rego mss-north-west-deploy.yml'
                   },
                  //  "BasedImage": {
                  //   sh "docker run --rm -v $(pwd):/project openpolicyagent/conftest test --policy opa-docker-security.rego Dockerfile"
                  //  },
                 "kubesec Scannning": {
                  sh 'bash kubesec-scan.sh'
                },
                "Master": {
               sh "bash cis-benchmark-master.sh"
              },
              "Etcd": {
               sh "bash cis-benchmark-etcd.sh"
             },
             "Kubelet": {
              sh "bash cis-benchMark-kubelet.sh"
             }
           )
         }
      }

    stage('comSecretMongodb') {
      steps {
        parallel(
          "createconfigMap": {
              sh "kubectl apply -f mss-north-west-cm.yml"
            },
          "mongodbDeployment": {
              sh "kubectl apply -f  mss-north-mongodb-statefulset.yml"
          },
          "createSecret": {
              sh "kubectl apply -f mss-north-west-secret.yml"
          }
        )
      }
    }

    stage('PleaseApprove West-Prod?') {
      steps {
        timeout(time: 2, unit: 'DAYS') {
          input 'Do you want to Approve  West Production Environment/Namespace Deployment?'
        }
      }
    }

 stage('west-prod') {
      steps {
        parallel(
          "Deployment": {
              sh "sed -i 's#replace#${REGISTRY}:${VERSION}#g' mss-north-west-deploy.yml"
              sh "kubectl -n west-prod apply -f mss-north-west-deploy.yml"
            },
          "Rollout West Status": {
              sh "kubectl apply -f mss-north-svc.yml"
          }
        )
      }
    }

   stage('RemoveResources') {  
      steps {
         parallel(
               "KillProcesses": {
                    sh "printenv" 
                  },
                 "RemoveDockerImages": {
                  sh 'docker rmi  $(docker images -q)'
                }
             )
         }
      }

  } // pipeline stages end here 
   post {
        always {
        junit 'target/surefire-reports/*.xml'
        jacoco execPattern: 'target/jacoco.exec'
        pitmutation mutationStatsFile: '**/target/pit-reports/**/mutations.xml'
        dependencyCheckPublisher pattern: 'target/dependency-check-report.xml'
       }
      success {
      script {
        /* Use slackNotifier.groovy from shared library and provide current build result as parameter */  
        env.failedStage = "none"
        env.emoji = ":white_check_mark: :tada: :thumbsup_all:"
        slackcodenotifications currentBuild.result
      }
    }
  }
}
