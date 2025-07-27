// el-ultimo-bastion/frontend/src/components/WorldNPCsEditor.jsx
import React, { useState, useEffect } from 'react';
import { createInstanciaNPC, getInstanciasNPCByMundo, getTiposNPC } from '../api/adminApi'; // Asegúrate de que estas sean las reales

const WorldNPCsEditor = ({ worldId }) => {
    const [formData, setFormData] = useState({
        id_tipo_npc: '',
        posicion: '{"x": 0, "y": 5, "z": 0}',
    });

    const [instanciaNPCs, setInstanciaNPCs] = useState([]);
    const [tiposNPC, setTiposNPC] = useState([]);
    const [message, setMessage] = useState('');
    const [error, setError] = useState('');

    useEffect(() => {
        const fetchData = async () => {
            try {
                // Cargar los TiposNPC (plantillas) desde el backend
                const tipos = await getTiposNPC(); // <-- Llamada REAL
                setTiposNPC(tipos);

                // Cargar las InstanciasNPC para este mundo desde el backend
                const instancias = await getInstanciasNPCByMundo(worldId); // <-- Llamada REAL
                setInstanciaNPCs(instancias);
            } catch (err) {
                setError('Error al cargar datos: ' + (err.response?.data?.message || err.message));
                console.error("Error en WorldNPCsEditor fetchData:", err);
            }
        };
        fetchData();
    }, [worldId]);

    const handleChange = (e) => {
        const { name, value } = e.target;
        setFormData(prev => ({ ...prev, [name]: value }));
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        setMessage('');
        setError('');
        if (!formData.id_tipo_npc) {
            setError('Por favor, selecciona un tipo de NPC (una plantilla).');
            return;
        }
        try {
            const dataToSend = {
                id_mundo: worldId,
                id_tipo_npc: parseInt(formData.id_tipo_npc),
                posicion: JSON.parse(formData.posicion),
            };
            await createInstanciaNPC(dataToSend); // <-- Llamada REAL
            setMessage('¡NPC añadido al mundo con éxito!');
            // Refrescar la lista después de añadir
            const instancias = await getInstanciasNPCByMundo(worldId); // <-- Llamada REAL
            setInstanciaNPCs(instancias);
            // Opcional: limpiar el formulario si quieres crear múltiples rápidamente
            setFormData(prev => ({ ...prev, id_tipo_npc: '', posicion: '{"x": 0, "y": 5, "z": 0}' }));
        } catch (err) {
            setError('Error al crear la instancia de NPC: ' + (err.response?.data?.message || err.message));
            console.error("Error al crear InstanciaNPC:", err);
        }
    };

    // Función auxiliar para encontrar el nombre de TipoNPC
    const getTipoNpcName = (tipoNpcId) => {
        const tipo = tiposNPC.find(t => t.id === tipoNpcId);
        return tipo ? tipo.nombre : 'Desconocido';
    };

    return (
        <div>
            <h3>Añadir NPC a este Mundo</h3>
            
            {message && <p style={{ color: 'green' }}>{message}</p>}
            {error && <p style={{ color: 'red' }}>{error}</p>}

            <form onSubmit={handleSubmit} style={{ border: '1px solid #ccc', padding: '20px', borderRadius: '8px', marginBottom: '30px' }}>
                <div style={{ marginBottom: '15px' }}>
                    <label>
                        <strong>Paso 1: Selecciona la plantilla (el "molde") a utilizar:</strong>
                        <select name="id_tipo_npc" value={formData.id_tipo_npc} onChange={handleChange} style={{ width: '100%', padding: '8px', marginTop: '5px' }}>
                            <option value="">-- Elige un arquetipo de NPC --</option>
                            {tiposNPC.map(tipo => (
                                <option key={tipo.id} value={tipo.id}>{tipo.nombre} (ID: {tipo.id})</option>
                            ))}
                        </select>
                    </label>
                </div>
                <div style={{ marginBottom: '15px' }}>
                    <label>
                        <strong>Paso 2: Define la posición en el mundo (JSON):</strong>
                        <textarea name="posicion" value={formData.posicion} onChange={handleChange} style={{ width: '100%', padding: '8px', fontFamily: 'monospace', minHeight: '60px', marginTop: '5px' }}></textarea>
                    </label>
                </div>
                <button type="submit" style={{ padding: '10px 15px', backgroundColor: '#28a745', color: 'white', border: 'none', borderRadius: '5px', cursor: 'pointer' }}>
                    Añadir NPC al Mundo
                </button>
            </form>

            <h3>NPCs existentes en este Mundo:</h3>
            <p style={{ marginBottom: '15px', color: '#666' }}>Aquí verás todas las instancias de NPC presentes en el mundo actual.</p>
            <ul>
                {instanciaNPCs.length === 0 ? (
                    <li>No hay instancias de NPC en este mundo. ¡Crea una arriba!</li>
                ) : (
                    instanciaNPCs.map(instancia => (
                        <li key={instancia.id} style={{ border: '1px solid #eee', padding: '10px', marginBottom: '10px', borderRadius: '5px' }}>
                            <strong>Instancia ID: {instancia.id}</strong><br/>
                            Tipo de NPC: **{instancia.tipo_npc?.nombre || getTipoNpcName(instancia.id_tipo_npc)}** (ID Arquetipo: {instancia.id_tipo_npc})<br />
                            Posición: <code>{JSON.stringify(instancia.posicion)}</code><br />
                            Vivo: {instancia.esta_vivo ? 'Sí' : 'No'}<br />
                            <small>
                                ID Gráfico: {instancia.tipo_npc?.id_grafico || 'N/A'} | Radio: {instancia.tipo_npc?.valores_rol?.hitbox_dimensions?.radius || 'N/A'} | Altura: {instancia.tipo_npc?.valores_rol?.hitbox_dimensions?.height || 'N/A'} | Color: {instancia.tipo_npc?.valores_rol?.color || 'N/A'}
                            </small>
                            {/* Opcional: Botones para editar o eliminar esta instancia */}
                        </li>
                    ))
                )}
            </ul>
        </div>
    );
};

export default WorldNPCsEditor;