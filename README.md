# El Último Bastión

**Videojuego social multijugador de misterio y supervivencia con narrativa emergente**

![Estado del Proyecto](https://img.shields.io/badge/Estado-Documentación%20Completa-blue)
![Fase](https://img.shields.io/badge/Fase-Planificación-orange)
![Tecnologías](https://img.shields.io/badge/Stack-Godot%20|%20Flask%20|%20PostgreSQL%20|%20React-green)

---

## 🎮 Descripción del Proyecto

**El Último Bastión** es un videojuego social multijugador de misterio y supervivencia donde los jugadores forman clanes en un mundo voxel que evoluciona semanalmente. Los jugadores deben descifrar enigmas, construir, sobrevivir a eventos narrativos y colaborar para alterar permanentemente el entorno del juego.

### Características Principales

- **🗺️ Mundo Dinámico:** El mundo cambia cada semana con eventos globales
- **🏘️ Sistema de Clanes:** Colaboración esencial para resolver misterios
- **📚 Narrativa Emergente:** La historia la escriben los jugadores
- **⚒️ Data-Driven:** Contenido creado sin programar desde panel de administración
- **🌐 Multijugador:** Experiencias compartidas en tiempo real

---

## 🏗️ Arquitectura Técnica

```
┌─────────────────┬─────────────────┬─────────────────┐
│   🎮 GODOT      │   🖥️ REACT      │   🐍 FLASK      │
│   Game Engine   │   Admin Panel   │   Backend API   │
│                 │                 │                 │
│ • Scripts GD    │ • Vite          │ • SQLAlchemy    │
│ • 3D/2D Scenes  │ • React Router  │ • Flask-CORS    │
│ • Networking    │ • Axios         │ • JWT Auth      │
└─────────────────┴─────────────────┴─────────────────┘
                           │
                  ┌─────────────────┐
                  │  🗄️ POSTGRESQL  │
                  │   Database      │
                  │                 │
                  │ • 12 Tablas     │
                  │ • Componentes   │
                  │ • Estado Juego  │
                  └─────────────────┘
```

---

## 📂 Estado Actual del Proyecto

### ✅ Completado
- **Documentación completa** del proyecto y arquitectura
- **Esquema de base de datos** detallado (12+ tablas)
- **Guías de desarrollo** y colaboración
- **Roadmap** con 14 tareas prioritarias organizadas

### 🚧 En Desarrollo
- **Nada actualmente** - Listo para comenzar implementación

### 🎯 Próximo Hito
**Crear estructura básica del proyecto** y **configurar base de datos**

---

## 📋 Documentación

| Documento | Descripción | Estado |
|-----------|-------------|---------|
| [`PROJECT_OVERVIEW.md`](docs/PROJECT_OVERVIEW.md) | Visión completa del juego, mecánicas y arquitectura | ✅ Completo |
| [`DATABASE_SCHEMA.md`](docs/DATABASE_SCHEMA.md) | Esquema detallado de la base de datos (347 líneas) | ✅ Completo |
| [`DEVELOPMENT_GUIDELINES.md`](docs/DEVELOPMENT_GUIDELINES.md) | Guías técnicas y flujo de trabajo | ✅ Completo |
| [`CURRENT_TASK_PROGRESS.md`](docs/CURRENT_TASK_PROGRESS.md) | Estado y progreso de todas las tareas | ✅ Completo |

---

## 🚀 Cómo Empezar

### Para Desarrolladores

1. **Leer Documentación**
   ```bash
   # Clona el repositorio
   git clone [URL_DEL_REPO]
   cd el-ultimo-bastion
   
   # Lee la documentación esencial
   cat docs/PROJECT_OVERVIEW.md
   cat docs/CURRENT_TASK_PROGRESS.md
   ```

2. **Próximos Pasos (En Orden)**
   - [ ] Crear estructura completa de carpetas
   - [ ] Configurar base de datos PostgreSQL
   - [ ] Implementar backend básico con Flask
   - [ ] Crear panel de administración con React
   - [ ] Configurar proyecto base en Godot

3. **Revisar Tareas Prioritarias**
   - Consulta [`CURRENT_TASK_PROGRESS.md`](docs/CURRENT_TASK_PROGRESS.md) para ver las 14 tareas organizadas por fases
   - Cada tarea incluye descripción, entregables, dependencias y estimaciones

### Para Diseñadores/Historiadores

Una vez que el panel de administración esté listo, podrás:

- **Crear NPCs** con diferentes comportamientos
- **Diseñar eventos** narrativos y sus consecuencias  
- **Configurar objetos** y sus propiedades
- **Definir misiones** y pistas para los jugadores

**No necesitas saber programar** - Todo se hará desde una interfaz web amigable.

---

## 🛠️ Tecnologías

| Componente | Tecnología | Versión | Propósito |
|------------|------------|---------|-----------|
| **Motor de Juego** | Godot Engine | 4.x | Cliente del juego, rendering, física |
| **Backend** | Python + Flask | 3.9+ | API REST, lógica de negocio |
| **Base de Datos** | PostgreSQL | 14+ | Persistencia de datos |
| **Frontend Admin** | React + Vite | 18+ | Panel de administración |
| **Comunicación** | HTTP/WebSockets | - | APIs entre servicios |

---

## 🎯 Filosofía del Proyecto

### Data-Driven Design
El juego está diseñado para que **historiadores y diseñadores** puedan crear contenido complejo sin escribir código. Todo el comportamiento del juego se define a través de datos en la base de datos.

### Modularidad
Cada componente (Godot, React, Flask) es **independiente** y se comunica mediante APIs bien definidas, facilitando el desarrollo colaborativo y el escalado.

### Iteraciones Rápidas
Enfoque en prototipos funcionales y **feedback temprano** para acelerar el desarrollo y asegurar que el juego cumpla la visión.

---

## 📞 Contribución

### Roles del Equipo
- **🧑‍💻 Desarrolladores:** Implementación técnica
- **🎨 Artistas:** Assets gráficos y visuales  
- **📚 Historiadores:** Narrativa y contenido
- **🎮 Diseñadores:** Mecánicas y balance

### Flujo de Trabajo
1. **Revisar** [`CURRENT_TASK_PROGRESS.md`](docs/CURRENT_TASK_PROGRESS.md) antes de empezar
2. **Tomar** la siguiente tarea prioritaria disponible
3. **Desarrollar** en rama feature separada
4. **Abrir** Pull Request para revisión
5. **Actualizar** el progreso de tareas al completar

---

## 📈 Roadmap

### 🎯 **Enero 2025** - Infraestructura Base
- Estructura del proyecto
- Base de datos funcionando
- APIs básicas

### 🎯 **Febrero 2025** - Conexión de Módulos  
- Mundo de prueba
- Personaje Bastión
- NPCs básicos

### 🎯 **Marzo 2025** - Despliegue y Colaboración
- Deploy en Render
- Panel admin funcional
- Pruebas con el equipo

### 🎯 **Abril+ 2025** - Entidades Avanzadas
- Animales y aldeas
- Sistema de clanes
- Eventos globales

---

## 📄 Licencia

[Definir según las necesidades del proyecto]

---

## 🤝 Contacto

[Definir canales de comunicación del equipo]

---

**🎮 ¡Construyamos juntos el mundo de El Último Bastión!**
