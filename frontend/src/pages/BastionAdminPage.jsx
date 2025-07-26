// el-ultimo-bastion/frontend/src/pages/BastionAdminPage.jsx
import React, { useState, useEffect } from 'react';
import { createBastion, getBastions, updateBastion, getUsuarios, getClanes, getCriaturaVivaBases } from '../api/adminApi';

const BastionAdminPage = () => {
    const [formData, setFormData] = useState({
        nombre_personaje: '',
        nivel: 1,
        experiencia: 0,
        id_usuario: '',
        id_clan: '',
        habilidades_aprendidas: '[]', // JSON string for array
        id_criatura_viva_base: '', // Para seleccionar una CVB existente
        // Initial CriaturaViva_Base fields for new Bastions if not reusing existing CVB
        initial_salud_max: 100,
        initial_hambre_max: 100,
        initial_dano_ataque_base: 10,
        initial_velocidad_movimiento: 6.0,
        initial_inventario_capacidad_slots: 25,
        initial_inventario_capacidad_peso_kg: 50.0,
        initial_loot_table_id: null
    });
    const [bastions, setBastions] = useState([]);
    const [usuarios, setUsuarios] = useState([]);
    const [clanes, setClanes] = useState([]);
    const [criaturaVivaBases, setCriaturaVivaBases] = useState([]);
    const [message, setMessage] = useState('');
    const [error, setError] = useState('');
    const [editingBastionId, setEditingBastionId] = useState(null);

    useEffect(() => {
        fetchBastions();
        fetchDropdownData();
    }, []);

    const fetchBastions = async () => {
        try {
            const data = await getBastions();
            setBastions(data);
        } catch (err) {
            setError('Error al cargar Bastiones: ' + (err.response?.data?.message || err.message));
        }
    };

    const fetchDropdownData = async () => {
        try {
            const users = await getUsuarios();
            setUsuarios(users);
            const clans = await getClanes();
            setClanes(clans);
            const cvbs = await getCriaturaVivaBases();
            setCriaturaVivaBases(cvbs);
        } catch (err) {
            console.error("Error fetching dropdown data:", err);
            setError('Error al cargar datos de dropdowns: ' + (err.response?.data?.message || err.message));
        }
    };

    const handleChange = (e) => {
        const { name, value, type } = e.target;
        setFormData(prev => ({
            ...prev,
            [name]: type === 'number' ? parseFloat(value) : value
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
                nivel: parseInt(formData.nivel),
                experiencia: parseInt(formData.experiencia),
                id_usuario: formData.id_usuario ? parseInt(formData.id_usuario) : null,
                id_clan: formData.id_clan ? parseInt(formData.id_clan) : null,
                habilidades_aprendidas: JSON.parse(formData.habilidades_aprendidas),
                id_criatura_viva_base: formData.id_criatura_viva_base ? parseInt(formData.id_criatura_viva_base) : null,
                // Para la creación, necesitamos una posición inicial si no se especifica.
                // Para la actualización, no se envía desde el panel.
                posicion_actual: editingBastionId ? undefined : { x: 0, y: 0, z: 0, mundo_id: 1 } // Default para creación si no se edita
            };

            let result;
            if (editingBastionId) {
                // Eliminar campos que no deben ser actualizables por el panel en un PUT
                delete dataToSend.posicion_actual; 
                delete dataToSend.id_usuario; // No se cambia el usuario de un Bastion existente
                delete dataToSend.id_criatura_viva_base; // No se cambia la CVB de un Bastion existente

                // Eliminar los campos initial_X para el PUT
                for (const key in dataToSend) {
                    if (key.startsWith('initial_')) {
                        delete dataToSend[key];
                    }
                }

                result = await updateBastion(editingBastionId, dataToSend);
                setMessage('Bastion actualizado con éxito!');
            } else {
                // Si no se selecciona una CVB existente, los campos initial_X son relevantes para la creación
                if (!dataToSend.id_criatura_viva_base) {
                    dataToSend.initial_salud_max = parseInt(formData.initial_salud_max);
                    dataToSend.initial_hambre_max = parseInt(formData.initial_hambre_max);
                    dataToSend.initial_dano_ataque_base = parseInt(formData.initial_dano_ataque_base);
                    dataToSend.initial_velocidad_movimiento = parseFloat(formData.initial_velocidad_movimiento);
                    dataToSend.initial_inventario_capacidad_slots = parseInt(formData.initial_inventario_capacidad_slots);
                    dataToSend.initial_inventario_capacidad_peso_kg = parseFloat(formData.initial_inventario_capacidad_peso_kg);
                    dataToSend.initial_loot_table_id = formData.initial_loot_table_id ? parseInt(formData.initial_loot_table_id) : null;
                } else {
                     // Si se usó una CVB existente, asegurar que los campos initial_X no se envíen
                     for (const key in dataToSend) {
                        if (key.startsWith('initial_')) {
                            delete dataToSend[key];
                        }
                    }
                }
                
                result = await createBastion(dataToSend);
                setMessage('Bastion creado con éxito!');
            }
            
            setFormData({ // Reset form
                nombre_personaje: '', nivel: 1, experiencia: 0, id_usuario: '', id_clan: '',
                habilidades_aprendidas: '[]', id_criatura_viva_base: '',
                initial_salud_max: 100, initial_hambre_max: 100, initial_dano_ataque_base: 10,
                initial_velocidad_movimiento: 6.0, initial_inventario_capacidad_slots: 25,
                initial_inventario_capacidad_peso_kg: 50.0, initial_loot_table_id: null
            });
            setEditingBastionId(null);
            fetchBastions(); // Refresh list
        } catch (err) {
            setError('Error al guardar Bastion: ' + (err.response?.data?.message || err.message));
        }
    };

    const handleEditClick = (bastion) => {
        setFormData({
            nombre_personaje: bastion.nombre_personaje,
            nivel: bastion.nivel,
            experiencia: bastion.experiencia,
            id_usuario: bastion.id_usuario || '', // El ID de usuario no se puede cambiar en la edición, pero se muestra
            id_clan: bastion.id_clan || '',
            habilidades_aprendidas: JSON.stringify(bastion.habilidades_aprendidas, null, 2),
            id_criatura_viva_base: bastion.id_criatura_viva_base || '',
            // Los campos initial_X no se usan para la edición de un Bastion existente
            initial_salud_max: 100, initial_hambre_max: 100, initial_dano_ataque_base: 10,
            initial_velocidad_movimiento: 6.0, initial_inventario_capacidad_slots: 25,
            initial_inventario_capacidad_peso_kg: 50.0, initial_loot_table_id: null
        });
        setEditingBastionId(bastion.id);
        setMessage('');
        setError('');
    };

    const handleCancelEdit = () => {
        setFormData({
            nombre_personaje: '', nivel: 1, experiencia: 0, id_usuario: '', id_clan: '',
            habilidades_aprendidas: '[]', id_criatura_viva_base: '',
            initial_salud_max: 100, initial_hambre_max: 100, initial_dano_ataque_base: 10,
            initial_velocidad_movimiento: 6.0, initial_inventario_capacidad_slots: 25,
            initial_inventario_capacidad_peso_kg: 50.0, initial_loot_table_id: null
        });
        setEditingBastionId(null);
        setMessage('');
        setError('');
    };

    const isCreatingNewBastion = !editingBastionId;

    return (
        <div style={{ padding: '20px', maxWidth: '1200px', margin: 'auto' }}>
            <h1>Administración de Bastiones</h1>
            
            {message && <p style={{ color: 'green' }}>{message}</p>}
            {error && <p style={{ color: 'red' }}>{error}</p>}

            <form onSubmit={handleSubmit} style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '20px', border: '1px solid #ccc', padding: '20px', borderRadius: '8px' }}>
                <fieldset style={{ gridColumn: 'span 2', padding: '15px', borderRadius: '8px', border: '1px solid #ddd' }}>
                    <legend>{isCreatingNewBastion ? 'Crear Nuevo Bastion' : `Editar Bastion (ID: ${editingBastionId})`}</legend>
                    <div style={{ display: 'grid', gap: '10px' }}>
                        <label>
                            Nombre del Personaje:
                            <input type="text" name="nombre_personaje" value={formData.nombre_personaje} onChange={handleChange} required style={{ width: '100%', padding: '8px' }} />
                        </label>
                        <label>
                            Nivel:
                            <input type="number" name="nivel" value={formData.nivel} onChange={handleChange} required style={{ width: '100%', padding: '8px' }} />
                        </label>
                        <label>
                            Experiencia:
                            <input type="number" name="experiencia" value={formData.experiencia} onChange={handleChange} required style={{ width: '100%', padding: '8px' }} />
                        </label>
                        <label>
                            Habilidades Aprendidas (JSON Array de IDs):
                            <textarea name="habilidades_aprendidas" value={formData.habilidades_aprendidas} onChange={handleJsonChange} style={{ width: '100%', height: '80px', padding: '8px', fontFamily: 'monospace' }}></textarea>
                        </label>
                        {isCreatingNewBastion && (
                            <>
                                <label>
                                    Usuario Asociado:
                                    <select name="id_usuario" value={formData.id_usuario} onChange={handleChange} required={isCreatingNewBastion} style={{ width: '100%', padding: '8px' }}>
                                        <option value="">Seleccionar Usuario (Requerido)</option>
                                        {usuarios.map(user => (
                                            <option key={user.id} value={user.id}>{user.username} (ID: {user.id})</option>
                                        ))}
                                    </select>
                                </label>
                                <label>
                                    Clan Asociado (Opcional):
                                    <select name="id_clan" value={formData.id_clan} onChange={handleChange} style={{ width: '100%', padding: '8px' }}>
                                        <option value="">Ninguno</option>
                                        {clanes.map(clan => (
                                            <option key={clan.id} value={clan.id}>{clan.nombre} (ID: {clan.id})</option>
                                        ))}
                                    </select>
                                </label>
                                <label>
                                    CriaturaViva_Base Existente (Opcional):
                                    <select name="id_criatura_viva_base" value={formData.id_criatura_viva_base} onChange={handleChange} style={{ width: '100%', padding: '8px' }}>
                                        <option value="">Crear Nueva (Recomendado)</option>
                                        {criaturaVivaBases.map(cvb => (
                                            <option key={cvb.id} value={cvb.id}>
                                                CVB ID: {cvb.id} (Salud: {cvb.danio?.salud_actual || 'N/A'}/{cvb.danio?.salud_max || 'N/A'} | Hambre: {cvb.hambre_actual || 'N/A'}/{cvb.hambre_max || 'N/A'})
                                            </option>
                                        ))}
                                    </select>
                                </label>
                                {!formData.id_criatura_viva_base && ( // Muestra estos campos si se va a crear una nueva CriaturaViva_Base
                                    <div style={{ borderTop: '1px dashed #ccc', paddingTop: '10px', marginTop: '10px', gridColumn: 'span 2' }}>
                                        <h4>Valores Iniciales para Nueva CriaturaViva_Base:</h4>
                                        <label>Salud Máx: <input type="number" name="initial_salud_max" value={formData.initial_salud_max} onChange={handleChange} required /></label>
                                        <label>Hambre Máx: <input type="number" name="initial_hambre_max" value={formData.initial_hambre_max} onChange={handleChange} required /></label>
                                        <label>Daño Ataque Base: <input type="number" name="initial_dano_ataque_base" value={formData.initial_dano_ataque_base} onChange={handleChange} required /></label>
                                        <label>Velocidad Movimiento: <input type="number" name="initial_velocidad_movimiento" value={formData.initial_velocidad_movimiento} onChange={handleChange} required step="0.1" /></label>
                                        <label>Slots Inventario: <input type="number" name="initial_inventario_capacidad_slots" value={formData.initial_inventario_capacidad_slots} onChange={handleChange} required /></label>
                                        <label>Peso Inventario (kg): <input type="number" name="initial_inventario_capacidad_peso_kg" value={formData.initial_inventario_capacidad_peso_kg} onChange={handleChange} required step="0.1" /></label>
                                        <label>ID Loot Table (Opcional): <input type="number" name="initial_loot_table_id" value={formData.initial_loot_table_id === null ? '' : formData.initial_loot_table_id} onChange={handleChange} /></label>
                                    </div>
                                )}
                            </>
                        )}
                        {!isCreatingNewBastion && (
                             <label style={{ gridColumn: 'span 2', fontStyle: 'italic', color: '#666' }}>
                                 Nota: La posición, salud y hambre se actualizan automáticamente desde el juego.
                             </label>
                        )}
                    </div>
                </fieldset>

                <div style={{ gridColumn: 'span 2', display: 'flex', justifyContent: 'flex-end', gap: '10px' }}>
                    <button type="submit" style={{ padding: '10px 15px', backgroundColor: '#007bff', color: 'white', border: 'none', borderRadius: '5px', cursor: 'pointer' }}>
                        {isCreatingNewBastion ? 'Crear Bastion' : 'Actualizar Bastion'}
                    </button>
                    {editingBastionId && (
                        <button type="button" onClick={handleCancelEdit} style={{ padding: '10px 15px', backgroundColor: '#6c757d', color: 'white', border: 'none', borderRadius: '5px', cursor: 'pointer' }}>
                            Cancelar Edición
                        </button>
                    )}
                </div>
            </form>

            <h2 style={{ marginTop: '30px' }}>Bastiones Existentes:</h2>
            <ul style={{ listStyle: 'none', padding: 0 }}>
                {bastions.map(bastion => (
                    <li key={bastion.id} style={{ border: '1px solid #eee', padding: '10px', marginBottom: '10px', borderRadius: '5px' }}>
                        <strong>{bastion.nombre_personaje}</strong> (ID: {bastion.id}) - Nivel: {bastion.nivel}<br />
                        Experiencia: {bastion.experiencia}<br />
                        Usuario: {bastion.usuario ? `${bastion.usuario.username} (ID: ${bastion.usuario.id})` : 'N/A'}<br />
                        Clan: {bastion.clan ? `${bastion.clan.nombre} (ID: ${bastion.clan.id})` : 'N/A'}<br />
                        CriaturaViva_Base ID: {bastion.id_criatura_viva_base}<br />
                        <details>
                            <summary>Posición Actual</summary>
                            <pre style={{ backgroundColor: '#f0f0f0', padding: '5px', borderRadius: '3px', whiteSpace: 'pre-wrap', wordBreak: 'break-all' }}>
                                {JSON.stringify(bastion.posicion_actual, null, 2) || 'N/A'}
                            </pre>
                        </details>
                        <details>
                            <summary>Stats de CriaturaViva_Base</summary>
                            <pre style={{ backgroundColor: '#f0f0f0', padding: '5px', borderRadius: '3px', whiteSpace: 'pre-wrap', wordBreak: 'break-all' }}>
                                {bastion.criatura_viva_base && bastion.criatura_viva_base.danio && bastion.criatura_viva_base.inventario ? JSON.stringify({
                                    salud_actual: bastion.criatura_viva_base.danio.salud_actual,
                                    salud_max: bastion.criatura_viva_base.danio.salud_max,
                                    hambre_actual: bastion.criatura_viva_base.hambre_actual,
                                    hambre_max: bastion.criatura_viva_base.hambre_max,
                                    dano_ataque_base: bastion.criatura_viva_base.dano_ataque_base,
                                    velocidad_movimiento: bastion.criatura_viva_base.velocidad_movimiento,
                                    inventario_slots: bastion.criatura_viva_base.inventario.capacidad_slots,
                                    inventario_peso: bastion.criatura_viva_base.inventario.capacidad_peso_kg,
                                }, null, 2) : 'Datos de CriaturaViva_Base no disponibles'}
                            </pre>
                        </details>
                        <button onClick={() => handleEditClick(bastion)} style={{ marginTop: '5px', padding: '5px 10px', backgroundColor: '#17a2b8', color: 'white', border: 'none', borderRadius: '3px', cursor: 'pointer' }}>Editar Configuración</button>
                    </li>
                ))}
            </ul>
        </div>
    );
};

export default BastionAdminPage;