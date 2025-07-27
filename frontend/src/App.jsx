// el-ultimo-bastion/frontend/src/App.jsx
import React, { useState } from 'react';
import TipoObjetoAdminPage from './pages/TipoObjetoAdminPage';
import MundoAdminPage from './pages/MundoAdminPage';
import BastionAdminPage from './pages/BastionAdminPage';
import WorldContentEditorPage from './pages/WorldContentEditorPage';
import TipoNPCAdminPage from './pages/TipoNPCAdminPage';

function App() {
  const [currentPage, setCurrentPage] = useState('mundos');
  const [editingWorldId, setEditingWorldId] = useState(null);

  const handleEditWorldContent = (worldId) => {
    setEditingWorldId(worldId);
    setCurrentPage('worldContentEditor');
  };

  const handleBackToWorlds = () => {
    setEditingWorldId(null);
    setCurrentPage('mundos');
  };

  const renderPage = () => {
    switch (currentPage) {
      case 'mundos':
        return <MundoAdminPage onEditWorldContent={handleEditWorldContent} />;
      case 'tiposObjeto':
        return <TipoObjetoAdminPage />;
      case 'tiposNPC': 
        return <TipoNPCAdminPage />;
      case 'bastiones':
        return <BastionAdminPage />;
      case 'worldContentEditor':
        return <WorldContentEditorPage worldId={editingWorldId} onBack={handleBackToWorlds} />;
      default:
        return <MundoAdminPage onEditWorldContent={handleEditWorldContent} />;
    }
  };

  const navButtonStyle = {
    padding: '10px 15px',
    margin: '0 5px',
    border: '1px solid #ccc',
    background: '#f0f0f0',
    cursor: 'pointer',
    borderRadius: '5px'
  };

  return (
    <div style={{ fontFamily: 'sans-serif' }}>
      <header style={{ padding: '10px 20px', borderBottom: '2px solid #ccc', display: 'flex', alignItems: 'center', background: '#fff' }}>
        <h1 style={{ margin: 0, fontSize: '24px' }}>El Último Bastión - Panel de Admin</h1>
        <nav style={{ marginLeft: 'auto' }}>
          <button style={navButtonStyle} onClick={() => setCurrentPage('mundos')}>Mundos</button>
          <button style={navButtonStyle} onClick={() => setCurrentPage('tiposNPC')}>Crear Tipos de NPC</button>
          <button style={navButtonStyle} onClick={() => setCurrentPage('tiposObjeto')}>Crear Tipos de Objeto</button>
          <button style={navButtonStyle} onClick={() => setCurrentPage('bastiones')}>Bastiones</button>
        </nav>
      </header>
      <main style={{ padding: '20px' }}>
        {renderPage()}
      </main>
    </div>
  );
}

export default App;