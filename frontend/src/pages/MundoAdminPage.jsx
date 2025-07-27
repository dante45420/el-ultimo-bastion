// el-ultimo-bastion/frontend/src/pages/MundoAdminPage.jsx
import React, { useState, useEffect } from 'react';
import { createMundo, getMundos, updateMundo, getUsuarios, getClanes } from '../api/adminApi';

const MundoAdminPage = ({ onEditWorldContent }) => {
    const [formData, setFormData] = useState({
        nombre_mundo: '',
        tipo_mundo: 'CLAN',
        id_propietario_clan: '',
        id_propietario_usuario: '',
        semilla_generacion: '',
        estado_actual_terreno: '{}',
        configuracion_actual: '{}'
    });
    const [mundos, setMundos] = useState([]);
    const [usuarios, setUsuarios] = useState([]);
    const [clanes, setClanes] = useState([]);
    const [message, setMessage] = useState('');
    const [error, setError] = useState('');
    const [editingMundoId, setEditingMundoId] = useState(null);

    useEffect(() => {
        fetchMundos();
        fetchUsuariosAndClanes();
    }, []);

    const fetchMundos = async () => {
        try {
            const data = await getMundos();
            setMundos(data);
        } catch (err) {
            setError('Error al cargar mundos: ' + (err.response?.data?.message || err.message));
        }
    };

    const fetchUsuariosAndClanes = async () => {
        try {
            const users = await getUsuarios();
            setUsuarios(users);
            const clans = await getClanes();
            setClanes(clans);
        } catch (err) {
            console.error("Error fetching users/clans for dropdowns:", err);
            setError('Error al cargar datos de usuarios/clanes para dropdowns: ' + (err.response?.data?.message || err.message));
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

    const handleTipoMundoChange = (e) => {
        const newTipoMundo = e.target.value;
        setFormData(prev => ({
            ...prev,
            tipo_mundo: newTipoMundo,
            id_propietario_clan: '',
            id_propietario_usuario: ''
        }));
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        setMessage('');
        setError('');
        try {
            const dataToSend = {
                ...formData,
                estado_actual_terreno: JSON.parse(formData.estado_actual_terreno),
                configuracion_actual: JSON.parse(formData.configuracion_actual),
                // Asegurarse de que los IDs sean null si están vacíos
                id_propietario_clan: formData.id_propietario_clan ? parseInt(formData.id_propietario_clan) : null,
                id_propietario_usuario: formData.id_propietario_usuario ? parseInt(formData.id_propietario_usuario) : null
            };

            let result;
            if (editingMundoId) {
                result = await updateMundo(editingMundoId, dataToSend);
                setMessage('Mundo actualizado con éxito!');
            } else {
                result = await createMundo(dataToSend);
                setMessage('Mundo creado con éxito!');
            }
            
            setFormData({
                nombre_mundo: '', tipo_mundo: 'CLAN', id_propietario_clan: '',
                id_propietario_usuario: '', semilla_generacion: '',
                estado_actual_terreno: '{}', configuracion_actual: '{}'
            });
            setEditingMundoId(null);
            fetchMundos();
        } catch (err) {
            setError('Error al guardar Mundo: ' + (err.response?.data?.message || err.message));
        }
    };

    const handleEditClick = (mundo) => {
        setFormData({
            nombre_mundo: mundo.nombre_mundo,
            tipo_mundo: mundo.tipo_mundo,
            id_propietario_clan: mundo.id_propietario_clan || '',
            id_propietario_usuario: mundo.id_propietario_usuario || '',
            semilla_generacion: mundo.semilla_generacion || '',
            estado_actual_terreno: JSON.stringify(mundo.estado_actual_terreno, null, 2),
            configuracion_actual: JSON.stringify(mundo.configuracion_actual, null, 2)
        });
        setEditingMundoId(mundo.id);
        setMessage('');
        setError('');
    };

    const handleCancelEdit = () => {
        setFormData({
            nombre_mundo: '', tipo_mundo: 'CLAN', id_propietario_clan: '',
            id_propietario_usuario: '', semilla_generacion: '',
            estado_actual_terreno: '{}', configuracion_actual: '{}'
        });
        setEditingMundoId(null);
        setMessage('');
        setError('');
    };

    return (
        <div style={{ padding: '20px', maxWidth: '1000px', margin: 'auto' }}>
            <h1>Administración de Mundos</h1>
            
            {message && <p style={{ color: 'green' }}>{message}</p>}
            {error && <p style={{ color: 'red' }}>{error}</p>}

            {/* Sección de Listado de Mundos Existentes - Más Prominente */}
            <h2 style={{ marginTop: '30px', marginBottom: '15px' }}>Mundos Existentes:</h2>
            <p style={{ marginBottom: '20px', color: '#666' }}>Selecciona un mundo para ver o editar su contenido (NPCs, Animales, Recursos).</p>
            <ul style={{ listStyle: 'none', padding: 0 }}>
                {mundos.map(mundo => (
                    <li key={mundo.id} style={{ border: '1px solid #eee', padding: '10px', marginBottom: '10px', borderRadius: '5px', display: 'flex', flexDirection: 'column', gap: '5px' }}>
                        <div>
                            <strong>{mundo.nombre_mundo}</strong> (ID: {mundo.id}) - Tipo: {mundo.tipo_mundo}<br />
                            {mundo.tipo_mundo === 'CLAN' && <span>Propietario Clan ID: {mundo.id_propietario_clan}</span>}
                            {mundo.tipo_mundo === 'PERSONAL' && <span>Propietario Usuario ID: {mundo.id_propietario_usuario}</span>}<br />
                            Semilla: <code>{mundo.semilla_generacion || 'N/A'}</code>
                        </div>
                        <div style={{ display: 'flex', gap: '10px', marginTop: '10px' }}>
                            <button onClick={() => handleEditClick(mundo)} style={{ padding: '5px 10px', backgroundColor: '#17a2b8', color: 'white', border: 'none', borderRadius: '3px', cursor: 'pointer' }}>Editar Configuración</button>
                            <button onClick={() => onEditWorldContent(mundo.id)} style={{ padding: '5px 10px', backgroundColor: '#28a745', color: 'white', border: 'none', borderRadius: '3px', cursor: 'pointer' }}>Editar Contenido de Mundo</button>
                        </div>
                    </li>
                ))}
            </ul>

            {/* Sección de Crear/Editar Mundo - Colapsable o menos prominente */}
            <h2 style={{ marginTop: '40px', marginBottom: '15px', borderTop: '1px solid #eee', paddingTop: '30px' }}>
                {editingMundoId ? `Editar Configuración de Mundo (ID: ${editingMundoId})` : 'Crear Nuevo Mundo (Manual)'}
            </h2>
            <p style={{ marginBottom: '20px', color: '#666' }}>Esta opción es para la creación manual de mundos. Los mundos de jugadores y clanes se crearán automáticamente en el futuro.</p>
            <form onSubmit={handleSubmit} style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '20px', border: '1px solid #ccc', padding: '20px', borderRadius: '8px' }}>
                <fieldset style={{ gridColumn: 'span 2', padding: '15px', borderRadius: '8px', border: '1px solid #ddd' }}>
                    <legend>Detalles Básicos</legend>
                    <div style={{ display: 'grid', gap: '10px' }}>
                        <label>
                            Nombre del Mundo:
                            <input type="text" name="nombre_mundo" value={formData.nombre_mundo} onChange={handleChange} required style={{ width: '100%', padding: '8px' }} />
                        </label>
                        <label>
                            Tipo de Mundo:
                            <select name="tipo_mundo" value={formData.tipo_mundo} onChange={handleTipoMundoChange} style={{ width: '100%', padding: '8px' }}>
                                <option value="CLAN">CLAN</option>
                                <option value="PERSONAL">PERSONAL</option>
                            </select>
                        </label>
                        {formData.tipo_mundo === 'CLAN' && (
                            <label>
                                ID Clan Propietario:
                                <select name="id_propietario_clan" value={formData.id_propietario_clan} onChange={handleChange} style={{ width: '100%', padding: '8px' }}>
                                    <option value="">Seleccionar Clan (Requerido)</option>
                                    {clanes.map(clan => (
                                        <option key={clan.id} value={clan.id}>{clan.nombre} (ID: {clan.id})</option>
                                    ))}
                                </select>
                            </label>
                        )}
                        {formData.tipo_mundo === 'PERSONAL' && (
                            <label>
                                ID Usuario Propietario:
                                <select name="id_propietario_usuario" value={formData.id_propietario_usuario} onChange={handleChange} style={{ width: '100%', padding: '8px' }}>
                                    <option value="">Seleccionar Usuario (Requerido)</option>
                                    {usuarios.map(user => (
                                        <option key={user.id} value={user.id}>{user.username} (ID: {user.id})</option>
                                    ))}
                                </select>
                            </label>
                        )}
                        <label>
                            Semilla de Generación:
                            <input type="text" name="semilla_generacion" value={formData.semilla_generacion} onChange={handleChange} style={{ width: '100%', padding: '8px' }} />
                        </label>
                    </div>
                </fieldset>

                <fieldset style={{ padding: '15px', borderRadius: '8px', border: '1px solid #ddd' }}>
                    <legend>Estado Actual del Terreno (JSON)</legend>
                    <textarea name="estado_actual_terreno" value={formData.estado_actual_terreno} onChange={handleJsonChange} style={{ width: '100%', height: '150px', padding: '8px', fontFamily: 'monospace' }}></textarea>
                </fieldset>

                <fieldset style={{ padding: '15px', borderRadius: '8px', border: '1px solid #ddd' }}>
                    <legend>Configuración Actual (JSON)</legend>
                    <textarea name="configuracion_actual" value={formData.configuracion_actual} onChange={handleJsonChange} style={{ width: '100%', height: '150px', padding: '8px', fontFamily: 'monospace' }}></textarea>
                </fieldset>

                <div style={{ gridColumn: 'span 2', display: 'flex', justifyContent: 'flex-end', gap: '10px' }}>
                    <button type="submit" style={{ padding: '10px 15px', backgroundColor: '#007bff', color: 'white', border: 'none', borderRadius: '5px', cursor: 'pointer' }}>
                        {editingMundoId ? 'Actualizar Mundo' : 'Crear Mundo'}
                    </button>
                    {editingMundoId && (
                        <button type="button" onClick={handleCancelEdit} style={{ padding: '10px 15px', backgroundColor: '#6c757d', color: 'white', border: 'none', borderRadius: '5px', cursor: 'pointer' }}>
                            Cancelar Edición
                        </button>
                    )}
                </div>
            </form>
        </div>
    );
};

export default MundoAdminPage;