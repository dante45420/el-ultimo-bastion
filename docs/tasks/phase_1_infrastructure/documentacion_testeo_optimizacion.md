# Documentación: Tareas de Infraestructura (Fase 1)

Este documento detalla la implementación, el testeo y las consideraciones de optimización para las tareas de la Fase 1: Infraestructura Básica.

---

## Tarea: 1.1 - Estructura del Proyecto

### 📝 Qué se Hizo (Implementación)

1.  **Creación de Estructura de Carpetas:** Se establecieron los directorios principales (`backend/`, `frontend/`, `game_engine/`) y sus subdirectorios (`backend/app/`, `backend/app/api/`, `backend/app/services/`, `frontend/src/api/`, `frontend/src/pages/`, `game_engine/assets/`, `game_engine/scenes/`, `game_engine/scripts/`).
2.  **Archivos de Configuración Base:** Se crearon los archivos esenciales para cada módulo:
    * `backend/.env`: Para variables de entorno (DB, secretos).
    * `backend/requirements.txt`: Dependencias de Python (Flask, SQLAlchemy, Pytest, python-dotenv).
    * `frontend/package.json`: Dependencias de Node.js (React, Vite, Axios).
    * `frontend/vite.config.js`: Configuración estándar de Vite.
    * `game_engine/project.godot`: Archivo de proyecto inicial de Godot.
3.  **Archivos de Aplicación Mínimos:**
    * **Backend:** `config.py`, `manage.py` (básico), `run.py`, `app/__init__.py`, `app/models.py` (placeholder), `app/schemas.py` (placeholder), `app/api/admin_routes.py` (básico), `app/api/auth_routes.py` (vacío), `app/api/game_routes.py` (vacío), `app/services/background_tasks.py` (placeholder).
    * **Frontend:** `src/App.jsx` (básico), `src/main.jsx`, `src/api/adminApi.js` (básico), `src/pages/TipoObjetoAdminPage.jsx` (placeholder).

### 🧪 Cómo se Testeó

1.  **Verificación Manual de Estructura:** Se confirmó visualmente que todas las carpetas y archivos se crearon en las ubicaciones correctas.
2.  **Verificación de Instalación de Dependencias:**
    * Ejecución de `npm install` en `frontend/` y `pip install -r requirements.txt` en `backend/`. Se verificó que no hubiera errores y que las carpetas `node_modules/` y `venv/` se crearan correctamente.
3.  **Verificación de Inicio Básico de Servidores:**
    * Ejecución de `python run.py` en `backend/`. Se verificó que el servidor Flask iniciara sin errores y estuviera escuchando en `http://localhost:5000/`.
    * Ejecución de `npm run dev` en `frontend/`. Se verificó que el servidor de desarrollo de React iniciara sin errores de compilación y que la página `http://localhost:5173/` cargara en el navegador.

### ⚙️ Consideraciones de Optimización

* **Estructura Ligera:** La estructura inicial se mantuvo mínima para facilitar el arranque rápido.
* **Contenedorización (Futuro):** Para despliegues y entornos de desarrollo uniformes, se considerará el uso de Docker para empaquetar los servicios de Backend y Frontend.
* **Gestión de Dependencias:** El uso de `requirements.txt` y `package.json` ya es una buena práctica. En el futuro, se podría considerar `pip-tools` para Python o `yarn.lock` para Node.js para un bloqueo más estricto de versiones de dependencias.

---

## Tarea: 1.2 - Base de Datos PostgreSQL

### 📝 Qué se Hizo (Implementación)

Esta tarea se dividió en 5 "tandas" para una implementación y testeo incremental:

1.  **Modelos de Base de Datos (`backend/app/models.py`):**
    * Se definió el esquema completo de la base de datos con todas las clases de modelos (`Inventario`, `Daño`, `CriaturaViva_Base`, `TipoObjeto`, `TipoLootTable`, `TipoHabilidad`, `TipoEdificio`, `TipoNPC`, `TipoAnimal`, `TipoRecursoTerreno`, `TipoComercianteOferta`, `TipoMision`, `TipoEventoGlobal`, `TipoPista`, `Usuario`, `Clan`, `Bastion`, `Mundo`, `InstanciaAldea`, `InstanciaNPC`, `InstanciaAnimal`, `InstanciaRecursoTerreno`, `InstanciaEdificio`, `MisionActiva`, `EventoGlobalActivo`, `InteraccionComercio`).
    * Se implementó la composición para la herencia (ej. `CriaturaViva_Base` referenciando `Inventario` y `Daño`).
    * Se hizo uso extensivo de tipos `JSONB` para campos mutables y configurables (ej. `valores_especificos`, `resistencia_dano`, `posicion`).
    * Se configuraron `UniqueConstraint` y `db.ForeignKey` para la integridad referencial.
2.  **Esquemas de Serialización (`backend/app/schemas.py`):**
    * Se crearon los esquemas de Marshmallow para todos los modelos, permitiendo la serialización a/desde JSON para la API.
    * Se añadieron validaciones (`validate.OneOf`, `validate.Length`, `validate.Range`) para asegurar la calidad de los datos de entrada.
3.  **Gestión de la Base de Datos (`backend/manage.py`):**
    * Se implementaron comandos `create_all_tables` y `drop_all_tables` para la gestión directa del esquema en desarrollo/pruebas.
    * Se implementó un comando `seed` que puebla la base de datos con datos de ejemplo para todos los tipos y algunas instancias iniciales (incluyendo el "Mundo Sandbox para Devs" y `CriaturaViva_Base`s de ejemplo).
4.  **Configuración de Migraciones:**
    * Se inicializó Flask-Migrate (`flask db init`).
    * Se generaron y aplicaron migraciones (`flask db migrate`, `flask db upgrade`) para mantener el esquema de la base de datos de desarrollo sincronizado con los modelos.
5.  **Entorno de Pruebas Unitarias:**
    * Se configuró `backend/tests/conftest.py` para un entorno de pruebas aislado, utilizando una base de datos de prueba separada (`el_ultimo_bastion_test_db`).
    * El `conftest.py` garantiza la limpieza de datos (`.query.delete()`) antes de cada test para evitar interferencias.
    * Se configuró la carga de variables de entorno (`dotenv_values`) de forma robusta para el entorno de pruebas.

### 🧪 Cómo se Testeó

Se utilizó una metodología de **testeo incremental por "tandas"** utilizando `pytest`:

1.  **Tanda 1 (Componentes Reutilizables):**
    * `backend/tests/test_tanda1_components.py` probó `Inventario`, `Daño`, `CriaturaViva_Base`.
    * **Pruebas clave:** Creación y actualización de instancias, verificación de `JSONB` (contenido), verificación de relaciones `NOT NULL` y `UNIQUE` (ej., una `CriaturaViva_Base` no puede compartir `Inventario` o `Daño` con otra).
    * **Depuración notable:** Se requirió ajustar los tests para manejar `ForeignKeyViolation`s que ocurrían debido a `session.rollback()` en pruebas de `UNIQUE` constraints. La solución fue dividir el test y asegurar que las dependencias existieran en el contexto de cada sub-prueba.
2.  **Tanda 2 (Tipos Fundamentales):**
    * `backend/tests/test_tanda2_types.py` probó `TipoObjeto`, `TipoLootTable`, `TipoHabilidad`, `TipoEdificio`.
    * **Pruebas clave:** Creación de los tipos con sus `JSONB` complejos (ej., `valores_especificos` para `TipoObjeto` incluyendo `tipo_dano`, `recursos_costo` para `TipoEdificio`), verificación de `UNIQUE` por nombre, y la relación `Daño.loot_table_id`.
    * **Depuración notable:** Se corrigió un `AttributeError` en `Daño` al añadir `loot_table_id` directamente en el modelo con `nullable=True` antes de la relación formal.
3.  **Tanda 3 (Estado del Juego - Nivel 1):**
    * `backend/tests/test_tanda3_game_state_level1.py` probó `Usuario`, `Clan`, `Bastion`, `Mundo`.
    * **Pruebas clave:** Creación de instancias con múltiples relaciones `NOT NULL` (ej., `Clan` con `id_lider_usuario`, `id_inventario_baluarte`; `Bastion` con `id_usuario`, `id_criatura_viva_base`). Verificación de `UniqueConstraint` para `Usuario` (username, email), `Clan` (nombre), `Mundo` (tipo y propietario), `Bastion` (usuario).
    * **Depuración notable:** Se ajustó el orden de `session.add()` y `session.flush()` en los tests para garantizar que los IDs de las entidades referenciadas existieran antes de que las entidades que las referencian fueran flusheadas, resolviendo `NotNullViolation` y `ForeignKeyViolation`.
4.  **Tanda 4 (Estado del Juego - Nivel 2 y 3):**
    * `backend/tests/test_tanda4_game_state_level2_3.py` probó `InstanciaAldea`, `InstanciaRecursoTerreno`, `InstanciaNPC`, `InstanciaAnimal`, `InstanciaEdificio`.
    * **Pruebas clave:** Creación de instancias complejas que dependen de múltiples `Tipo_` y componentes base. Verificación de las relaciones de pertenencia (ej., `InstanciaNPC` con `id_aldea_pertenece`), y la correcta asignación de componentes de `Inventario`/`Daño`.
5.  **Tanda 5 (Estado del Juego - Nivel 4):**
    * `backend/tests/test_tanda5_game_state_level4.py` probó `MisionActiva`, `EventoGlobalActivo`, `InteraccionComercio`.
    * **Pruebas clave:** Creación y actualización de misiones (incluyendo `JSONB` de progreso), eventos (con estados de logro), y registros de comercio.
    * **Depuración notable:** Se utilizó `sqlalchemy.orm.attributes.flag_modified()` para asegurar que los cambios en campos `JSONB` mutables fueran detectados por SQLAlchemy y persistidos correctamente, resolviendo `AssertionError`s donde los objetos no reflejaban los cambios después de un commit.

### ⚙️ Consideraciones de Optimización

* **Diseño Data-Driven:** La estructura actual está altamente optimizada para la escalabilidad del contenido. Los diseñadores pueden añadir nuevos ítems, NPCs, etc., mediante datos sin cambios de código.
* **ORM y Migraciones:** El uso de SQLAlchemy y Flask-Migrate es una práctica robusta y optimizada para la gestión de esquemas de bases de datos relacionales en Python.
* **Tests Aislados:** La configuración de `pytest` con limpieza de DB por test es crucial para la velocidad y fiabilidad de los tests, permitiendo un ciclo de desarrollo rápido.
* **Índices de Base de Datos (Futuro):** A medida que la base de datos crezca, se añadirán índices a columnas comúnmente consultadas (ej., `id_mundo` en `InstanciaNPC`) para optimizar el rendimiento de las consultas.
* **Pool de Conexiones (Futuro):** Para producción, se ajustará la configuración del pool de conexiones de SQLAlchemy para manejar múltiples usuarios concurrentes eficientemente.
* **Normalización/Desnormalización (Futuro):** Para casos de alta lectura, se podría considerar una desnormalización controlada (ej. vistas materializadas) si los cuellos de botella de rendimiento lo justifican.

## 🤝 Colaboración

* **Comunicación del Esquema:** `DATABASE_SCHEMA.md` es la fuente de verdad. Cualquier cambio en los modelos debe ser reflejado allí.
* **Reproducibilidad:** El `manage.py seed` es fundamental para que cualquier desarrollador pueda levantar un entorno de desarrollo con datos consistentes.

## 🗓️ Log de Actualizaciones de Documento

| Fecha       | Actualización                                                                                                                                                                                                                                                                                                                                                                               | Responsable |
| :---------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | :---------- |
| 2025-07-20  | Creación inicial del documento `documentacion_testeo_optimizacion.md` para la Fase 1: Infraestructura (Tareas 1.1 y 1.2), detallando implementación, testeo y optimizaciones. | AI          |