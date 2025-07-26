# Tarea: 4.2 - Distribución del Juego

## 📝 Descripción General

Esta tarea se enfoca en hacer que el juego Godot sea accesible para testers y diseñadores que no tienen el entorno de desarrollo completo de Godot Engine. Se generarán "builds" ejecutables del juego y se establecerán instrucciones claras para que puedan conectarse al Backend desplegado y probar las últimas funcionalidades.

## 🎯 Criterios de Aceptación (Definition of Done - DoD)

Para considerar esta tarea como 'Completa', deben cumplirse todos los siguientes criterios:

* **Builds del Juego Generados:** Se pueden generar builds ejecutables del proyecto Godot para al menos una plataforma (ej., Windows, macOS, Linux).
* **Conexión a Backend Remoto en Build:** El build del juego se conecta exitosamente al Backend Flask desplegado en Render (o similar).
* **Instrucciones de Instalación/Ejecución:** Se proporciona una guía clara y concisa para los testers sobre cómo descargar, instalar (si es necesario) y ejecutar el build del juego.
* **Flujo de Prueba Funcional para Testers:**
    * Un tester externo puede descargar el build.
    * Ejecutar el juego.
    * Verificar que el juego se conecta a los datos (ej., carga el mundo y los objetos creados por el administrador).
    * Verificar que las acciones del jugador (ej., movimiento, interacción básica) se sincronizan con la base de datos a través del Backend.
* **Feedback Loop Establecido:** Los testers saben cómo proporcionar feedback y reportar bugs (ej., vía GitHub Issues o un canal de comunicación).

## 🔧 Detalles Técnicos de Implementación (Enfoque Scrum - a Nivel de Epic)

* **Configuración de Exportación en Godot:**
    * Configurar los "Export Presets" en Godot para las plataformas deseadas (Project -> Export...).
    * Asegurar que los "Export Templates" estén instalados.
    * **Configuración de Conexión en Exportación:** Asegurarse de que la `API_BASE_URL` en `Data_Loader.gd` (o una variable global en Godot) se pueda configurar para el build. Esto podría hacerse a través de:
        * Hardcodear la URL del Backend remoto directamente en el script (`Data_Loader.gd`) antes de exportar (temporal).
        * Utilizar variables de entorno o un archivo de configuración en el build (más robusto).
* **Empaquetado de Assets:** Asegurarse de que todos los assets necesarios (modelos 3D, texturas, sprites) estén incluidos en el build final.
* **Plataforma de Distribución:**
    * Compartir el build a través de un servicio de almacenamiento en la nube (Google Drive, Dropbox).
    * Considerar plataformas de juego como Itch.io para builds de desarrollo si se busca una distribución más formal.
* **Sistema de Reporte:**
    * Configurar GitHub Issues (o Jira/Trello) para el seguimiento de bugs.
    * Establecer un canal de comunicación dedicado para testers (ej., Discord).

## 🚧 Bloqueadores/Riesgos

* Problemas de compatibilidad de builds con diferentes sistemas operativos o hardware.
* Tamaño del build del juego si incluye muchos assets (optimización de assets).
* Problemas de rendimiento en máquinas de testers.

## 🤝 Colaboración

* **Roles Involucrados:** Desarrollador Godot, QA/Tester, Líder de Proyecto.
* **Puntos de Contacto:** Coordinación estrecha para entregar builds estables y recoger feedback de manera eficiente.

## 🗓️ Log de Actualizaciones de Tarea

| Fecha       | Actualización                                                                                              | Responsable |
| :---------- | :--------------------------------------------------------------------------------------------------------- | :---------- |
| 2025-07-19  | Creación inicial de la definición de la tarea `4.2 - Distribución del Juego`. | AI          |