# Innovatech Chile — Frontend

Frontend de la plataforma Innovatech Chile, desarrollado en **React** y servido en producción mediante **Nginx**. Forma parte de un sistema compuesto por un frontend, dos microservicios backend (Ventas y Despachos) y una base de datos relacional MySQL, con un ciclo de integración y entrega continua (CI/CD) totalmente automatizado sobre **Amazon ECS (Fargate)**.

Repositorio del backend: [back-Innovatech](https://github.com/benjabarrera/back-Innovatech.git)

---

## Arquitectura

El frontend actúa como **reverse-proxy**: además de servir la aplicación React compilada, Nginx redirige las peticiones de API hacia los microservicios correspondientes mediante DNS interno (Service Connect en producción / red de Docker en desarrollo local).
Internet ── ALB (:80) ── Frontend / Nginx (:8080)
│
┌─────────────┼─────────────┐
│                            │
/api/v1/ventas               /api/v1/despachos
│                            │
Servicio Ventas (:8080)     Servicio Despachos (:8081)
│
MySQL (:3306)

En el entorno local, estos mismos alias (`ventas`, `despachos`, `mysql`) se resuelven a través de la red interna de `docker-compose`; en producción, a través de **ECS Service Connect**, sin necesidad de modificar el código de la aplicación.

---

## Stack tecnológico

| Componente        | Tecnología                          |
|--------------------|-------------------------------------|
| Framework          | React                                |
| Servidor           | Nginx (imagen `nginx-unprivileged`) |
| Contenerización    | Docker (build multietapa)           |
| CI/CD              | GitHub Actions                      |
| Registro de imagen | Amazon ECR                          |
| Orquestación       | Amazon ECS (Fargate)                |

---

## Estructura del proyecto
.
├── src/                    # Código fuente de la aplicación React
├── public/
├── nginx/
│   └── default.conf        # Configuración de reverse-proxy
├── Dockerfile               # Build multietapa (build → nginx-unprivileged)
├── .dockerignore
├── docker-compose.yml       # Orquestación local (frontend + backend + BD)
└── .github/
└── workflows/
└── deploy.yml       # Pipeline CI/CD

---

## Requisitos previos

- Node.js 18+ (solo para desarrollo local sin Docker)
- Docker y Docker Compose
- Cuenta de AWS con acceso a ECR/ECS (para despliegue)

---

## Ejecución local con Docker Compose

El entorno local levanta los cuatro servicios de la plataforma (frontend, ventas, despachos y mysql) en una misma red, reproduciendo el mismo esquema de comunicación usado en producción.

```bash
# Clonar ambos repositorios (frontend y backend) en la misma carpeta de trabajo
git clone https://github.com/benjabarrera/front-Innovatech.git
git clone https://github.com/benjabarrera/back-Innovatech.git

# Levantar el stack completo
docker-compose up --build
```

La aplicación queda disponible en [http://localhost:8080](http://localhost:8080).

Para detener y limpiar los contenedores:

```bash
docker-compose down
```

---

## Variables de entorno

| Variable      | Descripción                              |
|---------------|-------------------------------------------|
| `DB_ENDPOINT` | Host de la base de datos (`mysql` en local) |
| `DB_PORT`     | Puerto de la base de datos (`3306`)        |
| `DB_NAME`     | Nombre de la base de datos                 |
| `DB_USERNAME` | Usuario de conexión a la base de datos     |

Las credenciales sensibles (contraseñas) **no** se definen en variables de entorno planas: se gestionan como *secrets* (GitHub Secrets en el pipeline, AWS SSM Parameter Store en producción).

---

## Build de la imagen Docker

El `Dockerfile` usa una construcción multietapa: una etapa compila la aplicación React (`npm run build`) y otra, basada en `nginx-unprivileged`, sirve únicamente los artefactos estáticos resultantes. Esto reduce el tamaño final de la imagen y evita exponer herramientas de build en el contenedor de producción.

```bash
docker build -t innovatech-frontend .
docker run -p 8080:8080 innovatech-frontend
```

---

## Pipeline de CI/CD

El workflow de GitHub Actions (`.github/workflows/deploy.yml`) se dispara automáticamente con cada `push` a la rama `deploy`, y ejecuta las siguientes etapas:

1. **Build** — construye la imagen Docker del frontend.
2. **Test** — valida el empaquetado de la aplicación.
3. **Push** — autentica contra Amazon ECR y publica la imagen etiquetada.
4. **Deploy** — fuerza una actualización del servicio en ECS (`aws ecs update-service --force-new-deployment`), logrando un despliegue gradual sin interrupción del servicio.

La autenticación con AWS se realiza mediante `aws-actions/configure-aws-credentials`, usando credenciales temporales almacenadas como GitHub Secrets. Ninguna credencial queda expuesta en el código ni en el repositorio.

---

## Despliegue en producción (AWS ECS)

- **Registro de imágenes:** Amazon ECR (`innovatech-frontend`)
- **Orquestación:** Amazon ECS con Fargate, dentro del clúster `innovatech-cluster`
- **Exposición:** único servicio detrás de un Application Load Balancer (ALB) público en el puerto 80
- **Descubrimiento de servicios:** ECS Service Connect, con alias DNS internos (`ventas`, `despachos`, `mysql`)
- **Observabilidad:** logs enviados a Amazon CloudWatch mediante el driver `awslogs`

---

## Seguridad

- Imagen base minimalista (`nginx-unprivileged`), ejecutada como usuario no-root.
- Único puerto expuesto a Internet: el 80, a través del ALB.
- El frontend es el único componente accesible públicamente; los microservicios y la base de datos permanecen aislados dentro de la VPC.
- Escaneo de vulnerabilidades habilitado sobre la imagen publicada en Amazon ECR.

---

## Equipo

Proyecto desarrollado para la asignatura **ISY1101 — Introducción a Herramientas DevOps**, Duoc UC.

- Carlo Bettancourt
- Benjamin Barrera
- Cristian Bravo
