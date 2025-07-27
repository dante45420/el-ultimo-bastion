Guía de Desarrollo para "El Último Bastión"
1. Filosofía de Desarrollo
Data-Driven Design: La lógica del juego se basa en datos. El código debe ser genérico. El contenido se crea y modifica exclusivamente desde el panel de administración.

Modularidad: Cada componente (backend, frontend, motor de juego) es independiente.

Reutilización: Priorizar componentes y assets existentes.

Gráficos Simplificados: Foco en la interactividad y narrativa.

2. Stack Tecnológico
Motor de Juego: Godot Engine (v4.1.1 o superior).

Backend / API: Python con Flask.

Base de Datos: PostgreSQL.

Frontend (Panel de Administración): React con Vite.

3. Flujo de Trabajo y Colaboración
3.1. El Flujo de Creación de Contenido (Regla de Oro)
Nuestro descubrimiento más importante ha sido refinar nuestro flujo de trabajo, que ahora es la guía principal para añadir cualquier contenido al juego:

Crear el Arquetipo (El "Molde"):

Dónde: En las páginas de "Creación de Tipos" del panel de administración (ej. TipoNPCAdminPage).

Qué: Se define la plantilla de un objeto o criatura. Aquí se establecen todas sus propiedades base: salud, velocidad, comportamiento (si puede deambular), color, tamaño, etc.

Resultado: Un nuevo "molde" se guarda en la base de datos (ej. una nueva fila en la tabla TipoNPC).

Instanciar el Arquetipo (Las "Copias"):

Dónde: En el "Editor de Contenido de Mundo".

Qué: Se selecciona un "molde" de la lista de arquetipos existentes y se define únicamente su posición en el mundo.

Resultado: El sistema crea una "copia" (InstanciaNPC) en el mundo, que hereda automáticamente todas las propiedades de su arquetipo.

Este flujo es obligatorio y asegura que nuestro panel sea una herramienta de creación masiva y maleable.

3.2. Directrices Técnicas Críticas
Sincronización de la Base de Datos: Cualquier cambio en models.py DEBE ir seguido de una actualización de la base de datos. Durante el desarrollo, el comando python manage.py create_all_tables --force && python manage.py seed es esencial para mantener todo sincronizado. No hacerlo causa errores UndefinedColumn (Error 500).

Godot: Físico vs. Visual: Un nodo físico (CharacterBody3D) y su visual (MeshInstance3D) son entidades separadas. Para evitar que los modelos se hundan o floten, siempre se debe ajustar la posición del nodo visual para que su base se alinee con el origen del nodo físico (visual.position.y = altura / 2.0).

4. Directrices para Historiadores y Diseñadores
(Se mantiene la estructura anterior, pero ahora reforzada por el flujo de trabajo del punto 3.1)

Uso del Panel: El panel es tu herramienta principal. Usa las páginas de "Crear Tipos" para diseñar los bloques de construcción del juego y el "Editor de Mundos" para poblar los niveles.

Proceso de "Ver en el Juego":

Crea/modifica un arquetipo o instancia en el panel.

Notifica al desarrollador de Godot.

El desarrollador recargará la escena en Godot.

Tus cambios aparecerán instantáneamente en el juego para ser probados.