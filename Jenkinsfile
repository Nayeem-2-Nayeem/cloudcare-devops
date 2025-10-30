pipeline {
    agent any

    environment {
        AWS_REGION = 'us-east-2'
        DOCKER_IMAGE = "nayeem2nayeem/cloudcare-app:latest"
    }

    stages {

        stage('Checkout') {
            steps {
                echo "📦 Checking out code from GitHub..."
                withCredentials([usernamePassword(
                    credentialsId: '43c562fb-44ae-40c7-ad53-6c33df458893', // ✅ GitHub credentials
                    usernameVariable: 'GIT_USER',
                    passwordVariable: 'GIT_PASS'
                )]) {
                    git branch: 'main', url: "https://${GIT_USER}:${GIT_PASS}@github.com/Nayeem2Nayeem/cloudcare-devops.git"
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "🐳 Building Docker image..."
                sh '''
                  docker build -t $DOCKER_IMAGE .
                '''
            }
        }

        stage('Push Docker Image') {
            steps {
                echo "📤 Pushing image to Docker Hub..."
                withCredentials([usernamePassword(
                    credentialsId: 'b151f1df-de8e-4d8d-ab4c-d644e2ef4d95', // ✅ Docker Hub credentials
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh '''
                      echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                      docker push $DOCKER_IMAGE
                      docker logout
                    '''
                }
            }
        }

        stage('Deploy Infrastructure') {
            steps {
                echo "🚀 Deploying AWS Infrastructure using Terraform..."
                withCredentials([
                    string(credentialsId: 'aws_key', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'aws_secret_key', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    sh '''
                      cd terraform
                      terraform init
                      terraform apply -auto-approve \
                        -var "key_name=cloudcare-key" \
                        -var "db_password=cloudcare123"
                    '''
                }
            }
        }

        stage('Fetch EC2 Public IP') {
            steps {
                echo "🌐 Fetching EC2 public IP..."
                script {
                    env.EC2_IP = sh(
                        script: "aws ec2 describe-instances --region $AWS_REGION --query 'Reservations[*].Instances[*].PublicIpAddress' --output text",
                        returnStdout: true
                    ).trim()
                    echo "✅ EC2 Public IP: ${env.EC2_IP}"
                }
            }
        }

        stage('Configure EC2 with Ansible') {
            steps {
                echo "⚙️ Configuring EC2 instance with Ansible..."
                sh '''
                  cd ansible
                  echo "[ec2]" > hosts
                  echo "$EC2_IP ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/id_rsa" >> hosts
                  ansible-playbook -i hosts setup.yml
                '''
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
