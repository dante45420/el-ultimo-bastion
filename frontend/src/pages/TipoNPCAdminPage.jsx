// el-ultimo-bastion/frontend/src/pages/TipoNPCAdminPage.jsx
// VERSIÓN MEJORADA - FORMULARIO INTUITIVO PARA NPCs
import React, { useState, useEffect } from 'react';
import { createTipoNPC, getTiposNPC, getTiposObjeto } from '../api/adminApi';

const TipoNPCAdminPage = () => {
    const [formData, setFormData] = useState({
        nombre: '',
        descripcion: '',
        id_grafico: 'default_npc_model',
        rol_npc: 'GENERICO',
        comportamiento_ia: '',
        resistencia_dano: {},
        habilidades_base: [],
        valores_rol: {},
        // Estadísticas iniciales
        initial_salud_max: 100,
        initial_hambre_max: 100,
        initial_dano_ataque_base: 5,
        initial_velocidad_movimiento: 3.0,
        initial_inventario_capacidad_slots: 5,
        initial_inventario_capacidad_peso_kg: 20.0
    });
    
    const [npcTypes, setNpcTypes] = useState([]);
    const [availableObjects, setAvailableObjects] = useState([]);
    const [message, setMessage] = useState('');
    const [error, setError] = useState('');
    const [activeTab, setActiveTab] = useState('basic');

    // Configuraciones predefinidas por rol
    const roleConfigs = {
        GENERICO: {
            label: "🤷 Genérico",
            description: "NPC básico sin habilidades especiales",
            defaultBehavior: "Deambula aleatoriamente por el área.",
            color: "#8A2BE2",
            defaultStats: { salud: 100, hambre: 100, dano: 5, velocidad: 3.0 },
            interactions: ["talk"],
            settings: {
                ai_settings: { puede_deambular: true, wander_range: 10, velocidad_caminar: 2.5 },
                combat_settings: { puede_atacar_jugador: false, range: 1.5, cooldown: 2.0 },
                interaction_settings: { 
                    actions: ["talk"], 
                    prompt_talk: "Hablar",
                    prompt_generic: "Interactuar"
                },
                hitbox_dimensions: { radius: 0.4, height: 1.7 },
                color: "#8A2BE2",
                recruitment_settings: {
                    puede_ser_reclutado: false,
                    tipo_reclutamiento: "imposible",
                    requisitos: []
                },
                loot_settings: {
                    drops_loot_on_death: false,
                    conserva_inventario_on_death: false,
                    loot_table: []
                }
            }
        },
        COMERCIANTE: {
            label: "💰 Comerciante",
            description: "Compra y vende objetos",
            defaultBehavior: "Se mantiene en su puesto, ofrece intercambios comerciales.",
            color: "#FFD700",
            defaultStats: { salud: 80, hambre: 120, dano: 3, velocidad: 2.0 },
            interactions: ["talk", "trade"],
            settings: {
                ai_settings: { puede_deambular: false, wander_range: 5, velocidad_caminar: 1.5 },
                combat_settings: { puede_atacar_jugador: false, range: 1.5, cooldown: 2.0 },
                commerce_settings: { 
                    puede_comerciar: true,
                    saludo: "¡Bienvenido! ¿Qué quieres comprar?",
                    despedida: "¡Gracias por tu compra!",
                    descuento_base: 0.0,
                    markup_base: 1.2
                },
                interaction_settings: { 
                    actions: ["talk", "trade"], 
                    prompt_talk: "Hablar",
                    prompt_trade: "Comerciar",
                    prompt_generic: "Interactuar"
                },
                hitbox_dimensions: { radius: 0.4, height: 1.7 },
                color: "#FFD700",
                recruitment_settings: {
                    puede_ser_reclutado: true,
                    tipo_reclutamiento: "soborno",
                    requisitos: [
                        { tipo: "oro", cantidad: 100, descripcion: "Soborno en oro" }
                    ]
                },
                loot_settings: {
                    drops_loot_on_death: true,
                    conserva_inventario_on_death: false,
                    loot_table: [
                        { objeto_id: null, nombre: "Oro", probabilidad: 0.8, cantidad_min: 10, cantidad_max: 50 },
                        { objeto_id: null, nombre: "Poción de comercio", probabilidad: 0.3, cantidad_min: 1, cantidad_max: 2 }
                    ]
                }
            }
        },
        GUARDIA: {
            label: "🛡️ Guardia/Defensor",
            description: "Puede ser reclutado para defenderte",
            defaultBehavior: "Patrulla un área, puede ser reclutado como aliado.",
            color: "#4169E1",
            defaultStats: { salud: 150, hambre: 80, dano: 15, velocidad: 3.5 },
            interactions: ["talk", "recruit", "dismiss"],
            settings: {
                ai_settings: { puede_deambular: true, wander_range: 15, velocidad_caminar: 3.0 },
                combat_settings: { 
                    puede_atacar_jugador: false, 
                    range: 2.0, 
                    cooldown: 1.5,
                    visual_effects: { type: "slash", color: "#FF4444", size: 1.2 }
                },
                interaction_settings: { 
                    actions: ["talk", "recruit", "dismiss"], 
                    prompt_talk: "Hablar",
                    prompt_recruit: "Reclutar",
                    prompt_dismiss: "Despedir",
                    prompt_generic: "Interactuar"
                },
                hitbox_dimensions: { radius: 0.5, height: 1.8 },
                color: "#4169E1",
                rango_vision: 25,
                recruitment_settings: {
                    puede_ser_reclutado: true,
                    tipo_reclutamiento: "multiple_opciones",
                    requisitos: [
                        { tipo: "oro", cantidad: 50, descripcion: "Pago por servicios" },
                        { tipo: "objeto", objeto_id: null, cantidad: 1, descripcion: "Escudo de hierro", alternativa: true },
                        { tipo: "tarea", descripcion: "Completar misión de honor", alternativa: true }
                    ]
                },
                loot_settings: {
                    drops_loot_on_death: true,
                    conserva_inventario_on_death: true,
                    loot_table: [
                        { objeto_id: null, nombre: "Espada", probabilidad: 0.7, cantidad_min: 1, cantidad_max: 1 },
                        { objeto_id: null, nombre: "Armadura", probabilidad: 0.5, cantidad_min: 1, cantidad_max: 1 },
                        { objeto_id: null, nombre: "Oro", probabilidad: 0.9, cantidad_min: 20, cantidad_max: 80 }
                    ]
                }
            }
        },
        MALVADO: {
            label: "💀 Enemigo",
            description: "Ataca al jugador y otros NPCs",
            defaultBehavior: "Hostil, ataca a cualquier criatura que vea.",
            color: "#DC143C",
            defaultStats: { salud: 120, hambre: 60, dano: 20, velocidad: 4.0 },
            interactions: [],
            settings: {
                ai_settings: { puede_deambular: true, wander_range: 20, velocidad_caminar: 3.5 },
                combat_settings: { 
                    puede_atacar_jugador: true, 
                    range: 2.5, 
                    cooldown: 1.0,
                    visual_effects: { type: "explosion", color: "#FF0000", size: 1.5 }
                },
                interaction_settings: { actions: [] },
                hitbox_dimensions: { radius: 0.5, height: 1.8 },
                color: "#DC143C",
                rango_vision: 20,
                aggro_settings: {
                    es_agresivo: true,
                    ataca_first_sight: true,
                    persecucion_max_distance: 30
                },
                recruitment_settings: {
                    puede_ser_reclutado: false,
                    tipo_reclutamiento: "imposible",
                    requisitos: []
                },
                loot_settings: {
                    drops_loot_on_death: true,
                    conserva_inventario_on_death: false,
                    loot_table: [
                        { objeto_id: null, nombre: "Hueso raro", probabilidad: 0.4, cantidad_min: 1, cantidad_max: 3 },
                        { objeto_id: null, nombre: "Gema oscura", probabilidad: 0.1, cantidad_min: 1, cantidad_max: 1 },
                        { objeto_id: null, nombre: "Oro maldito", probabilidad: 0.6, cantidad_min: 5, cantidad_max: 25 }
                    ]
                }
            }
        },
        CONSTRUCTOR: {
            label: "🔨 Constructor/Artesano",
            description: "Construye objetos y edificios",
            defaultBehavior: "Trabaja en su área, puede construir objetos para el jugador.",
            color: "#8B4513",
            defaultStats: { salud: 90, hambre: 110, dano: 8, velocidad: 2.5 },
            interactions: ["talk", "build", "craft"],
            settings: {
                ai_settings: { puede_deambular: false, wander_range: 8, velocidad_caminar: 2.0 },
                combat_settings: { puede_atacar_jugador: false, range: 1.5, cooldown: 2.0 },
                craft_settings: {
                    puede_construir: true,
                    recipes_disponibles: ["casa_madera", "cerca", "pozo"],
                    costo_construccion: { madera: 10, piedra: 5 },
                    tiempo_construccion: 60
                },
                interaction_settings: { 
                    actions: ["talk", "build", "craft"], 
                    prompt_talk: "Hablar",
                    prompt_build: "Construir",
                    prompt_craft: "Crear objeto",
                    prompt_generic: "Interactuar"
                },
                hitbox_dimensions: { radius: 0.4, height: 1.7 },
                color: "#8B4513",
                recruitment_settings: {
                    puede_ser_reclutado: true,
                    tipo_reclutamiento: "intercambio_materiales",
                    requisitos: [
                        { tipo: "objeto", objeto_id: null, cantidad: 20, descripcion: "Madera de calidad" },
                        { tipo: "objeto", objeto_id: null, cantidad: 10, descripcion: "Herramientas de hierro" }
                    ]
                },
                loot_settings: {
                    drops_loot_on_death: true,
                    conserva_inventario_on_death: true,
                    loot_table: [
                        { objeto_id: null, nombre: "Herramientas", probabilidad: 0.9, cantidad_min: 1, cantidad_max: 3 },
                        { objeto_id: null, nombre: "Planos de construcción", probabilidad: 0.3, cantidad_min: 1, cantidad_max: 1 },
                        { objeto_id: null, nombre: "Madera", probabilidad: 0.8, cantidad_min: 5, cantidad_max: 15 }
                    ]
                }
            }
        },
        MASCOTA: {
            label: "🐾 Mascota/Compañero",
            description: "Puede seguirte y ayudarte",
            defaultBehavior: "Amigable, puede ser domado para seguir al jugador.",
            color: "#32CD32",
            defaultStats: { salud: 60, hambre: 140, dano: 10, velocidad: 4.5 },
            interactions: ["talk", "tame", "follow", "stay"],
            settings: {
                ai_settings: { puede_deambular: true, wander_range: 8, velocidad_caminar: 4.0 },
                combat_settings: { puede_atacar_jugador: false, range: 1.5, cooldown: 1.8 },
                taming_settings: {
                    puede_ser_domado: true,
                    requiere_comida: "Carne",
                    tiempo_domesticacion: 30,
                    lealtad_inicial: 50,
                    max_lealtad: 100
                },
                interaction_settings: { 
                    actions: ["talk", "tame", "follow", "stay"], 
                    prompt_talk: "Hablar",
                    prompt_tame: "Domar",
                    prompt_follow: "Seguir",
                    prompt_stay: "Quedarse",
                    prompt_generic: "Interactuar"
                },
                hitbox_dimensions: { radius: 0.3, height: 1.2 },
                color: "#32CD32",
                recruitment_settings: {
                    puede_ser_reclutado: true,
                    tipo_reclutamiento: "domesticacion",
                    requisitos: [
                        { tipo: "objeto", objeto_id: null, cantidad: 5, descripcion: "Carne fresca" },
                        { tipo: "tiempo", cantidad: 30, descripcion: "Tiempo de domesticación (segundos)" },
                        { tipo: "paciencia", descripcion: "Acercarse lentamente sin movimientos bruscos" }
                    ]
                },
                loot_settings: {
                    drops_loot_on_death: false,
                    conserva_inventario_on_death: true,
                    loot_table: []
                }
            }
        },
        MAGO: {
            label: "🔮 Mago",
            description: "Usa magia y pociones",
            defaultBehavior: "Estudioso, ofrece servicios mágicos y pociones.",
            color: "#9932CC",
            defaultStats: { salud: 70, hambre: 90, dano: 25, velocidad: 2.8 },
            interactions: ["talk", "magic", "potion"],
            settings: {
                ai_settings: { puede_deambular: false, wander_range: 6, velocidad_caminar: 2.5 },
                combat_settings: { 
                    puede_atacar_jugador: false, 
                    range: 4.0, 
                    cooldown: 3.0,
                    visual_effects: { type: "magic_blast", color: "#9932CC", size: 2.0 }
                },
                magic_settings: {
                    puede_usar_magia: true,
                    spells_disponibles: ["heal", "teleport", "shield"],
                    mana_max: 100,
                    costo_servicios: { heal: 20, teleport: 50, shield: 30 }
                },
                interaction_settings: { 
                    actions: ["talk", "magic", "potion"], 
                    prompt_talk: "Hablar",
                    prompt_magic: "Servicios Mágicos",
                    prompt_potion: "Pociones",
                    prompt_generic: "Interactuar"
                },
                hitbox_dimensions: { radius: 0.4, height: 1.7 },
                color: "#9932CC",
                recruitment_settings: {
                    puede_ser_reclutado: true,
                    tipo_reclutamiento: "intercambio_conocimiento",
                    requisitos: [
                        { tipo: "objeto", objeto_id: null, cantidad: 3, descripcion: "Gemas mágicas" },
                        { tipo: "objeto", objeto_id: null, cantidad: 1, descripcion: "Libro de hechizos antiguo" },
                        { tipo: "tarea", descripcion: "Resolver acertijo arcano", alternativa: true }
                    ]
                },
                loot_settings: {
                    drops_loot_on_death: true,
                    conserva_inventario_on_death: true,
                    loot_table: [
                        { objeto_id: null, nombre: "Pociones mágicas", probabilidad: 0.8, cantidad_min: 2, cantidad_max: 5 },
                        { objeto_id: null, nombre: "Cristal de mana", probabilidad: 0.4, cantidad_min: 1, cantidad_max: 2 },
                        { objeto_id: null, nombre: "Pergamino de hechizo", probabilidad: 0.6, cantidad_min: 1, cantidad_max: 3 }
                    ]
                }
            }
        }
    };

    // Tipos de reclutamiento disponibles
    const recruitmentTypes = {
        imposible: "❌ No se puede reclutar",
        soborno: "💰 Soborno con oro",
        domesticacion: "🐾 Domesticación con comida/paciencia", 
        intercambio_materiales: "🔧 Intercambio de materiales",
        intercambio_conocimiento: "📚 Intercambio de conocimiento",
        multiple_opciones: "🎯 Múltiples opciones",
        amistad: "💝 Ganarse su amistad",
        combate: "⚔️ Derrotarlo en combate",
        rescate: "🆘 Rescatarlo de una situación"
    };

    useEffect(() => {
        fetchNPCTypes();
        fetchAvailableObjects();
        handleRoleChange('GENERICO');
    }, []);

    const fetchNPCTypes = async () => {
        try {
            const data = await getTiposNPC();
            setNpcTypes(data);
        } catch (err) {
            setError('Error al cargar tipos de NPC: ' + (err.response?.data?.message || err.message));
        }
    };

    const fetchAvailableObjects = async () => {
        try {
            const data = await getTiposObjeto();
            setAvailableObjects(data);
        } catch (err) {
            console.error('Error al cargar objetos:', err);
        }
    };

    const handleRoleChange = (newRole) => {
        const config = roleConfigs[newRole];
        if (!config) return;
        
        setFormData(prev => ({
            ...prev,
            rol_npc: newRole,
            comportamiento_ia: config.defaultBehavior,
            valores_rol: config.settings,
            initial_salud_max: config.defaultStats.salud,
            initial_hambre_max: config.defaultStats.hambre,
            initial_dano_ataque_base: config.defaultStats.dano,
            initial_velocidad_movimiento: config.defaultStats.velocidad
        }));
    };

    const handleChange = (e) => {
        const { name, value, type } = e.target;
        
        if (name === 'rol_npc') {
            handleRoleChange(value);
            return;
        }
        
        const finalValue = type === 'number' ? parseFloat(value) : value;
        setFormData(prev => ({ ...prev, [name]: finalValue }));
    };

    // Función para actualizar configuraciones anidadas
    const updateNestedSetting = (path, value) => {
        setFormData(prev => {
            const newFormData = { ...prev };
            const pathArray = path.split('.');
            let current = newFormData.valores_rol;
            
            for (let i = 0; i < pathArray.length - 1; i++) {
                if (!current[pathArray[i]]) current[pathArray[i]] = {};
                current = current[pathArray[i]];
            }
            
            current[pathArray[pathArray.length - 1]] = value;
            return newFormData;
        });
    };

    // Función para agregar/quitar requisitos de reclutamiento
    const updateRecruitmentRequirement = (index, field, value) => {
        const currentRequirements = formData.valores_rol?.recruitment_settings?.requisitos || [];
        const newRequirements = [...currentRequirements];
        
        if (field === 'remove') {
            newRequirements.splice(index, 1);
        } else {
            if (!newRequirements[index]) newRequirements[index] = {};
            newRequirements[index][field] = value;
        }
        
        updateNestedSetting('recruitment_settings.requisitos', newRequirements);
    };

    const addRecruitmentRequirement = () => {
        const currentRequirements = formData.valores_rol?.recruitment_settings?.requisitos || [];
        updateNestedSetting('recruitment_settings.requisitos', [
            ...currentRequirements,
            { tipo: 'oro', cantidad: 10, descripcion: 'Nuevo requisito' }
        ]);
    };

    // Función para agregar/quitar items de loot
    const updateLootItem = (index, field, value) => {
        const currentLoot = formData.valores_rol?.loot_settings?.loot_table || [];
        const newLoot = [...currentLoot];
        
        if (field === 'remove') {
            newLoot.splice(index, 1);
        } else {
            if (!newLoot[index]) newLoot[index] = {};
            newLoot[index][field] = value;
        }
        
        updateNestedSetting('loot_settings.loot_table', newLoot);
    };

    const addLootItem = () => {
        const currentLoot = formData.valores_rol?.loot_settings?.loot_table || [];
        updateNestedSetting('loot_settings.loot_table', [
            ...currentLoot,
            { objeto_id: null, nombre: 'Nuevo objeto', probabilidad: 0.5, cantidad_min: 1, cantidad_max: 1 }
        ]);
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        setMessage('');
        setError('');

        try {
            console.log('Enviando datos:', formData);
            await createTipoNPC(formData);
            setMessage(`✅ NPC "${formData.nombre}" creado con éxito!`);
            
            // Reset form
            setFormData({
                nombre: '', descripcion: '', id_grafico: 'default_npc_model',
                rol_npc: 'GENERICO', comportamiento_ia: '', resistencia_dano: {},
                habilidades_base: [], valores_rol: {},
                initial_salud_max: 100, initial_hambre_max: 100,
                initial_dano_ataque_base: 5, initial_velocidad_movimiento: 3.0,
                initial_inventario_capacidad_slots: 5, initial_inventario_capacidad_peso_kg: 20.0
            });
            handleRoleChange('GENERICO');
            fetchNPCTypes();
        } catch (err) {
            console.error('Error completo:', err);
            setError('❌ Error al crear NPC: ' + (err.response?.data?.message || err.message));
        }
    };

    const getCurrentRoleConfig = () => {
        return roleConfigs[formData.rol_npc] || roleConfigs.GENERICO;
    };

    const TabButton = ({ id, label, icon }) => (
        <button
            type="button"
            onClick={() => setActiveTab(id)}
            style={{
                padding: '10px 15px',
                border: 'none',
                borderRadius: '5px 5px 0 0',
                backgroundColor: activeTab === id ? '#007bff' : '#e9ecef',
                color: activeTab === id ? 'white' : '#495057',
                cursor: 'pointer',
                fontWeight: 'bold'
            }}
        >
            {icon} {label}
        </button>
    );

    return (
        <div style={{ padding: '20px', maxWidth: '1200px', margin: 'auto' }}>
            <h1>🤖 Creador Súper Avanzado de NPCs</h1>

            {message && <div style={{ color: 'green', padding: '10px', backgroundColor: '#d4edda', borderRadius: '5px', marginBottom: '15px' }}>{message}</div>}
            {error && <div style={{ color: 'red', padding: '10px', backgroundColor: '#f8d7da', borderRadius: '5px', marginBottom: '15px' }}>{error}</div>}

            <form onSubmit={handleSubmit} style={{ border: '1px solid #dee2e6', borderRadius: '8px', backgroundColor: 'white', overflow: 'hidden' }}>
                
                {/* TABS DE NAVEGACIÓN */}
                <div style={{ display: 'flex', backgroundColor: '#f8f9fa', padding: '0 20px', flexWrap: 'wrap' }}>
                    <TabButton id="basic" label="Información Básica" icon="📝" />
                    <TabButton id="stats" label="Estadísticas" icon="📊" />
                    <TabButton id="ai" label="Inteligencia Artificial" icon="🧠" />
                    <TabButton id="combat" label="Combate" icon="⚔️" />
                    <TabButton id="interactions" label="Interacciones" icon="💬" />
                    <TabButton id="recruitment" label="Reclutamiento" icon="🤝" />
                    <TabButton id="loot" label="Sistema de Loot" icon="💎" />
                    <TabButton id="special" label="Configuración Especial" icon="⚙️" />
                    <TabButton id="preview" label="Vista Previa" icon="👁️" />
                </div>

                <div style={{ padding: '25px' }}>
                    
                    {/* TAB: INFORMACIÓN BÁSICA */}
                    {activeTab === 'basic' && (
                        <div>
                            <h2 style={{ marginTop: 0, color: '#495057' }}>📝 Información Básica</h2>
                            
                            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '20px', marginBottom: '20px' }}>
                                <label>
                                    <strong>Nombre del NPC:</strong>
                                    <input 
                                        type="text" 
                                        name="nombre" 
                                        value={formData.nombre} 
                                        onChange={handleChange} 
                                        required 
                                        style={{ width: '100%', padding: '8px', marginTop: '5px', borderRadius: '4px', border: '1px solid #ced4da' }} 
                                        placeholder="ej: Guardia Pedro, Comerciante Ana"
                                    />
                                </label>
                                
                                <label>
                                    <strong>Rol del NPC:</strong>
                                    <select 
                                        name="rol_npc" 
                                        value={formData.rol_npc} 
                                        onChange={handleChange} 
                                        style={{ width: '100%', padding: '8px', marginTop: '5px', borderRadius: '4px', border: '1px solid #ced4da' }}
                                    >
                                        {Object.entries(roleConfigs).map(([key, config]) => (
                                            <option key={key} value={key}>{config.label}</option>
                                        ))}
                                    </select>
                                </label>
                            </div>

                            <label style={{ display: 'block', marginBottom: '15px' }}>
                                <strong>Descripción:</strong>
                                <textarea 
                                    name="descripcion" 
                                    value={formData.descripcion} 
                                    onChange={handleChange} 
                                    style={{ width: '100%', padding: '8px', marginTop: '5px', minHeight: '80px', borderRadius: '4px', border: '1px solid #ced4da' }}
                                    placeholder="Describe qué hace este NPC..."
                                ></textarea>
                            </label>

                            <div style={{ padding: '15px', backgroundColor: getCurrentRoleConfig().color + '20', borderRadius: '8px', border: `2px solid ${getCurrentRoleConfig().color}` }}>
                                <h3 style={{ margin: '0 0 10px 0', color: getCurrentRoleConfig().color }}>
                                    {getCurrentRoleConfig().label}
                                </h3>
                                <p style={{ margin: '0', color: '#495057' }}>
                                    <strong>Tipo:</strong> {getCurrentRoleConfig().description}<br/>
                                    <strong>Comportamiento:</strong> {getCurrentRoleConfig().defaultBehavior}
                                </p>
                            </div>
                        </div>
                    )}

                    {/* TAB: ESTADÍSTICAS */}
                    {activeTab === 'stats' && (
                        <div>
                            <h2 style={{ marginTop: 0, color: '#495057' }}>📊 Estadísticas del NPC</h2>
                            
                            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '15px' }}>
                                <label>
                                    <strong>❤️ Salud Máxima:</strong>
                                    <input 
                                        type="number" 
                                        name="initial_salud_max" 
                                        value={formData.initial_salud_max} 
                                        onChange={handleChange} 
                                        min="1" max="1000"
                                        style={{ width: '100%', padding: '8px', marginTop: '5px', borderRadius: '4px', border: '1px solid #ced4da' }} 
                                    />
                                </label>
                                
                                <label>
                                    <strong>🍖 Hambre Máxima:</strong>
                                    <input 
                                        type="number" 
                                        name="initial_hambre_max" 
                                        value={formData.initial_hambre_max} 
                                        onChange={handleChange} 
                                        min="1" max="1000"
                                        style={{ width: '100%', padding: '8px', marginTop: '5px', borderRadius: '4px', border: '1px solid #ced4da' }} 
                                    />
                                </label>
                                
                                <label>
                                    <strong>⚔️ Daño Base:</strong>
                                    <input 
                                        type="number" 
                                        name="initial_dano_ataque_base" 
                                        value={formData.initial_dano_ataque_base} 
                                        onChange={handleChange} 
                                        min="0" max="200"
                                        style={{ width: '100%', padding: '8px', marginTop: '5px', borderRadius: '4px', border: '1px solid #ced4da' }} 
                                    />
                                </label>
                                
                                <label>
                                    <strong>🏃 Velocidad:</strong>
                                    <input 
                                        type="number" 
                                        name="initial_velocidad_movimiento" 
                                        value={formData.initial_velocidad_movimiento} 
                                        onChange={handleChange} 
                                        min="0.1" max="20" step="0.1"
                                        style={{ width: '100%', padding: '8px', marginTop: '5px', borderRadius: '4px', border: '1px solid #ced4da' }} 
                                    />
                                </label>
                                
                                <label>
                                    <strong>🎒 Slots de Inventario:</strong>
                                    <input 
                                        type="number" 
                                        name="initial_inventario_capacidad_slots" 
                                        value={formData.initial_inventario_capacidad_slots} 
                                        onChange={handleChange} 
                                        min="1" max="50"
                                        style={{ width: '100%', padding: '8px', marginTop: '5px', borderRadius: '4px', border: '1px solid #ced4da' }} 
                                    />
                                </label>
                                
                                <label>
                                    <strong>⚖️ Peso Máximo (kg):</strong>
                                    <input 
                                        type="number" 
                                        name="initial_inventario_capacidad_peso_kg" 
                                        value={formData.initial_inventario_capacidad_peso_kg} 
                                        onChange={handleChange} 
                                        min="0.1" max="1000" step="0.1"
                                        style={{ width: '100%', padding: '8px', marginTop: '5px', borderRadius: '4px', border: '1px solid #ced4da' }} 
                                    />
                                </label>
                            </div>
                        </div>
                    )}

                    {/* TAB: INTELIGENCIA ARTIFICIAL */}
                    {activeTab === 'ai' && (
                        <div>
                            <h2 style={{ marginTop: 0, color: '#495057' }}>🧠 Configuración de IA</h2>
                            
                            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '20px' }}>
                                <label>
                                    <strong>🚶 Puede Deambular:</strong>
                                    <select 
                                        value={formData.valores_rol?.ai_settings?.puede_deambular || false} 
                                        onChange={(e) => updateNestedSetting('ai_settings.puede_deambular', e.target.value === 'true')}
                                        style={{ width: '100%', padding: '8px', marginTop: '5px', borderRadius: '4px', border: '1px solid #ced4da' }}
                                    >
                                        <option value="true">Sí, deambula libremente</option>
                                        <option value="false">No, se queda en su lugar</option>
                                    </select>
                                </label>
                                
                                <label>
                                    <strong>📏 Rango de Deambulación:</strong>
                                    <input 
                                        type="number" 
                                        value={formData.valores_rol?.ai_settings?.wander_range || 10} 
                                        onChange={(e) => updateNestedSetting('ai_settings.wander_range', parseInt(e.target.value))}
                                        min="1" max="100"
                                        style={{ width: '100%', padding: '8px', marginTop: '5px', borderRadius: '4px', border: '1px solid #ced4da' }} 
                                    />
                                </label>
                                
                                <label>
                                    <strong>🏃 Velocidad de Caminar:</strong>
                                    <input 
                                        type="number" 
                                        value={formData.valores_rol?.ai_settings?.velocidad_caminar || 2.5} 
                                        onChange={(e) => updateNestedSetting('ai_settings.velocidad_caminar', parseFloat(e.target.value))}
                                        min="0.1" max="10" step="0.1"
                                        style={{ width: '100%', padding: '8px', marginTop: '5px', borderRadius: '4px', border: '1px solid #ced4da' }} 
                                    />
                                </label>
                            </div>
                            
                            <label style={{ display: 'block', marginTop: '20px' }}>
                                <strong>🤖 Comportamiento Personalizado:</strong>
                                <textarea 
                                    name="comportamiento_ia" 
                                    value={formData.comportamiento_ia} 
                                    onChange={handleChange} 
                                    style={{ width: '100%', padding: '8px', marginTop: '5px', minHeight: '100px', borderRadius: '4px', border: '1px solid #ced4da' }}
                                    placeholder="Describe el comportamiento específico de este NPC..."
                                ></textarea>
                            </label>
                        </div>
                    )}

                    {/* TAB: COMBATE */}
                    {activeTab === 'combat' && (
                        <div>
                            <h2 style={{ marginTop: 0, color: '#495057' }}>⚔️ Configuración de Combate</h2>
                            
                            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '20px', marginBottom: '20px' }}>
                                <label>
                                    <strong>🎯 Puede Atacar al Jugador:</strong>
                                    <select 
                                        value={formData.valores_rol?.combat_settings?.puede_atacar_jugador || false} 
                                        onChange={(e) => updateNestedSetting('combat_settings.puede_atacar_jugador', e.target.value === 'true')}
                                        style={{ width: '100%', padding: '8px', marginTop: '5px', borderRadius: '4px', border: '1px solid #ced4da' }}
                                    >
                                        <option value="false">No, es pacífico</option>
                                        <option value="true">Sí, es hostil</option>
                                    </select>
                                </label>
                                
                                <label>
                                    <strong>📏 Rango de Ataque:</strong>
                                    <input 
                                        type="number" 
                                        value={formData.valores_rol?.combat_settings?.range || 1.5} 
                                        onChange={(e) => updateNestedSetting('combat_settings.range', parseFloat(e.target.value))}
                                        min="0.5" max="10" step="0.1"
                                        style={{ width: '100%', padding: '8px', marginTop: '5px', borderRadius: '4px', border: '1px solid #ced4da' }} 
                                    />
                                </label>
                                
                                <label>
                                    <strong>⏱️ Cooldown entre Ataques (seg):</strong>
                                    <input 
                                        type="number" 
                                        value={formData.valores_rol?.combat_settings?.cooldown || 2.0} 
                                        onChange={(e) => updateNestedSetting('combat_settings.cooldown', parseFloat(e.target.value))}
                                        min="0.1" max="10" step="0.1"
                                        style={{ width: '100%', padding: '8px', marginTop: '5px', borderRadius: '4px', border: '1px solid #ced4da' }} 
                                    />
                                </label>
                                
                                {formData.rol_npc === 'MALVADO' && (
                                    <label>
                                        <strong>👁️ Rango de Visión:</strong>
                                        <input 
                                            type="number" 
                                            value={formData.valores_rol?.rango_vision || 20} 
                                            onChange={(e) => updateNestedSetting('rango_vision', parseInt(e.target.value))}
                                            min="5" max="50"
                                            style={{ width: '100%', padding: '8px', marginTop: '5px', borderRadius: '4px', border: '1px solid #ced4da' }} 
                                        />
                                    </label>
                                )}
                            </div>
                            
                            <h3>🎨 Efectos Visuales de Combate</h3>
                            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '15px' }}>
                                <label>
                                    <strong>Tipo de Efecto:</strong>
                                    <select 
                                        value={formData.valores_rol?.combat_settings?.visual_effects?.type || 'slash'} 
                                        onChange={(e) => updateNestedSetting('combat_settings.visual_effects.type', e.target.value)}
                                        style={{ width: '100%', padding: '8px', marginTop: '5px', borderRadius: '4px', border: '1px solid #ced4da' }}
                                    >
                                        <option value="slash">🗡️ Slash</option>
                                        <option value="explosion">💥 Explosión</option>
                                        <option value="magic_blast">✨ Ráfaga Mágica</option>
                                        <option value="punch">👊 Puñetazo</option>
                                    </select>
                                </label>
                                
                                <label>
                                    <strong>Color:</strong>
                                    <input 
                                        type="color" 
                                        value={formData.valores_rol?.combat_settings?.visual_effects?.color || '#FF4444'} 
                                        onChange={(e) => updateNestedSetting('combat_settings.visual_effects.color', e.target.value)}
                                        style={{ width: '100%', padding: '8px', marginTop: '5px', borderRadius: '4px', border: '1px solid #ced4da' }} 
                                    />
                                </label>
                                
                                <label>
                                    <strong>Tamaño:</strong>
                                    <input 
                                        type="number" 
                                        value={formData.valores_rol?.combat_settings?.visual_effects?.size || 1.2} 
                                        onChange={(e) => updateNestedSetting('combat_settings.visual_effects.size', parseFloat(e.target.value))}
                                        min="0.5" max="5" step="0.1"
                                        style={{ width: '100%', padding: '8px', marginTop: '5px', borderRadius: '4px', border: '1px solid #ced4da' }} 
                                    />
                                </label>
                            </div>
                        </div>
                    )}

                    {/* TAB: INTERACCIONES */}
                    {activeTab === 'interactions' && (
                        <div>
                            <h2 style={{ marginTop: 0, color: '#495057' }}>💬 Configuración de Interacciones</h2>
                            
                            <div style={{ marginBottom: '20px' }}>
                                <strong>Acciones Disponibles:</strong>
                                <div style={{ display: 'flex', flexWrap: 'wrap', gap: '10px', marginTop: '10px' }}>
                                    {['talk', 'trade', 'recruit', 'dismiss', 'build', 'craft', 'tame', 'follow', 'stay', 'magic', 'potion'].map(action => (
                                        <label key={action} style={{ display: 'flex', alignItems: 'center', gap: '5px' }}>
                                            <input 
                                                type="checkbox" 
                                                checked={formData.valores_rol?.interaction_settings?.actions?.includes(action) || false}
                                                onChange={(e) => {
                                                    const currentActions = formData.valores_rol?.interaction_settings?.actions || [];
                                                    if (e.target.checked) {
                                                        updateNestedSetting('interaction_settings.actions', [...currentActions, action]);
                                                    } else {
                                                        updateNestedSetting('interaction_settings.actions', currentActions.filter(a => a !== action));
                                                    }
                                                }}
                                            />
                                            {action.charAt(0).toUpperCase() + action.slice(1)}
                                        </label>
                                    ))}
                                </div>
                            </div>
                            
                            <h3>🏷️ Textos de Prompts</h3>
                            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '15px' }}>
                                <label>
                                    <strong>Prompt "Hablar":</strong>
                                    <input 
                                        type="text" 
                                        value={formData.valores_rol?.interaction_settings?.prompt_talk || 'Hablar'} 
                                        onChange={(e) => updateNestedSetting('interaction_settings.prompt_talk', e.target.value)}
                                        style={{ width: '100%', padding: '8px', marginTop: '5px', borderRadius: '4px', border: '1px solid #ced4da' }} 
                                    />
                                </label>
                                
                                <label>
                                    <strong>Prompt "Comerciar":</strong>
                                    <input 
                                        type="text" 
                                        value={formData.valores_rol?.interaction_settings?.prompt_trade || 'Comerciar'} 
                                        onChange={(e) => updateNestedSetting('interaction_settings.prompt_trade', e.target.value)}
                                        style={{ width: '100%', padding: '8px', marginTop: '5px', borderRadius: '4px', border: '1px solid #ced4da' }} 
                                    />
                                </label>
                                
                                <label>
                                    <strong>Prompt "Reclutar":</strong>
                                    <input 
                                        type="text" 
                                        value={formData.valores_rol?.interaction_settings?.prompt_recruit || 'Reclutar'} 
                                        onChange={(e) => updateNestedSetting('interaction_settings.prompt_recruit', e.target.value)}
                                        style={{ width: '100%', padding: '8px', marginTop: '5px', borderRadius: '4px', border: '1px solid #ced4da' }} 
                                    />
                                </label>
                                
                                <label>
                                    <strong>Prompt Genérico:</strong>
                                    <input 
                                        type="text" 
                                        value={formData.valores_rol?.interaction_settings?.prompt_generic || 'Interactuar'} 
                                        onChange={(e) => updateNestedSetting('interaction_settings.prompt_generic', e.target.value)}
                                        style={{ width: '100%', padding: '8px', marginTop: '5px', borderRadius: '4px', border: '1px solid #ced4da' }} 
                                    />
                                </label>
                            </div>
                        </div>
                    )}

                    {/* TAB: RECLUTAMIENTO - ¡COMPLETAMENTE NUEVO! */}
                    {activeTab === 'recruitment' && (
                        <div>
                            <h2 style={{ marginTop: 0, color: '#495057' }}>🤝 Sistema de Reclutamiento/Domado</h2>
                            
                            <div style={{ marginBottom: '20px' }}>
                                <label>
                                    <strong>¿Se puede reclutar/domar?</strong>
                                    <select 
                                        value={formData.valores_rol?.recruitment_settings?.puede_ser_reclutado || false} 
                                        onChange={(e) => updateNestedSetting('recruitment_settings.puede_ser_reclutado', e.target.value === 'true')}
                                        style={{ width: '100%', padding: '8px', marginTop: '5px', borderRadius: '4px', border: '1px solid #ced4da' }}
                                    >
                                        <option value="false">❌ No se puede reclutar</option>
                                        <option value="true">✅ Sí se puede reclutar</option>
                                    </select>
                                </label>
                            </div>

                            {formData.valores_rol?.recruitment_settings?.puede_ser_reclutado && (
                                <>
                                    <div style={{ marginBottom: '20px' }}>
                                        <label>
                                            <strong>Tipo de Reclutamiento:</strong>
                                            <select 
                                                value={formData.valores_rol?.recruitment_settings?.tipo_reclutamiento || 'soborno'} 
                                                onChange={(e) => updateNestedSetting('recruitment_settings.tipo_reclutamiento', e.target.value)}
                                                style={{ width: '100%', padding: '8px', marginTop: '5px', borderRadius: '4px', border: '1px solid #ced4da' }}
                                            >
                                                {Object.entries(recruitmentTypes).map(([key, label]) => (
                                                    <option key={key} value={key}>{label}</option>
                                                ))}
                                            </select>
                                        </label>
                                    </div>

                                    <h3>🎯 Requisitos para Reclutamiento</h3>
                                    <div style={{ border: '1px solid #dee2e6', borderRadius: '8px', padding: '15px', backgroundColor: '#f8f9fa' }}>
                                        {(formData.valores_rol?.recruitment_settings?.requisitos || []).map((req, index) => (
                                            <div key={index} style={{ 
                                                display: 'grid', 
                                                gridTemplateColumns: '150px 150px 1fr 100px 50px', 
                                                gap: '10px', 
                                                alignItems: 'center',
                                                marginBottom: '10px',
                                                padding: '10px',
                                                backgroundColor: 'white',
                                                borderRadius: '5px',
                                                border: '1px solid #ced4da'
                                            }}>
                                                <select
                                                    value={req.tipo || 'oro'}
                                                    onChange={(e) => updateRecruitmentRequirement(index, 'tipo', e.target.value)}
                                                    style={{ padding: '5px', borderRadius: '3px', border: '1px solid #ced4da' }}
                                                >
                                                    <option value="oro">💰 Oro</option>
                                                    <option value="objeto">📦 Objeto específico</option>
                                                    <option value="comida">🍖 Comida</option>
                                                    <option value="tarea">📋 Completar tarea</option>
                                                    <option value="tiempo">⏰ Tiempo/Paciencia</option>
                                                    <option value="combate">⚔️ Derrotar en combate</option>
                                                    <option value="paciencia">🧘 Paciencia/Confianza</option>
                                                </select>

                                                {(req.tipo === 'oro' || req.tipo === 'objeto' || req.tipo === 'comida' || req.tipo === 'tiempo') && (
                                                    <input
                                                        type="number"
                                                        value={req.cantidad || 1}
                                                        onChange={(e) => updateRecruitmentRequirement(index, 'cantidad', parseInt(e.target.value))}
                                                        placeholder="Cantidad"
                                                        style={{ padding: '5px', borderRadius: '3px', border: '1px solid #ced4da' }}
                                                        min="1"
                                                    />
                                                )}

                                                {req.tipo === 'objeto' && (
                                                    <select
                                                        value={req.objeto_id || ''}
                                                        onChange={(e) => updateRecruitmentRequirement(index, 'objeto_id', e.target.value)}
                                                        style={{ padding: '5px', borderRadius: '3px', border: '1px solid #ced4da' }}
                                                    >
                                                        <option value="">Seleccionar objeto...</option>
                                                        {availableObjects.map(obj => (
                                                            <option key={obj.id} value={obj.id}>
                                                                {obj.nombre} ({obj.tipo_objeto})
                                                            </option>
                                                        ))}
                                                    </select>
                                                )}

                                                <input
                                                    type="text"
                                                    value={req.descripcion || ''}
                                                    onChange={(e) => updateRecruitmentRequirement(index, 'descripcion', e.target.value)}
                                                    placeholder="Descripción del requisito"
                                                    style={{ padding: '5px', borderRadius: '3px', border: '1px solid #ced4da' }}
                                                />

                                                <label style={{ display: 'flex', alignItems: 'center', gap: '5px', fontSize: '12px' }}>
                                                    <input
                                                        type="checkbox"
                                                        checked={req.alternativa || false}
                                                        onChange={(e) => updateRecruitmentRequirement(index, 'alternativa', e.target.checked)}
                                                    />
                                                    Alt.
                                                </label>

                                                <button
                                                    type="button"
                                                    onClick={() => updateRecruitmentRequirement(index, 'remove')}
                                                    style={{ 
                                                        backgroundColor: '#dc3545', 
                                                        color: 'white', 
                                                        border: 'none', 
                                                        borderRadius: '3px', 
                                                        padding: '5px',
                                                        cursor: 'pointer'
                                                    }}
                                                >
                                                    ❌
                                                </button>
                                            </div>
                                        ))}

                                        <button
                                            type="button"
                                            onClick={addRecruitmentRequirement}
                                            style={{ 
                                                backgroundColor: '#28a745', 
                                                color: 'white', 
                                                border: 'none', 
                                                borderRadius: '5px', 
                                                padding: '10px 15px',
                                                cursor: 'pointer',
                                                width: '100%',
                                                marginTop: '10px'
                                            }}
                                        >
                                            ➕ Agregar Requisito
                                        </button>
                                    </div>

                                    <div style={{ marginTop: '15px', padding: '10px', backgroundColor: '#e9ecef', borderRadius: '5px' }}>
                                        <h4>💡 Ejemplos de configuración:</h4>
                                        <ul style={{ margin: 0, paddingLeft: '20px', fontSize: '14px' }}>
                                            <li><strong>Soborno:</strong> 100 oro + alternativa de espada mágica</li>
                                            <li><strong>Domesticación:</strong> 5 carnes + 30 segundos de paciencia</li>
                                            <li><strong>Intercambio:</strong> 20 maderas + 10 herramientas de hierro</li>
                                            <li><strong>Tarea:</strong> Completar misión "Rescatar aldeanos"</li>
                                            <li><strong>Combate:</strong> Derrotarlo en duelo + respetar su honor</li>
                                        </ul>
                                    </div>
                                </>
                            )}
                        </div>
                    )}

                    {/* TAB: LOOT - ¡COMPLETAMENTE NUEVO! */}
                    {activeTab === 'loot' && (
                        <div>
                            <h2 style={{ marginTop: 0, color: '#495057' }}>💎 Sistema de Loot al Morir</h2>
                            
                            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '20px', marginBottom: '20px' }}>
                                <label>
                                    <strong>¿Suelta loot al morir?</strong>
                                    <select 
                                        value={formData.valores_rol?.loot_settings?.drops_loot_on_death || false} 
                                        onChange={(e) => updateNestedSetting('loot_settings.drops_loot_on_death', e.target.value === 'true')}
                                        style={{ width: '100%', padding: '8px', marginTop: '5px', borderRadius: '4px', border: '1px solid #ced4da' }}
                                    >
                                        <option value="false">❌ No suelta nada</option>
                                        <option value="true">✅ Sí suelta loot</option>
                                    </select>
                                </label>

                                <label>
                                    <strong>¿Conserva su inventario al morir?</strong>
                                    <select 
                                        value={formData.valores_rol?.loot_settings?.conserva_inventario_on_death || false} 
                                        onChange={(e) => updateNestedSetting('loot_settings.conserva_inventario_on_death', e.target.value === 'true')}
                                        style={{ width: '100%', padding: '8px', marginTop: '5px', borderRadius: '4px', border: '1px solid #ced4da' }}
                                    >
                                        <option value="false">❌ Pierde su inventario</option>
                                        <option value="true">✅ Se lleva el inventario a la tumba</option>
                                    </select>
                                </label>
                            </div>

                            {formData.valores_rol?.loot_settings?.drops_loot_on_death && (
                                <>
                                    <h3>💰 Tabla de Loot</h3>
                                    <div style={{ border: '1px solid #dee2e6', borderRadius: '8px', padding: '15px', backgroundColor: '#f8f9fa' }}>
                                        {(formData.valores_rol?.loot_settings?.loot_table || []).map((loot, index) => (
                                            <div key={index} style={{ 
                                                display: 'grid', 
                                                gridTemplateColumns: '2fr 1fr 80px 80px 80px 50px', 
                                                gap: '10px', 
                                                alignItems: 'center',
                                                marginBottom: '10px',
                                                padding: '10px',
                                                backgroundColor: 'white',
                                                borderRadius: '5px',
                                                border: '1px solid #ced4da'
                                            }}>
                                                <div>
                                                    <select
                                                        value={loot.objeto_id || ''}
                                                        onChange={(e) => {
                                                            const selectedObj = availableObjects.find(obj => obj.id == e.target.value);
                                                            updateLootItem(index, 'objeto_id', e.target.value || null);
                                                            if (selectedObj) {
                                                                updateLootItem(index, 'nombre', selectedObj.nombre);
                                                            }
                                                        }}
                                                        style={{ width: '100%', padding: '5px', borderRadius: '3px', border: '1px solid #ced4da' }}
                                                    >
                                                        <option value="">💭 Objeto personalizado</option>
                                                        {availableObjects.map(obj => (
                                                            <option key={obj.id} value={obj.id}>
                                                                {obj.nombre} ({obj.tipo_objeto})
                                                            </option>
                                                        ))}
                                                    </select>
                                                    
                                                    {!loot.objeto_id && (
                                                        <input
                                                            type="text"
                                                            value={loot.nombre || ''}
                                                            onChange={(e) => updateLootItem(index, 'nombre', e.target.value)}
                                                            placeholder="Nombre del objeto personalizado"
                                                            style={{ width: '100%', padding: '5px', marginTop: '5px', borderRadius: '3px', border: '1px solid #ced4da' }}
                                                        />
                                                    )}
                                                </div>

                                                <div>
                                                    <label style={{ fontSize: '12px', fontWeight: 'bold' }}>Probabilidad:</label>
                                                    <input
                                                        type="number"
                                                        value={Math.round((loot.probabilidad || 0.5) * 100)}
                                                        onChange={(e) => updateLootItem(index, 'probabilidad', parseFloat(e.target.value) / 100)}
                                                        min="0" max="100" step="5"
                                                        style={{ width: '100%', padding: '5px', borderRadius: '3px', border: '1px solid #ced4da' }}
                                                    />
                                                    <span style={{ fontSize: '11px', color: '#666' }}>%</span>
                                                </div>

                                                <div>
                                                    <label style={{ fontSize: '12px', fontWeight: 'bold' }}>Min:</label>
                                                    <input
                                                        type="number"
                                                        value={loot.cantidad_min || 1}
                                                        onChange={(e) => updateLootItem(index, 'cantidad_min', parseInt(e.target.value))}
                                                        min="1" max="999"
                                                        style={{ width: '100%', padding: '5px', borderRadius: '3px', border: '1px solid #ced4da' }}
                                                    />
                                                </div>

                                                <div>
                                                    <label style={{ fontSize: '12px', fontWeight: 'bold' }}>Max:</label>
                                                    <input
                                                        type="number"
                                                        value={loot.cantidad_max || 1}
                                                        onChange={(e) => updateLootItem(index, 'cantidad_max', parseInt(e.target.value))}
                                                        min="1" max="999"
                                                        style={{ width: '100%', padding: '5px', borderRadius: '3px', border: '1px solid #ced4da' }}
                                                    />
                                                </div>

                                                <div style={{ fontSize: '11px', textAlign: 'center', color: '#666' }}>
                                                    {loot.probabilidad ? `${Math.round(loot.probabilidad * 100)}%` : '50%'}<br/>
                                                    {loot.cantidad_min || 1}-{loot.cantidad_max || 1}
                                                </div>

                                                <button
                                                    type="button"
                                                    onClick={() => updateLootItem(index, 'remove')}
                                                    style={{ 
                                                        backgroundColor: '#dc3545', 
                                                        color: 'white', 
                                                        border: 'none', 
                                                        borderRadius: '3px', 
                                                        padding: '5px',
                                                        cursor: 'pointer'
                                                    }}
                                                >
                                                    ❌
                                                </button>
                                            </div>
                                        ))}

                                        <button
                                            type="button"
                                            onClick={addLootItem}
                                            style={{ 
                                                backgroundColor: '#28a745', 
                                                color: 'white', 
                                                border: 'none', 
                                                borderRadius: '5px', 
                                                padding: '10px 15px',
                                                cursor: 'pointer',
                                                width: '100%',
                                                marginTop: '10px'
                                            }}
                                        >
                                            ➕ Agregar Item de Loot
                                        </button>
                                    </div>

                                    <div style={{ marginTop: '15px', padding: '10px', backgroundColor: '#e9ecef', borderRadius: '5px' }}>
                                        <h4>💡 Explicación del Sistema de Loot:</h4>
                                        <ul style={{ margin: 0, paddingLeft: '20px', fontSize: '14px' }}>
                                            <li><strong>Probabilidad:</strong> % de posibilidad de que suelte este objeto (0-100%)</li>
                                            <li><strong>Cantidad Min/Max:</strong> Rango de cantidad que puede soltar</li>
                                            <li><strong>Objeto personalizado:</strong> Si no seleccionas de la lista, puedes escribir cualquier cosa</li>
                                            <li><strong>Conservar inventario:</strong> Si está activado, no suelta su equipamiento personal</li>
                                        </ul>
                                    </div>
                                </>
                            )}
                        </div>
                    )}

                    {/* TAB: CONFIGURACIÓN ESPECIAL */}
                    {activeTab === 'special' && (
                        <div>
                            <h2 style={{ marginTop: 0, color: '#495057' }}>⚙️ Configuración Especial por Rol</h2>
                            
                            {/* COMERCIANTE */}
                            {formData.rol_npc === 'COMERCIANTE' && (
                                <div style={{ padding: '15px', backgroundColor: '#fff3cd', borderRadius: '8px', marginBottom: '20px' }}>
                                    <h3>💰 Configuración de Comercio</h3>
                                    <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '15px', marginBottom: '20px' }}>
                                        <label>
                                            <strong>Saludo:</strong>
                                            <input 
                                                type="text" 
                                                value={formData.valores_rol?.commerce_settings?.saludo || ''} 
                                                onChange={(e) => updateNestedSetting('commerce_settings.saludo', e.target.value)}
                                                style={{ width: '100%', padding: '8px', marginTop: '5px', borderRadius: '4px', border: '1px solid #ced4da' }} 
                                                placeholder="¡Bienvenido! ¿Qué quieres comprar?"
                                            />
                                        </label>
                                        
                                        <label>
                                            <strong>Despedida:</strong>
                                            <input 
                                                type="text" 
                                                value={formData.valores_rol?.commerce_settings?.despedida || ''} 
                                                onChange={(e) => updateNestedSetting('commerce_settings.despedida', e.target.value)}
                                                style={{ width: '100%', padding: '8px', marginTop: '5px', borderRadius: '4px', border: '1px solid #ced4da' }} 
                                                placeholder="¡Gracias por tu compra!"
                                            />
                                        </label>
                                        
                                        <label>
                                            <strong>Descuento Base (%):</strong>
                                            <input 
                                                type="number" 
                                                value={Math.round((formData.valores_rol?.commerce_settings?.descuento_base || 0) * 100)} 
                                                onChange={(e) => updateNestedSetting('commerce_settings.descuento_base', parseFloat(e.target.value) / 100)}
                                                min="0" max="90" step="1"
                                                style={{ width: '100%', padding: '8px', marginTop: '5px', borderRadius: '4px', border: '1px solid #ced4da' }} 
                                            />
                                        </label>
                                        
                                        <label>
                                            <strong>Markup de Precios:</strong>
                                            <input 
                                                type="number" 
                                                value={formData.valores_rol?.commerce_settings?.markup_base || 1.2} 
                                                onChange={(e) => updateNestedSetting('commerce_settings.markup_base', parseFloat(e.target.value))}
                                                min="0.5" max="5" step="0.1"
                                                style={{ width: '100%', padding: '8px', marginTop: '5px', borderRadius: '4px', border: '1px solid #ced4da' }} 
                                            />
                                        </label>
                                    </div>

                                    <h4>🛒 Ofertas de Comercio</h4>
                                    <div style={{ border: '1px solid #dee2e6', borderRadius: '8px', padding: '15px', backgroundColor: '#f8f9fa' }}>
                                        {(formData.valores_rol?.commerce_settings?.ofertas_comercio || []).map((oferta, index) => (
                                            <div key={index} style={{ 
                                                display: 'grid', 
                                                gridTemplateColumns: '2fr 1fr 2fr 1fr 50px', 
                                                gap: '10px', 
                                                alignItems: 'center',
                                                marginBottom: '10px',
                                                padding: '10px',
                                                backgroundColor: 'white',
                                                borderRadius: '5px',
                                                border: '1px solid #ced4da'
                                            }}>
                                                <div>
                                                    <label style={{ fontSize: '12px', fontWeight: 'bold' }}>Requiere:</label>
                                                    <select
                                                        value={oferta.requiere?.objeto_id || ''}
                                                        onChange={(e) => {
                                                            const selectedObj = availableObjects.find(obj => obj.id == e.target.value);
                                                            updateNestedSetting(`commerce_settings.ofertas_comercio.${index}.requiere.objeto_id`, e.target.value || null);
                                                            if (selectedObj) {
                                                                updateNestedSetting(`commerce_settings.ofertas_comercio.${index}.requiere.nombre`, selectedObj.nombre);
                                                            }
                                                        }}
                                                        style={{ width: '100%', padding: '5px', borderRadius: '3px', border: '1px solid #ced4da' }}
                                                    >
                                                        <option value="">Seleccionar objeto...</option>
                                                        {availableObjects.map(obj => (
                                                            <option key={obj.id} value={obj.id}>
                                                                {obj.nombre} ({obj.tipo_objeto})
                                                            </option>
                                                        ))}
                                                    </select>
                                                </div>

                                                <div>
                                                    <label style={{ fontSize: '12px', fontWeight: 'bold' }}>Cantidad:</label>
                                                    <input
                                                        type="number"
                                                        value={oferta.requiere?.cantidad || 1}
                                                        onChange={(e) => updateNestedSetting(`commerce_settings.ofertas_comercio.${index}.requiere.cantidad`, parseInt(e.target.value))}
                                                        min="1" max="999"
                                                        style={{ width: '100%', padding: '5px', borderRadius: '3px', border: '1px solid #ced4da' }}
                                                    />
                                                </div>

                                                <div>
                                                    <label style={{ fontSize: '12px', fontWeight: 'bold' }}>Ofrece:</label>
                                                    <select
                                                        value={oferta.ofrece?.objeto_id || ''}
                                                        onChange={(e) => {
                                                            const selectedObj = availableObjects.find(obj => obj.id == e.target.value);
                                                            updateNestedSetting(`commerce_settings.ofertas_comercio.${index}.ofrece.objeto_id`, e.target.value || null);
                                                            if (selectedObj) {
                                                                updateNestedSetting(`commerce_settings.ofertas_comercio.${index}.ofrece.nombre`, selectedObj.nombre);
                                                            }
                                                        }}
                                                        style={{ width: '100%', padding: '5px', borderRadius: '3px', border: '1px solid #ced4da' }}
                                                    >
                                                        <option value="">Seleccionar objeto...</option>
                                                        {availableObjects.map(obj => (
                                                            <option key={obj.id} value={obj.id}>
                                                                {obj.nombre} ({obj.tipo_objeto})
                                                            </option>
                                                        ))}
                                                    </select>
                                                </div>

                                                <div>
                                                    <label style={{ fontSize: '12px', fontWeight: 'bold' }}>Cantidad:</label>
                                                    <input
                                                        type="number"
                                                        value={oferta.ofrece?.cantidad || 1}
                                                        onChange={(e) => updateNestedSetting(`commerce_settings.ofertas_comercio.${index}.ofrece.cantidad`, parseInt(e.target.value))}
                                                        min="1" max="999"
                                                        style={{ width: '100%', padding: '5px', borderRadius: '3px', border: '1px solid #ced4da' }}
                                                    />
                                                </div>

                                                <button
                                                    type="button"
                                                    onClick={() => {
                                                        const currentOfertas = formData.valores_rol?.commerce_settings?.ofertas_comercio || [];
                                                        const newOfertas = currentOfertas.filter((_, i) => i !== index);
                                                        updateNestedSetting('commerce_settings.ofertas_comercio', newOfertas);
                                                    }}
                                                    style={{ 
                                                        backgroundColor: '#dc3545', 
                                                        color: 'white', 
                                                        border: 'none', 
                                                        borderRadius: '3px', 
                                                        padding: '5px',
                                                        cursor: 'pointer'
                                                    }}
                                                >
                                                    ❌
                                                </button>
                                            </div>
                                        ))}

                                        <button
                                            type="button"
                                            onClick={() => {
                                                const currentOfertas = formData.valores_rol?.commerce_settings?.ofertas_comercio || [];
                                                updateNestedSetting('commerce_settings.ofertas_comercio', [
                                                    ...currentOfertas,
                                                    { 
                                                        requiere: { objeto_id: null, nombre: '', cantidad: 1 },
                                                        ofrece: { objeto_id: null, nombre: '', cantidad: 1 }
                                                    }
                                                ]);
                                            }}
                                            style={{ 
                                                backgroundColor: '#28a745', 
                                                color: 'white', 
                                                border: 'none', 
                                                borderRadius: '5px', 
                                                padding: '10px 15px',
                                                cursor: 'pointer',
                                                width: '100%',
                                                marginTop: '10px'
                                            }}
                                        >
                                            ➕ Agregar Oferta de Comercio
                                        </button>
                                    </div>
                                </div>
                            )}

                            {/* MASCOTA */}
                            {formData.rol_npc === 'MASCOTA' && (
                                <div style={{ padding: '15px', backgroundColor: '#d1ecf1', borderRadius: '8px', marginBottom: '20px' }}>
                                    <h3>🐾 Configuración de Domado</h3>
                                    <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '15px' }}>
                                        <label>
                                            <strong>Comida Requerida:</strong>
                                            <select 
                                                value={formData.valores_rol?.taming_settings?.requiere_comida || 'Carne'} 
                                                onChange={(e) => updateNestedSetting('taming_settings.requiere_comida', e.target.value)}
                                                style={{ width: '100%', padding: '8px', marginTop: '5px', borderRadius: '4px', border: '1px solid #ced4da' }}
                                            >
                                                <option value="Carne">🥩 Carne</option>
                                                <option value="Pescado">🐟 Pescado</option>
                                                <option value="Frutas">🍎 Frutas</option>
                                                <option value="Verduras">🥕 Verduras</option>
                                                <option value="Cualquiera">🍽️ Cualquier comida</option>
                                            </select>
                                        </label>
                                        
                                        <label>
                                            <strong>Tiempo de Domesticación (seg):</strong>
                                            <input 
                                                type="number" 
                                                value={formData.valores_rol?.taming_settings?.tiempo_domesticacion || 30} 
                                                onChange={(e) => updateNestedSetting('taming_settings.tiempo_domesticacion', parseInt(e.target.value))}
                                                min="5" max="300" step="5"
                                                style={{ width: '100%', padding: '8px', marginTop: '5px', borderRadius: '4px', border: '1px solid #ced4da' }} 
                                            />
                                        </label>
                                        
                                        <label>
                                            <strong>Lealtad Inicial (%):</strong>
                                            <input 
                                                type="number" 
                                                value={formData.valores_rol?.taming_settings?.lealtad_inicial || 50} 
                                                onChange={(e) => updateNestedSetting('taming_settings.lealtad_inicial', parseInt(e.target.value))}
                                                min="0" max="100" step="5"
                                                style={{ width: '100%', padding: '8px', marginTop: '5px', borderRadius: '4px', border: '1px solid #ced4da' }} 
                                            />
                                        </label>
                                        
                                        <label>
                                            <strong>Lealtad Máxima (%):</strong>
                                            <input 
                                                type="number" 
                                                value={formData.valores_rol?.taming_settings?.max_lealtad || 100} 
                                                onChange={(e) => updateNestedSetting('taming_settings.max_lealtad', parseInt(e.target.value))}
                                                min="50" max="100" step="5"
                                                style={{ width: '100%', padding: '8px', marginTop: '5px', borderRadius: '4px', border: '1px solid #ced4da' }} 
                                            />
                                        </label>
                                    </div>
                                </div>
                            )}

                            {/* MAGO */}
                            {formData.rol_npc === 'MAGO' && (
                                <div style={{ padding: '15px', backgroundColor: '#f3e5f5', borderRadius: '8px', marginBottom: '20px' }}>
                                    <h3>🔮 Configuración Mágica</h3>
                                    <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '15px' }}>
                                        <label>
                                            <strong>Mana Máximo:</strong>
                                            <input 
                                                type="number" 
                                                value={formData.valores_rol?.magic_settings?.mana_max || 100} 
                                                onChange={(e) => updateNestedSetting('magic_settings.mana_max', parseInt(e.target.value))}
                                                min="50" max="500" step="10"
                                                style={{ width: '100%', padding: '8px', marginTop: '5px', borderRadius: '4px', border: '1px solid #ced4da' }} 
                                            />
                                        </label>
                                        
                                        <label>
                                            <strong>Costo Curación:</strong>
                                            <input 
                                                type="number" 
                                                value={formData.valores_rol?.magic_settings?.costo_servicios?.heal || 20} 
                                                onChange={(e) => updateNestedSetting('magic_settings.costo_servicios.heal', parseInt(e.target.value))}
                                                min="5" max="100" step="5"
                                                style={{ width: '100%', padding: '8px', marginTop: '5px', borderRadius: '4px', border: '1px solid #ced4da' }} 
                                            />
                                        </label>
                                        
                                        <label>
                                            <strong>Costo Teletransporte:</strong>
                                            <input 
                                                type="number" 
                                                value={formData.valores_rol?.magic_settings?.costo_servicios?.teleport || 50} 
                                                onChange={(e) => updateNestedSetting('magic_settings.costo_servicios.teleport', parseInt(e.target.value))}
                                                min="10" max="200" step="10"
                                                style={{ width: '100%', padding: '8px', marginTop: '5px', borderRadius: '4px', border: '1px solid #ced4da' }} 
                                            />
                                        </label>
                                        
                                        <label>
                                            <strong>Costo Escudo:</strong>
                                            <input 
                                                type="number" 
                                                value={formData.valores_rol?.magic_settings?.costo_servicios?.shield || 30} 
                                                onChange={(e) => updateNestedSetting('magic_settings.costo_servicios.shield', parseInt(e.target.value))}
                                                min="5" max="100" step="5"
                                                style={{ width: '100%', padding: '8px', marginTop: '5px', borderRadius: '4px', border: '1px solid #ced4da' }} 
                                            />
                                        </label>
                                    </div>
                                </div>
                            )}

                            {/* CONSTRUCTOR */}
                            {formData.rol_npc === 'CONSTRUCTOR' && (
                                <div style={{ padding: '15px', backgroundColor: '#f8d7da', borderRadius: '8px', marginBottom: '20px' }}>
                                    <h3>🔨 Configuración de Construcción</h3>
                                    <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '15px' }}>
                                        <label>
                                            <strong>Tiempo de Construcción (seg):</strong>
                                            <input 
                                                type="number" 
                                                value={formData.valores_rol?.craft_settings?.tiempo_construccion || 60} 
                                                onChange={(e) => updateNestedSetting('craft_settings.tiempo_construccion', parseInt(e.target.value))}
                                                min="10" max="600" step="10"
                                                style={{ width: '100%', padding: '8px', marginTop: '5px', borderRadius: '4px', border: '1px solid #ced4da' }} 
                                            />
                                        </label>
                                        
                                        <label>
                                            <strong>Costo Madera:</strong>
                                            <input 
                                                type="number" 
                                                value={formData.valores_rol?.craft_settings?.costo_construccion?.madera || 10} 
                                                onChange={(e) => updateNestedSetting('craft_settings.costo_construccion.madera', parseInt(e.target.value))}
                                                min="1" max="100" step="1"
                                                style={{ width: '100%', padding: '8px', marginTop: '5px', borderRadius: '4px', border: '1px solid #ced4da' }} 
                                            />
                                        </label>
                                        
                                        <label>
                                            <strong>Costo Piedra:</strong>
                                            <input 
                                                type="number" 
                                                value={formData.valores_rol?.craft_settings?.costo_construccion?.piedra || 5} 
                                                onChange={(e) => updateNestedSetting('craft_settings.costo_construccion.piedra', parseInt(e.target.value))}
                                                min="1" max="100" step="1"
                                                style={{ width: '100%', padding: '8px', marginTop: '5px', borderRadius: '4px', border: '1px solid #ced4da' }} 
                                            />
                                        </label>
                                    </div>
                                </div>
                            )}

                            {/* HITBOX Y APARIENCIA */}
                            <h3>🎯 Hitbox y Apariencia</h3>
                            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '15px' }}>
                                <label>
                                    <strong>Radio del Hitbox:</strong>
                                    <input 
                                        type="number" 
                                        value={formData.valores_rol?.hitbox_dimensions?.radius || 0.4} 
                                        onChange={(e) => updateNestedSetting('hitbox_dimensions.radius', parseFloat(e.target.value))}
                                        min="0.1" max="2" step="0.1"
                                        style={{ width: '100%', padding: '8px', marginTop: '5px', borderRadius: '4px', border: '1px solid #ced4da' }} 
                                    />
                                </label>
                                
                                <label>
                                    <strong>Altura del Hitbox:</strong>
                                    <input 
                                        type="number" 
                                        value={formData.valores_rol?.hitbox_dimensions?.height || 1.7} 
                                        onChange={(e) => updateNestedSetting('hitbox_dimensions.height', parseFloat(e.target.value))}
                                        min="0.5" max="5" step="0.1"
                                        style={{ width: '100%', padding: '8px', marginTop: '5px', borderRadius: '4px', border: '1px solid #ced4da' }} 
                                    />
                                </label>
                                
                                <label>
                                    <strong>Color del NPC:</strong>
                                    <input 
                                        type="color" 
                                        value={formData.valores_rol?.color || getCurrentRoleConfig().color} 
                                        onChange={(e) => updateNestedSetting('color', e.target.value)}
                                        style={{ width: '100%', padding: '8px', marginTop: '5px', borderRadius: '4px', border: '1px solid #ced4da' }} 
                                    />
                                </label>
                            </div>
                        </div>
                    )}

                    {/* TAB: VISTA PREVIA */}
                    {activeTab === 'preview' && (
                        <div>
                            <h2 style={{ marginTop: 0, color: '#495057' }}>👁️ Vista Previa del NPC</h2>
                            
                            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '20px' }}>
                                <div style={{ padding: '15px', backgroundColor: '#f8f9fa', borderRadius: '8px', border: '1px solid #dee2e6' }}>
                                    <h3 style={{ margin: '0 0 15px 0', color: getCurrentRoleConfig().color }}>
                                        {getCurrentRoleConfig().label} {formData.nombre}
                                    </h3>
                                    <p><strong>Descripción:</strong> {formData.descripcion || getCurrentRoleConfig().description}</p>
                                    <p><strong>Comportamiento:</strong> {formData.comportamiento_ia}</p>
                                    
                                    <h4>📊 Estadísticas:</h4>
                                    <ul style={{ margin: 0, paddingLeft: '20px' }}>
                                        <li>❤️ Salud: {formData.initial_salud_max}</li>
                                        <li>🍖 Hambre: {formData.initial_hambre_max}</li>
                                        <li>⚔️ Daño: {formData.initial_dano_ataque_base}</li>
                                        <li>🏃 Velocidad: {formData.initial_velocidad_movimiento}</li>
                                        <li>🎒 Inventario: {formData.initial_inventario_capacidad_slots} slots, {formData.initial_inventario_capacidad_peso_kg}kg</li>
                                    </ul>
                                    
                                    <h4>💬 Interacciones:</h4>
                                    <div style={{ display: 'flex', flexWrap: 'wrap', gap: '5px' }}>
                                        {(formData.valores_rol?.interaction_settings?.actions || []).map(action => (
                                            <span key={action} style={{ 
                                                backgroundColor: getCurrentRoleConfig().color, 
                                                color: 'white', 
                                                padding: '3px 8px', 
                                                borderRadius: '12px', 
                                                fontSize: '12px' 
                                            }}>
                                                {action}
                                            </span>
                                        ))}
                                    </div>

                                    <h4>🤝 Reclutamiento:</h4>
                                    <div style={{ fontSize: '14px' }}>
                                        {formData.valores_rol?.recruitment_settings?.puede_ser_reclutado ? (
                                            <div>
                                                <p style={{ margin: '5px 0', color: 'green' }}>✅ Se puede reclutar</p>
                                                <p style={{ margin: '5px 0' }}><strong>Tipo:</strong> {recruitmentTypes[formData.valores_rol?.recruitment_settings?.tipo_reclutamiento] || 'Soborno'}</p>
                                                <p style={{ margin: '5px 0' }}><strong>Requisitos:</strong></p>
                                                <ul style={{ margin: '5px 0', paddingLeft: '20px' }}>
                                                    {(formData.valores_rol?.recruitment_settings?.requisitos || []).map((req, i) => (
                                                        <li key={i}>{req.descripcion} {req.alternativa && '(Alternativa)'}</li>
                                                    ))}
                                                </ul>
                                            </div>
                                        ) : (
                                            <p style={{ margin: '5px 0', color: 'red' }}>❌ No se puede reclutar</p>
                                        )}
                                    </div>

                                    <h4>💎 Loot:</h4>
                                    <div style={{ fontSize: '14px' }}>
                                        {formData.valores_rol?.loot_settings?.drops_loot_on_death ? (
                                            <div>
                                                <p style={{ margin: '5px 0', color: 'green' }}>✅ Suelta loot al morir</p>
                                                <p style={{ margin: '5px 0' }}>
                                                    <strong>Inventario:</strong> {formData.valores_rol?.loot_settings?.conserva_inventario_on_death ? 'Se lo lleva a la tumba' : 'Se puede obtener'}
                                                </p>
                                                <ul style={{ margin: '5px 0', paddingLeft: '20px' }}>
                                                    {(formData.valores_rol?.loot_settings?.loot_table || []).map((loot, i) => (
                                                        <li key={i}>
                                                            {loot.nombre} ({Math.round((loot.probabilidad || 0.5) * 100)}% - {loot.cantidad_min || 1}-{loot.cantidad_max || 1})
                                                        </li>
                                                    ))}
                                                </ul>
                                            </div>
                                        ) : (
                                            <p style={{ margin: '5px 0', color: 'red' }}>❌ No suelta loot</p>
                                        )}
                                    </div>
                                </div>
                                
                                <div style={{ padding: '15px', backgroundColor: '#ffffff', borderRadius: '8px', border: '1px solid #dee2e6' }}>
                                    <h4 style={{ margin: '0 0 10px 0' }}>🔧 Configuración JSON Completa:</h4>
                                    <pre style={{ 
                                        backgroundColor: '#f8f9fa', 
                                        padding: '10px', 
                                        borderRadius: '4px', 
                                        fontSize: '11px', 
                                        overflow: 'auto', 
                                        maxHeight: '600px',
                                        border: '1px solid #ced4da'
                                    }}>
                                        {JSON.stringify(formData, null, 2)}
                                    </pre>
                                </div>
                            </div>
                        </div>
                    )}

                    {/* BOTÓN DE ENVÍO */}
                    <button 
                        type="submit" 
                        style={{ 
                            width: '100%', 
                            padding: '15px', 
                            backgroundColor: getCurrentRoleConfig().color, 
                            color: 'white', 
                            border: 'none', 
                            borderRadius: '5px', 
                            fontSize: '18px', 
                            fontWeight: 'bold',
                            cursor: 'pointer',
                            marginTop: '30px'
                        }}
                    >
                        🚀 Crear NPC: {getCurrentRoleConfig().label}
                    </button>
                </div>
            </form>

            {/* LISTA DE NPCS EXISTENTES */}
            <h2 style={{ marginTop: '40px' }}>🤖 NPCs Existentes:</h2>
            <div style={{ display: 'grid', gap: '15px' }}>
                {npcTypes.map(npc => (
                    <div key={npc.id} style={{ border: '1px solid #dee2e6', padding: '15px', borderRadius: '8px', backgroundColor: '#f8f9fa' }}>
                        <h3 style={{ margin: '0 0 10px 0', color: '#495057' }}>
                            {roleConfigs[npc.rol_npc]?.label || '🤖'} {npc.nombre} 
                            <span style={{ fontSize: '14px', color: '#6c757d' }}>(ID: {npc.id})</span>
                        </h3>
                        <p style={{ margin: '0 0 10px 0', color: '#6c757d' }}>{npc.descripcion}</p>
                        <div style={{ display: 'flex', gap: '20px', fontSize: '14px', marginBottom: '10px' }}>
                            <span><strong>Rol:</strong> {npc.rol_npc}</span>
                            <span><strong>Gráfico:</strong> {npc.id_grafico}</span>
                            <span style={{ color: npc.valores_rol?.color || '#8A2BE2' }}>
                                <strong>●</strong> Color: {npc.valores_rol?.color || '#8A2BE2'}
                            </span>
                            <span>
                                <strong>Reclutable:</strong> {npc.valores_rol?.recruitment_settings?.puede_ser_reclutado ? '✅' : '❌'}
                            </span>
                            <span>
                                <strong>Loot:</strong> {npc.valores_rol?.loot_settings?.drops_loot_on_death ? '💎' : '❌'}
                            </span>
                        </div>
                        <details>
                            <summary style={{ cursor: 'pointer', fontWeight: 'bold' }}>Ver Configuración Completa</summary>
                            <pre style={{ backgroundColor: '#ffffff', padding: '10px', borderRadius: '4px', fontSize: '11px', marginTop: '10px', border: '1px solid #ced4da' }}>
                                {JSON.stringify(npc, null, 2)}
                            </pre>
                        </details>
                    </div>
                ))}
            </div>
        </div>
    );
};

export default TipoNPCAdminPage;
