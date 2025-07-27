// el-ultimo-bastion/frontend/src/api/adminApi.js
import axios from 'axios'; // Asumiendo que instalaste axios: npm install axios

// Configura tu instancia de axios base. Asegúrate de que apunte a tu backend Flask.
// Si tu backend Flask corre en http://127.0.0.1:5000 y el blueprint es '/api/v1/admin'
const axiosInstance = axios.create({
    baseURL: 'http://127.0.0.1:5000/api/v1/admin', 
    headers: {
        'Content-Type': 'application/json',
    },
});

// --- Funciones para TipoObjeto ---
export const createTipoObjeto = async (data) => {
    const response = await axiosInstance.post('/tipos_objeto', data);
    return response.data;
};
export const getTiposObjeto = async () => {
    const response = await axiosInstance.get('/tipos_objeto');
    return response.data;
};

// --- Funciones para Mundo ---
export const createMundo = async (data) => {
    const response = await axiosInstance.post('/mundos', data);
    return response.data;
};
export const getMundos = async () => {
    const response = await axiosInstance.get('/mundos');
    return response.data;
};
export const getMundo = async (id) => {
    const response = await axiosInstance.get(`/mundos/${id}`);
    return response.data;
};
export const updateMundo = async (id, data) => {
    const response = await axiosInstance.put(`/mundos/${id}`, data);
    return response.data;
};

// --- Funciones para TipoNPC ---
export const createTipoNPC = async (data) => {
    const response = await axiosInstance.post('/tipos_npc', data);
    return response.data;
};
export const getTiposNPC = async () => {
    const response = await axiosInstance.get('/tipos_npc');
    return response.data;
};

// --- Funciones para InstanciaNPC ---
export const createInstanciaNPC = async (data) => {
    const response = await axiosInstance.post('/instancias_npc', data);
    return response.data;
};
export const getInstanciasNPCByMundo = async (mundoId) => {
    const response = await axiosInstance.get(`/instancias_npc_by_mundo/${mundoId}`);
    return response.data;
};
export const getInstanciasNPC = async () => { // Si decides mantener una vista global de instancias
    const response = await axiosInstance.get('/instancias_npc');
    return response.data;
};


// --- Funciones para Usuario y Clan (para dropdowns) ---
export const getUsuarios = async () => {
    const response = await axiosInstance.get('/usuarios');
    return response.data;
};
export const getClanes = async () => {
    const response = await axiosInstance.get('/clanes');
    return response.data;
};

// --- Funciones para Bastion ---
export const createBastion = async (data) => {
    const response = await axiosInstance.post('/bastiones', data);
    return response.data;
};
export const getBastions = async () => {
    const response = await axiosInstance.get('/bastiones');
    return response.data;
};
export const updateBastion = async (id, data) => {
    const response = await axiosInstance.put(`/bastiones/${id}`, data);
    return response.data;
};
export const getBastionByUserId = async (userId) => {
    const response = await axiosInstance.get(`/bastiones_by_user/${userId}`);
    return response.data;
};

// --- Funciones para CriaturaViva_Base (para dropdowns de Bastion si aplica) ---
export const getCriaturaVivaBases = async () => {
    const response = await axiosInstance.get('/criaturaviva_bases');
    return response.data;
};