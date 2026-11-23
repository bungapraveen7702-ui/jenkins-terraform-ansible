pipeline {
    agent any

    environment {
        AWS_DEFAULT_REGION = 'ap-southeast-2'
        SSH_CIDR = '103.49.54.125/32'
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Terraform Init') {
            steps {
                dir('terraform') {
                    withCredentials([[
                        $class: 'AmazonWebServicesCredentialsBinding',
                        credentialsId: 'aws-credentials'
                    ]]) {
                        sh 'terraform init'
                    }
                }
            }
        }

        stage('Terraform Validate') {
            steps {
                dir('terraform') {
                    sh 'terraform validate'
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                dir('terraform') {
                    withCredentials([[
                        $class: 'AmazonWebServicesCredentialsBinding',
                        credentialsId: 'aws-credentials'
                    ]]) {
                        sh '''
                          terraform plan \
                            -var="ssh_cidr=${SSH_CIDR}"
                        '''
                    }
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                dir('terraform') {
                    withCredentials([[
                        $class: 'AmazonWebServicesCredentialsBinding',
                        credentialsId: 'aws-credentials'
                    ]]) {
                        sh '''
                          terraform apply -auto-approve \
                            -var="ssh_cidr=${SSH_CIDR}"
                        '''
                    }
                }
            }
        }

        stage('Get EC2 IP') {
            steps {
                dir('terraform') {
                    withCredentials([[
                        $class: 'AmazonWebServicesCredentialsBinding',
                        credentialsId: 'aws-credentials'
                    ]]) {
                        script {
                            env.EC2_IP = sh(
                                script: 'terraform output -raw public_ip',
                                returnStdout: true
                            ).trim()
                        }
                    }
                }

                echo "EC2 IP: ${EC2_IP}"
            }
        }

        stage('Configure EC2 using Ansible') {
            steps {
                sshagent(credentials: ['ec2-ssh-key']) {
                    script {
                        sh '''
                          mkdir -p ansible
                          echo "${EC2_IP} ansible_user=ubuntu ansible_ssh_private_key_file=/tmp/ec2_key ansible_ssh_common_args='-o StrictHostKeyChecking=no'" > ansible/inventory
                        '''

                        sh '''
                          ansible-playbook \
                            -i ansible/inventory \
                            ansible/playbook.yml \
                            --private-key /tmp/ec2_key
                        '''
                    }
                }
            }
        }
    }
}