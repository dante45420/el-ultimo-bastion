// el-ultimo-bastion/frontend/src/pages/TipoObjetoAdminPage.jsx
import React, { useState, useEffect } from 'react';
import { createTipoObjeto, getTiposObjeto } from '../api/adminApi';

const TipoObjetoAdminPage = () => {
    const [formData, setFormData] = useState({
        nombre: '',
        descripcion: '',
        id_grafico: '',
        tipo_objeto: 'RECURSO', // Valor por defecto
        es_apilable: false,
        peso_unidad: 0.1,
        valores_especificos: '{}' // JSON string
    });
    const [objectTypes, setObjectTypes] = useState([]);
    const [message, setMessage] = useState('');
    const [error, setError] = useState('');

    // Tipos de objeto válidos (para el select/dropdown)
    const validObjectTypes = [
        "RECURSO", "ARMA", "EQUIPO", "POCION", "COMIDA",
        "CONSTRUCCION", "MONTURA", "TESORO", "MISION", "HERRAMIENTA"
    ];

    useEffect(() => {
        fetchObjectTypes();
    }, []);

    const fetchObjectTypes = async () => {
        try {
            const data = await getTiposObjeto();
            setObjectTypes(data);
        } catch (err) {
            setError('Error al cargar tipos de objeto: ' + (err.response?.data?.message || err.message));
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
                ...formData,
                valores_especificos: JSON.parse(formData.valores_especificos)
            };
            await createTipoObjeto(dataToSend);
            setMessage('Tipo de Objeto creado con éxito!');
            setFormData({ // Reset form
                nombre: '', descripcion: '', id_grafico: '',
                tipo_objeto: 'RECURSO', es_apilable: false, peso_unidad: 0.1,
                valores_especificos: '{}'
            });
            fetchObjectTypes(); // Refresh list
        } catch (err) {
            setError('Error al crear Tipo de Objeto: ' + (err.response?.data?.message || err.message));
        }
    };

    return (
        <div style={{ padding: '20px', maxWidth: '800px', margin: 'auto' }}>
            <h1>Administración de Tipos de Objeto</h1>

            {message && <p style={{ color: 'green' }}>{message}</p>}
            {error && <p style={{ color: 'red' }}>{error}</p>}

            <form onSubmit={handleSubmit} style={{ display: 'grid', gap: '10px', border: '1px solid #ccc', padding: '20px', borderRadius: '8px' }}>
                <label>
                    Nombre:
                    <input type="text" name="nombre" value={formData.nombre} onChange={handleChange} required style={{ width: '100%', padding: '8px' }} />
                </label>
                <label>
                    Descripción:
                    <textarea name="descripcion" value={formData.descripcion} onChange={handleChange} style={{ width: '100%', padding: '8px', minHeight: '60px' }}></textarea>
                </label>
                <label>
                    ID Gráfico (ej. "sword_icon_01"):
                    <input type="text" name="id_grafico" value={formData.id_grafico} onChange={handleChange} style={{ width: '100%', padding: '8px' }} />
                </label>
                <label>
                    Tipo de Objeto:
                    <select name="tipo_objeto" value={formData.tipo_objeto} onChange={handleChange} style={{ width: '100%', padding: '8px' }}>
                        {validObjectTypes.map(type => (
                            <option key={type} value={type}>{type}</option>
                        ))}
                    </select>
                </label>
                <label>
                    Es Apilable:
                    <input type="checkbox" name="es_apilable" checked={formData.es_apilable} onChange={handleChange} />
                </label>
                <label>
                    Peso por Unidad (kg):
                    <input type="number" step="0.01" name="peso_unidad" value={formData.peso_unidad} onChange={handleChange} style={{ width: '100%', padding: '8px' }} />
                </label>
                <label>
                    Valores Específicos (JSON - ej: "dano_min":10, "tipo_dano":"CORTANTE"):
                    <textarea name="valores_especificos" value={formData.valores_especificos} onChange={handleChange} style={{ width: '100%', padding: '8px', minHeight: '80px', fontFamily: 'monospace' }}></textarea>
                </label>
                <button type="submit" style={{ padding: '10px 15px', backgroundColor: '#007bff', color: 'white', border: 'none', borderRadius: '5px', cursor: 'pointer' }}>
                    Crear Tipo de Objeto
                </button>
            </form>

            <h2 style={{ marginTop: '30px' }}>Tipos de Objeto Existentes:</h2>
            <ul style={{ listStyle: 'none', padding: 0 }}>
                {objectTypes.map(obj => (
                    <li key={obj.id} style={{ border: '1px solid #eee', padding: '10px', marginBottom: '10px', borderRadius: '5px' }}>
                        <strong>{obj.nombre}</strong> (ID: {obj.id}) - Tipo: {obj.tipo_objeto} - Peso: {obj.peso_unidad}kg {obj.es_apilable ? '(Apilable)' : ''}<br />
                        <small>{obj.descripcion}</small><br />
                        <pre style={{ backgroundColor: '#f0f0f0', padding: '5px', borderRadius: '3px', whiteSpace: 'pre-wrap', wordBreak: 'break-all' }}>
                            {JSON.stringify(obj.valores_especificos, null, 2)}
                        </pre>
                    </li>
                ))}
            </ul>
        </div>
    );
};

export default TipoObjetoAdminPage;