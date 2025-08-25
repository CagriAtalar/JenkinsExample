#!/bin/bash

echo "🚀 Counter App Deployment Script"
echo "================================"

# Renk kodları
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Hata durumunda çık
set -e

# Fonksiyonlar
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Minikube kontrol
check_minikube() {
    log_info "Minikube durumu kontrol ediliyor..."
    if ! minikube status > /dev/null 2>&1; then
        log_warn "Minikube çalışmıyor. Başlatılıyor..."
        minikube start
    else
        log_info "Minikube zaten çalışıyor ✓"
    fi
}

# Docker environment ayarla
setup_docker_env() {
    log_info "Docker environment ayarlanıyor..."
    eval $(minikube docker-env)
    log_info "Docker environment ayarlandı ✓"
}

# Images build et
build_images() {
    log_info "Docker images build ediliyor..."
    
    log_info "Backend image build ediliyor..."
    docker build -t counter-backend:latest ./backend
    
    log_info "Frontend image build ediliyor..."
    docker build -t counter-frontend:latest ./frontend
    
    log_info "Images build edildi ✓"
}

# Kubernetes deploy
deploy_k8s() {
    log_info "Kubernetes resources deploy ediliyor..."
    
    kubectl apply -f k8s/namespace.yaml
    kubectl apply -f k8s/postgres-configmap.yaml
    kubectl apply -f k8s/postgres-secret.yaml
    kubectl apply -f k8s/postgres-init-configmap.yaml
    kubectl apply -f k8s/postgres-pvc.yaml
    kubectl apply -f k8s/postgres-deployment.yaml
    kubectl apply -f k8s/backend-deployment.yaml
    kubectl apply -f k8s/frontend-deployment.yaml
    
    log_info "Kubernetes resources deploy edildi ✓"
}

# Deployment bekle
wait_for_deployment() {
    log_info "Deployments'ların hazır olması bekleniyor..."
    
    kubectl wait --for=condition=available --timeout=300s deployment/postgres-deployment -n counter-app
    kubectl wait --for=condition=available --timeout=300s deployment/backend-deployment -n counter-app
    kubectl wait --for=condition=available --timeout=300s deployment/frontend-deployment -n counter-app
    
    log_info "Tüm deployments hazır ✓"
}

# Health check
health_check() {
    log_info "Health check yapılıyor..."
    
    # Backend port forward (background)
    kubectl port-forward svc/backend-service 3000:3000 -n counter-app &
    PORT_FORWARD_PID=$!
    
    # Biraz bekle
    sleep 10
    
    # Health endpoint test
    if curl -f http://localhost:3000/health > /dev/null 2>&1; then
        log_info "Backend health check başarılı ✓"
    else
        log_error "Backend health check başarısız ✗"
        kill $PORT_FORWARD_PID 2>/dev/null || true
        exit 1
    fi
    
    # Port forward'ı durdur
    kill $PORT_FORWARD_PID 2>/dev/null || true
    
    log_info "Health check tamamlandı ✓"
}

# Durum göster
show_status() {
    log_info "Deployment durumu:"
    echo ""
    kubectl get all -n counter-app
    echo ""
    log_info "Frontend'e erişim için:"
    echo "kubectl port-forward svc/frontend-service 8080:80 -n counter-app"
    echo ""
    log_info "Sonra tarayıcıda açın: http://localhost:8080"
}

# Cleanup fonksiyonu
cleanup() {
    log_warn "Cleanup yapılıyor..."
    kubectl delete namespace counter-app 2>/dev/null || true
    log_info "Cleanup tamamlandı"
}

# Ana fonksiyon
main() {
    echo ""
    
    # Cleanup seçeneği
    if [[ "$1" == "cleanup" ]]; then
        cleanup
        exit 0
    fi
    
    # Deploy işlemleri
    check_minikube
    setup_docker_env
    build_images
    deploy_k8s
    wait_for_deployment
    health_check
    show_status
    
    echo ""
    log_info "🎉 Deployment başarıyla tamamlandı!"
}

# Script'i çalıştır
main "$@"
