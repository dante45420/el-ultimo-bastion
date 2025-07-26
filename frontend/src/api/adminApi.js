// el-ultimo-bastion/frontend/src/api/adminApi.js
import axios from 'axios';

const API_BASE_URL = 'http://localhost:5000/api/v1/admin';

// --- Funciones API para TipoObjeto ---
export const createTipoObjeto = async (objectData) => {
    try {
        const response = await axios.post(`${API_BASE_URL}/tipos_objeto`, objectData);
        return response.data;
    } catch (error) {
        console.error('Error creating TipoObjeto:', error.response ? error.response.data : error.message);
        throw error;
    }
};

export const getTiposObjeto = async () => {
    try {
        const response = await axios.get(`${API_BASE_URL}/tipos_objeto`);
        return response.data;
    }
    catch (error) {
        console.error('Error fetching TipoObjetos:', error.response ? error.response.data : error.message);
        throw error;
    }
};

export const getTipoObjeto = async (objId) => {
    try {
        const response = await axios.get(`${API_BASE_URL}/tipos_objeto/${objId}`);
        return response.data;
    }
    catch (error) {
        console.error('Error fetching TipoObjeto:', error.response ? error.response.data : error.message);
        throw error;
    }
};


// --- Funciones API para Mundo ---

export const createMundo = async (mundoData) => {
    try {
        const response = await axios.post(`${API_BASE_URL}/mundos`, mundoData);
        return response.data;
    } catch (error) {
        console.error('Error creating Mundo:', error.response ? error.response.data : error.message);
        throw error;
    }
};

export const getMundos = async () => {
    try {
        const response = await axios.get(`${API_BASE_URL}/mundos`);
        return response.data;
    } catch (error) {
        console.error('Error fetching Mundos:', error.response ? error.response.data : error.message);
        throw error;
    }
};

export const getMundo = async (mundoId) => {
    try {
        const response = await axios.get(`${API_BASE_URL}/mundos/${mundoId}`);
        return response.data;
    } catch (error) {
        console.error('Error fetching Mundo:', error.response ? error.response.data : error.message);
        throw error;
    }
};

export const updateMundo = async (mundoId, mundoData) => {
    try {
        const response = await axios.put(`${API_BASE_URL}/mundos/${mundoId}`, mundoData);
        return response.data;
    } catch (error) {
        console.error('Error updating Mundo:', error.response ? error.response.data : error.message);
        throw error;
    }
};


// --- Funciones API para InstanciaNPC ---

export const createInstanciaNPC = async (npcData) => {
    try {
        const response = await axios.post(`${API_BASE_URL}/instancias_npc`, npcData);
        return response.data;
    } catch (error) {
        console.error('Error creating InstanciaNPC:', error.response ? error.response.data : error.message);
        throw error;
    }
};

export const getInstanciasNPC = async () => {
    try {
        const response = await axios.get(`${API_BASE_URL}/instancias_npc`);
        return response.data;
    } catch (error) {
        console.error('Error fetching InstanciaNPCs:', error.response ? error.response.data : error.message);
        throw error;
    }
};

export const getInstanciasNPCByMundo = async (mundoId) => {
    try {
        const response = await axios.get(`${API_BASE_URL}/instancias_npc_by_mundo/${mundoId}`);
        return response.data;
    } catch (error) {
        console.error(`Error fetching InstanciaNPCs for Mundo ${mundoId}:`, error.response ? error.response.data : error.message);
        throw error;
    }
};

export const updateInstanciaNPC = async (instId, npcData) => {
    try {
        const response = await axios.put(`${API_BASE_URL}/instancias_npc/${instId}`, npcData);
        return response.data;
    } catch (error) {
        console.error('Error updating InstanciaNPC:', error.response ? error.response.data : error.message);
        throw error;
    }
};


// --- Funciones para dependencias de Dropdowns (ahora apuntan a endpoints reales del backend) ---

export const getUsuarios = async () => {
    try {
        const response = await axios.get(`${API_BASE_URL}/usuarios`);
        return response.data;
    } catch (error) {
        console.error('Error fetching Usuarios for dropdown:', error.response ? error.response.data : error.message);
        throw error;
    }
};

export const getClanes = async () => {
    try {
        const response = await axios.get(`${API_BASE_URL}/clanes`);
        return response.data;
    } catch (error) {
        console.error('Error fetching Clanes for dropdown:', error.response ? error.response.data : error.message);
        throw error;
    }
};

export const getTiposNPC = async () => {
    try {
        const response = await axios.get(`${API_BASE_URL}/tipos_npc`);
        return response.data;
    } catch (error) {
        console.error('Error fetching TipoNPCs for dropdown:', error.response ? error.response.data : error.message);
        throw error;
    }
};

export const getCriaturaVivaBases = async () => {
    try {
        const response = await axios.get(`${API_BASE_URL}/criaturaviva_bases`);
        return response.data;
    } catch (error) {
        console.error('Error fetching CriaturaVivaBases for dropdown:', error.response ? error.response.data : error.message);
        throw error;
    }
};

// --- Funciones API para Bastion ---
export const createBastion = async (bastionData) => {
    try {
        const response = await axios.post(`${API_BASE_URL}/bastiones`, bastionData);
        return response.data;
    } catch (error) {
        console.error('Error creating Bastion:', error.response ? error.response.data : error.message);
        throw error;
    }
};

export const getBastions = async () => {
    try {
        const response = await axios.get(`${API_BASE_URL}/bastiones`);
        return response.data;
    } catch (error) {
        console.error('Error fetching Bastions:', error.response ? error.response.data : error.message);
        throw error;
    }
};

export const getBastion = async (bastionId) => {
    try {
        const response = await axios.get(`${API_BASE_URL}/bastiones/${bastionId}`);
        return response.data;
    } catch (error) {
        console.error('Error fetching Bastion:', error.response ? error.response.data : error.message);
        throw error;
    }
};

export const updateBastion = async (bastionId, bastionData) => {
    try {
        const response = await axios.put(`${API_BASE_URL}/bastiones/${bastionId}`, bastionData);
        return response.data;
    } catch (error) {
        console.error('Error updating Bastion:', error.response ? error.response.data : error.message);
        throw error;
    }
};

// --- Funciones para Sincronización de Game State (desde Godot) ---
// Aunque se llama desde el frontend para simulación en este plan,
// su uso principal será desde Data_Loader.gd
export const syncBastionGameState = async (bastionId, gameStateData) => {
    try {
        const response = await axios.put(`${API_BASE_URL}/bastiones/${bastionId}/sync_game_state`, gameStateData);
        return response.data;
    } catch (error) {
        console.error('Error syncing Bastion game state:', error.response ? error.response.data : error.message);
        throw error;
    }
};