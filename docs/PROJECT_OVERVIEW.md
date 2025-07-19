# Contexto Global del Proyecto para Copilot: El Último Bastión

**NOMBRE DEL PROYECTO:** El Último Bastión

**TIPO DE PROYECTO:** Videojuego social multijugador de misterio y supervivencia con enfoque en narrativa emergente y colaboración.

---

**1. VISIÓN Y ESENCIA DEL JUEGO:**

* **Descripción Breve:** Un juego social multijugador de misterio y supervivencia. Los jugadores forman clanes en un mundo voxel que evoluciona semanalmente para descifrar enigmas, construir y sobrevivir a eventos narrativos que alteran permanentemente el entorno.
* **Conceptos Básicos:**
    * **Supervivencia y Crafteo:** Recolectar, construir y equiparse para sobrevivir.
    * **Misterio Evolutivo:** La historia se revela a través de pistas y eventos periódicos.
    * **Colaboración Social:** Los clanes son el núcleo para progresar y resolver enigmas.
    * **Mundo Persistente y Dinámico:** Las decisiones y acciones de los jugadores tienen consecuencias visibles y permanentes en el mundo.
* **Valores Agregados:**
    * **Narrativa Emergente:** La historia la escriben los jugadores con sus descubrimientos y fracasos.
    * **Eventos en Vivo:** Crean momentos únicos y compartidos que generan una comunidad fuerte.
    * **Alta Rejugabilidad:** El mundo y las historias cambian constantemente, haciendo que cada ciclo sea una experiencia nueva.
    * **Experiencia de Calidad (Desconexión Offline):** El objetivo es ayudar a la gente a vivir bien, desconectados de las pantallas y fortalecer lazos familiares. Se realizarán colaboraciones para tener pistas dinámicas y entretenidas fuera de la pantalla (ej. retos físicos en lugares como McDonald's).
* **Solución General:** Ofrece una experiencia multijugador que va más allá del "grind" tradicional, enfocándose en la intriga, la colaboración y una narrativa en constante cambio que mantiene a los jugadores enganchados. La esencia está en la interactividad y la constante narrativa, no en las gráficas y funciones complejas.

---

**2. ESTRUCTURA DE MUNDOS Y PROGRESIÓN:**

* **Mundos del Juego:**
    * **Mundo del Clan (Mundo de Eventos):** El mundo principal y dinámico que evoluciona con los eventos semanales. Cambia constantemente y se interactúa en él semana a semana. Este mundo está sujeto a cambios drásticos y reinicios parciales por Épocas.
    * **Mundo Personal:** Un mundo muy grande lleno de misiones secundarias para las cuales se pueden usar los recursos del clan, pero no se pueden usar los recursos personales para el mundo del clan. Estas misiones son complejas e imposibles sin habilidades adquiridas en el mundo del clan.
    * **Mundo de Progreso del Clan (Baluarte del Clan):** Una zona persistente e instanciada para cada clan, que *no* está sujeta a los eventos destructivos del Mundo del Clan dinámico. Sirve como hub, memoria histórica y lugar de almacenamiento de progreso a largo plazo del clan. Permite almacenar recompensas y recursos limitados entre Épocas.
* **Ciclos de Historias (Épocas):**
    * Son el corazón del juego, con una estructura predecible para crear contenido rápido y consistente.
    * **Estructura Semanal:**
        1.  **Lunes a Jueves (Misterio y Preparación):** Pistas crípticas liberadas. Jugadores en modo supervivencia sandbox (exploran, recolectan, craftean, fortifican, teorizan).
        2.  **Viernes a Sábado (Evento en Vivo - 48h):** Activación de un evento global relacionado con pistas (ej. invasión, mazmorra temporal, desastre natural). "Ganar" el ciclo = cumplir objetivo del evento, otorgando recompensas y prestigio al clan.
        3.  **Domingo (Consecuencias y Cierre):** El Mundo del Clan se actualiza permanentemente según el resultado del evento (ej. aldea en ruinas/florece). Anuncio de "lore tidbit" para cerrar la historia semanal y enganche para la siguiente.
    * **Progresión entre Épocas (Ciclos Multi-Semanales):**
        * Los ciclos de eventos duran un número "x" de semanas, formando una "Época".
        * Al final de cada Época, el Mundo del Clan se "reinicia" o "reconfigura drásticamente" (ej. un cataclismo global).
        * El clan decide qué elementos específicos, habilidades parciales o recursos limitados pueden ser transferidos del Mundo de Eventos al Mundo de Progreso del Clan. Estos elementos transferidos pueden perderse o no en futuros eventos si son llevados de vuelta al Mundo de Eventos. Objetos muy poderosos (ej. dragones) son temporales y no se transfieren.
* **Incorporación de Nuevos Jugadores:**
    * Cuando un jugador se une, es dirigido a una zona específica llena de NPCs guías y otros jugadores de nivel similar.
    * Esta zona ofrece misiones y tutoriales para entender el juego y ponerse al día.
    * Una vez que el jugador progresa, puede unirse a un clan existente o crear uno.
    * La flexibilidad y consecuencias del código aseguran que los nuevos jugadores puedan integrarse sin desequilibrar la progresión de los clanes.
* **Roles de Clan (Orgánicos):** No hay asignación de roles. Emergerán naturalmente: Analistas (descifran pistas), Exploradores (buscan recursos/pistas), Constructores (diseñan defensas), Combatientes (protegen). Los personajes (Bastiones) tendrán habilidades diferentes para estos roles (ej. constructor: menos daño, más inventario; combatiente: más daño, menos inventario).
* **Progresión del Personaje (Bastión):** El "Bastión" (personaje de cada jugador) tendrá niveles y habilidades permanentes que pueden cambiar y evolucionar a lo largo del tiempo, independientemente del reinicio de las Épocas del Mundo del Clan.
* **Competitividad y Experiencia del Clan:** Los clanes obtendrán "experiencia de clan" por logros/victorias. Esta experiencia permitirá clasificar clanes y definir servidores por niveles de experiencia de clan, fomentando la competición.
* **Consecuencias Automáticas de Eventos:** Todas las consecuencias de los eventos e interacciones son automáticas y drásticas. El mundo reacciona no solo a los resultados de los eventos, sino también a las acciones/inacciones de los jugadores, con efectos que pueden arrastrarse por varias semanas/Épocas.
    * Ejemplo 1: Meteoritos en el evento matan dragones, impidiendo volar.
    * Ejemplo 2: Desastre atómico crea nuevo tipo de NPC (recursos valiosos o peligros de contaminación).

---

**3. FILOSOFÍA Y PRÁCTICAS DE PROGRAMACIÓN:**

* **Gráficas:** Muy simples, reutilizables, basadas en assets gratuitos y fácilmente modificables (ej. pixel art, vóxel básico). El foco es la interactividad, no el fotorrealismo.
* **Variables Generales:** Todas las configuraciones (stats iniciales del Bastión, hambre, daño por hambre, precios de recursos, población de aldeas, etc.) se definen en scripts/archivos de configuración externos, fácilmente accesibles y modificables (ej. JSON, YAML).
* **Diseño Data-Driven (Programación sin Programar):**
    * **Objetivo Principal:** Permitir a personas creativas (historiadores, diseñadores narrativos) crear y definir miles de objetos y entidades del juego desde un panel de administración, sin necesidad de escribir código.
    * **Mecanismo:** El panel de administración (Frontend) leerá esquemas de datos predefinidos. Estos esquemas, almacenados en la base de datos, describirán las propiedades de las "clases" del juego (NPC, Objeto, Misión, Evento, etc.). Los usuarios llenarán formularios en el panel, y esto generará instancias de datos en la DB.
    * **Interacciones:** La lógica del juego leerá estos datos para determinar el comportamiento y las interacciones entre entidades (ej. NPC y aldeas, personaje y daño, aldeas y clanes).
    * **Reutilización:** Maximizar el uso de componentes y lógica existente, minimizando la creación de código nuevo para cada nueva entidad.
* **Estructura de Código y Tecnologías:**
    * **Lenguajes/Frameworks:**
        * **Motor de Juego:** Godot Engine (GDScript principal, C#/C++ para optimizaciones si es necesario).
        * **Backend (API / Lógica del Servidor):** Python con Flask.
        * **Base de Datos:** PostgreSQL (para todos los datos persistentes del juego y las definiciones de contenido).
        * **Frontend (Panel de Administración):** React con Vite.
    * **Arquitectura:** Muy ordenada. Enfoque en la separación de preocupaciones. Uso intensivo de diseño basado en componentes (Godot) y diseño data-driven.
    * **Comunicación entre Componentes:** Estrictamente a través de la terminal (APIs REST sobre HTTP, WebSockets si es necesario para tiempo real). No hay atajos o dependencias directas de código entre los servicios principales (Frontend, Backend, Godot Game). Esto permite la futura división del monorepo si es necesario.
* **Minimizar Creación de Código:** Utilizar al máximo componentes existentes (Godot Engine handles physics, rendering, input) y bibliotecas/paquetes.
* **Colaboración y Pruebas desde el Día Uno:**
    * **Flujo:** Los desarrolladores deben poder clonar el repositorio, configurar el entorno y empezar a probar/añadir entidades inmediatamente.
    * **Hot Reload/Live Testing:** La capacidad de los colaboradores (especialmente historiadores/diseñadores) de crear/modificar entidades en el panel de administración y ver los cambios reflejados rápidamente en el juego (al reiniciar la escena en Godot, por ejemplo).
    * **Documentación:** Los atributos de las clases, la lógica del juego y los controladores deben estar muy bien documentados, idealmente con un sistema semiautomático (ej. comentarios de código que generen docs).

---

**4. DESAFÍOS IDENTIFICADOS (Y CONSIDERACIONES PARA COPILOT):**

* **Gestión de Contexto en Chats Largos:** Los modelos de lenguaje tienden a perder el hilo en conversaciones extensas. **SOLUCIÓN:** Romper las solicitudes en pasos muy pequeños y atómicos. Nunca pidas "todo el juego" a la vez. Cada prompt debe ser una tarea específica y limitada.
* **Plan de Inicio desde Cero con Colaboración Inmediata:** La dificultad de establecer un flujo de trabajo para que múltiples roles (devs, artistas, historiadores) puedan contribuir desde el principio con herramientas definidas y conectadas. **SOLUCIÓN:** La arquitectura modular y data-driven es la respuesta. Copilot debe ayudar a establecer las bases de cada módulo de forma independiente pero con puntos de conexión claros.
* **Complejidad del Código vs. Escalabilidad:** El riesgo de que la complejidad del juego (narrativa, eventos) se traduzca en un código inmanejable. **SOLUCIÓN:** El diseño data-driven es la clave para la simplicidad y escalabilidad del código. Copilot debe priorizar la creación de clases base genéricas y la delegación de comportamientos a los datos. El código principal debe ser simple y extensible.
* **Lentitud en el Desarrollo:** La necesidad de acelerar el progreso. **SOLUCIÓN:** Iteraciones rápidas, enfoque en prototipos funcionales y el uso eficiente de las herramientas.

---

**ESTRUCTURA DE REPOSITORIO (Confirmada):**
/el-ultimo-bastion/
├── backend/                  # Flask (API, gestión de DB, lógica de autenticación/clanes)
│   ├── app/                  # Carpeta principal de la aplicación Flask
│   │   ├── init.py       # Inicialización de la app Flask, DB y Blueprints
│   │   ├── models.py         # Definiciones de todos los modelos de SQLAlchemy
│   │   ├── schemas.py        # Esquemas de Marshmallow para serialización/validación
│   │   ├── api/              # Blueprints para las rutas de la API
│   │   │   ├── init.py
│   │   │   ├── admin_routes.py # Rutas para el panel de administración
│   │   │   ├── auth_routes.py  # Rutas de autenticación (a implementar)
│   │   │   └── game_routes.py  # Rutas para la lógica del juego (a implementar)
│   │   └── services/         # Lógica de negocio y tareas en segundo plano
│   │       ├── init.py
│   │       └── background_tasks.py # Ejemplo de tareas en segundo plano
│   ├── config.py             # Configuraciones de la aplicación (DB, secretos, etc.)
│   ├── manage.py             # Script CLI para gestión de la base de datos (create, drop, seed, migrate)
│   ├── run.py                # Script para iniciar la aplicación en desarrollo
│   ├── requirements.txt      # Dependencias de Python
│   └── .env                  # Variables de entorno (¡NO SUBIR A GIT!)
│
├── frontend/                 # React con Vite (Panel de Administración)
│   ├── public/
│   ├── src/
│   │   ├── api/              # Cliente API para el backend
│   │   ├── components/       # Componentes reutilizables
│   │   ├── pages/            # Páginas de la interfaz (ej. NpcAdminPage)
│   │   └── App.jsx
│   ├── index.html
│   ├── package.json
│   └── vite.config.js
│
├── game_engine/              # Godot Engine Project
│   ├── project.godot         # Configuración del proyecto Godot
│   ├── assets/               # Gráficos (modelos 3D, texturas, sprites)
│   ├── scenes/               # Escenas de juego (main_scene, personal_world, bastion_hub)
│   ├── scripts/              # Scripts de Godot (GDScript/C#)
│   │   ├── Global.gd         # Singleton global (opcional)
│   │   ├── Player.gd         # Lógica del Bastión del jugador
│   │   ├── NPC.gd            # Script base para NPCs (carga datos de DB)
│   │   ├── Entity.gd         # Script base para entidades interactivas
│   │   ├── WorldManager.gd   # Gestiona la carga del mundo, eventos
│   │   ├── UI_Manager.gd     # Gestiona UI en juego
│   │   └── Data_Loader.gd    # Maneja comunicación Godot <-> Backend
│   └── builds/
│
├── .gitignore
├── README.md

