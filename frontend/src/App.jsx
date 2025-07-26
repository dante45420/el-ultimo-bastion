// el-ultimo-bastion/frontend/src/App.jsx
import React, { useState } from 'react';
import TipoObjetoAdminPage from './pages/TipoObjetoAdminPage';
import MundoAdminPage from './pages/MundoAdminPage';
import InstanciaNPCAdminPage from './pages/InstanciaNPCAdminPage';
import BastionAdminPage from './pages/BastionAdminPage';
import WorldContentEditorPage from './pages/WorldContentEditorPage'; // Importamos el nuevo editor

function App() {
  const [currentPage, setCurrentPage] = useState('mundos');
  // Nuevo estado para manejar la edición de contenido de un mundo específico
  const [editingWorldId, setEditingWorldId] = useState(null);

  const handleEditWorldContent = (worldId) => {
    setEditingWorldId(worldId);
    setCurrentPage('worldContentEditor'); // Cambiamos a la nueva página de edición
  };

  const handleBackToWorlds = () => {
    setEditingWorldId(null);
    setCurrentPage('mundos'); // Volvemos a la lista de mundos
  };

  const renderPage = () => {
    switch (currentPage) {
      case 'tiposObjeto':
        return <TipoObjetoAdminPage />;
      case 'mundos':
        return <MundoAdminPage onEditWorldContent={handleEditWorldContent} />;
      case 'instanciasNPC':
        return <InstanciaNPCAdminPage />;
      case 'bastiones':
        return <BastionAdminPage />;
      // Nuevo caso para mostrar el editor de contenido del mundo
      case 'worldContentEditor':
        return <WorldContentEditorPage worldId={editingWorldId} onBack={handleBackToWorlds} />;
      default:
        return <MundoAdminPage onEditWorldContent={handleEditWorldContent} />;
    }
  };

  return (
    <div style={{ display: 'flex', fontFamily: 'sans-serif' }}>
      <nav style={{ width: '200px', borderRight: '1px solid #ccc', padding: '20px' }}>
        <h2>El Último Bastión</h2>
        <ul style={{ listStyle: 'none', padding: 0 }}>
          <li style={{ marginBottom: '10px' }}><button onClick={() => setCurrentPage('mundos')}>Mundos</button></li>
          <li style={{ marginBottom: '10px' }}><button onClick={() => setCurrentPage('tiposObjeto')}>Tipos de Objeto</button></li>
          <li style={{ marginBottom: '10px' }}><button onClick={() => setCurrentPage('instanciasNPC')}>Instancias NPC (Global)</button></li>
          <li style={{ marginBottom: '10px' }}><button onClick={() => setCurrentPage('bastiones')}>Bastiones</button></li>
        </ul>
      </nav>
      <main style={{ flex: 1, padding: '20px' }}>
        {renderPage()}
      </main>
    </div>
  );
}

export default App;
