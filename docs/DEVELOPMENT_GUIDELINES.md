# Guía de Desarrollo para "El Último Bastión"

## 1. Filosofía de Desarrollo

* **Data-Driven Design:** La lógica del juego se basa en datos cargados desde la base de datos. Esto permite a los diseñadores (historiadores, artistas) crear contenido sin tocar el código. El código base debe ser genérico y extensible.
* **Modularidad:** Cada componente (backend, frontend, motor de juego) es independiente y se comunica a través de APIs bien definidas (REST/WebSockets). Esto facilita la colaboración y el escalado.
* **Reutilización:** Priorizar el uso de componentes, bibliotecas y assets existentes (gratuitos o de la comunidad) para minimizar el tiempo de desarrollo desde cero.
* **Gráficos Simplificados:** Enfoque en la interactividad y narrativa, no en gráficos fotorrealistas. Los assets gráficos deben ser fácilmente modificables y reutilizables (pixel art, voxel básico).

## 2. Stack Tecnológico

* **Motor de Juego:** Godot Engine (GDScript, con opción a C# o C++ para optimizaciones).
* **Backend / API:** Python con Flask.
* **Base de Datos:** PostgreSQL.
* **Frontend (Panel de Administración):** React con Vite.
* **Comunicación entre Servicios:** HTTP REST (JSON) y/o WebSockets (para tiempo real si es necesario).

## 3. Flujo de Trabajo y Colaboración

### 3.1. Control de Versiones (Git)

* Utilizar **Git** para todo el código fuente.
* **Ramas de Features:** Cada tarea o funcionalidad nueva debe desarrollarse en una rama separada (ej. `feature/npc-admin-panel`, `bugfix/fix-login`).
* **Pull Requests (PRs):** Abrir PRs para revisar el código antes de fusionar a `main`. Requiere aprobación de al menos otro desarrollador.
* **Commits Claros:** Mensajes de commit descriptivos y concisos.

### 3.2. Proceso de Desarrollo (Iterativo)

1.  **Definición de Tarea:** Clarificar qué se va a implementar (ej. "Implementar la creación de TipoNPC en el panel de admin").
2.  **Desarrollo de Módulos:**
    * **Backend:** Implementar modelos, esquemas, rutas API.
    * **Frontend:** Desarrollar componentes UI para el panel.
    * **Godot:** Implementar scripts para consumir la API y visualizar/simular la lógica.
3.  **Pruebas:**
    * **Locales:** Probar cada módulo individualmente.
    * **Integración:** Asegurarse de que los módulos se comunican correctamente (ej. crear NPC en panel, verlo en Godot).
4.  **Documentación:** **¡Crucial!** Cada funcionalidad o clase nueva debe documentarse inmediatamente.

## 4. Directrices para Historiadores y Diseñadores (Uso del Panel de Administración)

El panel de administración es su principal herramienta para crear contenido del juego. No se requiere saber programar, pero sí entender cómo se estructuran los datos.

* **Acceso al Panel:** Se les proporcionará una URL y credenciales de acceso al panel de administración (ej. `http://localhost:5173` en desarrollo, URL de producción después).
* **Campos de Formulario y su Impacto:**
    * Cada formulario en el panel corresponde a un "Tipo" de entidad (ej. TipoNPC, TipoObjeto).
    * **Nombre:** El nombre que aparecerá en el juego.
    * **Descripción:** Texto que ayuda a entender el propósito o lore de la entidad.
    * **ID Gráfico:** **Este es un identificador clave.** Es una cadena de texto (ej. "goblin_a_sprite", "longsword_mesh") que el motor Godot usará para saber qué recurso visual (modelo 3D, sprite, textura) cargar para esta entidad.
        * **Preguntar a los Artistas:** El equipo de arte les proporcionará una lista de IDs gráficos disponibles y las convenciones.
        * **Consistencia:** Usen exactamente los IDs proporcionados para que los gráficos aparezcan correctamente.
    * **Valores Numéricos (Salud, Daño, etc.):** Impactan directamente las mecánicas del juego. Experimenten con ellos para balancear el juego.
    * **Campos JSON (ej. `loot_posible`, `habilidades_activas`):**
        * Estos campos requieren un formato JSON válido (objetos `{}` o arrays `[]`).
        * **`loot_posible`:** Define qué objetos suelta un NPC y con qué probabilidad.
            * Formato: `[{"id_objeto": ID_DEL_OBJETO, "probabilidad": 0.X}, ...]`
            * `ID_DEL_OBJETO`: Es el ID numérico de un `TipoObjeto` ya creado.
        * **`habilidades_activas`:** Lista de IDs de habilidades que el NPC puede usar.
            * Formato: `[ID_HABILIDAD_1, ID_HABILIDAD_2, ...]`
            * `ID_HABILIDAD_X`: Es el ID numérico de un `TipoHabilidad` ya creado.
        * **Validación:** El panel podría dar errores si el JSON no es válido. Usen un validador JSON si es necesario.
    * **Campos de Texto Libre (ej. `comportamiento_ia`):** Estos campos son descriptivos para los programadores. Sirven como una guía de diseño sobre cómo debería actuar la IA.
* **Proceso de "Ver en el Juego":**
    1.  Modificar o crear una entidad en el panel de administración y guardarla.
    2.  El programador del motor de Godot ejecutará el juego (o lo recargará).
    3.  El juego se conectará automáticamente al backend, cargará los datos más recientes y la entidad debería aparecer o comportarse según su definición.
    4.  Reportar cualquier discrepancia o sugerencia a los desarrolladores en el canal de comunicación.

## 5. Pruebas y Retroalimentación

* **Entorno de Desarrollo:** Siempre trabajaremos en un entorno de desarrollo donde los cambios pueden ser rápidos y donde se permite romper cosas temporalmente.
* **Canales de Comunicación:** Usaremos [Slack/Discord/Microsoft Teams] para la comunicación diaria, preguntas rápidas y coordinar.
* **Reporte de Bugs/Feedback:** Utilizar un sistema de seguimiento de tareas (ej. Trello, Jira, GitHub Issues) para reportar bugs, sugerir mejoras o dar feedback detallado.

---