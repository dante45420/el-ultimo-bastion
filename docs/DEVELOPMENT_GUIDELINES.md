# Guía de Desarrollo para "El Último Bastión"

## 1. Filosofía de Desarrollo
**Data-Driven Design:** La lógica del juego se basa en datos. El código debe ser genérico y extensible. El contenido se crea y modifica exclusivamente desde el panel de administración. Esto permite una flexibilidad y maleabilidad donde la creatividad es el límite.

**Modularidad y Composición por Nodos:** Cada funcionalidad (salud, inventario, movimiento, IA) se encapsula en un "componente" (un nodo de Godot con su propio script). Estos componentes se añaden como hijos a las entidades principales (Jugador, NPC, Aldea), promoviendo la reutilización y evitando scripts monolíticos.

**Reutilización:** Priorizar componentes, scripts y assets existentes.

**Gráficos Simplificados:** El foco está en la interactividad, la narrativa emergente y la jugabilidad, no en el fotorrealismo.

## 2. Stack Tecnológico
**Motor de Juego:** Godot Engine (v4.1.1 o superior).
**Backend / API:** Python con Flask.
**Base de Datos:** PostgreSQL.
**Frontend (Panel de Administración):** React con Vite.

## 3. Flujo de Trabajo y Colaboración

### 3.1. El Flujo de Creación de Contenido (Regla de Oro)
Nuestro flujo de trabajo central para añadir contenido al juego:

1.  **Crear el Arquetipo (El "Molde"):**
    * **Dónde:** En las páginas de "Creación de Tipos" del panel de administración (ej. `TipoNPCAdminPage`).
    * **Qué:** Se define la plantilla de un objeto, criatura o elemento. Aquí se establecen todas sus propiedades base y configuraciones iniciales (salud máxima, velocidad base, tipo de rol, color, tamaño, etc.).
    * **Resultado:** Un nuevo "molde" genérico se guarda en la base de datos (ej. una nueva fila en la tabla `TipoNPC`).

2.  **Instanciar el Arquetipo (Las "Copias"):**
    * **Dónde:** En el "Editor de Contenido de Mundo" (ej. `WorldContentEditorPage` que usa `WorldNPCsEditor`).
    * **Qué:** Se selecciona un "molde" (arquetipo) de la lista de tipos existentes y se define únicamente su estado específico en un mundo particular (ej. su `posicion`, si está `esta_vivo`, o `valores_dinamicos` únicos para esa instancia).
    * **Resultado:** El sistema crea una "copia" (ej. `InstanciaNPC`) en la base de datos vinculada a un `Mundo`, que hereda automáticamente todas las propiedades de su arquetipo y se inicializa con ellas.

Este flujo es obligatorio y asegura que nuestro panel sea una herramienta de creación masiva y maleable para los diseñadores, sin necesidad de tocar código.

### 3.2. Directrices Técnicas Críticas

**Sincronización de la Base de Datos:** Cualquier cambio en `models.py` DEBE ir seguido de una actualización de la base de datos. Durante el desarrollo, el comando `python manage.py create_all_tables --force && python manage.py seed` es esencial para mantener todo sincronizado. No hacerlo causa errores de base de datos.

**Godot: Física vs. Visual:** Un nodo físico (`CharacterBody3D`) y su visual (`MeshInstance3D`) son entidades separadas. Para evitar que los modelos se hundan o floten, el nodo visual y de colisión siempre se debe ajustar para que su base se alinee con el origen del nodo físico (`visual.position.y = altura / 2.0`).

**Godot: Asignación de Scripts de Escenas:** Cuando se crea una nueva escena (`.tscn`) que será instanciada dinámicamente (como `NPC.tscn` o `HealthComponent.tscn`), su script (`.gd`) principal **DEBE estar asignado al nodo raíz de esa escena** dentro del editor de Godot para que el script se ejecute al instanciarse.

**Godot: Preload de Escenas:** Al precargar escenas (`const MY_SCENE = preload("res://path/to/my_scene.tscn")`), es crucial que la ruta sea absolutamente correcta. Godot debe poder encontrar y cargar el recurso.

**Godot: Capas de Colisión y Máscaras:** Para que los objetos (`CharacterBody3D`, `StaticBody3D`, `Area3D`) colisionen o detecten correctamente, sus `collision_layer` (en qué capa está) y `collision_mask` (con qué capas colisiona/detecta) deben configurarse apropiadamente.

### 3.3. Directrices para Historiadores y Diseñadores
(Se mantiene la estructura anterior, pero ahora reforzada por el flujo de trabajo del punto 3.1)

**Uso del Panel:** El panel es tu herramienta principal. Usa las páginas de "Crear Tipos" para diseñar los bloques de construcción del juego y el "Editor de Mundos" para poblar los niveles con instancias.

**Proceso de "Ver en el Juego":**
1.  Crea/modifica un arquetipo o instancia en el panel de administración.
2.  Inicia el juego en Godot Engine.
3.  Tus cambios aparecerán instantáneamente en el juego para ser probados. Si hay un problema, consulta a un desarrollador.

## 4. Visión de la Arquitectura de Componentes en Godot (Refinada)

El diseño del juego se basa en el principio de **composición de nodos** en Godot. Cada funcionalidad clave es un "componente" (un nodo reutilizable con su propio script) que se añade como hijo a las entidades principales (`PlayerCharacter`, `NPC`, `InstanciaAldea`, `InstanciaAnimal`).

**Componentes ya implementados y en uso:**
* **`HealthComponent.gd`:** Gestiona salud, daño, muerte y regeneración.
* **`HungerComponent.gd`:** Gestiona hambre, decaimiento y daño por inanición.
* **`InventoryComponent.gd`:** Gestiona almacenamiento de ítems, slots y peso.

**Próximos Componentes Esenciales (Ejemplos):**
* **`MovementComponent.gd`:** Encapsula la lógica de movimiento (caminar, volar, nadar) y las propiedades de colisión (`collision_layer`, `collision_mask`).
* **`VisualsComponent.gd`:** Manejará la carga de modelos 3D (`id_grafico`), aplicación de materiales, escala, y control de animaciones. También el `NameLabel`.
* **`CombatComponent.gd`:** Gestionará los ataques, habilidades de combate, cálculo de daño y cooldowns.
* **`AIComponent.gd`:** Para NPCs, implementará los comportamientos de IA definidos por su `rol_npc` (deambular, atacar, comerciar, construir).
* **`InteractionComponent.gd`:** Manejará interacciones no combativas (diálogos, comercio, misiones, recolección).
* **`QuestLogComponent.gd`:** Para el jugador, gestionará las misiones activas y su progreso.

**Interacciones y Maleabilidad:**
La clave para la maleabilidad es que estos componentes se comunican a través de **señales** (para eventos) y **llamadas directas a métodos de hermanos** (para solicitar acciones o datos). El `DataLoader` es el puente con el backend, permitiendo que las configuraciones de los componentes provengan directamente de la base de datos, posibilitando una variedad infinita de comportamientos y apariencias sin tocar el código central de Godot. Por ejemplo, un evento global puede cambiar la "gravedad" o "comportamiento_ia" en la base de datos, y los componentes lo leerán y se adaptarán dinámicamente.

---

Este es un gran salto adelante. Con la base funcional y los documentos actualizados, estamos listos para la siguiente fase de desarrollo de tu juego.