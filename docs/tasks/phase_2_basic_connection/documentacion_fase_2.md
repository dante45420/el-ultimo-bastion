Documentación y Aprendizajes: Fase 2 - Conexión y Mundo Sandbox
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

[NUEVO] Error 4: Error de Base de Datos (column ... does not exist) - Error 500
Síntoma: El servidor fallaba al intentar obtener la lista de NPCs.

Causa Raíz: Desincronización entre el código de los modelos (models.py) y la estructura real de la base de datos. Añadimos columnas al código que no existían en la tabla tiponpc.

Aprendizaje Clave: La base de datos es la fuente de verdad. Modificar los modelos en el código es solo el primer paso. Es mandatorio actualizar el esquema de la base de datos para que coincida, ya sea con migraciones o (en esta fase) reconstruyendo las tablas.

[NUEVO] Error 5: Error de Lógica (Bastion para usuario X no encontrado) - Error 404
Síntoma: El personaje del jugador no se cargaba.

Causa Raíz: El script Player.gd en Godot tenía un ID de usuario fijo. Al reiniciar la base de datos con el seed, los IDs se regeneraron, causando un desajuste.

Aprendizaje Clave: Los IDs hardcodeados son frágiles y deben evitarse en lo posible. Durante las pruebas, es vital verificar que los IDs usados en el cliente coinciden con los de la base de datos actual.

[NUEVO] Error 6: Bugs Visuales (Entidades Flotando/Hundidas)
Síntoma: El jugador y los NPCs no se alineaban correctamente con el suelo.

Causa Raíz: Un concepto fundamental de Godot: la separación entre el nodo de colisión (cuyo origen está en la base) y el nodo visual (cuyo origen está en el centro).

Aprendizaje Clave: Siempre se debe ajustar la posición relativa del nodo visual para alinearlo con su contraparte física (ej. visual.position.y = altura / 2.0).

✨ Decisiones de Arquitectura y Escalabilidad (Visión Refinada)
Terreno Dinámico: Validado.

Entidades Data-Driven: La visión ha sido refinada y validada. La lección más importante de esta fase es la formalización del flujo de trabajo "Arquetipo -> Instancia". Este modelo es la clave para nuestra estrategia de escalabilidad, permitiendo a los diseñadores crear contenido de forma masiva y maleable a través del panel de administración.

Suelo de Emergencia y Colisiones: Validado.