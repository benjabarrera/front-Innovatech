# ===== Etapa 1: build de la SPA con Vite =====
FROM node:20-alpine AS build
WORKDIR /app

# Instalamos dependencias
COPY package*.json ./
RUN npm ci

# Copiamos el resto del código y generamos la carpeta /dist
COPY . .
RUN npm run build

# ===== Etapa 2: servir con Nginx =====
# Usamos nginxinc/nginx-unprivileged que es la mejor práctica
FROM nginxinc/nginx-unprivileged:1.27-alpine

# Copiamos la configuración personalizada de Nginx
# Nota: La ruta en esta imagen es /etc/nginx/conf.d/default.conf
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copiamos los archivos estáticos desde la etapa 'build'
COPY --from=build /app/dist /usr/share/nginx/html

# Exponemos el puerto 8080 (por defecto en esta imagen)
EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]
