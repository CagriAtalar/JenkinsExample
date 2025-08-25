FROM nginx:alpine

# Static dosyaları nginx'e kopyala
COPY . /usr/share/nginx/html/

# Nginx konfigürasyonu
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
