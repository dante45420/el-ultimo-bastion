# Tarea: 1.1 - Estructura del Proyecto

## 📝 Descripción General

Esta tarea inicial establece la estructura de carpetas fundamental del proyecto "El Último Bastión", así como los archivos de configuración básicos necesarios para que los diferentes componentes (Backend, Frontend, Godot Engine) coexistan y se preparen para la integración. Es la base sobre la cual se construirá todo el desarrollo futuro.

## 🎯 Criterios de Aceptación (Definition of Done - DoD)

Para considerar esta tarea como 'Completa', deben cumplirse todos los siguientes criterios:

* **Estructura de Carpetas Creada:** Los directorios `backend/`, `frontend/`, `game_engine/` y sus subdirectorios especificados en `PROJECT_OVERVIEW.md` (`ESTRUCTURA_DE_REPOSITORIO (Confirmada)`) han sido creados en la raíz del proyecto.
* **Archivos de Configuración Iniciales Creados:**
    * `backend/.env` ha sido creado con las variables de entorno iniciales (`DB_USER`, `DB_PASSWORD`, `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_NAME_TEST`, `SECRET_KEY`, `FRONTEND_URL`, `ADMIN_EMAIL`, `ADMIN_PASSWORD`, `ADMIN_NAME`, `ADMIN_PHONE`).
    * `backend/requirements.txt` ha sido creado con las dependencias de Python especificadas (`Flask`, `Flask-SQLAlchemy`, `psycopg2-binary`, `Flask-Migrate`, `Marshmallow`, `flask-cors`, `Click`, `pytest`, `python-dotenv`).
    * `frontend/package.json` ha sido creado con las dependencias de Node.js (`react`, `react-dom`, `axios`, `vite`, etc.) y `frontend/vite.config.js` estándar.
    * `game_engine/project.godot` ha sido inicializado como un proyecto de Godot vacío.
* **Archivos de Aplicación Base Creados:**
    * `backend/config.py`
    * `backend/manage.py`
    * `backend/run.py`
    * `backend/app/__init__.py`
    * `backend/app/models.py` (inicialmente vacío o con placeholders, la implementación detallada es parte de la Tarea 1.2)
    * `backend/app/schemas.py` (inicialmente vacío o con placeholders, la implementación detallada es parte de la Tarea 1.2)
    * `backend/app/api/__init__.py`, `backend/app/api/admin_routes.py`, `backend/app/api/auth_routes.py`, `backend/app/api/game_routes.py` (archivos vacíos o con Blueprints mínimos).
    * `backend/app/services/__init__.py`, `backend/app/services/background_tasks.py`.
    * `frontend/src/App.jsx`, `frontend/src/main.jsx`.
    * `frontend/src/api/adminApi.js`.
    * `frontend/src/pages/TipoObjetoAdminPage.jsx` (inicialmente vacío o con placeholder).
* **Dependencias Instaladas:** Las dependencias de `requirements.txt` (Python) y `package.json` (Node.js) han sido instaladas exitosamente.

## 🔧 Detalles Técnicos de Implementación

### Estructura de Carpetas

La estructura debe ser replicada tal cual se especifica en la sección `ESTRUCTURA_DE_REPOSITORIO (Confirmada)` del `PROJECT_OVERVIEW.md`. Esto asegura la modularidad y el desacoplamiento entre los servicios.

### Archivos de Configuración

* `.env`: Almacena credenciales y configuraciones sensibles o específicas del entorno. Es crucial que **NO sea versionado en Git**. `python-dotenv` lo leerá.
* `requirements.txt` / `package.json`: Listan las dependencias exactas del proyecto para replicar el entorno en cualquier máquina.

### Archivos de Aplicación Base

* **Backend (Flask):**
    * `config.py`: Centraliza la configuración de la aplicación Flask, leyendo del `.env`.
    * `app/__init__.py`: Factory para crear la aplicación Flask, inicializar SQLAlchemy, Flask-Migrate y registrar Blueprints.
    * `app/models.py`: Archivo donde residirán todas las definiciones de modelos de base de datos (`db.Model`).
    * `app/schemas.py`: Contendrá los esquemas de Marshmallow para serialización y validación de datos.
    * `manage.py`: Script de línea de comandos para tareas de desarrollo y DB (crear/eliminar tablas, seedear, gestionar migraciones).
    * `run.py`: Script simple para iniciar el servidor de desarrollo Flask.
* **Frontend (React):**
    * `src/App.jsx`, `src/main.jsx`: Componentes raíz de la aplicación React.
    * `src/api/adminApi.js`: Centralizará las llamadas API al backend desde el frontend.

## 🧪 Pruebas Detalladas

* **Verificación Manual:**
    1.  Crear la estructura de carpetas.
    2.  Poblar los archivos de configuración y base.
    3.  Ejecutar `npm install` en `frontend/` y `pip install -r requirements.txt` en `backend/`.
    4.  Verificar que `python run.py` en `backend/` inicia el servidor Flask sin errores.
    5.  Verificar que `npm run dev` en `frontend/` inicia el servidor de desarrollo de React sin errores de compilación.

## 🚧 Bloqueadores/Riesgos

* Errores de ruta o tipográficos al crear la estructura o copiar archivos.
* Problemas de permisos al crear carpetas o archivos.
* Problemas de instalación de dependencias (versiones de Python/Node.js).

## 🤝 Colaboración

* **Roles Involucrados:** Desarrollador Backend, Desarrollador Frontend.
* **Instrucciones para Colaboradores:** Seguir los pasos de creación de estructura y copiar los contenidos de archivo exactamente como se indica.

## 🗓️ Log de Actualizaciones de Tarea

| Fecha       | Actualización                                                                                              | Responsable |
| :---------- | :--------------------------------------------------------------------------------------------------------- | :---------- |
| 2025-07-19  | Creación inicial del documento `task_1_1_project_structure.md` con pasos detallados y criterios de aceptación. | AI          |