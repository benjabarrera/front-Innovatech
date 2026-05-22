# ===== Etapa 1: build de la SPA con Vite =====
FROM node:20-alpine AS build
WORKDIR /app

# Instalamos dependencias en una capa aparte para aprovechar la cache
COPY package*.json ./
RUN npm ci

# Copiamos el resto del codigo y generamos los archivos estaticos en /app/dist
COPY . .
RUN npm run build

# ===== Etapa 2: servir con Nginx (imagen no-root) =====
# nginx-unprivileged corre como usuario sin privilegios y escucha en el puerto 8080
FROM nginxinc/nginx-unprivileged:1.27-alpine

# Reemplazamos la config por defecto con la nuestra (sirve la SPA + reverse proxy a los backends)
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copiamos los archivos estaticos ya compilados
COPY --from=build /app/dist /usr/share/nginx/html

EXPOSE 8080
