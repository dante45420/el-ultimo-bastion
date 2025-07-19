# el-ultimo-bastion/backend/tests/conftest.py

import pytest
import os
from app import create_app, db
from app import models
from dotenv import dotenv_values

dotenv_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '.env')
env_vars = dotenv_values(dotenv_path)

@pytest.fixture(scope='session')
def app():
    test_db_uri = os.environ.get('DATABASE_URL_TEST') or \
                  f"postgresql://{env_vars.get('DB_USER')}:{env_vars.get('DB_PASSWORD')}@{env_vars.get('DB_HOST')}:{env_vars.get('DB_PORT')}/{env_vars.get('DB_NAME_TEST')}"

    app = create_app(test_config={
        "TESTING": True,
        "SQLALCHEMY_DATABASE_URI": test_db_uri,
        "SECRET_KEY": "test_secret_key",
        "FRONTEND_URL": "http://localhost:5173"
    })

    with app.app_context():
        db.create_all() # Asegúrate de que todas las tablas existen al inicio de la sesión
        yield app
        db.session.remove()
        db.drop_all() # Elimina todas las tablas al final de la sesión

@pytest.fixture(scope='function')
def session(app):
    """Fixture para una sesión de base de datos limpia para cada test."""
    with app.app_context():
        # Limpiar datos de las tablas más propensas a UNIQUE violations antes de cada test
        # ¡IMPORTANTE: Añade aquí todas las tablas que tienen UNIQUE constraints
        # y que se insertan en tus tests!
        models.InteraccionComercio.query.delete()
        models.MisionActiva.query.delete()
        models.EventoGlobalActivo.query.delete()
        models.InstanciaEdificio.query.delete()
        models.InstanciaNPC.query.delete()
        models.InstanciaAnimal.query.delete()
        models.InstanciaRecursoTerreno.query.delete()
        models.InstanciaAldea.query.delete()
        models.Mundo.query.delete()
        models.Bastion.query.delete()
        models.Clan.query.delete()
        models.Usuario.query.delete() # <--- CLAVE: Limpiar usuarios
        models.CriaturaViva_Base.query.delete()
        models.Daño.query.delete()
        models.Inventario.query.delete()

        # También las tablas de tipo si sus nombres/IDs son únicos y se crean en los tests
        models.TipoComercianteOferta.query.delete()
        models.TipoMision.query.delete()
        models.TipoPista.query.delete()
        models.TipoEventoGlobal.query.delete()
        models.TipoNPC.query.delete()
        models.TipoAnimal.query.delete()
        models.TipoRecursoTerreno.query.delete()
        models.TipoHabilidad.query.delete()
        models.TipoEdificio.query.delete()
        models.TipoLootTable.query.delete()
        models.TipoObjeto.query.delete()

        db.session.commit() # Confirma la limpieza

        # Inicia una nueva transacción para el test
        connection = db.engine.connect()
        transaction = connection.begin()
        db.session.begin_nested() # Inicia una sub-transacción

        db.session.bind = connection

        yield db.session

        db.session.remove()
        db.session.rollback() # Revierte la sub-transacción
        transaction.rollback() # Revierte la transacción principal
        connection.close()