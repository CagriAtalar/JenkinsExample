pipeline {
    agent any
    
    environment {
        DOCKER_REGISTRY = 'localhost:5000'
        APP_NAME = 'counter-app'
        NAMESPACE = 'counter-app'
        MINIKUBE_IP = '192.168.49.2'
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out code...'
                checkout scm
            }
        }
        
        stage('Build Images') {
            parallel {
                stage('Build Backend') {
                    steps {
                        script {
                            echo 'Building backend Docker image...'
                            sh '''
                                cd backend
                                docker build -t counter-backend:${BUILD_NUMBER} .
                                docker tag counter-backend:${BUILD_NUMBER} counter-backend:latest
                            '''
                        }
                    }
                }
                stage('Build Frontend') {
                    steps {
                        script {
                            echo 'Building frontend Docker image...'
                            sh '''
                                cd frontend
                                docker build -t counter-frontend:${BUILD_NUMBER} .
                                docker tag counter-frontend:${BUILD_NUMBER} counter-frontend:latest
                            '''
                        }
                    }
                }
            }
        }
        
        
        
        stage('Deploy to Minikube') {
            steps {
                script {
                    echo 'Deploying to Minikube...'
                    sh '''
                        # Kubeconfig'i host dosyasını bozmadan kopyala ve onun üzerinde çalış
                        mkdir -p /home/jenkins/.kube
                        cp -f /home/jenkins/.kube/config /home/jenkins/.kube/config.jenkins
                        export KUBECONFIG=/home/jenkins/.kube/config.jenkins
                        if grep -q "/home/cagri/.minikube" "$KUBECONFIG"; then
                          sed -i 's|/home/cagri|/home/jenkins|g' "$KUBECONFIG"
                        fi
                        
                        # Images'ları build et (zaten yapıldı)
                        echo "Images already built in previous stage"
                        
                        # Namespace oluştur
                        kubectl apply -f k8s/namespace.yaml --validate=false
                        
                        # ConfigMaps ve Secrets
                        kubectl apply -f k8s/postgres-configmap.yaml --validate=false
                        kubectl apply -f k8s/postgres-secret.yaml --validate=false
                        kubectl apply -f k8s/postgres-init-configmap.yaml --validate=false
                        
                        # PVC
                        kubectl apply -f k8s/postgres-pvc.yaml --validate=false
                        
                        # Deployments
                        kubectl apply -f k8s/postgres-deployment.yaml --validate=false
                        kubectl apply -f k8s/backend-deployment.yaml --validate=false
                        kubectl apply -f k8s/frontend-deployment.yaml --validate=false
                        
                        # Built images'ları Minikube Docker'ına yükle
                        docker save counter-frontend:${BUILD_NUMBER} -o /tmp/counter-frontend-${BUILD_NUMBER}.tar
                        docker save counter-backend:${BUILD_NUMBER} -o /tmp/counter-backend-${BUILD_NUMBER}.tar
                        docker cp /tmp/counter-frontend-${BUILD_NUMBER}.tar minikube:/counter-frontend-${BUILD_NUMBER}.tar
                        docker cp /tmp/counter-backend-${BUILD_NUMBER}.tar minikube:/counter-backend-${BUILD_NUMBER}.tar
                        docker exec minikube docker load -i /counter-frontend-${BUILD_NUMBER}.tar
                        docker exec minikube docker load -i /counter-backend-${BUILD_NUMBER}.tar
                        
                        # Yeni build edilen imajları deploy et
                        kubectl set image deployment/frontend-deployment frontend=counter-frontend:${BUILD_NUMBER} -n counter-app
                        kubectl set image deployment/backend-deployment backend=counter-backend:${BUILD_NUMBER} -n counter-app
                        
                        # Rollout durumunu bekle
                        kubectl rollout status deployment/frontend-deployment -n counter-app
                        kubectl rollout status deployment/backend-deployment -n counter-app
                        
                        # Wait for deployments
                        kubectl wait --for=condition=available --timeout=300s deployment/postgres-deployment -n counter-app
                        kubectl wait --for=condition=available --timeout=300s deployment/backend-deployment -n counter-app
                        kubectl wait --for=condition=available --timeout=300s deployment/frontend-deployment -n counter-app
                    '''
                }
            }
        }
        
        stage('Health Check') {
            steps {
                script {
                    echo 'Performing health checks...'
                    sh '''
                        # Kubeconfig'i host dosyasını bozmadan kopyala ve onun üzerinde çalış
                        mkdir -p /home/jenkins/.kube
                        cp -f /home/jenkins/.kube/config /home/jenkins/.kube/config.jenkins
                        export KUBECONFIG=/home/jenkins/.kube/config.jenkins
                        if grep -q "/home/cagri/.minikube" "$KUBECONFIG"; then
                          sed -i 's|/home/cagri|/home/jenkins|g' "$KUBECONFIG"
                        fi
                        
                        # Backend health check
                        kubectl port-forward svc/backend-service 3000:3000 -n counter-app &
                        PORT_FORWARD_PID=$!
                        sleep 10
                        
                        # Health endpoint kontrolü
                        if curl -f http://localhost:3000/health; then
                            echo "Backend health check passed"
                        else
                            echo "Backend health check failed"
                            kill $PORT_FORWARD_PID
                            exit 1
                        fi
                        
                        kill $PORT_FORWARD_PID
                        
                        # Pod durumlarını kontrol et
                        kubectl get pods -n counter-app
                    '''
                }
            }
        }
        
        stage('Expose Service') {
            steps {
                script {
                    echo 'Setting up port forwarding...'
                    sh '''
                        # Kubeconfig'i host dosyasını bozmadan kopyala ve onun üzerinde çalış
                        mkdir -p /home/jenkins/.kube
                        cp -f /home/jenkins/.kube/config /home/jenkins/.kube/config.jenkins
                        export KUBECONFIG=/home/jenkins/.kube/config.jenkins
                        if grep -q "/home/cagri/.minikube" "$KUBECONFIG"; then
                          sed -i 's|/home/cagri|/home/jenkins|g' "$KUBECONFIG"
                        fi
                        
                        echo "Frontend service bilgileri:"
                        kubectl get svc frontend-service -n counter-app
                        
                        echo "Port forwarding için komut:"
                        echo "kubectl port-forward svc/frontend-service 8080:80 -n counter-app"
                    '''
                }
            }
        }
    }
    
    post {
        always {
            echo 'Pipeline completed!'
            script {
                sh '''
                    # Kubeconfig'i host dosyasını bozmadan kopyala ve onun üzerinde çalış
                    mkdir -p /home/jenkins/.kube
                    cp -f /home/jenkins/.kube/config /home/jenkins/.kube/config.jenkins
                    export KUBECONFIG=/home/jenkins/.kube/config.jenkins
                    if grep -q "/home/cagri/.minikube" "$KUBECONFIG"; then
                      sed -i 's|/home/cagri|/home/jenkins|g' "$KUBECONFIG"
                    fi
                    
                    echo "=== DEPLOYMENT SUMMARY ==="
                    kubectl get all -n counter-app
                    echo ""
                    echo "Frontend'e erişim için:"
                    echo "kubectl port-forward svc/frontend-service 8080:80 -n counter-app"
                    echo "Sonra tarayıcıda: http://localhost:8080"
                '''
            }
        }
        success {
            echo 'Pipeline succeeded! 🎉'
        }
        failure {
            echo 'Pipeline failed! ❌'
            script {
                sh '''
                    # Kubeconfig'i host dosyasını bozmadan kopyala ve onun üzerinde çalış
                    mkdir -p /home/jenkins/.kube
                    cp -f /home/jenkins/.kube/config /home/jenkins/.kube/config.jenkins
                    export KUBECONFIG=/home/jenkins/.kube/config.jenkins
                    if grep -q "/home/cagri/.minikube" "$KUBECONFIG"; then
                      sed -i 's|/home/cagri|/home/jenkins|g' "$KUBECONFIG"
                    fi
                    
                    echo "=== DEBUG INFO ==="
                    kubectl get pods -n counter-app
                    kubectl logs -l app=backend -n counter-app --tail=50 || true
                    kubectl logs -l app=frontend -n counter-app --tail=50 || true
                '''
            }
        }
    }
}
