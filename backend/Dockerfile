FROM node:18-alpine

WORKDIR /app

# Package dosyalarını kopyala
COPY package*.json ./

# Dependencies'leri install et
RUN npm install --omit=dev

# Uygulama kodunu kopyala
COPY . .

# Non-root user oluştur
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nodejs -u 1001

USER nodejs

EXPOSE 3000

CMD ["node", "server.js"]
