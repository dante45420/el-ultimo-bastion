---

### **2. `DEVELOPMENT_GUIDELINES.md` (Actualizado)**

```markdown
# Guía de Desarrollo para "El Último Bastión"

## 1. Filosofía de Desarrollo

* **Data-Driven Design:** La lógica del juego se basa en datos cargados desde la base de datos. Esto permite a los diseñadores (historiadores, artistas) crear contenido sin tocar el código. El código base debe ser genérico y extensible.
* **Modularidad:** Cada componente (backend, frontend, motor de juego) es independiente y se comunica a través de APIs bien definidas (REST/WebSockets). Esto facilita la colaboración y el escalado.
* **Reutilización:** Priorizar el uso de componentes, bibliotecas y assets existentes (gratuitos o de la comunidad) para minimizar el tiempo de desarrollo desde cero.
* **Gráficos Simplificados:** Enfoque en la interactividad y narrativa, no en gráficos fotorrealistas. Los assets gráficos deben ser fácilmente modificables y reutilizables (pixel art, voxel básico).

## 2. Stack Tecnológico

* **Motor de Juego:** Godot Engine (**v4.1.1 o superior**).
    > **Nota Crítica:** El proyecto está desarrollado sobre Godot 4. La API de esta versión es significativamente diferente a la de Godot 3. Cualquier desarrollo o consulta de documentación debe hacerse específicamente para Godot 4 para evitar errores fundamentales (ej. el manejo de `FastNoiseLite`).
* **Backend / API:** Python con Flask.
* **Base de Datos:** PostgreSQL.
* **Frontend (Panel de Administración):** React con Vite.

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

## 4. Directrices para Historiadores y Diseñadores (Uso del Panel de Administración - NUEVO ENFOQUE)

El panel de administración se concibe como una herramienta central para la creación y gestión del contenido del juego a diferentes niveles:

### 4.1. Páginas Principales del Panel:

* **"Definición de Tipos" (Genérica):**
    * **Propósito:** Crear y gestionar las "plantillas" o "recetas" globales de los elementos del juego. Aquí se definen `TipoObjeto`, `TipoNPC`, `TipoAnimal`, `TipoEdificio`, `TipoHabilidad`, `TipoLootTable`, `TipoComercianteOferta`, `TipoMision`, `TipoEventoGlobal`, `TipoPista`.
    * **Interfaz:** Formularios intuitivos con validación de entrada, listado de tipos creados.

* **"Gestión de Mundos y Contenido In-World":**
    * **Propósito:** Seleccionar una instancia de `Mundo` y poblarla/editarla con `Instancia`s de entidades.
    * **Flujo:** Primero se selecciona un `Mundo` específico (ej., "Mundo Sandbox para Devs", o el Mundo Personal de un jugador específico, o un Mundo de Clan). Una vez seleccionado, se habilita el editor de contenido para ese mundo.
    * **Edición de Geografía Global (para el `Mundo` seleccionado):**
        * Modificar `Mundo.semilla_generacion`.
        * Editar `Mundo.configuracion_actual` (ej. clima, nivel de peligro).
        * (La edición granular de `Mundo.estado_actual_terreno` de forma visual es más compleja y se pospone, priorizando la creación de entidades).
    * **Edición de Entidades In-World (Instancias):**
        * Listas de `InstanciaNPC`, `InstanciaAnimal`, `InstanciaRecursoTerreno`, `InstanciaAldea`, `InstanciaEdificio`, `MisionActiva`, `EventoGlobalActivo` presentes en *ese `Mundo` seleccionado*.
        * Formularios para añadir nuevas `Instancia`s a este mundo (seleccionando su `Tipo_` y `posicion`).
        * Opciones para editar el estado de instancias existentes (ej., `posicion` de un NPC, `salud_actual` de un edificio, `esta_agotado` de un recurso, `estado_mision` de una misión activa).
    * **Comportamiento por Tipo de Mundo (Visión Detallada):**
        * **Mundo Sandbox:** Este será el foco de desarrollo inicial. Totalmente editable en esta página. Los cambios afectan solo a *esta instancia específica* de `Mundo` compartida por los desarrolladores para pruebas.
        * **Mundos Personales:** Se pueden seleccionar Mundos Personales de jugadores específicos para editarlos. **Los NPCs, Aldeas, Animales, etc. *dentro de un mundo personal específico* pueden ser editados por el administrador para influir en misiones e interacciones individuales del jugador.** La `semilla_generacion` y `configuracion_actual` de un `Mundo` de tipo `PERSONAL` (si se hace desde la "Definición de Tipos" de `Mundo` y se aplica globalmente) afectaría a todos los Mundos Personales que compartan esa configuración. La "interacción" del jugador (completar misiones, domar animales) se realiza en Godot y se guarda en tablas vinculadas al jugador.
        * **Mundo del Clan:** El panel permitirá crear nuevos "servidores de juego" (instancias de `Mundo` tipo `CLAN`), asignar clanes a ellos según nivel para equilibrar. La edición de eventos afectará a estos mundos de clan. Aquí la dinámica es más compleja por los ciclos de Épocas y reinicios.

* **Página 3: "Gestión de Apariencias" / "Assets":**
    * **Propósito:** Centralizar la gestión visual de los assets del juego.
    * **Funcionalidad:**
        * Listado de todos los `id_grafico` disponibles (para todos los `Tipo_`s).
        * Poder asociar un `id_grafico` a sus propiedades visuales/físicas clave (ej. `escala_modelo`, `dimensiones_hitbox` - almacenadas en `valores_especificos` o `valores_rol` de los Tipos).
        * **Previsualización:** La previsualización de cómo "queda" un asset se hará principalmente en Godot Engine.

### 4.2. Campos de Formulario y su Impacto:

* **`ID Gráfico`:** Es un identificador clave. Cadena de texto (ej. "goblin_a_sprite", "longsword_mesh") que Godot usará para cargar el recurso visual. Proporcionado por el equipo de arte.
* **Campos JSON (ej. `valores_especificos`, `resistencia_dano`, `posicion`, `objetivos`):** Requieren formato JSON válido. Controlan parámetros complejos de comportamiento, interacción y estado.
* **Valores Numéricos:** Afectan directamente las mecánicas del juego (salud, daño, velocidad).

### 4.3. Proceso de "Ver en el Juego" (Debugging):

1.  Modificar o crear una entidad en el panel de administración y guardarla.
2.  El programador del motor de Godot ejecutará el juego (o lo recargará).
3.  El juego se conectará automáticamente al backend, cargará los datos más recientes y la entidad debería aparecer o comportarse según su definición.
4.  Reportar cualquier discrepancia o sugerencia a los desarrolladores en el canal de comunicación.

## 5. Pruebas y Retroalimentación

* **Entorno de Desarrollo:** Siempre trabajaremos en un entorno de desarrollo donde los cambios pueden ser rápidos y donde se permite romper cosas temporalmente.
* **Canales de Comunicación:** Usaremos [Slack/Discord/Microsoft Teams] para la comunicación diaria, preguntas rápidas y coordinar.
* **Reporte de Bugs/Feedback:** Utilizar un sistema de seguimiento de tareas (ej. Trello, Jira, GitHub Issues) para reportar bugs, sugerir mejoras o dar feedback detallado.

---

**5. GESTIÓN DE PROGRESO DE JUGADOR Y LOGEO (SANDBOX VS. PRODUCCIÓN):**

* **Sistema de Logeo en Godot (Futuro):**
    * El cliente Godot enviará credenciales (username/password) a un endpoint de autenticación en Flask (`backend/app/api/auth_routes.py`).
    * Flask verificará contra la tabla `Usuario` y devolverá un token de sesión.
    * Todas las llamadas API de Godot posteriores usarán este token para identificar al jugador.
* **Gestión del Progreso (Sandbox vs. Personal/Clan - ENFOQUE ADAPTATIVO):**
    * **Fase Actual (Desarrollo - Mundo Sandbox):**
        * Godot se conectará **por defecto al `Mundo` de la base de datos cuyo `nombre_mundo` sea "Mundo Sandbox para Devs"**.
        * Todos los desarrolladores y diseñadores compartirán este mismo `Mundo Sandbox`.
        * El progreso del `Bastion` (jugador actual), `InstanciaNPC`, `InstanciaAldea`, etc., creado o modificado en el Sandbox se guardará en las tablas de `Instancia_` vinculadas al ID de ese `Mundo Sandbox`.
        * **Progreso de Desarrolladores:** Inicialmente, cada desarrollador puede usar un `Bastion` de "desarrollador" pre-existente (del `seed`) que esté vinculado a este Mundo Sandbox. El progreso de ese `Bastion` se guarda en el Sandbox.
    * **Transición a Producción (Mundo Personal/Clan - Más Adelante):**
        * Cuando el juego esté cerca de producción, la lógica de Godot se adaptará:
            * Al logearse, Godot consultará la tabla `Bastion` (o una nueva tabla `PlayerSession` vinculada al `Usuario`) para obtener el `id_mundo` al que debe conectarse el jugador (`Mundo` personal del jugador o `Mundo` de Clan al que pertenece su clan).
            * **Mundos Personales:** Se crearán automáticamente para cada `Usuario` nuevo (`manage.py` o API de registro). El `Bastion` del jugador se vinculará a su `Mundo` personal. Godot cargará las `Instancia_`s vinculadas al `id_mundo` personal del jugador. **El administrador podrá editar estas instancias (`InstanciaNPC`, `InstanciaAldea`, etc.) para un mundo personal específico a través del panel de administración.**
            * **Mundos de Clan:** Podría haber un `Mundo` de Clan principal por defecto, o varios `Mundo`s de Clan que se crean (y resetean por Épocas) y a los cuales se asignan los clanes. La lógica de Godot cargará las `Instancia_`s del `Mundo` de Clan al que pertenezca el `Bastion` del jugador.
        * La clave es que la estructura de la base de datos ya está pensada para esto. Las tablas `Instancia_` (`InstanciaNPC`, `InstanciaAldea`, etc.) tienen un `id_mundo` que las vincula a una instancia específica de `Mundo`.

---

**4. DESAFÍOS IDENTIFICADOS (Y CONSIDERACIONES PARA COPILOT):**

* **Gestión de Contexto en Chats Largos:** Los modelos de lenguaje tienden a perder el hilo en conversaciones extensas. **SOLUCIÓN:** Romper las solicitudes en pasos muy pequeños y atómicos. Nunca pidas "todo el juego" a la vez. Cada prompt debe ser una tarea específica y limitada.
* **Plan de Inicio desde Cero con Colaboración Inmediata:** La dificultad de establecer un flujo de trabajo para que múltiples roles (devs, artistas, historiadores) puedan contribuir desde el principio con herramientas definidas y conectadas. **SOLUCIÓN:** La arquitectura modular y data-driven es la respuesta. Copilot debe ayudar a establecer las bases de cada módulo de forma independiente pero con puntos de conexión claros.
* **Complejidad del Código vs. Escalabilidad:** El riesgo de que la complejidad del juego (narrativa, eventos) se traduzca en un código inmanejable. **SOLUCIÓN:** El diseño data-driven es la clave para la simplicidad y escalabilidad del código. Copilot debe priorizar la creación de clases base genéricas y la delegación de comportamientos a los datos. El código principal debe ser simple y extensible.
* **Lentitud en el Desarrollo:** La necesidad de acelerar el progreso. **SOLUCIÓN:** Iteraciones rápidas, enfoque en prototipos funcionales y el uso eficiente de las herramientas.

---

**ESTRUCTURA DE REPOSITORIO (Confirmada):**