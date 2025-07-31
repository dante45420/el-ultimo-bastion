# Documentación y Aprendizajes: Fase 2 - Conexión y Mundo Sandbox

📝 Resumen de la Fase
Esta fase fue fundamental. Se estableció la conexión entre Godot y el backend y se logró una base jugable. Los errores encontrados fueron cruciales para refinar nuestra arquitectura y comprender a fondo las herramientas y el flujo de trabajo que definirá el futuro del proyecto.

🐛 Proceso de Depuración Detallado y Lecciones Aprendidas

Error 1: Invalid access... en FastNoiseLite
Causa Raíz: Uso de una API de Godot 3 en un proyecto de Godot 4.

Aprendizaje Clave: Verificar siempre la versión específica de la API del motor.

Error 2: HTTPRequest is processing a request (ERR_BUSY)
Causa Raíz: Múltiples solicitudes simultáneas a un HTTPRequest no preparado para ello.

Aprendizaje Clave: La arquitectura de cola implementada en DataLoader.gd es una solución robusta para gestionar llamadas a la API de forma ordenada.

Error 3: El Archivo sin Guardar (●)
Causa Raíz: Cambios no guardados en los scripts de Godot.

Aprendizaje Clave: Siempre guardar (Ctrl+S). Un error simple puede tener efectos en cascada.

Error 4: Error de Base de Datos (column ... does not exist) - Error 500
Síntoma: El servidor fallaba al intentar obtener la lista de NPCs.

Causa Raíz: Desincronización entre el código de los modelos (models.py) y la estructura real de la base de datos. Añadimos columnas al código que no existían en la tabla tiponpc.

Aprendizaje Clave: La base de datos es la fuente de verdad. Modificar los modelos en el código es solo el primer paso. Es mandatorio actualizar el esquema de la base de datos para que coincida, ya sea con migraciones o (en esta fase) reconstruyendo las tablas.

Error 5: Error de Lógica (Bastion para usuario X no encontrado) - Error 404
Síntoma: El personaje del jugador no se cargaba.

Causa Raíz: El script Player.gd en Godot tenía un ID de usuario fijo. Al reiniciar la base de datos con el seed, los IDs se regeneraron, causando un desajuste.

Aprendizaje Clave: Los IDs hardcodeados son frágiles y deben evitarse en lo posible. Durante las pruebas, es vital verificar que los IDs usados en el cliente coinciden con los de la base de datos actual.

Error 6: Bugs Visuales (Entidades Flotando/Hundidas)
Síntoma: El jugador y los NPCs no se alineaban correctamente con el suelo.

Causa Raíz: Un concepto fundamental de Godot: la separación entre el nodo de colisión (cuyo origen está en la base) y el nodo visual (cuyo origen está en el centro).

Aprendizaje Clave: Siempre se debe ajustar la posición relativa del nodo visual para alinearlo con su contraparte física (ej. visual.position.y = altura / 2.0).

Error 7: `Identifier 'variable_name' not declared in the current scope`
Síntoma: Variables de clase (como `wander_timer` o `current_health`) no reconocidas dentro de funciones.
Causa Raíz: La variable no estaba declarada explícitamente como variable de instancia al inicio del script, o hubo un error de copia/guardado que omitió su declaración.
Aprendizaje Clave: Asegurarse de que todas las variables de clase (que se usan en múltiples funciones) estén declaradas con `var name: Type = initial_value` directamente debajo de `extends ClassName`.

Error 8: Script no ejecutándose en nodos instanciados (`[DEBUG] NPC ID:` prints no aparecen)
Síntoma: Los datos del backend llegan a Godot, pero los NPCs no se visualizan ni se comportan. Los `print`s de depuración dentro del script del NPC no aparecen.
Causa Raíz: El script del nodo (`NPC.gd`) no está asignado al nodo raíz de la escena que se está instanciando (`NPC.tscn`). Alternativamente, la ruta de `preload` para la escena en el `World.gd` es incorrecta, o el `add_child` no está añadiendo el nodo al `SceneTree` correctamente.
Aprendizaje Clave:
1.  Siempre asignar el script (`.gd`) al nodo raíz de su escena (`.tscn`) en el editor de Godot.
2.  Verificar las rutas de `preload` (`const MY_SCENE = preload("res://path.tscn")`).
3.  Usar `Remote Scene Tree` en Godot para inspeccionar la escena en tiempo de ejecución y ver si el nodo instanciado existe, dónde está, si tiene script y sus hijos.

Error 9: `Invalid call. Nonexistent function 'is_valid' in base 'PackedScene'.`
Síntoma: Al intentar verificar si un `PackedScene` precargado es válido con `is_valid()`.
Causa Raíz: `is_valid()` es un método para `Object`s o instancias de nodos, no para recursos como `PackedScene`.
Aprendizaje Clave: Para verificar si un `PackedScene` se precargó correctamente, basta con comprobar si no es `null`.

Error 10: "Traspasar NPCs y NPCs entre sí"
Síntoma: El jugador puede pasar a través de los NPCs, y los NPCs pueden pasar a través de otros NPCs.
Causa Raíz: Las máscaras de colisión (`collision_mask`) de `CharacterBody3D` (Player y NPC) no estaban configuradas para detectar las capas en las que residen otros `CharacterBody3D`.
Aprendizaje Clave: Configurar `collision_layer` (dónde reside el objeto) y `collision_mask` (qué capas detecta) para permitir interacciones de colisión entre los tipos de objetos deseados.

Error 11: "La función comer funcionó raro, aumentaba los 20 pero instantáneamente los perdía y partía con 0"
Síntoma: El hambre disminuye demasiado rápido, a pesar de usar el botón "Comer".
Causa Raíz: La tasa de decaimiento del hambre (`hunger_decay_rate`) era demasiado alta en relación con el `delta` del `_process` de Godot, haciendo que el hambre se redujera casi instantáneamente.
Aprendizaje Clave: Ajustar las tasas de decaimiento y regeneración en relación con `delta` y los valores máximos/mínimos para que sean perceptibles y equilibrados en el juego.

Error 12: "No pude pegarle a nada"
Síntoma: El rayo de ataque no detectaba colisiones con NPCs.
Causa Raíz: El `PhysicsRayQueryParameters3D.collision_mask` del rayo no incluía la capa donde reside los NPCs.
Aprendizaje Clave: Asegurarse de que los `RayCast3D` o las consultas de rayo tienen las máscaras de colisión correctas para detectar los objetos deseados.

✨ Decisiones de Arquitectura y Escalabilidad (Visión Refinada)
**Terreno Dinámico:** Validado.

**Entidades Data-Driven:** La visión ha sido refinada y validada. La lección más importante de esta fase es la formalización del flujo de trabajo "Arquetipo -> Instancia". Este modelo es la clave para nuestra estrategia de escalabilidad, permitiendo a los diseñadores crear contenido de forma masiva y maleable a través del panel de administración.

**Suelo de Emergencia y Colisiones:** Validado.

**Arquitectura de Componentes:** Se ha iniciado la implementación de una arquitectura basada en componentes (nodos hijos con scripts especializados) para gestionar funcionalidades como salud, hambre e inventario (`HealthComponent`, `HungerComponent`, `InventoryComponent`). Este enfoque es crucial para la maleabilidad y escalabilidad del juego, permitiendo añadir y modificar comportamientos de forma modular.