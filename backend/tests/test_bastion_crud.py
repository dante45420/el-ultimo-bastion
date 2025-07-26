# el-ultimo-bastion/backend/tests/test_bastion_crud.py
import pytest
from app import db
from app.models import Usuario, Clan, Bastion, Inventario, Daño, CriaturaViva_Base, Mundo, TipoLootTable
from werkzeug.security import generate_password_hash
from decimal import Decimal

# La fixture 'session' y 'client' se proporcionan desde conftest.py

def test_create_bastion_new_criaturavivabase(session, client):
    """
    Testea la creación de un Bastion cuando no se proporciona un id_criatura_viva_base
    y se espera que se creen automáticamente Inventario, Daño y CriaturaViva_Base.
    """
    # Preparar un usuario y un mundo (necesario para las FKs del Bastion)
    user = Usuario(username="test_user_new_cvb", password_hash=generate_password_hash("password"), email="new_cvb@example.com")
    session.add(user)
    session.flush() # Para obtener el ID del usuario

    clan_inv = Inventario(capacidad_slots=10, capacidad_peso_kg=100)
    session.add(clan_inv)
    session.flush()
    clan = Clan(nombre="Test Clan New CVB", id_lider_usuario=user.id, id_inventario_baluarte=clan_inv.id)
    session.add(clan)
    session.flush()

    mundo = Mundo(tipo_mundo="PERSONAL", id_propietario_usuario=user.id, nombre_mundo="Test Mundo New CVB")
    session.add(mundo)
    session.flush()

    bastion_data = {
        "id_usuario": user.id,
        "id_clan": clan.id,
        "nombre_personaje": "NuevoHeroeCVB",
        "nivel": 1,
        "experiencia": 0,
        "posicion_actual": {"x": 10, "y": 0, "z": 10, "mundo_id": mundo.id},
        "habilidades_aprendidas": [],
        # No se proporciona id_criatura_viva_base, se deben usar los initial_ fields
        "initial_salud_max": 120,
        "initial_hambre_max": 90,
        "initial_dano_ataque_base": 12,
        "initial_velocidad_movimiento": 7.5,
        "initial_inventario_capacidad_slots": 30,
        "initial_inventario_capacidad_peso_kg": 60.0,
        "initial_loot_table_id": None
    }
    
    response = client.post('/api/v1/admin/bastiones', json=bastion_data)
    assert response.status_code == 201
    data = response.get_json()
    
    assert data['nombre_personaje'] == "NuevoHeroeCVB"
    assert data['id_usuario'] == user.id
    assert data['id_criatura_viva_base'] is not None

    # Verificar que CriaturaViva_Base, Inventario y Daño se crearon y tienen los valores correctos
    bastion_in_db = session.query(Bastion).filter_by(id=data['id']).first()
    assert bastion_in_db is not None
    assert bastion_in_db.criatura_viva_base is not None
    assert bastion_in_db.criatura_viva_base.inventario is not None
    assert bastion_in_db.criatura_viva_base.danio is not None
    
    assert bastion_in_db.criatura_viva_base.danio.salud_max == 120
    assert bastion_in_db.criatura_viva_base.danio.salud_actual == 120
    assert bastion_in_db.criatura_viva_base.hambre_max == 90
    assert bastion_in_db.criatura_viva_base.hambre_actual == 90
    assert bastion_in_db.criatura_viva_base.dano_ataque_base == 12
    assert float(bastion_in_db.criatura_viva_base.velocidad_movimiento) == 7.5
    assert bastion_in_db.criatura_viva_base.inventario.capacidad_slots == 30
    assert float(bastion_in_db.criatura_viva_base.inventario.capacidad_peso_kg) == 60.0

    assert bastion_in_db.posicion_actual == {"x": 10, "y": 0, "z": 10, "mundo_id": mundo.id}

def test_create_bastion_existing_criaturavivabase(session, client):
    """
    Testea la creación de un Bastion cuando se proporciona un id_criatura_viva_base existente.
    """
    user = Usuario(username="test_user_existing_cvb", password_hash=generate_password_hash("password"), email="exist_cvb@example.com")
    session.add(user)
    session.flush()

    mundo = Mundo(tipo_mundo="PERSONAL", id_propietario_usuario=user.id, nombre_mundo="Test Mundo Existing CVB")
    session.add(mundo)
    session.flush()

    # Create existing CriaturaViva_Base components
    inv = Inventario(capacidad_slots=30, capacidad_peso_kg=60.0)
    dano = Daño(salud_actual=150, salud_max=150)
    session.add_all([inv, dano])
    session.flush()
    cv_base = CriaturaViva_Base(hambre_actual=90, hambre_max=100, dano_ataque_base=12, velocidad_movimiento=7.0, id_danio=dano.id, id_inventario=inv.id)
    session.add(cv_base)
    session.flush()

    bastion_data = {
        "id_usuario": user.id,
        "nombre_personaje": "HeroeExistenteCVB",
        "nivel": 2,
        "experiencia": 500,
        "posicion_actual": {"x": 20, "y": 0, "z": 20, "mundo_id": mundo.id},
        "habilidades_aprendidas": [],
        "id_criatura_viva_base": cv_base.id # Proporcionar un ID existente
    }
    response = client.post('/api/v1/admin/bastiones', json=bastion_data)
    assert response.status_code == 201
    data = response.get_json()
    assert data['id_criatura_viva_base'] == cv_base.id
    # Asegurarse de que no se crearon nuevos componentes inesperadamente
    assert session.query(CriaturaViva_Base).count() == 1 # Solo la que creamos manualmente

def test_bastion_unique_user_id_constraint(session, client):
    """
    Verifica que no se puede crear un segundo Bastion para el mismo usuario.
    """
    user = Usuario(username="unique_user_test", password_hash=generate_password_hash("password"), email="unique_test@example.com")
    session.add(user)
    session.flush()

    mundo = Mundo(tipo_mundo="PERSONAL", id_propietario_usuario=user.id, nombre_mundo="Test Mundo Unique User")
    session.add(mundo)
    session.flush()

    # Crear una CriaturaViva_Base para el primer Bastion
    inv1 = Inventario(capacidad_slots=10, capacidad_peso_kg=20)
    dano1 = Daño(salud_actual=50, salud_max=50)
    session.add_all([inv1, dano1])
    session.flush()
    cv_base1 = CriaturaViva_Base(hambre_actual=40, hambre_max=50, dano_ataque_base=5, velocidad_movimiento=3.0, id_danio=dano1.id, id_inventario=inv1.id)
    session.add(cv_base1)
    session.flush()

    bastion_data_1 = {
        "id_usuario": user.id,
        "nombre_personaje": "BastionUnique1",
        "nivel": 1, "experiencia": 0,
        "posicion_actual": {"x": 0, "y": 0, "z": 0, "mundo_id": mundo.id},
        "habilidades_aprendidas": [],
        "id_criatura_viva_base": cv_base1.id
    }
    response_1 = client.post('/api/v1/admin/bastiones', json=bastion_data_1)
    assert response_1.status_code == 201

    # Crear una segunda CriaturaViva_Base para el segundo intento de Bastion (necesario por unique constraint en CVB)
    inv2 = Inventario(capacidad_slots=10, capacidad_peso_kg=20)
    dano2 = Daño(salud_actual=50, salud_max=50)
    session.add_all([inv2, dano2])
    session.flush()
    cv_base2 = CriaturaViva_Base(hambre_actual=40, hambre_max=50, dano_ataque_base=5, velocidad_movimiento=3.0, id_danio=dano2.id, id_inventario=inv2.id)
    session.add(cv_base2)
    session.flush()

    bastion_data_2 = { # Mismo user ID
        "id_usuario": user.id,
        "nombre_personaje": "BastionUnique2",
        "nivel": 1, "experiencia": 0,
        "posicion_actual": {"x": 1, "y": 1, "z": 1, "mundo_id": mundo.id},
        "habilidades_aprendidas": [],
        "id_criatura_viva_base": cv_base2.id
    }
    response_2 = client.post('/api/v1/admin/bastiones', json=bastion_data_2)
    assert response_2.status_code == 409 # Esperamos un conflicto debido a la restricción UNIQUE

def test_update_bastion_attributes_from_admin_panel(session, client):
    """
    Testea la actualización de atributos NO dinámicos del Bastion desde el panel de admin.
    """
    user = Usuario(username="update_admin_test", password_hash=generate_password_hash("password"), email="update_admin@example.com")
    session.add(user)
    session.flush()

    mundo = Mundo(tipo_mundo="PERSONAL", id_propietario_usuario=user.id, nombre_mundo="Test Mundo Update Admin")
    session.add(mundo)
    session.flush()

    inv = Inventario(capacidad_slots=10, capacidad_peso_kg=20)
    dano = Daño(salud_actual=50, salud_max=50)
    session.add_all([inv, dano])
    session.flush()
    cv_base = CriaturaViva_Base(hambre_actual=40, hambre_max=50, dano_ataque_base=5, velocidad_movimiento=3.0, id_danio=dano.id, id_inventario=inv.id)
    session.add(cv_base)
    session.flush()

    bastion = Bastion(
        id_usuario=user.id, nombre_personaje="OriginalAdminBastion", nivel=1, experiencia=0,
        posicion_actual={"x": 0, "y": 0, "z": 0, "mundo_id": mundo.id},
        habilidades_aprendidas=[100], id_criatura_viva_base=cv_base.id
    )
    session.add(bastion)
    session.commit() # Commit aquí para obtener un ID para el Bastion

    update_data = {
        "nombre_personaje": "UpdatedAdminBastion",
        "nivel": 5,
        "experiencia": 1000,
        "habilidades_aprendidas": [100, 101]
    }
    response = client.put(f'/api/v1/admin/bastiones/{bastion.id}', json=update_data)
    assert response.status_code == 200
    data = response.get_json()
    assert data['nombre_personaje'] == "UpdatedAdminBastion"
    assert data['nivel'] == 5
    assert data['experiencia'] == 1000
    assert data['habilidades_aprendidas'] == [100, 101]
    
    # Verificar que los campos dinámicos NO fueron actualizados por esta ruta
    updated_bastion_in_db = session.query(Bastion).filter_by(id=bastion.id).first()
    assert updated_bastion_in_db.posicion_actual == {"x": 0, "y": 0, "z": 0, "mundo_id": mundo.id}


def test_sync_bastion_game_state_from_godot(session, client):
    """
    Testea la sincronización de atributos dinámicos del Bastion (posición, salud, hambre)
    desde el juego (Godot).
    """
    user = Usuario(username="sync_godot_test_user", password_hash=generate_password_hash("password"), email="sync_godot@example.com")
    session.add(user)
    session.flush()

    mundo = Mundo(tipo_mundo="PERSONAL", id_propietario_usuario=user.id, nombre_mundo="Test Mundo Sync Godot")
    session.add(mundo)
    session.flush()

    inv = Inventario(capacidad_slots=10, capacidad_peso_kg=20)
    dano = Daño(salud_actual=50, salud_max=50)
    session.add_all([inv, dano])
    session.flush()
    cv_base = CriaturaViva_Base(hambre_actual=40, hambre_max=50, dano_ataque_base=5, velocidad_movimiento=3.0, id_danio=dano.id, id_inventario=inv.id)
    session.add(cv_base)
    session.flush()

    bastion = Bastion(
        id_usuario=user.id, nombre_personaje="SyncBastionFromGodot", nivel=1, experiencia=0,
        posicion_actual={"x": 0, "y": 0, "z": 0, "mundo_id": mundo.id}, # Posición inicial
        habilidades_aprendidas=[], id_criatura_viva_base=cv_base.id
    )
    session.add(bastion)
    session.commit()

    sync_data = {
        "posicion_actual": {"x": 100, "y": 10, "z": 50, "mundo_id": mundo.id},
        "criatura_viva_base": {
            "salud_actual": 30,
            "hambre_actual": 25
        }
    }
    response = client.put(f'/api/v1/admin/bastiones/{bastion.id}/sync_game_state', json=sync_data)
    assert response.status_code == 200
    
    # Verificar directamente desde la DB que los cambios persistieron
    updated_bastion = session.query(Bastion).filter_by(id=bastion.id).first()
    assert updated_bastion.posicion_actual == {"x": 100, "y": 10, "z": 50, "mundo_id": mundo.id}
    assert updated_bastion.criatura_viva_base.danio.salud_actual == 30
    assert updated_bastion.criatura_viva_base.hambre_actual == 25
    # Verificar que otros campos no se vieron afectados
    assert updated_bastion.nivel == 1
    assert updated_bastion.experiencia == 0


def test_get_bastion_by_user_id(session, client):
    """
    Testea la ruta para obtener un Bastion dado un ID de usuario.
    """
    user = Usuario(username="get_by_user_test", password_hash=generate_password_hash("password"), email="get_by_user@example.com")
    session.add(user)
    session.flush()

    mundo = Mundo(tipo_mundo="PERSONAL", id_propietario_usuario=user.id, nombre_mundo="Test Mundo Get By User")
    session.add(mundo)
    session.flush()

    inv = Inventario(capacidad_slots=10, capacidad_peso_kg=20)
    dano = Daño(salud_actual=50, salud_max=50)
    session.add_all([inv, dano])
    session.flush()
    cv_base = CriaturaViva_Base(hambre_actual=40, hambre_max=50, dano_ataque_base=5, velocidad_movimiento=3.0, id_danio=dano.id, id_inventario=inv.id)
    session.add(cv_base)
    session.flush()

    bastion = Bastion(
        id_usuario=user.id, nombre_personaje="BastionByUser", nivel=10, experiencia=5000,
        posicion_actual={"x": 50, "y": 5, "z": 50, "mundo_id": mundo.id},
        habilidades_aprendidas=[1,2,3], id_criatura_viva_base=cv_base.id
    )
    session.add(bastion)
    session.commit()

    response = client.get(f'/api/v1/admin/bastiones_by_user/{user.id}')
    assert response.status_code == 200
    data = response.get_json()
    assert data['nombre_personaje'] == "BastionByUser"
    assert data['id_usuario'] == user.id
    assert data['nivel'] == 10
    assert data['experiencia'] == 5000
    assert 'posicion_actual' in data
    assert 'criatura_viva_base' in data # Verificar que los datos anidados se incluyen

    # Test for non-existent user
    response_not_found = client.get('/api/v1/admin/bastiones_by_user/99999')
    assert response_not_found.status_code == 404
    assert "no encontrado" in response_not_found.get_json()['message']

def test_get_bastions_list(session, client):
    """
    Testea la ruta para obtener todos los Bastiones.
    """
    user1 = Usuario(username="list_test_user1", password_hash=generate_password_hash("pass1"), email="list1@example.com")
    user2 = Usuario(username="list_test_user2", password_hash=generate_password_hash("pass2"), email="list2@example.com")
    session.add_all([user1, user2])
    session.flush()

    mundo1 = Mundo(tipo_mundo="PERSONAL", id_propietario_usuario=user1.id, nombre_mundo="List Mundo 1")
    mundo2 = Mundo(tipo_mundo="PERSONAL", id_propietario_usuario=user2.id, nombre_mundo="List Mundo 2")
    session.add_all([mundo1, mundo2])
    session.flush()

    inv1 = Inventario(capacidad_slots=10, capacidad_peso_kg=20)
    dano1 = Daño(salud_actual=50, salud_max=50)
    session.add_all([inv1, dano1])
    session.flush()
    cv_base1 = CriaturaViva_Base(hambre_actual=40, hambre_max=50, dano_ataque_base=5, velocidad_movimiento=3.0, id_danio=dano1.id, id_inventario=inv1.id)
    session.add(cv_base1)
    session.flush()

    inv2 = Inventario(capacidad_slots=15, capacidad_peso_kg=30)
    dano2 = Daño(salud_actual=60, salud_max=60)
    session.add_all([inv2, dano2])
    session.flush()
    cv_base2 = CriaturaViva_Base(hambre_actual=50, hambre_max=60, dano_ataque_base=7, velocidad_movimiento=4.0, id_danio=dano2.id, id_inventario=inv2.id)
    session.add(cv_base2)
    session.flush()

    bastion1 = Bastion(id_usuario=user1.id, nombre_personaje="ListBastion1", nivel=1, experiencia=0, posicion_actual={"x": 1, "y": 1, "z": 1, "mundo_id": mundo1.id}, habilidades_aprendidas=[], id_criatura_viva_base=cv_base1.id)
    bastion2 = Bastion(id_usuario=user2.id, nombre_personaje="ListBastion2", nivel=2, experiencia=100, posicion_actual={"x": 2, "y": 2, "z": 2, "mundo_id": mundo2.id}, habilidades_aprendidas=[], id_criatura_viva_base=cv_base2.id)
    session.add_all([bastion1, bastion2])
    session.commit()

    response = client.get('/api/v1/admin/bastiones')
    assert response.status_code == 200
    data = response.get_json()
    assert len(data) == 2
    assert any(b['nombre_personaje'] == "ListBastion1" for b in data)
    assert any(b['nombre_personaje'] == "ListBastion2" for b in data)
    # Check for nested data presence
    assert all('criatura_viva_base' in b for b in data)
    assert all('usuario' in b for b in data)