// el-ultimo-bastion/frontend/src/components/WorldNPCsEditor.jsx
import React, { useState, useEffect } from 'react';
import { createInstanciaNPC, getInstanciasNPCByMundo, updateInstanciaNPC, getTiposNPC, getCriaturaVivaBases } from '../api/adminApi';

const WorldNPCsEditor = ({ worldId }) => {
    const [formData, setFormData] = useState({
        id_tipo_npc: '',
        id_criatura_viva_base: '', // Campo para seleccionar una CVB existente o dejar en blanco para crear
        posicion: '{"x":0,"y":0,"z":0}',
        esta_vivo: true,
        // Campos opcionales para la creación de CVB si id_criatura_viva_base no se selecciona
        initial_salud_max: 50,
        initial_hambre_max: 50,
        initial_dano_ataque_base: 5,
        initial_velocidad_movimiento: 3.0,
        initial_inventario_capacidad_slots: 5,
        initial_inventario_capacidad_peso_kg: 10.0,
        initial_loot_table_id: null,
        // Estos campos no se usarán para el PUT, solo para el POST de creación
    });
    const [instanciaNPCs, setInstanciaNPCs] = useState([]);
    const [tiposNPC, setTiposNPC] = useState([]);
    const [criaturaVivaBases, setCriaturaVivaBases] = useState([]);
    const [message, setMessage] = useState('');
    const [error, setError] = useState('');
    const [editingInstanciaNPCId, setEditingInstanciaNPCId] = useState(null);

    useEffect(() => {
        if (worldId) {
            fetchInstanciaNPCs();
            fetchDropdownData();
        }
    }, [worldId]);

    const fetchInstanciaNPCs = async () => {
        try {
            const data = await getInstanciasNPCByMundo(worldId);
            setInstanciaNPCs(data);
        } catch (err) {
            setError('Error al cargar Instancias NPC para este mundo: ' + (err.response?.data?.message || err.message));
        }
    };

    const fetchDropdownData = async () => {
        try {
            const tipos = await getTiposNPC();
            setTiposNPC(tipos);
            const cvbs = await getCriaturaVivaBases();
            setCriaturaVivaBases(cvbs);
        } catch (err) {
            console.error("Error fetching dropdown data for NPC instances:", err);
            setError('Error al cargar datos de dropdowns de NPC: ' + (err.response?.data?.message || err.message));
        }
    };

    const handleChange = (e) => {
        const { name, value, type, checked } = e.target;
        setFormData(prev => ({
            ...prev,
            [name]: type === 'checkbox' ? checked : (type === 'number' ? parseFloat(value) : value)
        }));
    };

    const handleJsonChange = (e) => {
        const { name, value } = e.target;
        setFormData(prev => ({ ...prev, [name]: value }));
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        setMessage('');
        setError('');
        try {
            const dataToSend = {
                ...formData,
                id_mundo: worldId, // Asignar automáticamente al mundo actual
                posicion: JSON.parse(formData.posicion),
                id_tipo_npc: parseInt(formData.id_tipo_npc),
                esta_vivo: formData.esta_vivo, // Ya es booleano
            };

            if (formData.id_criatura_viva_base) {
                dataToSend.id_criatura_viva_base = parseInt(formData.id_criatura_viva_base);
            } else {
                // Si no se seleccionó una CVB existente, se envían los campos initial_X para crear una nueva
                dataToSend.initial_salud_max = parseInt(formData.initial_salud_max);
                dataToSend.initial_hambre_max = parseInt(formData.initial_hambre_max);
                dataToSend.initial_dano_ataque_base = parseInt(formData.initial_dano_ataque_base);
                dataToSend.initial_velocidad_movimiento = parseFloat(formData.initial_velocidad_movimiento);
                dataToSend.initial_inventario_capacidad_slots = parseInt(formData.initial_inventario_capacidad_slots);
                dataToSend.initial_inventario_capacidad_peso_kg = parseFloat(formData.initial_inventario_capacidad_peso_kg);
                dataToSend.initial_loot_table_id = formData.initial_loot_table_id ? parseInt(formData.initial_loot_table_id) : null;
            }

            let result;
            if (editingInstanciaNPCId) {
                // Para la actualización, solo enviar los campos que se pueden modificar.
                // id_tipo_npc, id_mundo, id_criatura_viva_base NO se deberían cambiar
                // Los campos initial_X tampoco son relevantes en una actualización
                const updateData = {
                    posicion: dataToSend.posicion,
                    esta_vivo: dataToSend.esta_vivo,
                    // Add other updatable fields here (e.g., id_aldea_pertenece, valores_dinamicos)
                };
                result = await updateInstanciaNPC(editingInstanciaNPCId, updateData);
                setMessage('Instancia NPC actualizada con éxito!');
            } else {
                result = await createInstanciaNPC(dataToSend);
                setMessage('Instancia NPC creada con éxito!');
            }

            setFormData({ // Reset form
                id_tipo_npc: '', id_criatura_viva_base: '', posicion: '{"x":0,"y":0,"z":0}', esta_vivo: true,
                initial_salud_max: 50, initial_hambre_max: 50, initial_dano_ataque_base: 5,
                initial_velocidad_movimiento: 3.0, initial_inventario_capacidad_slots: 5,
                initial_inventario_capacidad_peso_kg: 10.0, initial_loot_table_id: null
            });
            setEditingInstanciaNPCId(null);
            fetchInstanciaNPCs(); // Refresh list
        } catch (err) {
            setError('Error al guardar Instancia NPC: ' + (err.response?.data?.message || err.message));
        }
    };

    const handleEditClick = (instancia) => {
        setFormData({
            id_tipo_npc: instancia.id_tipo_npc,
            id_criatura_viva_base: instancia.id_criatura_viva_base,
            posicion: JSON.stringify(instancia.posicion, null, 2),
            esta_vivo: instancia.esta_vivo,
            // No cargar initial_X fields para edición, ya que no se usan en PUT
        });
        setEditingInstanciaNPCId(instancia.id);
        setMessage('');
        setError('');
    };

    const handleCancelEdit = () => {
        setFormData({
            id_tipo_npc: '', id_criatura_viva_base: '', posicion: '{"x":0,"y":0,"z":0}', esta_vivo: true,
            initial_salud_max: 50, initial_hambre_max: 50, initial_dano_ataque_base: 5,
            initial_velocidad_movimiento: 3.0, initial_inventario_capacidad_slots: 5,
            initial_inventario_capacidad_peso_kg: 10.0, initial_loot_table_id: null
        });
        setEditingInstanciaNPCId(null);
        setMessage('');
        setError('');
    };

    const isCreatingNewInstancia = !editingInstanciaNPCId;

    return (
        <div style={{ marginTop: '30px', borderTop: '1px solid #ccc', paddingTop: '20px' }}>
            <h2>Gestionar NPCs de este Mundo</h2>

            {message && <p style={{ color: 'green' }}>{message}</p>}
            {error && <p style={{ color: 'red' }}>{error}</p>}

            <form onSubmit={handleSubmit} style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '20px', border: '1px solid #ccc', padding: '20px', borderRadius: '8px', marginBottom: '30px' }}>
                <fieldset style={{ gridColumn: 'span 2', padding: '15px', borderRadius: '8px', border: '1px solid #ddd' }}>
                    <legend>{isCreatingNewInstancia ? 'Crear Nueva Instancia NPC' : `Editar Instancia NPC (ID: ${editingInstanciaNPCId})`}</legend>
                    <div style={{ display: 'grid', gap: '10px' }}>
                        <label>
                            Tipo NPC:
                            <select name="id_tipo_npc" value={formData.id_tipo_npc} onChange={handleChange} required disabled={!isCreatingNewInstancia} style={{ width: '100%', padding: '8px' }}>
                                <option value="">Seleccionar Tipo NPC</option>
                                {tiposNPC.map(tipo => (
                                    <option key={tipo.id} value={tipo.id}>{tipo.nombre} (ID: {tipo.id})</option>
                                ))}
                            </select>
                        </label>
                        {isCreatingNewInstancia && (
                            <label>
                                CriaturaViva_Base Existente (Opcional):
                                <select name="id_criatura_viva_base" value={formData.id_criatura_viva_base} onChange={handleChange} style={{ width: '100%', padding: '8px' }}>
                                    <option value="">Crear Nueva (Recomendado)</option>
                                    {criaturaVivaBases.map(cvb => (
                                        <option key={cvb.id} value={cvb.id}>{cvb.id} (Salud: {cvb.danio?.salud_actual}/{cvb.danio?.salud_max})</option>
                                    ))}
                                </select>
                            </label>
                        )}
                        {!formData.id_criatura_viva_base && isCreatingNewInstancia && (
                            <div style={{ borderTop: '1px dashed #ccc', paddingTop: '10px', marginTop: '10px', gridColumn: 'span 2' }}>
                                <h4>Valores Iniciales para Nueva CriaturaViva_Base:</h4>
                                <label>Salud Máx: <input type="number" name="initial_salud_max" value={formData.initial_salud_max} onChange={handleChange} required /></label>
                                <label>Hambre Máx: <input type="number" name="initial_hambre_max" value={formData.initial_hambre_max} onChange={handleChange} required /></label>
                                <label>Daño Ataque Base: <input type="number" name="initial_dano_ataque_base" value={formData.initial_dano_ataque_base} onChange={handleChange} required /></label>
                                <label>Velocidad Movimiento: <input type="number" name="initial_velocidad_movimiento" value={formData.initial_velocidad_movimiento} onChange={handleChange} required step="0.1" /></label>
                                <label>Slots Inventario: <input type="number" name="initial_inventario_capacidad_slots" value={formData.initial_inventario_capacidad_slots} onChange={handleChange} required /></label>
                                <label>Peso Inventario (kg): <input type="number" name="initial_inventario_capacidad_peso_kg" value={formData.initial_inventario_capacidad_peso_kg} onChange={handleChange} required step="0.1" /></label>
                                <label>ID Loot Table (Opcional): <input type="number" name="initial_loot_table_id" value={formData.initial_loot_table_id || ''} onChange={handleChange} /></label>
                            </div>
                        )}

                        <label>
                            Posición (JSON):
                            <textarea name="posicion" value={formData.posicion} onChange={handleJsonChange} style={{ width: '100%', height: '80px', padding: '8px', fontFamily: 'monospace' }} required></textarea>
                        </label>
                        <label>
                            Está Vivo:
                            <input type="checkbox" name="esta_vivo" checked={formData.esta_vivo} onChange={handleChange} />
                        </label>
                        {/* Otros campos opcionales como id_aldea_pertenece, id_clan_pertenece etc. pueden añadirse aquí */}
                    </div>
                </fieldset>

                <div style={{ gridColumn: 'span 2', display: 'flex', justifyContent: 'flex-end', gap: '10px' }}>
                    <button type="submit" style={{ padding: '10px 15px', backgroundColor: '#007bff', color: 'white', border: 'none', borderRadius: '5px', cursor: 'pointer' }}>
                        {isCreatingNewInstancia ? 'Crear Instancia NPC' : 'Actualizar Instancia NPC'}
                    </button>
                    {editingInstanciaNPCId && (
                        <button type="button" onClick={handleCancelEdit} style={{ padding: '10px 15px', backgroundColor: '#6c757d', color: 'white', border: 'none', borderRadius: '5px', cursor: 'pointer' }}>
                            Cancelar Edición
                        </button>
                    )}
                </div>
            </form>

            <h3>Instancias NPC en este Mundo:</h3>
            <ul style={{ listStyle: 'none', padding: 0 }}>
                {instanciaNPCs.map(instancia => (
                    <li key={instancia.id} style={{ border: '1px solid #eee', padding: '10px', marginBottom: '10px', borderRadius: '5px' }}>
                        <strong>ID: {instancia.id}</strong> - Tipo NPC ID: {instancia.id_tipo_npc}<br />
                        CriaturaViva_Base ID: {instancia.id_criatura_viva_base}<br />
                        Posición: <code>{JSON.stringify(instancia.posicion)}</code><br />
                        Está Vivo: {instancia.esta_vivo ? 'Sí' : 'No'}<br />
                        <button onClick={() => handleEditClick(instancia)} style={{ marginTop: '5px', padding: '5px 10px', backgroundColor: '#17a2b8', color: 'white', border: 'none', borderRadius: '3px', cursor: 'pointer' }}>Editar</button>
                    </li>
                ))}
            </ul>
        </div>
    );
};

export default WorldNPCsEditor;