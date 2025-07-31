// el-ultimo-bastion/frontend/src/pages/TipoObjetoAdminPage.jsx
// VERSIÓN MEJORADA - FORMULARIO INTELIGENTE
import React, { useState, useEffect } from 'react';
import { createTipoObjeto, getTiposObjeto } from '../api/adminApi';

const TipoObjetoAdminPage = () => {
    const [formData, setFormData] = useState({
        nombre: '',
        descripcion: '',
        id_grafico: '',
        tipo_objeto: 'COMIDA', // Cambio por defecto para crear carne
        es_apilable: true,
        peso_unidad: 0.1,
        // Campos específicos por tipo
        specificFields: {}
    });
    const [objectTypes, setObjectTypes] = useState([]);
    const [message, setMessage] = useState('');
    const [error, setError] = useState('');

    // Tipos de objeto válidos con sus campos específicos
    const objectTypeConfig = {
        COMIDA: {
            label: "Comida",
            fields: [
                { name: 'valor_hambre', label: 'Restaura Hambre', type: 'number', default: 25, help: 'Cuántos puntos de hambre restaura' },
                { name: 'valor_comercio', label: 'Valor de Comercio', type: 'number', default: 5, help: 'Precio base para comerciar' },
                { name: 'tiempo_descomposicion', label: 'Tiempo Descomposición (seg)', type: 'number', default: 300, help: 'Segundos antes de echarse a perder' },
                { name: 'efecto_salud', label: 'Efecto en Salud', type: 'number', default: 0, help: 'Puntos de salud que restaura (opcional)' }
            ]
        },
        ARMA: {
            label: "Arma",
            fields: [
                { name: 'dano_min', label: 'Daño Mínimo', type: 'number', default: 5, help: 'Daño mínimo que causa' },
                { name: 'dano_max', label: 'Daño Máximo', type: 'number', default: 10, help: 'Daño máximo que causa' },
                { name: 'tipo_dano', label: 'Tipo de Daño', type: 'select', options: ['CORTANTE', 'CONTUNDENTE', 'PERFORANTE', 'FUEGO', 'HIELO'], default: 'CORTANTE' },
                { name: 'velocidad_ataque', label: 'Velocidad Ataque (seg)', type: 'number', default: 1.0, step: 0.1, help: 'Tiempo entre ataques' },
                { name: 'alcance', label: 'Alcance', type: 'number', default: 1.5, step: 0.1, help: 'Distancia de ataque' },
                { name: 'durabilidad_max', label: 'Durabilidad Máxima', type: 'number', default: 100, help: 'Usos antes de romperse' },
                { name: 'valor_comercio', label: 'Valor de Comercio', type: 'number', default: 50 }
            ]
        },
        EQUIPO: {
            label: "Equipo/Armadura",
            fields: [
                { name: 'slot_equipo', label: 'Slot de Equipo', type: 'select', options: ['CABEZA', 'PECHO', 'PIERNAS', 'PIES', 'MANOS', 'ACCESORIO'], default: 'PECHO' },
                { name: 'defensa_fisica', label: 'Defensa Física', type: 'number', default: 5, help: 'Reducción de daño físico' },
                { name: 'defensa_magica', label: 'Defensa Mágica', type: 'number', default: 0, help: 'Reducción de daño mágico' },
                { name: 'resistencias', label: 'Resistencias Especiales', type: 'multiselect', options: ['FUEGO', 'HIELO', 'VENENO', 'CORTANTE', 'CONTUNDENTE'], help: 'Resistencias a tipos de daño' },
                { name: 'durabilidad_max', label: 'Durabilidad Máxima', type: 'number', default: 200 },
                { name: 'valor_comercio', label: 'Valor de Comercio', type: 'number', default: 75 }
            ]
        },
        RECURSO: {
            label: "Recurso",
            fields: [
                { name: 'valor_comercio', label: 'Valor de Comercio', type: 'number', default: 2, help: 'Precio base por unidad' },
                { name: 'rareza', label: 'Rareza', type: 'select', options: ['COMUN', 'POCO_COMUN', 'RARO', 'EPICO', 'LEGENDARIO'], default: 'COMUN' },
                { name: 'usos_crafting', label: 'Usos en Crafting', type: 'text', default: '', help: 'Para qué se puede usar (ej: "construccion,herramientas")' }
            ]
        },
        POCION: {
            label: "Poción",
            fields: [
                { name: 'efecto_principal', label: 'Efecto Principal', type: 'select', options: ['CURACION', 'MANA', 'FUERZA', 'VELOCIDAD', 'RESISTENCIA'], default: 'CURACION' },
                { name: 'potencia', label: 'Potencia', type: 'number', default: 50, help: 'Cuánto cura/mejora' },
                { name: 'duracion', label: 'Duración (seg)', type: 'number', default: 0, help: '0 = instantáneo, >0 = efecto temporal' },
                { name: 'valor_comercio', label: 'Valor de Comercio', type: 'number', default: 25 }
            ]
        },
        HERRAMIENTA: {
            label: "Herramienta",
            fields: [
                { name: 'tipo_herramienta', label: 'Tipo', type: 'select', options: ['PICO', 'HACHA', 'PALA', 'MARTILLO', 'SIERRA'], default: 'PICO' },
                { name: 'eficiencia', label: 'Eficiencia', type: 'number', default: 1.0, step: 0.1, help: 'Multiplicador de velocidad' },
                { name: 'durabilidad_max', label: 'Durabilidad Máxima', type: 'number', default: 150 },
                { name: 'valor_comercio', label: 'Valor de Comercio', type: 'number', default: 30 }
            ]
        },
        TESORO: {
            label: "Tesoro",
            fields: [
                { name: 'valor_comercio', label: 'Valor de Comercio', type: 'number', default: 100, help: 'Solo para vender' },
                { name: 'rareza', label: 'Rareza', type: 'select', options: ['COMUN', 'POCO_COMUN', 'RARO', 'EPICO', 'LEGENDARIO'], default: 'RARO' }
            ]
        }
    };

    useEffect(() => {
        fetchObjectTypes();
        // Inicializar campos específicos
        handleTypeChange('COMIDA');
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
        
        if (name === 'tipo_objeto') {
            handleTypeChange(value);
            return;
        }
        
        setFormData(prev => ({
            ...prev,
            [name]: type === 'checkbox' ? checked : (type === 'number' ? parseFloat(value) || 0 : value)
        }));
    };

    const handleTypeChange = (newType) => {
        const config = objectTypeConfig[newType];
        const defaultSpecificFields = {};
        
        config?.fields.forEach(field => {
            if (field.type === 'multiselect') {
                defaultSpecificFields[field.name] = [];
            } else {
                defaultSpecificFields[field.name] = field.default;
            }
        });

        setFormData(prev => ({
            ...prev,
            tipo_objeto: newType,
            specificFields: defaultSpecificFields
        }));
    };

    const handleSpecificFieldChange = (fieldName, value, isMultiSelect = false) => {
        setFormData(prev => ({
            ...prev,
            specificFields: {
                ...prev.specificFields,
                [fieldName]: isMultiSelect ? value : (typeof prev.specificFields[fieldName] === 'number' ? parseFloat(value) || 0 : value)
            }
        }));
    };

    const handleMultiSelectChange = (fieldName, option) => {
        setFormData(prev => {
            const currentValues = prev.specificFields[fieldName] || [];
            const newValues = currentValues.includes(option) 
                ? currentValues.filter(v => v !== option)
                : [...currentValues, option];
            
            return {
                ...prev,
                specificFields: {
                    ...prev.specificFields,
                    [fieldName]: newValues
                }
            };
        });
    };

    const generateValoresEspecificos = () => {
        const valores = { ...formData.specificFields };
        
        // Limpiar campos vacíos
        Object.keys(valores).forEach(key => {
            if (valores[key] === '' || valores[key] === null || 
                (Array.isArray(valores[key]) && valores[key].length === 0)) {
                delete valores[key];
            }
        });
        
        return valores;
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
                tipo_objeto: formData.tipo_objeto,
                es_apilable: formData.es_apilable,
                peso_unidad: formData.peso_unidad,
                valores_especificos: generateValoresEspecificos()
            };
            
            await createTipoObjeto(dataToSend);
            setMessage(`✅ Tipo de Objeto "${formData.nombre}" creado con éxito!`);
            
            // Reset form
            setFormData({
                nombre: '', descripcion: '', id_grafico: '',
                tipo_objeto: 'COMIDA', es_apilable: true, peso_unidad: 0.1,
                specificFields: {}
            });
            handleTypeChange('COMIDA');
            fetchObjectTypes();
        } catch (err) {
            setError('❌ Error al crear Tipo de Objeto: ' + (err.response?.data?.message || err.message));
        }
    };

    const renderSpecificFields = () => {
        const config = objectTypeConfig[formData.tipo_objeto];
        if (!config) return null;

        return (
            <div style={{ marginTop: '20px', padding: '15px', backgroundColor: '#f8f9fa', borderRadius: '8px', border: '1px solid #dee2e6' }}>
                <h3 style={{ margin: '0 0 15px 0', color: '#495057' }}>Configuración Específica para {config.label}</h3>
                
                {config.fields.map(field => (
                    <div key={field.name} style={{ marginBottom: '15px' }}>
                        <label style={{ display: 'block', fontWeight: 'bold', marginBottom: '5px' }}>
                            {field.label}:
                            {field.help && <small style={{ fontWeight: 'normal', color: '#6c757d' }}> ({field.help})</small>}
                        </label>
                        
                        {field.type === 'select' ? (
                            <select 
                                value={formData.specificFields[field.name] || field.default}
                                onChange={(e) => handleSpecificFieldChange(field.name, e.target.value)}
                                style={{ width: '100%', padding: '8px', borderRadius: '4px', border: '1px solid #ced4da' }}
                            >
                                {field.options.map(option => (
                                    <option key={option} value={option}>{option}</option>
                                ))}
                            </select>
                        ) : field.type === 'multiselect' ? (
                            <div>
                                {field.options.map(option => (
                                    <label key={option} style={{ display: 'inline-block', marginRight: '15px', fontWeight: 'normal' }}>
                                        <input
                                            type="checkbox"
                                            checked={(formData.specificFields[field.name] || []).includes(option)}
                                            onChange={() => handleMultiSelectChange(field.name, option)}
                                            style={{ marginRight: '5px' }}
                                        />
                                        {option}
                                    </label>
                                ))}
                            </div>
                        ) : (
                            <input
                                type={field.type}
                                step={field.step}
                                value={formData.specificFields[field.name] || field.default}
                                onChange={(e) => handleSpecificFieldChange(field.name, e.target.value)}
                                style={{ width: '100%', padding: '8px', borderRadius: '4px', border: '1px solid #ced4da' }}
                            />
                        )}
                    </div>
                ))}
            </div>
        );
    };

    return (
        <div style={{ padding: '20px', maxWidth: '900px', margin: 'auto' }}>
            <h1>🛠️ Creador de Tipos de Objeto</h1>

            {message && <div style={{ color: 'green', padding: '10px', backgroundColor: '#d4edda', borderRadius: '5px', marginBottom: '15px' }}>{message}</div>}
            {error && <div style={{ color: 'red', padding: '10px', backgroundColor: '#f8d7da', borderRadius: '5px', marginBottom: '15px' }}>{error}</div>}

            <form onSubmit={handleSubmit} style={{ border: '1px solid #dee2e6', padding: '25px', borderRadius: '8px', backgroundColor: 'white' }}>
                <h2 style={{ marginTop: 0, color: '#495057' }}>Información Básica</h2>
                
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(300px, 1fr))', gap: '15px', marginBottom: '20px' }}>
                    <label>
                        <strong>Nombre del Objeto:</strong>
                        <input 
                            type="text" 
                            name="nombre" 
                            value={formData.nombre} 
                            onChange={handleChange} 
                            required 
                            style={{ width: '100%', padding: '8px', marginTop: '5px', borderRadius: '4px', border: '1px solid #ced4da' }} 
                            placeholder="ej: Carne, Espada de Hierro, Poción de Curación"
                        />
                    </label>
                    
                    <label>
                        <strong>Tipo de Objeto:</strong>
                        <select 
                            name="tipo_objeto" 
                            value={formData.tipo_objeto} 
                            onChange={handleChange} 
                            style={{ width: '100%', padding: '8px', marginTop: '5px', borderRadius: '4px', border: '1px solid #ced4da' }}
                        >
                            {Object.entries(objectTypeConfig).map(([key, config]) => (
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
                        placeholder="Describe para qué sirve este objeto..."
                    ></textarea>
                </label>

                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '15px', marginBottom: '20px' }}>
                    <label>
                        <strong>ID Gráfico:</strong>
                        <input 
                            type="text" 
                            name="id_grafico" 
                            value={formData.id_grafico} 
                            onChange={handleChange} 
                            style={{ width: '100%', padding: '8px', marginTop: '5px', borderRadius: '4px', border: '1px solid #ced4da' }}
                            placeholder="ej: meat_raw_01"
                        />
                    </label>
                    
                    <label>
                        <strong>Peso por Unidad (kg):</strong>
                        <input 
                            type="number" 
                            step="0.01" 
                            name="peso_unidad" 
                            value={formData.peso_unidad} 
                            onChange={handleChange} 
                            style={{ width: '100%', padding: '8px', marginTop: '5px', borderRadius: '4px', border: '1px solid #ced4da' }} 
                        />
                    </label>
                    
                    <label style={{ display: 'flex', alignItems: 'center', marginTop: '25px' }}>
                        <input 
                            type="checkbox" 
                            name="es_apilable" 
                            checked={formData.es_apilable} 
                            onChange={handleChange} 
                            style={{ marginRight: '8px' }}
                        />
                        <strong>Es Apilable</strong>
                    </label>
                </div>

                {renderSpecificFields()}

                <div style={{ marginTop: '25px', padding: '15px', backgroundColor: '#e9ecef', borderRadius: '5px' }}>
                    <h4 style={{ margin: '0 0 10px 0' }}>Vista Previa del JSON:</h4>
                    <pre style={{ backgroundColor: '#f8f9fa', padding: '10px', borderRadius: '4px', fontSize: '12px', overflow: 'auto' }}>
                        {JSON.stringify(generateValoresEspecificos(), null, 2)}
                    </pre>
                </div>

                <button 
                    type="submit" 
                    style={{ 
                        width: '100%', 
                        padding: '12px', 
                        backgroundColor: '#28a745', 
                        color: 'white', 
                        border: 'none', 
                        borderRadius: '5px', 
                        fontSize: '16px', 
                        fontWeight: 'bold',
                        cursor: 'pointer',
                        marginTop: '20px'
                    }}
                >
                    🎯 Crear Tipo de Objeto
                </button>
            </form>

            <h2 style={{ marginTop: '40px' }}>📦 Tipos de Objeto Existentes:</h2>
            <div style={{ display: 'grid', gap: '15px' }}>
                {objectTypes.map(obj => (
                    <div key={obj.id} style={{ border: '1px solid #dee2e6', padding: '15px', borderRadius: '8px', backgroundColor: '#f8f9fa' }}>
                        <h3 style={{ margin: '0 0 10px 0', color: '#495057' }}>
                            🔹 {obj.nombre} <span style={{ fontSize: '14px', color: '#6c757d' }}>(ID: {obj.id})</span>
                        </h3>
                        <p style={{ margin: '0 0 10px 0', color: '#6c757d' }}>{obj.descripcion}</p>
                        <div style={{ display: 'flex', gap: '20px', fontSize: '14px', marginBottom: '10px' }}>
                            <span><strong>Tipo:</strong> {obj.tipo_objeto}</span>
                            <span><strong>Peso:</strong> {obj.peso_unidad}kg</span>
                            <span><strong>Apilable:</strong> {obj.es_apilable ? '✅' : '❌'}</span>
                        </div>
                        <details>
                            <summary style={{ cursor: 'pointer', fontWeight: 'bold' }}>Ver Valores Específicos</summary>
                            <pre style={{ backgroundColor: '#ffffff', padding: '10px', borderRadius: '4px', fontSize: '12px', marginTop: '10px', border: '1px solid #ced4da' }}>
                                {JSON.stringify(obj.valores_especificos, null, 2)}
                            </pre>
                        </details>
                    </div>
                ))}
            </div>
        </div>
    );
};

export default TipoObjetoAdminPage;