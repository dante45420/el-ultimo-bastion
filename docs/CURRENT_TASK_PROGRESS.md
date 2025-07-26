# Progreso de Tareas - El Último Bastión

## 📊 Estado Actual del Proyecto
**Fecha de última actualización:** 2025-07-26
**Fase actual:** Fase 2 - Depuración de Conexión Básica y Mundo Sandbox
**Próximo hito:** Lograr que el personaje del jugador (Bastión) sea visible, controlable y no caiga a través del mundo.

### Resumen Ejecutivo
- ✅ **Infraestructura Base Completa:** La base de datos, el backend y la estructura del proyecto son sólidos.
- ✅ **Conexión Funcional:** Godot se conecta exitosamente al backend, carga los datos del mundo y los NPCs. El terreno se genera dinámicamente a partir de la base de datos.
- ⏳ **En progreso:** Depuración de la física y la visualización del jugador en el "Mundo Sandbox". Se están resolviendo problemas de colisiones ("caída al vacío") y de visibilidad del personaje.
- 🎯 **Objetivo inmediato:** Alcanzar un estado "jugable" básico donde el jugador puede moverse por un mundo sólido y ver a su personaje y a los NPCs.

---

## 🗂️ Tareas Organizadas por Fases

### **FASE 1: INFRAESTRUCTURA BASE**

#### 1.1 Estructura del Proyecto
- **Estado:** ✅ Completada

#### 1.2 Base de Datos PostgreSQL
- **Estado:** ✅ Completada y Validada

---

### **FASE 2: CONEXIÓN BÁSICA Y MUNDO SANDBOX**

#### 2.1 Mundo Sandbox Editable
- **Estado:** ✅ **Completada (Base Funcional)**
- **Prioridad:** Crítica
- **Descripción:** Se ha implementado la lógica para que Godot se conecte al `Mundo Sandbox` definido en la base de datos. El terreno se genera proceduralmente usando `FastNoiseLite`, y sus parámetros (`terrain_size`, `noise_octaves`, etc.) se leen correctamente desde la configuración del mundo en la DB. Las instancias de NPCs asociadas a este mundo también se cargan.
- **Entregables:**
  - ✅ Conexión Godot -> Backend para obtener datos del mundo.
  - ✅ Generación de terreno voxel procedural basado en `semilla` y `configuracion_actual`.
  - ✅ Instanciación de NPCs en sus posiciones correctas.
  - 🚧 **Pendiente:** Depuración de la física del terreno para que sea sólido.

#### 2.2 Bastión (Personaje Jugador)
- **Estado:** ⏳ **En Progreso**
- **Prioridad:** Crítica
- **Descripción:** Se ha implementado el script `Player.gd` para el personaje jugador. El script carga los datos del `Bastion` desde el backend y permite el control de movimiento (WASD) y cámara (ratón). Actualmente se encuentra en fase de depuración para solucionar problemas de visibilidad y colisiones.
- **Entregables:**
  - ✅ Script de `Player.gd` con lógica de movimiento y cámara.
  - ✅ Conexión con el backend para cargar datos iniciales del Bastión.
  - 🚧 **Pendiente:** Solucionar el bug que impide ver el modelo del personaje.
  - 🚧 **Pendiente:** Solucionar el bug de colisiones que provoca que el personaje caiga a través del suelo.

---

### **PRÓXIMOS PASOS INMEDIATOS**

1.  **[CRÍTICO] Debugging de Física y Visualización:**
    * **Objetivo:** Solucionar el bug de "caída al vacío".
    * **Acción:** Verificar y corregir la configuración de **Capas y Máscaras de Colisión** (`Collision Layers/Masks`) en el editor de Godot para el jugador y los objetos del mundo. Implementar un "suelo de emergencia" para garantizar una base sólida.
    * **Objetivo:** Solucionar el bug del "personaje invisible".
    * **Acción:** Asegurar que el script `Player.gd` cree una malla visual por defecto (cápsula magenta) y que la cámara (`SpringArm3D`) esté configurada con una distancia (`spring_length`) para garantizar una vista en tercera persona.
2.  **Verificación Visual de NPCs:**
    * **Objetivo:** Confirmar que los NPCs son visibles en el mundo.
    * **Acción:** Implementar una malla visual por defecto (cubos de colores) para los NPCs para que sean fácilmente identificables.
3.  **Refinamiento de Controles:**
    * **Objetivo:** Asegurar que el personaje se mueve y salta correctamente sobre el terreno sólido.
    * **Acción:** Probar los controles de movimiento una vez que el personaje colisione correctamente.


### **FASE 3: Contenido de Tipos y Comportamientos (Enfoque Scrum - Nivel de Feature)**

#### 3.1 Tipos de Entidades Base (NPCS, Animales, Recursos Terreno)
- **Estado:** 🔴 Pendiente
- **Prioridad:** Media
- **Descripción:** Implementar la gestión de las "definiciones" o "tipos" de entidades que se usarán para poblar los mundos. Esto incluye `TipoNPC`, `TipoAnimal`, `TipoRecursoTerreno`, `TipoEdificio`, `TipoMision`, `TipoEventoGlobal`, `TipoPista`, `TipoComercianteOferta`, `TipoLootTable`.
- **Entregables:**
  - APIs CRUD para todas estas tablas de `Tipo_`.
  - Páginas de panel de administración para definir estos tipos de entidades.
  - El `seed` de `manage.py` se expande para incluir ejemplos de estos tipos.
- **Dependencias:** 2.1 (El Mundo Sandbox es el lienzo para probar estos tipos)
- **Estimación:** 15-20 horas (ya tenemos los modelos y esquemas, esto es API y Frontend)

#### 3.2 Comportamientos y Visualizaciones Avanzadas de Entidades
- **Estado:** 🔴 Pendiente
- **Prioridad:** Media
- **Descripción:** Desarrollar la lógica de comportamiento y visualización avanzada para las entidades.
- **Entregables:**
  - Lógica de IA para `TipoNPC.rol_npc` (Constructor, Malvado, Comerciante, Mago).
  - Lógica de IA para `TipoAnimal.comportamiento_tipo` (Hostil, Pacífico, Territorial).
  - Carga dinámica de assets 3D/2D en Godot basada en `id_grafico`, incluyendo ajuste de tamaño y hitbox.
  - Implementación de `resistencia_dano` y `efectividad_herramienta`.
- **Dependencias:** 3.1 (necesita los Tipos definidos)
- **Estimación:** 15-20 horas

---

### **FASE 4: DESPLIEGUE Y COLABORACIÓN**

#### 4.1 Despliegue en Render
- **Estado:** 🔴 Pendiente
- **Prioridad:** Alta
- **Descripción:** Subir backend y frontend a Render para colaboración.
- **Entregables:** Backend y Frontend desplegados y accesibles; DB remota; Godot se conecta a la API remota.
- **Dependencias:** 2.1 (Backend y Frontend funcional), 2.2 (Backend para Bastion)
- **Estimación:** 4-6 horas

#### 4.2 Distribución del Juego (Godot)
- **Estado:** 🔴 Pendiente
- **Prioridad:** Media
- **Descripción:** Generar builds del juego y establecer proceso de distribución para testers.
- **Entregables:** Builds ejecutables del juego; Instrucciones de instalación/ejecución; Feedback loop establecido.
- **Dependencias:** 4.1
- **Estimación:** 3-4 horas

---

### **FASE 5: SISTEMAS DE JUEGO CENTRALES**

#### 5.1 Sistema de Aldeas Completo
- **Estado:** 🔴 Pendiente
- **Prioridad:** Media
- **Descripción:** Implementar aldeas con edificios, gestión de inventario, relaciones con NPCs y funciones de producción.
- **Entregables:** API para `InstanciaAldea` e `InstanciaEdificio`; Panel admin para aldeas y edificios; Sistema de construcción en Godot; Lógica de producción; Interacción de NPCs constructores.
- **Dependencias:** 2.1 (Mundo Sandbox), 3.1 (Tipos de Edificio, NPC Constructor)
- **Estimación:** 15-20 horas

#### 5.2 Sistema de Clanes
- **Estado:** 🔴 Pendiente
- **Prioridad:** Media
- **Descripción:** Implementar el sistema completo de clanes (creación, gestión de miembros, Baluarte).
- **Entregables:** API para clanes; Panel admin; Funcionalidades de clan en Godot; Inventario de clan.
- **Dependencias:** 2.1 (Mundo Sandbox), 2.2 (Bastion), 3.1 (Usuario, Clan)
- **Estimación:** 12-15 horas

#### 5.3 Misiones y Eventos
- **Estado:** 🔴 Pendiente
- **Prioridad:** Media
- **Descripción:** Implementar el sistema de misiones y eventos globales.
- **Entregables:** API para `MisionActiva` y `EventoGlobalActivo`; Panel admin; Lógica de misiones en Godot (aceptar, progresar, completar); Lógica de eventos en Godot (activación, efectos, objetivos).
- **Dependencias:** 2.1 (Mundo Sandbox), 3.1 (Tipos de Misión, Evento)
- **Estimación:** 15-20 horas

---

### **FASE 6: ESCALABILIDAD Y REJUGABILIDAD**

#### 6.1 Interacción y Progresión Jugador-Entidad
- **Estado:** 🔴 Pendiente
- **Prioridad:** Alta
- **Descripción:** Conectar el Bastión con NPCs, animales y aldeas para interacciones completas de juego.
- **Entregables:** Combate Jugador-Entidad; Recolección; Comercio; Domesticación/Montura; Misiones (todo integrado en Godot).
- **Dependencias:** 2.2 (Bastión), 3.2 (Comportamientos de Entidades), 5.1 (Animales), 5.2 (Aldeas), 5.3 (Misiones, Eventos).
- **Estimación:** 15-20 horas

#### 6.2 Mundos Múltiples (Personal/Clan) y Épocas
- **Estado:** 🔴 Pendiente
- **Prioridad:** Media
- **Descripción:** Implementar la gestión de múltiples mundos y el sistema de Épocas para rejugabilidad.
- **Entregables:** Lógica para crear y gestionar Mundos Personales/de Clan; Transición entre mundos; Lógica de reinicio de Época; Persistencia de progreso selectivo entre Épocas.
- **Dependencias:** 2.1 (Fundamento de Mundo), 5.2 (Clanes), 5.3 (Eventos).
- **Estimación:** 20-25 horas

---

### **FASE 7: EXPANSIÓN (Futuro)**

#### 7.1 Funcionalidades Avanzadas
- **Estado:** 🔴 Pendiente
- **Prioridad:** Baja
- **Descripción:** Características adicionales (crafteo complejo, árboles de habilidades, eventos fuera de pantalla).
- **Notas:** Se definirá según progreso de fases anteriores y feedback.

---

## 🚀 Próximos Pasos Inmediatos (Para la Siguiente Sesión de Gemini)

### Esta Semana
1.  **[CRÍTICO]** Continuar **Fase 2.1: Mundo Sandbox Editable y Editor de Contenido In-World**.
    * **Paso 1: Identificar/Crear el Mundo Sandbox:** Asegurarnos de que un `Mundo` con `nombre="Mundo Sandbox para Devs"` exista en la DB y que Godot lo cargue. (ESTO YA ESTÁ HECHO Y VERIFICADO EN TU ÚLTIMA SALIDA).
    * **Paso 2: Godot Engine - Cargar el Mundo Sandbox por Defecto** (ESTO YA ESTÁ HECHO Y VERIFICADO EN TU ÚLTIMA SALIDA).
    * **Paso 3: Backend API para `InstanciaNPC` (CRUD básico):** (ESTO YA ESTÁ HECHO EN `admin_routes.py`).
    * **Paso 4: Frontend para `InstanciaNPCAdminPage.jsx` (Formulario y Lista):** (ESTO YA ESTÁ HECHO).
    * **Paso 5: Godot Engine - Instanciación de `InstanciaNPC` en el Mundo Sandbox:** Que Godot cargue los NPCs creados para el Mundo Sandbox. (ESTO YA ESTÁ HECHO Y VERIFICADO EN TU ÚLTIMA SALIDA).
    * **Paso 6: Godot Engine - Implementar Control Básico de Cámara/Jugador (`Player.gd` y `main_scene.tscn`):** Permite moverte por el mundo y ver los NPCs. (LO QUE EMPEZAMOS A HACER).
    * **Paso 7: Backend API para `Bastion` (CRUD básico):** Para poder editar los stats del Bastión desde el panel.
    * **Paso 8: Frontend para `BastionAdminPage.jsx`:** Para editar el Bastión.
    * **Paso 9: Godot Engine - Cargar y Sincronizar Stats del Bastión:** Conectar `Player.gd` al backend para mostrar y actualizar los stats.

### Siguientes 2 Semanas
1.  Comenzar **Fase 3.1 Tipos de Entidades Base** (APIs y Paneles para el resto de Tipos: `TipoAnimal`, `TipoEdificio`, etc.).

---

## 📋 Notas Importantes para Nuevos Chats / Colaboradores

### Contexto Clave
-   **Proyecto:** Videojuego multijugador de misterio y supervivencia
-   **Arquitectura:** Godot + Flask + PostgreSQL + React
-   **Filosofía:** Diseño Data-Driven (contenido editable sin código)
-   **Objetivo:** Que historiadores/diseñadores puedan crear contenido fácilmente

### Archivos de Referencia Esenciales (Confirmados y Actualizados)
-   `PROJECT_OVERVIEW.md` - Visión completa del juego.
-   `DATABASE_SCHEMA.md` - Esquema detallado de la BD.
-   `DEVELOPMENT_GUIDELINES.md` - Guías técnicas y de colaboración.
-   `CURRENT_TASK_PROGRESS.md` - Estado actual de las tareas del proyecto (este documento).

### Estado Técnico Actual
-   **Completado:** Todas las definiciones de modelos de base de datos ORM están completas y se ha validado su funcionalidad con tests unitarios exhaustivos (Tandas 1 a 5).
-   **En progreso:** Fase 2.1 Mundo Sandbox Editable y Editor de Contenido In-World. Ya se carga el mundo Sandbox y los NPCs son generados visualmente.
-   **Bloqueadores:** Falta el control de cámara/jugador en Godot para ver los NPCs, e integrar la edición de stats del Bastión desde el panel.
-   **Decisiones técnicas tomadas:** Stack tecnológico completo definido; arquitectura data-driven confirmada; enfoque en Mundo Sandbox para desarrollo.

### Para Empezar Desarrollo
1.  Siempre revisar este documento (`CURRENT_TASK_PROGRESS.md`) primero.
2.  Consultar `PROJECT_OVERVIEW.md`, `DATABASE_SCHEMA.md` y `DEVELOPMENT_GUIDELINES.md` para el contexto.
3.  Seguir el orden de prioridades establecido en "Próximos Pasos Inmediatos".
4.  Actualizar este documento al completar tareas.

---

## 🔄 Log de Cambios

| Fecha       | Actualización                                                                                                                                                                                                                                                                         | Responsable |
| :---------- | :--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :---------- |
| 2025-01-28  | Creación inicial del documento con todas las tareas prioritarias.                                                                                                                                                                                                            | Sistema     |
| 2025-07-19  | Completada y validada la "Fase 1.2 Base de Datos PostgreSQL".                                                                                                                                                                                                           | Humano/AI   |
| 2025-07-19  | Reajuste del plan para priorizar "Mundo Sandbox Editable" y "Editor de Contenido In-World" (Fase 2.1). Fusión de Fase 3.1 inicial en Fase 2.1. Ajuste de descripciones y estimaciones de tareas futuras. | Humano/AI   |
| 2025-07-19  | **Ajuste de la visión del panel de administración y mundos personales/clan:** Clarificación sobre la edición de entidades *dentro* de mundos personales por el administrador para misiones/interacciones. Detalle del panel en 3 páginas: Tipos, Gestión de Mundos (con editor In-World), Apariencias. Actualización de `PROJECT_OVERVIEW.md` y `DEVELOPMENT_GUIDELINES.md`. | Humano/AI   |
| 2025-07-20  | **Confirmación de Godot Sandbox World y NPC generation:** Se verificó que el mundo sandbox se carga y los NPCs se generan visualmente, aunque la cámara/control de jugador es una limitación actual. Se actualiza el `CURRENT_TASK_PROGRESS.md`. | Humano/AI   |

---

**Para colaboradores nuevos:** Este documento es la fuente de verdad del progreso. Siempre consultarlo antes de comenzar cualquier trabajo.