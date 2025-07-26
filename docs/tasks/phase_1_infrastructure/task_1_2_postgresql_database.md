# Tarea: 1.2 - Base de Datos PostgreSQL

## 📝 Descripción General

Esta tarea se enfoca en la implementación del esquema completo de la base de datos PostgreSQL utilizando SQLAlchemy y Flask-Migrate. Se incluyen las definiciones de todos los modelos (`backend/app/models.py`), sus esquemas de serialización (`backend/app/schemas.py`), y los scripts CLI para gestionar la base de datos. La validación se realiza mediante una suite exhaustiva de tests unitarios que simulan interacciones reales y aseguran la integridad de los datos.

## 🎯 Criterios de Aceptación (Definition of Done - DoD)

Para considerar esta tarea como 'Completa', deben cumplirse todos los siguientes criterios:

* **Bases de Datos Creadas:** Las bases de datos `el_ultimo_bastion_db` (desarrollo) y `el_ultimo_bastion_test_db` (pruebas) existen en PostgreSQL.
* **`backend/app/models.py` Completo:** Todas las clases de modelos de base de datos (Inventario, Daño, CriaturaViva_Base, TipoObjeto, TipoLootTable, TipoHabilidad, TipoEdificio, TipoNPC, TipoAnimal, TipoRecursoTerreno, TipoComercianteOferta, TipoMision, TipoEventoGlobal, TipoPista, Usuario, Clan, Bastion, Mundo, InstanciaAldea, InstanciaNPC, InstanciaAnimal, InstanciaRecursoTerreno, InstanciaEdificio, MisionActiva, EventoGlobalActivo, InteraccionComercio) están definidas correctamente con sus columnas, tipos de datos, nulidad, restricciones de unicidad y relaciones (`db.relationship`).
* **`backend/app/schemas.py` Completo:** Todos los esquemas de Marshmallow correspondientes a los modelos de `models.py` están definidos, incluyendo validaciones (`validate`) y la gestión de campos `JSONB` y `ARRAY`.
* **`backend/manage.py` Implementado:** El script CLI `manage.py` contiene los comandos `create_all_tables`, `drop_all_tables` y `seed`.
* **Flask-Migrate Configurado:** El directorio `migrations/` y `alembic.ini` existen. Las migraciones (`flask db migrate`, `flask db upgrade`) se ejecutan sin errores y reflejan el esquema completo de `models.py` en la base de datos de desarrollo.
* **Tests Unitarios Exhaustivos Implementados y Pasando:**
    * `backend/tests/conftest.py` está configurado para un entorno de pruebas aislado (DB de pruebas separada, limpieza por test).
    * **Todos los tests en los siguientes archivos pasan exitosamente:**
        * `backend/tests/test_tanda1_components.py` (Inventario, Daño, CriaturaViva_Base)
        * `backend/tests/test_tanda2_types.py` (TipoObjeto, TipoLootTable, TipoHabilidad, TipoEdificio)
        * `backend/tests/test_tanda3_game_state_level1.py` (Usuario, Clan, Bastion, Mundo)
        * `backend/tests/test_tanda4_game_state_level2_3.py` (InstanciaAldea, InstanciaRecursoTerreno, InstanciaNPC, InstanciaAnimal, InstanciaEdificio)
        * `backend/tests/test_tanda5_game_state_level4.py` (MisionActiva, EventoGlobalActivo, InteraccionComercio)
    * Los tests simulan la creación, lectura y actualización de los datos, y verifican las restricciones de unicidad y las relaciones entre modelos.
* **Datos de Seeding Funcionales:** El comando `python manage.py seed` se ejecuta sin errores y puebla la base de datos de desarrollo con datos de ejemplo para todas las tablas.

## 🔧 Detalles Técnicos de Implementación

### 1. Modelos de Base de Datos (`backend/app/models.py`)

* **Composición para Herencia:** La "herencia" entre entidades (ej., `Bastion` "es una" `CriaturaViva_Base`) se implementa a través de composición (referencias a IDs de componentes como `Inventario`, `Daño`, `CriaturaViva_Base`).
* **JSONB:** Uso extensivo de `JSONB` para `valores_especificos`, `valores_rol`, `resistencia_dano`, `efectividad_herramienta`, `objetivos`, `recompensa`, `efectos_mundo`, `estado_logro_clanes`, `posicion_actual`, `progreso_objetivos`, etc. Esto permite flexibilidad para los diseñadores sin cambios de esquema en cada iteración de contenido.
* **ARRAY(db.Integer):** Para listas de IDs como `habilidades_aprendidas`.
* **Claves Foráneas (`db.ForeignKey`, `db.relationship`):** Establecen las conexiones entre las tablas. Se utilizan `lazy=True` (carga perezosa) y `uselist=False` cuando la relación es de uno a uno.
* **`UniqueConstraint`:** Para asegurar la unicidad combinada (ej., `Mundo` por `tipo_mundo` y `propietario`).

### 2. Esquemas de Serialización (`backend/app/schemas.py`)

* **Marshmallow:** Utilizado para convertir objetos Python a JSON (para la API) y viceversa.
* **`fields.Raw()`:** Para mapear directamente los campos `JSONB`.
* **`validate.OneOf`, `validate.Length`, `validate.Range`:** Para validación de datos a nivel de aplicación, asegurando que los datos que entran a la base de datos son válidos.

### 3. Gestión de la Base de Datos (`backend/manage.py`)

* **`flask db init/migrate/upgrade`:** Flujo estándar para gestionar el esquema de la base de datos de forma versionada y controlada.
* **`create_all_tables`/`drop_all_tables`:** Comandos directos de SQLAlchemy para recrear la base de datos desde cero, útil para entornos de desarrollo y pruebas.
* **`seed`:** Contiene lógica para poblar la base de datos con datos de ejemplo. La secuencia de inserción es crítica debido a las dependencias de claves foráneas, asegurando que las tablas referenciadas existan antes de insertar las que las referencian.
    * Se utiliza `session.flush()` para obtener IDs de objetos recién creados antes de que se haga el `commit` final, permitiendo usar esos IDs en relaciones `NOT NULL`.
    * Se importa `generate_password_hash` para almacenar contraseñas de forma segura.

### 4. Entorno de Pruebas (`backend/tests/conftest.py` y `backend/tests/test_*.py`)

* **Base de Datos de Prueba Aislada:** El `conftest.py` configura `pytest` para usar una base de datos PostgreSQL separada (`el_ultimo_bastion_test_db`).
* **Limpieza por Test:** El fixture `session` en `conftest.py` limpia explícitamente los datos de las tablas más relevantes (las que tienen restricciones `UNIQUE` o son pobladas en cada test) antes de la ejecución de cada test unitario. Esto garantiza que cada test se ejecuta en un estado de base de datos limpio e independiente.
* **Transacciones Anidadas:** Los tests se ejecutan dentro de transacciones anidadas, que se revierten al final de cada test. Esto asegura que los cambios realizados por un test no afecten a otros tests.
* **Simulación de Interacciones:** Los tests simulan la creación, lectura y actualización de modelos, incluyendo casos límite como la violación de restricciones de unicidad o la actualización de campos `JSONB` (donde se utilizó `flag_modified` para asegurar el dirty tracking de SQLAlchemy).

## 🚧 Bloqueadores/Riesgos Superados

* **Problemas de Carga de Variables de Entorno (`.env`):** Resuelto asegurando la carga explícita de `dotenv_values` en `conftest.py`.
* **`ModuleNotFoundError`:** Resuelto con la configuración de `PYTHONPATH`.
* **`InvalidRequestError` (Doble mapeo de `InstanciaAldea`):** Resuelto asegurando una única y completa definición de la clase `InstanciaAldea` en `models.py`.
* **`NotNullViolation` y `ForeignKeyViolation` en Tests:** Resueltos ajustando el orden de `session.add()` / `session.flush()` en los tests, y asegurando que las dependencias existan con IDs válidos antes de ser referenciadas.
* **`AssertionError` en Actualización de `JSONB`:** Resuelto utilizando `flag_modified` para forzar a SQLAlchemy a detectar cambios en campos `JSONB` mutables.

## 🤝 Colaboración

* **Roles Involucrados:** Desarrollador Backend, Experto en Bases de Datos, QA (a través de tests).
* **Instrucciones para Colaboradores:** Al trabajar en la base de datos, siempre ejecutar los tests unitarios relevantes después de cualquier cambio y asegurar que pasen. Referirse a `DATABASE_SCHEMA.md` para la definición de tablas.

## 🗓️ Log de Actualizaciones de Tarea

| Fecha       | Actualización                                                                                                                                                                             | Responsable |
| :---------- | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :---------- |
| 2025-07-19  | Creación inicial del documento `task_1_2_postgresql_database.md` con pasos detallados y criterios de aceptación para la implementación completa y validada de la base de datos. | AI          |