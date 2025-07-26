// el-ultimo-bastion/frontend/src/pages/InstanciaNPCAdminPage.jsx
import React, { useState, useEffect } from 'react';
import { createInstanciaNPC, getInstanciasNPCByMundo, getTiposNPC, getMundos, getCriaturaVivaBases, getUsuarios, getClanes, getInstanciasNPC, } from '../api/adminApi';

const InstanciaNPCAdminPage = () => {
    const [formData, setFormData] = useState({
        id_tipo_npc: '',
        id_criatura_viva_base: '',
        id_mundo: '',
        posicion: '{"x": 0, "y": 0, "z": 0}', // JSON string
        esta_vivo: true,
        id_aldea_pertenece: '', // Campo opcional
        id_clan_pertenece: '',  // Campo opcional
        id_persona_pertenece: '', // Campo opcional
        restriccion_area: '{}', // JSON string
        valores_dinamicos: '{}' // JSON string
    });
    const [instanciasNpc, setInstanciasNpc] = useState([]);
    const [tiposNpc, setTiposNpc] = useState([]);
    const [mundos, setMundos] = useState([]);
    const [criaturaVivaBases, setCriaturaVivaBases] = useState([]); // Para el dropdown de CriaturaViva_Base
    const [usuarios, setUsuarios] = useState([]); // Para dropdowns de dueños
    const [clanes, setClanes] = useState([]);     // Para dropdowns de clanes (InstanciaNPC puede pertenecer a)

    const [message, setMessage] = useState('');
    const [error, setError] = useState('');
    const [selectedMundoId, setSelectedMundoId] = useState(''); // Para filtrar por mundo

    useEffect(() => {
        fetchDependencies();
    }, []);

    useEffect(() => {
        if (selectedMundoId) {
            fetchInstanciasNpcBySelectedMundo();
        } else {
            fetchInstanciasNpc(); // Si no hay mundo seleccionado, mostrar todas
        }
    }, [selectedMundoId]);

    const fetchDependencies = async () => {
        try {
            const fetchedTiposNpc = await getTiposNPC();
            setTiposNpc(fetchedTiposNpc);
            const fetchedMundos = await getMundos();
            setMundos(fetchedMundos);
            const fetchedCriaturaVivaBases = await getCriaturaVivaBases();
            setCriaturaVivaBases(fetchedCriaturaVivaBases);
            const fetchedUsuarios = await getUsuarios();
            setUsuarios(fetchedUsuarios);
            const fetchedClanes = await getClanes();
            setClanes(fetchedClanes);

        } catch (err) {
            console.error("Error fetching NPC dependencies:", err);
            setError('Error al cargar dependencias (Tipos NPC, Mundos, CV Bases, Usuarios, Clanes).');
        }
    };

    const fetchInstanciasNpc = async () => {
        try {
            const data = await getInstanciasNPC();
            setInstanciasNpc(data);
        } catch (err) {
            setError('Error al cargar instancias de NPC: ' + (err.response?.data?.message || err.message));
        }
    };

    const fetchInstanciasNpcBySelectedMundo = async () => {
        try {
            const data = await getInstanciasNPCByMundo(selectedMundoId);
            setInstanciasNpc(data);
        } catch (err) {
            setError(`Error al cargar instancias de NPC para el mundo ${selectedMundoId}: ` + (err.response?.data?.message || err.message));
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
                id_tipo_npc: parseInt(formData.id_tipo_npc),
                id_criatura_viva_base: parseInt(formData.id_criatura_viva_base),
                id_mundo: parseInt(formData.id_mundo),
                posicion: JSON.parse(formData.posicion),
                restriccion_area: formData.restriccion_area ? JSON.parse(formData.restriccion_area) : {},
                valores_dinamicos: formData.valores_dinamicos ? JSON.parse(formData.valores_dinamicos) : {},
                id_aldea_pertenece: formData.id_aldea_pertenece ? parseInt(formData.id_aldea_pertenece) : null,
                id_clan_pertenece: formData.id_clan_pertenece ? parseInt(formData.id_clan_pertenece) : null,
                id_persona_pertenece: formData.id_persona_pertenece ? parseInt(formData.id_persona_pertenece) : null,
            };
            await createInstanciaNPC(dataToSend);
            setMessage('Instancia de NPC creada con éxito!');
            setFormData({ // Reset form
                id_tipo_npc: '', id_criatura_viva_base: '', id_mundo: '',
                posicion: '{"x": 0, "y": 0, "z": 0}', esta_vivo: true,
                id_aldea_pertenece: '', id_clan_pertenece: '', id_persona_pertenece: '',
                restriccion_area: '{}', valores_dinamicos: '{}'
            });
            if (selectedMundoId) {
                fetchInstanciasNpcBySelectedMundo();
            } else {
                fetchInstanciasNpc();
            }
        } catch (err) {
            setError('Error al crear Instancia de NPC: ' + (err.response?.data?.message || err.message));
        }
    };

    return (
        <div style={{ padding: '20px', maxWidth: '1000px', margin: 'auto' }}>
            <h1>Administración de Instancias de NPC</h1>
            
            {message && <p style={{ color: 'green' }}>{message}</p>}
            {error && <p style={{ color: 'red' }}>{error}</p>}

            <form onSubmit={handleSubmit} style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '20px', border: '1px solid #ccc', padding: '20px', borderRadius: '8px' }}>
                <fieldset style={{ gridColumn: 'span 2', padding: '15px', borderRadius: '8px', border: '1px solid #ddd' }}>
                    <legend>Crear Nueva Instancia de NPC</legend>
                    <div style={{ display: 'grid', gap: '10px' }}>
                        <label>
                            Tipo de NPC:
                            <select name="id_tipo_npc" value={formData.id_tipo_npc} onChange={handleChange} required style={{ width: '100%', padding: '8px' }}>
                                <option value="">Seleccionar Tipo de NPC</option>
                                {tiposNpc.map(tipo => (
                                    <option key={tipo.id} value={tipo.id}>{tipo.nombre} (ID: {tipo.id})</option>
                                ))}
                            </select>
                        </label>
                        <label>
                            Base de Criatura Viva (CVB):
                            <select name="id_criatura_viva_base" value={formData.id_criatura_viva_base} onChange={handleChange} required style={{ width: '100%', padding: '8px' }}>
                                <option value="">Seleccionar CVB (¡Importante!) - Solo IDs existentes</option>
                                {criaturaVivaBases.map(cvb => (
                                    <option key={cvb.id} value={cvb.id}>CVB ID: {cvb.id}</option>
                                ))}
                            </select>
                            <small style={{ color: 'gray' }}>Asegúrate de usar un ID de CriaturaViva_Base que ya exista en tu DB (creados al crear TipoNPCs con el seed).</small>
                        </label>
                        <label>
                            Mundo:
                            <select name="id_mundo" value={formData.id_mundo} onChange={handleChange} required style={{ width: '100%', padding: '8px' }}>
                                <option value="">Seleccionar Mundo</option>
                                {mundos.map(mundo => (
                                    <option key={mundo.id} value={mundo.id}>{mundo.nombre_mundo} (ID: {mundo.id}) - {mundo.tipo_mundo}</option>
                                ))}
                            </select>
                        </label>
                        <label>
                            Posición (JSON - ej: "x":0,"y":0,"z":0):
                            <textarea name="posicion" value={formData.posicion} onChange={handleJsonChange} required style={{ width: '100%', padding: '8px', fontFamily: 'monospace' }}></textarea>
                        </label>
                        <label>
                            Está Vivo:
                            <input type="checkbox" name="esta_vivo" checked={formData.esta_vivo} onChange={handleChange} />
                        </label>
                        <label>
                            ID Aldea a la que pertenece (Opcional):
                            <input type="number" name="id_aldea_pertenece" value={formData.id_aldea_pertenece} onChange={handleChange} style={{ width: '100%', padding: '8px' }} />
                        </label>
                        <label>
                            ID Clan al que pertenece (Opcional):
                            <input type="number" name="id_clan_pertenece" value={formData.id_clan_pertenece} onChange={handleChange} style={{ width: '100%', padding: '8px' }} />
                        </label>
                        <label>
                            ID Persona a la que pertenece (Opcional):
                            <input type="number" name="id_persona_pertenece" value={formData.id_persona_pertenece} onChange={handleChange} style={{ width: '100%', padding: '8px' }} />
                        </label>
                        <label>
                            Restricción de Área (JSON - ej: "tipo":"RECT","coords":[x1,y1,z1,x2,y2,z2]):
                            <textarea name="restriccion_area" value={formData.restriccion_area} onChange={handleJsonChange} style={{ width: '100%', padding: '8px', fontFamily: 'monospace' }}></textarea>
                        </label>
                        <label>
                            Valores Dinámicos (JSON):
                            <textarea name="valores_dinamicos" value={formData.valores_dinamicos} onChange={handleJsonChange} style={{ width: '100%', padding: '8px', fontFamily: 'monospace' }}></textarea>
                        </label>
                    </div>
                </fieldset>
                <div style={{ gridColumn: 'span 2', display: 'flex', justifyContent: 'flex-end', gap: '10px' }}>
                    <button type="submit" style={{ padding: '10px 15px', backgroundColor: '#007bff', color: 'white', border: 'none', borderRadius: '5px', cursor: 'pointer' }}>
                        Crear Instancia NPC
                    </button>
                </div>
            </form>

            <h2 style={{ marginTop: '30px' }}>Instancias de NPC Existentes:</h2>
            <label>
                Filtrar por Mundo:
                <select value={selectedMundoId} onChange={(e) => setSelectedMundoId(e.target.value)} style={{ marginLeft: '10px', padding: '5px' }}>
                    <option value="">Todos los Mundos</option>
                    {mundos.map(mundo => (
                        <option key={mundo.id} value={mundo.id}>{mundo.nombre_mundo} (ID: {mundo.id})</option>
                    ))}
                </select>
            </label>
            <ul style={{ listStyle: 'none', padding: 0, marginTop: '15px' }}>
                {instanciasNpc.length === 0 ? (
                    <li>No hay instancias de NPC para mostrar.</li>
                ) : (
                    instanciasNpc.map(npc => (
                        <li key={npc.id} style={{ border: '1px solid #eee', padding: '10px', marginBottom: '10px', borderRadius: '5px' }}>
                            <strong>Instancia ID: {npc.id}</strong> - Tipo NPC ID: {npc.id_tipo_npc} - Mundo ID: {npc.id_mundo}<br />
                            Posición: {JSON.stringify(npc.posicion)} - Vivo: {npc.esta_vivo ? 'Sí' : 'No'}<br />
                            <small>
                                Aldea: {npc.id_aldea_pertenece || 'N/A'} | Clan: {npc.id_clan_pertenece || 'N/A'} | Persona: {npc.id_persona_pertenece || 'N/A'}
                            </small><br />
                            <pre style={{ backgroundColor: '#f0f0f0', padding: '5px', borderRadius: '3px', whiteSpace: 'pre-wrap', wordBreak: 'break-all', fontSize: '0.8em' }}>
                                Valores Dinámicos: {JSON.stringify(npc.valores_dinamicos, null, 2)}
                                <br />
                                Restricción Área: {JSON.stringify(npc.restriccion_area, null, 2)}
                            </pre>
                            {/* Más botones para editar/eliminar se pueden añadir aquí */}
                        </li>
                    ))
                )}
            </ul>
        </div>
    );
};

export default InstanciaNPCAdminPage;