// el-ultimo-bastion/frontend/src/pages/WorldContentEditorPage.jsx
import React, { useState, useEffect } from 'react';
import { getMundo } from '../api/adminApi';
import WorldNPCsEditor from '../components/WorldNPCsEditor';

const WorldContentEditorPage = ({ worldId, onBack }) => {
    const [mundo, setMundo] = useState(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState('');
    const [currentTab, setCurrentTab] = useState('npcs');

    useEffect(() => {
        const fetchMundoDetails = async () => {
            try {
                setLoading(true);
                const data = await getMundo(worldId);
                setMundo(data);
                setError('');
            } catch (err) {
                setError('Error al cargar detalles del Mundo: ' + (err.response?.data?.message || err.message));
                setMundo(null);
            } finally {
                setLoading(false);
            }
        };
        fetchMundoDetails();
    }, [worldId]);

    if (loading) return <p>Cargando Mundo...</p>;
    if (error) return <p style={{ color: 'red' }}>{error}</p>;
    if (!mundo) return <p>No se pudo cargar el Mundo.</p>;

    return (
        <div style={{ padding: '20px', maxWidth: '1200px', margin: 'auto' }}>
            <button onClick={onBack} style={{ marginBottom: '20px', padding: '8px 15px', backgroundColor: '#6c757d', color: 'white', border: 'none', borderRadius: '5px', cursor: 'pointer' }}>
                &lt; Volver a Mundos
            </button>
            <h1>Editor de Contenido para "{mundo.nombre_mundo}" (ID: {mundo.id})</h1>
            <p>Tipo: {mundo.tipo_mundo} | Semilla: {mundo.semilla_generacion}</p>

            <div style={{ display: 'flex', borderBottom: '1px solid #ccc', marginBottom: '20px' }}>
                <button 
                    onClick={() => setCurrentTab('npcs')} 
                    style={{ padding: '10px 15px', border: 'none', background: currentTab === 'npcs' ? '#eee' : 'transparent', cursor: 'pointer' }}
                >
                    NPCs
                </button>
                <button 
                    onClick={() => setCurrentTab('animals')} 
                    style={{ padding: '10px 15px', border: 'none', background: currentTab === 'animals' ? '#eee' : 'transparent', cursor: 'pointer' }}
                >
                    Animales (Próximamente)
                </button>
            </div>

            {currentTab === 'npcs' && <WorldNPCsEditor worldId={worldId} />}
            {currentTab === 'animals' && <p>Editor de Animales en construcción...</p>}
        </div>
    );
};

export default WorldContentEditorPage;