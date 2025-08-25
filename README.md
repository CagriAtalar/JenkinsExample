# Minimal Counter App

Bu proje, butona basınca PostgreSQL veritabanındaki sayacı artıran çok basit bir web uygulamasıdır.

## Teknolojiler

- **Frontend**: HTML, CSS, JavaScript (Vanilla)
- **Backend**: Node.js + Express
- **Database**: PostgreSQL
- **Container**: Docker
- **Orchestration**: Kubernetes (Minikube)
- **CI/CD**: Jenkins

## Proje Yapısı

```
elmaliturta/
├── frontend/           # Frontend dosyaları
│   ├── index.html     # Ana sayfa
│   ├── style.css      # Stiller
│   ├── script.js      # JavaScript
│   ├── Dockerfile     # Frontend container
│   └── nginx.conf     # Nginx konfigürasyonu
├── backend/            # Backend API
│   ├── server.js      # Express server
│   ├── package.json   # Node.js dependencies
│   ├── Dockerfile     # Backend container
│   └── env-config.txt # Environment variables örneği
├── database/           # Database scripts
│   └── init.sql       # PostgreSQL init script
├── k8s/               # Kubernetes manifests
│   ├── namespace.yaml
│   ├── postgres-*.yaml
│   ├── backend-deployment.yaml
│   └── frontend-deployment.yaml
├── docker-compose.yml  # Local development
├── Jenkinsfile        # CI/CD pipeline
└── README.md          # Bu dosya
```

## Kurulum ve Çalıştırma

### 1. Önkoşullar

```bash
# Docker
sudo apt update
sudo apt install docker.io

# Minikube
curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube /usr/local/bin/

# kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install kubectl /usr/local/bin/

# Jenkins (isteğe bağlı)
```

### 2. Local Development (Docker Compose)

```bash
# .env dosyasını oluştur
cp backend/env-config.txt backend/.env

# Tüm servisleri başlat
docker-compose up -d

# Logs'ları takip et
docker-compose logs -f

# Erişim
# Frontend: http://localhost:8080
# Backend API: http://localhost:3000
# PostgreSQL: localhost:5432
```

### 3. Kubernetes Deployment (Minikube)

```bash
# Minikube'ı başlat
minikube start

# Docker environment'ı ayarla
eval $(minikube docker-env)

# Docker images'ları build et
docker build -t counter-backend:latest ./backend
docker build -t counter-frontend:latest ./frontend

# Kubernetes resources'ları deploy et
kubectl apply -f k8s/

# Deployment durumunu kontrol et
kubectl get all -n counter-app

# Frontend'e erişim için port forwarding
kubectl port-forward svc/frontend-service 8080:80 -n counter-app

# Tarayıcıda açın: http://localhost:8080
```

### 4. Jenkins Pipeline

```bash
# Jenkins'i çalıştır (Docker ile)
docker run -d -p 8080:8080 -v jenkins_home:/var/jenkins_home jenkins/jenkins:lts

# Jenkins'te yeni pipeline job oluştur
# SCM olarak bu repository'yi ekle
# Jenkinsfile'ı pipeline script olarak kullan

# Pipeline'ı çalıştır
```

## API Endpoints

```
GET  /health              - Health check
GET  /api/counter         - Counter değerini getir
POST /api/counter/increment - Counter'ı 1 artır
```

## Kullanım

1. Uygulamayı açın
2. "Sayacı Artır" butonuna basın
3. Sayac değeri artacak ve veritabanına kaydedilecek

## Troubleshooting

### Port Forwarding Kontrol

```bash
# Aktif port forward'ları göster
ps aux | grep "port-forward"

# Port forward'ı durdur
pkill -f "port-forward"

# Yeni port forward başlat
kubectl port-forward svc/frontend-service 8080:80 -n counter-app
```

### Logs

```bash
# Backend logs
kubectl logs -l app=backend -n counter-app

# Frontend logs
kubectl logs -l app=frontend -n counter-app

# PostgreSQL logs
kubectl logs -l app=postgres -n counter-app
```

### Reset

```bash
# Tüm resources'ları sil
kubectl delete namespace counter-app

# Minikube'ı sıfırla
minikube delete
minikube start
```

## Geliştirme

### Backend değişiklikleri

```bash
# Backend'i rebuild et
docker build -t counter-backend:latest ./backend

# Pod'ları restart et
kubectl rollout restart deployment/backend-deployment -n counter-app
```

### Frontend değişiklikleri

```bash
# Frontend'i rebuild et
docker build -t counter-frontend:latest ./frontend

# Pod'ları restart et
kubectl rollout restart deployment/frontend-deployment -n counter-app
```

## WSL IP Ayarları

Eğer WSL kullanıyorsanız:

1. `frontend/script.js` içindeki `apiUrl` değerini WSL IP'nize göre güncelleyin
2. WSL IP'sini öğrenmek için: `ip addr show eth0`
3. Örnek: `this.apiUrl = 'http://172.20.10.2:3000/api';`

## Lisans

Bu proje eğitim amaçlıdır.
