pipeline {
    agent any

    environment {
        AWS_REGION = 'us-east-2'
        DOCKER_REPO = "nayeem2nayeem/cloudcare-app"
    }

    parameters {
        booleanParam(name: 'DESTROY', defaultValue: false, description: 'Check this to destroy infrastructure after deployment')
    }

    stages {

        stage('Checkout') {
            steps {
                echo "📦 Checking out code from GitHub..."
                withCredentials([usernamePassword(
                    credentialsId: '43c562fb-44ae-40c7-ad53-6c33df458893',
                    usernameVariable: 'GIT_USER',
                    passwordVariable: 'GIT_PASS'
                )]) {
                    git branch: 'main', url: "https://${GIT_USER}:${GIT_PASS}@github.com/Nayeem-2-Nayeem/cloudcare-devops.git"
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "🐳 Building Docker image..."
                script {
                    def tag = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
                    env.IMAGE_TAG = "${DOCKER_REPO}:${tag}"
                    env.LATEST_TAG = "${DOCKER_REPO}:latest"
                }
                sh '''
                  docker builder prune -f
                  docker build -t $IMAGE_TAG -f Dockerfile ./app
                  docker tag $IMAGE_TAG $LATEST_TAG
                '''
            }
        }

        stage('Push Docker Image') {
            steps {
                echo "📤 Pushing image to Docker Hub..."
                withCredentials([usernamePassword(
                    credentialsId: 'b151f1df-de8e-4d8d-ab4c-d644e2ef4d95',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh '''
                      echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                      docker push $IMAGE_TAG
                      docker push $LATEST_TAG
                      docker logout
                    '''
                }
            }
        }

        stage('Deploy Infrastructure (Terraform)') {
            steps {
                echo "🚀 Deploying AWS Infrastructure..."
                withCredentials([
                    string(credentialsId: 'aws_key', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'aws_secret_key', variable: 'AWS_SECRET_ACCESS_KEY'),
                    string(credentialsId: 'db_password', variable: 'DB_PASSWORD')
                ]) {
                    sh '''
                      cd terraform
                      terraform init -input=false
                      terraform validate
                      terraform apply -auto-approve \
                        -var "key_name=cloudcare-key" \
                        -var "db_password=${DB_PASSWORD}"
                    '''
                }
            }
        }

        stage('Fetch EC2 Public IP') {
            steps {
                echo "🌐 Fetching EC2 Public IP from Terraform output..."
                script {
                    env.EC2_IP = sh(
                        script: "cd terraform && terraform output -raw ec2_public_ip",
                        returnStdout: true
                    ).trim()
                    echo "✅ EC2 Public IP: ${env.EC2_IP}"
                }
            }
        }

        stage('Configure EC2 with Ansible') {
            steps {
                echo "⚙️ Configuring EC2 instance using Ansible..."
                withCredentials([sshUserPrivateKey(
                    credentialsId: 'ssh-key',
                    keyFileVariable: 'SSH_KEY'
                )]) {
                    sh '''
                      cd ansible
                      echo "[ec2]" > hosts
                      echo "$EC2_IP ansible_user=ubuntu ansible_ssh_private_key_file=$SSH_KEY" >> hosts
                      ansible-playbook -i hosts setup.yml -e "docker_image=$LATEST_TAG"
                    '''
                }
            }
        }

        stage('Post-Deployment Verification') {
            steps {
                echo "🧪 Verifying application deployment..."
                sh '''
                  sleep 10
                  curl -I http://$EC2_IP && echo "✅ App is up!" || echo "⚠️ App might be down. Check manually!"
                '''
            }
        }

        stage('Destroy Infrastructure (optional)') {
            when {
                expression { return params.DESTROY == true }
            }
            steps {
                echo "🧹 Destroying AWS Infrastructure..."
                withCredentials([
                    string(credentialsId: 'aws_key', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'aws_secret_key', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    sh '''
                      cd terraform
                      terraform destroy -auto-approve
                    '''
                }
            }
        }
    }

    post {
        success {
            echo "✅ Pipeline completed successfully!"
        }
        failure {
            echo "❌ Pipeline failed! Check logs for details."
        }
        always {
            echo "🏁 Pipeline finished running."
        }
    }
}
