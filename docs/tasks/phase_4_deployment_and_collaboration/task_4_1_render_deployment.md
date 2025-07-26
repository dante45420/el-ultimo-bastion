# Tarea: 4.1 - Despliegue en Render

## 📝 Descripción General

Esta tarea crucial se enfoca en llevar la aplicación Flask (Backend) y el panel de administración React (Frontend) a un entorno de producción en la nube utilizando Render.com. Esto permitirá que el equipo (desarrolladores, diseñadores, historiadores, testers) colabore de forma remota, accediendo a una única fuente de verdad para los datos del juego. El juego Godot se configurará para conectarse a este Backend remoto.

## 🎯 Criterios de Aceptación (Definition of Done - DoD)

Para considerar esta tarea como 'Completa', deben cumplirse todos los siguientes criterios:

* **Backend (Flask) Desplegado:**
    * El servicio de Backend Flask está desplegado en Render.com.
    * Es accesible a través de una URL pública (ej., `https://el-ultimo-bastion-api.onrender.com`).
    * Los endpoints API de administración (`/api/v1/admin/tipos_objeto`, `/api/v1/admin/mundos`, etc.) son funcionales a través de esta URL.
* **Base de Datos (PostgreSQL) Desplegada:**
    * Una instancia de PostgreSQL está provisionada en la nube (Render.com u otro proveedor compatible).
    * La aplicación Flask está conectada a esta base de datos remota.
    * Las tablas de la base de datos están creadas y migradas a su estado más reciente.
    * El comando `manage.py seed` se ha ejecutado una vez en el entorno de Render para poblar la DB con datos iniciales.
* **Frontend (React) Desplegado:**
    * El panel de administración React está desplegado en Render.com (o un servicio de hosting estático como Netlify/Vercel, si se prefiere).
    * Es accesible a través de una URL pública (ej., `https://el-ultimo-bastion-admin.onrender.com`).
    * El Frontend se conecta y consume los datos del Backend desplegado (verificar URLs en `frontend/src/api/adminApi.js`).
* **Godot Engine - Conexión Remota:**
    * El proyecto Godot (en la máquina de desarrollo) se ha modificado para que `Data_Loader.gd` apunte a la URL pública del Backend desplegado.
    * Godot puede crear, leer y actualizar datos de la base de datos remota a través del Backend.
* **Verificación de Colaboración:**
    * Un miembro del equipo (no el que hizo el despliegue) puede acceder al panel de administración remoto y crear/editar un `TipoObjeto` o un `Mundo`.
    * Otro miembro (o el mismo) puede iniciar el juego Godot en su máquina local y verificar que los cambios de datos realizados en el panel remoto se reflejan en el juego.

## 🔧 Detalles Técnicos de Implementación (Enfoque Scrum - a Nivel de Epic)

* **Backend Despliegue:**
    * **Dockerfile (opcional pero recomendado):** Crear un `Dockerfile` en `backend/` para contenerizar la aplicación Flask. Render puede construir a partir de Dockerfiles.
    * **`Procfile`:** Definir cómo se inicia la aplicación (ej. `web: gunicorn app:create_app()`).
    * **Variables de Entorno en Render:** Configurar todas las variables de `.env` (URLs de DB, Secrets, etc.) directamente en el panel de Render para el servicio del Backend.
    * **Conexión a DB:** La `SQLALCHEMY_DATABASE_URI` en `config.py` debe ser dinámica para usar la variable de entorno `DATABASE_URL` proporcionada por Render.
    * **Migraciones y Seeding en Despliegue:** Configurar comandos de "build" o "start" en Render para ejecutar `flask db upgrade` y `python manage.py seed` (con lógica de solo seedear si no hay datos) al momento del despliegue inicial.
* **Frontend Despliegue:**
    * **Build estático:** Configurar el `package.json` de frontend para un comando `build` que genere archivos HTML/CSS/JS estáticos (Vite ya lo hace con `npm run build`).
    * **Servicio de Hosting Estático:** Render puede hostear servicios estáticos. La base URL del backend en `frontend/src/api/adminApi.js` debe ser la URL pública del backend desplegado.
* **Base de Datos:**
    * Provisionar un PostgreSQL Managed Service en Render o un proveedor como Supabase/Neon.
    * Asegurar que las reglas de firewall permitan la conexión desde el Backend.
* **Godot Engine:**
    * Actualizar `backend/app/config.py` para que `FRONTEND_URL` pueda ser una variable de entorno.
    * En `Data_Loader.gd` (Godot), la `API_BASE_URL` se debe cambiar de `http://localhost:5000` a la URL pública del Backend desplegado.

## 🚧 Bloqueadores/Riesgos

* Configuración compleja de variables de entorno y secretos en la nube.
* Problemas de `psycopg2` al conectarse a DB remota (firewall, IP whitelisting).
* Conflictos de CORS si no se configura correctamente la URL del frontend.
* Tiempo de despliegue inicial.

## 🤝 Colaboración

* **Roles Involucrados:** DevOps/Despliegue, Desarrollador Backend, Desarrollador Frontend.
* **Puntos de Contacto:** Comunicación constante para depurar problemas de conexión entre servicios remotos.

## 🗓️ Log de Actualizaciones de Tarea

| Fecha       | Actualización                                                                                                 | Responsable |
| :---------- | :------------------------------------------------------------------------------------------------------------ | :---------- |
| 2025-07-19  | Creación inicial de la definición de la tarea `4.1 - Despliegue en Render`. | AI          |