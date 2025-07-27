// el-ultimo-bastion/frontend/src/pages/TipoNPCAdminPage.jsx
import React, { useState, useEffect } from 'react';
import { createTipoNPC, getTiposNPC } from '../api/adminApi'; // Asegúrate de que estas sean las reales

// Componente simple para el tooltip de ayuda
const HelpTooltip = ({ text }) => {
    const [isVisible, setIsVisible] = useState(false);
    return (
        <span
            onMouseEnter={() => setIsVisible(true)}
            onMouseLeave={() => setIsVisible(false)}
            style={{
                marginLeft: '5px',
                cursor: 'help',
                fontSize: '0.8em',
                color: '#888',
                position: 'relative',
                display: 'inline-block'
            }}
        >
            ⓘ
            {isVisible && (
                <div style={{
                    position: 'absolute',
                    left: '20px',
                    top: '0',
                    backgroundColor: '#333',
                    color: 'white',
                    padding: '8px',
                    borderRadius: '4px',
                    width: '200px',
                    zIndex: 100,
                    fontSize: '0.9em',
                    boxShadow: '0 2px 5px rgba(0,0,0,0.2)'
                }}>
                    {text}
                </div>
            )}
        </span>
    );
};

const TipoNPCAdminPage = () => {
    const [formData, setFormData] = useState({
        // Sección 1: Identidad
        nombre: '',
        descripcion: '',
        id_grafico: 'default_npc_model',

        // Sección 2: Rol y Comportamiento
        rol_npc: 'GENERICO',
        comportamiento_ia: 'Deambula pacíficamente.',
        puede_deambular: true, // Esto irá dentro de valores_rol

        // Sección 3: Apariencia Visual y Colisión (dentro de valores_rol)
        visual_radius: 0.5,
        visual_height: 1.0,
        visual_color: '#00FF00', // Color verde por defecto
        
        // Sección 4: Estadísticas Base (lo que antes era CriaturaViva_Base, para el backend)
        initial_salud_max: 100,
        initial_hambre_max: 100,
        initial_dano_ataque_base: 5,
        initial_velocidad_movimiento: 3.0,

        // Sección 5: Inventario y Loot (para el backend)
        initial_inventario_capacidad_slots: 5,
        initial_inventario_capacidad_peso_kg: 20.0,
        initial_loot_table_id: null, 
    });

    const [tiposNPC, setTiposNPC] = useState([]);
    const [message, setMessage] = useState('');
    const [error, setError] = useState('');

    useEffect(() => {
        fetchTiposNPC();
    }, []);

    const fetchTiposNPC = async () => {
        try {
            const data = await getTiposNPC();
            setTiposNPC(data);
        } catch (err) {
            setError('Error al cargar tipos de NPC: ' + (err.response?.data?.message || err.message));
        }
    };

    const handleChange = (e) => {
        const { name, value, type, checked } = e.target;
        setFormData(prev => ({
            ...prev,
            [name]: type === 'checkbox' ? checked : (type === 'number' ? parseFloat(value) : value)
        }));
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        setMessage('');
        setError('');
        try {
            const dataToSend = {
                nombre: formData.nombre,
                descripcion: formData.descripcion,
                id_grafico: formData.id_grafico,
                rol_npc: formData.rol_npc,
                comportamiento_ia: formData.comportamiento_ia,
                habilidades_base: [], // Asumiendo que no hay input aún para esto
                resistencia_dano: {}, // Asumiendo que no hay input aún para esto
                
                // Construyendo el JSON `valores_rol` para el backend
                valores_rol: {
                    puede_deambular: formData.puede_deambular,
                    hitbox_dimensions: {
                        radius: formData.visual_radius,
                        height: formData.visual_height,
                    },
                    color: formData.visual_color, // Añadimos el color aquí
                },

                // Campos para inicializar CriaturaViva_Base en el backend
                initial_salud_max: formData.initial_salud_max,
                initial_hambre_max: formData.initial_hambre_max,
                initial_dano_ataque_base: formData.initial_dano_ataque_base,
                initial_velocidad_movimiento: formData.initial_velocidad_movimiento,
                initial_inventario_capacidad_slots: formData.initial_inventario_capacidad_slots,
                initial_inventario_capacidad_peso_kg: formData.initial_inventario_capacidad_peso_kg,
                initial_loot_table_id: formData.initial_loot_table_id,
            };

            await createTipoNPC(dataToSend);
            setMessage(`¡Tipo de NPC "${formData.nombre}" creado con éxito! Ahora puedes instanciarlo en el Editor de Mundos.`);
            setFormData({ // Reset form
                nombre: '', descripcion: '', id_grafico: 'default_npc_model',
                rol_npc: 'GENERICO', comportamiento_ia: 'Deambula pacíficamente.', puede_deambular: true,
                visual_radius: 0.5, visual_height: 1.0, visual_color: '#00FF00',
                initial_salud_max: 100, initial_hambre_max: 100, initial_dano_ataque_base: 5,
                initial_velocidad_movimiento: 3.0, initial_inventario_capacidad_slots: 5,
                initial_inventario_capacidad_peso_kg: 20.0, initial_loot_table_id: null,
            });
            fetchTiposNPC(); // Refrescar la lista de tipos en esta página
        } catch (err) {
            setError('Error al crear Tipo de NPC: ' + (err.response?.data?.message || err.message));
            console.error("Error al enviar TipoNPC:", err);
        }
    };

    const fieldsetStyle = {
        border: '1px solid #ccc',
        borderRadius: '8px',
        padding: '20px',
        marginBottom: '20px'
    };
    const labelStyle = { display: 'block', marginBottom: '10px' };
    const inputStyle = { width: '100%', padding: '8px', boxSizing: 'border-box' };

    return (
        <div style={{ maxWidth: '900px', margin: 'auto' }}>
            <h1>Creador de Arquetipos de NPC</h1>
            <p>Define una nueva "plantilla" de NPC. Una vez creada, podrás añadir instancias de este NPC en cualquier mundo desde el "Editor de Contenido de Mundo".</p>
            
            {message && <p style={{ color: 'green', border: '1px solid green', padding: '10px', borderRadius: '5px' }}>{message}</p>}
            {error && <p style={{ color: 'red' }}>{error}</p>}

            <form onSubmit={handleSubmit}>
                <fieldset style={fieldsetStyle}>
                    <legend><h3>Paso 1: Identidad y Apariencia <HelpTooltip text="Define el nombre, descripción y el ID del modelo gráfico que usará este tipo de NPC en el juego." /></h3></legend>
                    <label style={labelStyle}>
                        Nombre del Arquetipo (ej. "Zombie Lento", "Mago de Fuego", "Hombre Canario"):
                        <input type="text" name="nombre" value={formData.nombre} onChange={handleChange} required style={inputStyle} />
                    </label>
                    <label style={labelStyle}>
                        Descripción (Lore o notas para otros diseñadores):
                        <textarea name="descripcion" value={formData.descripcion} onChange={handleChange} style={{...inputStyle, minHeight: '60px'}}></textarea>
                    </label>
                     <label style={labelStyle}>
                        ID Gráfico (Nombre interno del modelo 3D/sprite que Godot buscará):
                        <input type="text" name="id_grafico" value={formData.id_grafico} onChange={handleChange} style={inputStyle} />
                        <HelpTooltip text="Este ID debe coincidir con el nombre de un recurso gráfico (ej. escena, mesh) en el proyecto Godot. Por ejemplo: 'goblin_model', 'spider_sprite'." />
                    </label>
                </fieldset>

                <fieldset style={fieldsetStyle}>
                    <legend><h3>Paso 2: Rol, Comportamiento y Dimensiones Físicas <HelpTooltip text="Define cómo se comportará este NPC en el juego y sus dimensiones físicas." /></h3></legend>
                    <label style={labelStyle}>
                        Rol Principal (Define la IA base en el juego):
                        <select name="rol_npc" value={formData.rol_npc} onChange={handleChange} style={inputStyle}>
                            <option value="GENERICO">Genérico (Pacífico, de ambiente)</option>
                            <option value="MALVADO">Malvado (Hostil, ataca a jugadores)</option>
                            <option value="CONSTRUCTOR">Constructor (Repara o construye estructuras)</option>
                            <option value="COMERCIANTE">Comerciante (Ofrece intercambios)</option>
                            <option value="MAGO">Mago (Usa habilidades especiales)</option>
                        </select>
                        <HelpTooltip text="El rol determina el conjunto de acciones y decisiones que la inteligencia artificial del NPC puede tomar." />
                    </label>
                    <label style={labelStyle}>
                        Comportamiento de IA (Descripción detallada para desarrolladores):
                        <textarea name="comportamiento_ia" value={formData.comportamiento_ia} onChange={handleChange} style={{...inputStyle, minHeight: '60px'}}></textarea>
                        <HelpTooltip text="Notas internas sobre cómo debería funcionar la IA de este NPC (ej. 'Ataca al jugador si está a 10m y tiene menos del 50% de vida')." />
                    </label>
                    <label style={labelStyle}>
                        <input type="checkbox" name="puede_deambular" checked={formData.puede_deambular} onChange={handleChange} style={{ marginRight: '10px' }} />
                        ¿Puede moverse aleatoriamente (deambular)?
                        <HelpTooltip text="Si está marcado, el NPC buscará puntos aleatorios dentro de un radio para moverse. Si no, permanecerá estático (a menos que otra IA lo mueva)." />
                    </label>
                    <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '20px' }}>
                        <label style={labelStyle}>
                            Radio de Colisión/Visual (en metros):
                            <input type="number" step="0.1" name="visual_radius" value={formData.visual_radius} onChange={handleChange} required style={inputStyle} />
                            <HelpTooltip text="El radio del cilindro o cápsula que representa al NPC en el juego (para colisiones y renderizado por defecto)." />
                        </label>
                        <label style={labelStyle}>
                            Altura de Colisión/Visual (en metros):
                            <input type="number" step="0.1" name="visual_height" value={formData.visual_height} onChange={handleChange} required style={inputStyle} />
                            <HelpTooltip text="La altura del cilindro o cápsula que representa al NPC en el juego." />
                        </label>
                        <label style={labelStyle}>
                            Color Base (Hex, ej. #FF00FF):
                            <input type="color" name="visual_color" value={formData.visual_color} onChange={handleChange} style={{...inputStyle, height: '40px'}} />
                            <HelpTooltip text="Color por defecto del NPC si no se carga un modelo específico, o como base para efectos visuales." />
                        </label>
                    </div>
                </fieldset>

                <fieldset style={fieldsetStyle}>
                    <legend><h3>Paso 3: Estadísticas Iniciales de Criatura Viva <HelpTooltip text="Estos valores definen los atributos iniciales del NPC cuando se crea una instancia en el mundo." /></h3></legend>
                     <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '20px' }}>
                        <label style={labelStyle}>
                            Salud Máxima Inicial:
                            <input type="number" name="initial_salud_max" value={formData.initial_salud_max} onChange={handleChange} required style={inputStyle} />
                            <HelpTooltip text="La salud máxima que tendrá este NPC al ser creado." />
                        </label>
                         <label style={labelStyle}>
                            Daño de Ataque Base Inicial:
                            <input type="number" name="initial_dano_ataque_base" value={formData.initial_dano_ataque_base} onChange={handleChange} required style={inputStyle} />
                            <HelpTooltip text="El daño que causa este NPC en sus ataques básicos." />
                        </label>
                        <label style={labelStyle}>
                            Velocidad de Movimiento Inicial (metros/segundo):
                            <input type="number" step="0.1" name="initial_velocidad_movimiento" value={formData.initial_velocidad_movimiento} onChange={handleChange} required style={inputStyle} />
                            <HelpTooltip text="La velocidad base a la que se moverá este NPC." />
                        </label>
                         <label style={labelStyle}>
                            Hambre Máxima Inicial:
                            <input type="number" name="initial_hambre_max" value={formData.initial_hambre_max} onChange={handleChange} required style={inputStyle} />
                            <HelpTooltip text="La capacidad máxima de hambre del NPC. Afecta cuánto tiempo puede estar sin comer." />
                        </label>
                        <label style={labelStyle}>
                            Slots de Inventario Iniciales:
                            <input type="number" name="initial_inventario_capacidad_slots" value={formData.initial_inventario_capacidad_slots} onChange={handleChange} required style={inputStyle} />
                            <HelpTooltip text="Número de espacios disponibles en el inventario de este NPC al ser creado." />
                        </label>
                        <label style={labelStyle}>
                            Capacidad de Peso Inicial (kg):
                            <input type="number" step="0.1" name="initial_inventario_capacidad_peso_kg" value={formData.initial_inventario_capacidad_peso_kg} onChange={handleChange} required style={inputStyle} />
                            <HelpTooltip text="El peso máximo de objetos que este NPC puede cargar en su inventario al ser creado." />
                        </label>
                        <label style={labelStyle}>
                            ID de Loot Table Inicial (Opcional):
                            <input type="number" name="initial_loot_table_id" value={formData.initial_loot_table_id === null ? '' : formData.initial_loot_table_id} onChange={handleChange} style={inputStyle} />
                            <HelpTooltip text="El ID de la tabla de botín (Loot Table) que este NPC usará al morir. Si no se especifica, no soltará botín predefinido." />
                        </label>
                    </div>
                </fieldset>
                
                <button type="submit" style={{ width: '100%', padding: '15px', fontSize: '18px', backgroundColor: '#28a745', color: 'white', border: 'none', borderRadius: '5px', cursor: 'pointer' }}>
                    Crear Arquetipo de NPC
                </button>
            </form>

            <h2 style={{ marginTop: '30px' }}>Tipos de NPC Existentes:</h2>
            <p style={{ marginBottom: '15px', color: '#666' }}>Estos son todos los arquetipos de NPC que has definido. Puedes usarlos para crear nuevas instancias en cualquier mundo.</p>
            <ul style={{ listStyle: 'none', padding: 0 }}>
                {tiposNPC.length === 0 ? (
                    <li>No hay tipos de NPC creados aún.</li>
                ) : (
                    tiposNPC.map(tipo => (
                        <li key={tipo.id} style={{ border: '1px solid #eee', padding: '10px', marginBottom: '10px', borderRadius: '5px' }}>
                            <strong>{tipo.nombre}</strong> (ID: {tipo.id}) - Rol: {tipo.rol_npc}<br />
                            <small>{tipo.descripcion}</small><br />
                            ID Gráfico: <code>{tipo.id_grafico || 'N/A'}</code><br />
                            Deambula: {tipo.valores_rol?.puede_deambular ? 'Sí' : 'No'}<br />
                            Dimensiones: R: {tipo.valores_rol?.hitbox_dimensions?.radius || 'N/A'}, H: {tipo.valores_rol?.hitbox_dimensions?.height || 'N/A'}<br />
                            Color: <span style={{display: 'inline-block', width: '20px', height: '20px', backgroundColor: tipo.valores_rol?.color || 'transparent', border: '1px solid #ccc', verticalAlign: 'middle'}}></span> {tipo.valores_rol?.color || 'N/A'}
                        </li>
                    ))
                )}
            </ul>
        </div>
    );
};

export default TipoNPCAdminPage;