// el-ultimo-bastion/frontend/src/App.jsx
import React, { useState } from 'react';
import TipoObjetoAdminPage from './pages/TipoObjetoAdminPage';
import MundoAdminPage from './pages/MundoAdminPage';
import BastionAdminPage from './pages/BastionAdminPage';
import WorldContentEditorPage from './pages/WorldContentEditorPage';
import TipoNPCAdminPage from './pages/TipoNPCAdminPage';

// ¡NUEVO COMPONENTE! Esta será la nueva página principal de "Mundos"
function WorldTemplateSelector({ onEditWorldContent }) {
  // En un futuro, obtendrías el ID del sandbox de una API o config
  const SANDBOX_WORLD_ID = 1; 

  const buttonStyle = {
    display: 'block',
    width: '100%',
    padding: '20px',
    fontSize: '18px',
    marginBottom: '15px',
    cursor: 'pointer'
  };

  return (
    <div>
      <h1>Selección de Entorno de Trabajo</h1>
      <p>Elige qué plantilla de mundo o entorno de pruebas deseas gestionar.</p>
      <button 
        style={buttonStyle}
        onClick={() => onEditWorldContent(SANDBOX_WORLD_ID)}
      >
        Gestionar Mundo Sandbox
      </button>
      <button style={{...buttonStyle, background: '#eee', cursor: 'not-allowed'}} disabled>
        Gestionar Plantilla de Mundos Personales (Próximamente)
      </button>
      <button style={{...buttonStyle, background: '#eee', cursor: 'not-allowed'}} disabled>
        Gestionar Plantilla de Mundo de Clan (Próximamente)
      </button>
    </div>
  );
}


function App() {
  const [currentPage, setCurrentPage] = useState('worldSelector'); // Cambiado el valor inicial
  const [editingWorldId, setEditingWorldId] = useState(null);

  const handleEditWorldContent = (worldId) => {
    setEditingWorldId(worldId);
    setCurrentPage('worldContentEditor');
  };

  const handleBackToSelector = () => {
    setEditingWorldId(null);
    setCurrentPage('worldSelector');
  };

  const renderPage = () => {
    switch (currentPage) {
      case 'worldSelector':
        return <WorldTemplateSelector onEditWorldContent={handleEditWorldContent} />;
      case 'configMundos':
        return <MundoAdminPage />; // Esta página ahora solo configura mundos
      case 'tiposObjeto':
        return <TipoObjetoAdminPage />;
      case 'tiposNPC': 
        return <TipoNPCAdminPage />;
      case 'bastiones':
        return <BastionAdminPage />;
      case 'worldContentEditor':
        return <WorldContentEditorPage worldId={editingWorldId} onBack={handleBackToSelector} />;
      default:
        return <WorldTemplateSelector onEditWorldContent={handleEditWorldContent} />;
    }
  };

  const navButtonStyle = {
    padding: '10px 15px', margin: '0 5px', border: '1px solid #ccc',
    background: '#f0f0f0', cursor: 'pointer', borderRadius: '5px'
  };

  return (
    <div style={{ fontFamily: 'sans-serif' }}>
      <header style={{ padding: '10px 20px', borderBottom: '2px solid #ccc', display: 'flex', alignItems: 'center', background: '#fff' }}>
        <h1 style={{ margin: 0, fontSize: '24px' }}>El Último Bastión - Panel de Admin</h1>
        <nav style={{ marginLeft: 'auto' }}>
          <button style={navButtonStyle} onClick={() => setCurrentPage('worldSelector')}>Gestión de Mundos</button>
          <button style={navButtonStyle} onClick={() => setCurrentPage('tiposNPC')}>Crear Arquetipos NPC</button>
          <button style={navButtonStyle} onClick={() => setCurrentPage('tiposObjeto')}>Crear Arquetipos Objeto</button>
          <button style={navButtonStyle} onClick={() => setCurrentPage('bastiones')}>Soporte a Jugadores</button>
          <button style={navButtonStyle} onClick={() => setCurrentPage('configMundos')}>Configuración de Mundos</button>
        </nav>
      </header>
      <main style={{ padding: '20px' }}>
        {renderPage()}
      </main>
    </div>
  );
}

export default App;