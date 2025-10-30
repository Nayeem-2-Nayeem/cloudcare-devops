pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "nayeem2nayeem/cloudcare-app:latest"
        AWS_REGION = "ap-south-1"
    }

    stages {

        stage('Checkout') {
            steps {
                echo '📦 Checking out code from GitHub...'
                git branch: 'main', url: 'https://github.com/Nayeem-2-Nayeem/cloudcare-devops.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                echo '🐳 Building Docker image...'
                sh 'docker build -t $DOCKER_IMAGE .'
            }
        }

        stage('Push Docker Image') {
            steps {
                echo '📤 Pushing image to Docker Hub...'
                withCredentials([string(credentialsId: 'b1511fdf-de8e-4d8d-ab4c-d644e2ef4d95', variable: 'DOCKER_PASS')]) {
                    sh '''
                        echo $DOCKER_PASS | docker login -u nayeem2nayeem --password-stdin
                        docker push $DOCKER_IMAGE
                    '''
                }
            }
        }

        stage('Deploy Infrastructure') {
            steps {
                echo '☁️ Deploying AWS infrastructure with Terraform...'
                dir('terraform') {
                    withCredentials([
                        string(credentialsId: 'aws_key', variable: 'AWS_ACCESS_KEY_ID'),
                        string(credentialsId: 'aws_secret_key', variable: 'AWS_SECRET_ACCESS_KEY')
                    ]) {
                        sh '''
                            export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                            export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
                            terraform init
                            terraform apply -auto-approve -lock=false \
                              -var db_password=YourStrongPass123 \
                              -var key_name=dy
                        '''
                    }
                }
            }
        }

        stage('Fetch EC2 Public IP') {
            steps {
                echo '🌐 Fetching EC2 public IP from Terraform output...'
                dir('terraform') {
                    script {
                        env.EC2_PUBLIC_IP = sh(script: "terraform output -raw ec2_public_ip", returnStdout: true).trim()
                        echo "✅ EC2 Public IP: ${env.EC2_PUBLIC_IP}"
                    }
                }
            }
        }

        stage('Configure EC2 with Ansible') {
            steps {
                echo '⚙️ Configuring EC2 instance with Ansible...'
                withCredentials([sshUserPrivateKey(credentialsId: '43c562fb-44ae-40c7-ad53-6c33df458893', keyFileVariable: 'SSH_KEY')]) {
                    sh '''
                        ansible-playbook -i "${EC2_PUBLIC_IP}," \
                          --private-key $SSH_KEY \
                          ansible/playbook.yml
                    '''
                }
            }
        }
    }

    post {
        success {
            echo '✅ Pipeline completed successfully!'
        }
        failure {
            echo '❌ Pipeline failed! Check logs for details.'
        }
        always {
            echo '🏁 Pipeline finished running.'
        }
    }
}
