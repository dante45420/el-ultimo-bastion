# el-ultimo-bastion/backend/tests/test_tanda3_game_state_level1.py
import pytest
from app.models import Usuario, Clan, Bastion, Mundo, Inventario, Daño, CriaturaViva_Base
import sqlalchemy.exc
from werkzeug.security import generate_password_hash, check_password_hash

# --- Tests para Usuario ---
# (Estos tests ya pasaron y no necesitan cambios)
def test_create_usuario(session):
    print("\n--- Test: Crear Usuario ---")
    password_clear = "password123"
    password_hash = generate_password_hash(password_clear)
    user = Usuario(username="testuser", password_hash=password_hash, email="test@example.com")
    session.add(user)
    session.commit()
    assert user.id is not None
    assert user.username == "testuser"
    assert check_password_hash(user.password_hash, password_clear)
    print(f"Usuario '{user.username}' creado con ID: {user.id}")

def test_usuario_unique_username(session):
    print("\n--- Test: Unicidad de Usuario (username) ---")
    password_hash = generate_password_hash("password123")
    user1 = Usuario(username="uniqueuser", password_hash=password_hash, email="unique@example.com")
    session.add(user1)
    session.flush()

    with pytest.raises(sqlalchemy.exc.IntegrityError) as excinfo:
        user_dup_name = Usuario(username="uniqueuser", password_hash=password_hash, email="other@example.com")
        session.add(user_dup_name)
        session.flush()
    assert "unique constraint" in str(excinfo.value).lower()
    session.rollback()
    print("Excepción de username duplicado capturada correctamente.")

def test_usuario_unique_email(session):
    print("\n--- Test: Unicidad de Usuario (email) ---")
    password_hash = generate_password_hash("password123")
    user1 = Usuario(username="uniqueuser_email", password_hash=password_hash, email="unique_email@example.com")
    session.add(user1)
    session.flush()

    with pytest.raises(sqlalchemy.exc.IntegrityError) as excinfo:
        user_dup_email = Usuario(username="anotheruser_email", password_hash=password_hash, email="unique_email@example.com")
        session.add(user_dup_email)
        session.flush()
    assert "unique constraint" in str(excinfo.value).lower()
    session.rollback()
    print("Excepción de email duplicado capturada correctamente.")


# --- Tests para Clan ---
def test_create_clan(session):
    print("\n--- Test: Crear Clan ---")
    user = Usuario(username="leader_clan_test", password_hash=generate_password_hash("pass"), email="leader_clan@clan.com")
    session.add(user)
    session.flush() # FLUSH 1: user tiene ID

    inv_clan = Inventario(capacidad_slots=50, capacidad_peso_kg=500.0)
    session.add(inv_clan)
    session.flush() # FLUSH 2: inv_clan tiene ID

    clan = Clan(nombre="Clan Alfa", descripcion="Un clan poderoso.", id_lider_usuario=user.id, id_inventario_baluarte=inv_clan.id)
    session.add(clan)
    session.commit() # COMMIT 3: clan tiene ID y relaciones

    assert clan.id is not None
    assert clan.nombre == "Clan Alfa"
    assert clan.lider.username == "leader_clan_test"
    assert clan.inventario_baluarte.capacidad_slots == 50
    print(f"Clan '{clan.nombre}' creado con ID: {clan.id}")

def test_clan_unique_name(session):
    print("\n--- Test: Unicidad de nombre en Clan ---")
    user_leader = Usuario(username="leader2_clan_test", password_hash=generate_password_hash("pass"), email="leader2_clan@clan.com")
    session.add(user_leader)
    session.flush() # FLUSH: user_leader tiene ID

    inv_clan1 = Inventario(capacidad_slots=10)
    session.add(inv_clan1)
    session.flush() # FLUSH: inv_clan1 tiene ID

    clan1 = Clan(nombre="Clan Beta", id_lider_usuario=user_leader.id, id_inventario_baluarte=inv_clan1.id)
    session.add(clan1)
    session.flush() # FLUSH: clan1 tiene ID

    inv_clan2 = Inventario(capacidad_slots=10) # Crear nuevo inventario para el segundo clan
    session.add(inv_clan2)
    session.flush() # FLUSH: inv_clan2 tiene ID

    with pytest.raises(sqlalchemy.exc.IntegrityError) as excinfo:
        clan2 = Clan(nombre="Clan Beta", id_lider_usuario=user_leader.id, id_inventario_baluarte=inv_clan2.id) # Mismo nombre
        session.add(clan2)
        session.flush()
    assert "unique constraint" in str(excinfo.value).lower()
    session.rollback()
    print("Excepción de nombre de Clan duplicado capturada correctamente.")

# --- Tests para Mundo ---
def test_create_mundo_clan_type(session):
    print("\n--- Test: Crear Mundo de Clan ---")
    user = Usuario(username="leader_m_test", password_hash=generate_password_hash("pass"), email="leader_m@clan.com")
    session.add(user)
    session.flush() # FLUSH: user tiene ID

    inv_clan_m = Inventario(capacidad_slots=10)
    session.add(inv_clan_m)
    session.flush() # FLUSH: inv_clan_m tiene ID

    clan = Clan(nombre="Clan del Mundo_test", id_lider_usuario=user.id, id_inventario_baluarte=inv_clan_m.id)
    session.add(clan)
    session.flush() # FLUSH: clan tiene ID

    mundo = Mundo(tipo_mundo="CLAN", id_propietario_clan=clan.id, nombre_mundo="El Gran Valle", semilla_generacion="XYZ123", configuracion_actual={"clima": "templado"})
    session.add(mundo)
    session.commit()
    assert mundo.id is not None
    assert mundo.tipo_mundo == "CLAN"
    assert mundo.propietario_clan.nombre == "Clan del Mundo_test"
    assert mundo.semilla_generacion == "XYZ123"
    print(f"Mundo '{mundo.nombre_mundo}' de tipo '{mundo.tipo_mundo}' creado con ID: {mundo.id}")

def test_create_mundo_personal_type(session):
    print("\n--- Test: Crear Mundo Personal ---")
    user = Usuario(username="personal_player_test", password_hash=generate_password_hash("pass"), email="personal@player.com")
    session.add(user)
    session.flush() # FLUSH: user tiene ID

    mundo = Mundo(tipo_mundo="PERSONAL", id_propietario_usuario=user.id, nombre_mundo="Mi Refugio Secreto", configuracion_actual={"seguridad": "ALTA"})
    session.add(mundo)
    session.commit()
    assert mundo.id is not None
    assert mundo.tipo_mundo == "PERSONAL"
    assert mundo.propietario_usuario.username == "personal_player_test"
    print(f"Mundo '{mundo.nombre_mundo}' de tipo '{mundo.tipo_mundo}' creado con ID: {mundo.id}")

def test_mundo_unique_constraints_clan(session):
    print("\n--- Test: Restricción Única de Mundo (Clan) ---")
    # Creamos un usuario y clan solo para esta sub-prueba
    user_c = Usuario(username="u_clan_unique", password_hash=generate_password_hash("p"), email="u_clan@e.com")
    session.add(user_c)
    session.flush() # Obtener ID para user_c

    inv_c = Inventario(capacidad_slots=1)
    session.add(inv_c)
    session.flush() # Obtener ID para inv_c

    clan_c = Clan(nombre="Clan_Unique_Test", id_lider_usuario=user_c.id, id_inventario_baluarte=inv_c.id)
    session.add(clan_c)
    session.flush() # Obtener ID para clan_c

    # Primer Mundo CLAN (válido)
    mundo_clan_1 = Mundo(tipo_mundo="CLAN", id_propietario_clan=clan_c.id, nombre_mundo="Mundo Clan Unico 1")
    session.add(mundo_clan_1)
    session.flush()
    print("Mundo Clan Unico 1 creado.")

    # Intento duplicado para el mismo clan
    with pytest.raises(sqlalchemy.exc.IntegrityError) as excinfo:
        mundo_clan_dup = Mundo(tipo_mundo="CLAN", id_propietario_clan=clan_c.id, nombre_mundo="Mundo Clan Unico Duplicado")
        session.add(mundo_clan_dup)
        session.flush()
    assert "unique constraint" in str(excinfo.value).lower()
    session.rollback() # Limpia la transacción después del fallo
    print("Excepción de Mundo CLAN duplicado capturada correctamente.")


# --- Tests para Bastion ---
def test_create_bastion(session):
    print("\n--- Test: Crear Bastion (Personaje del Jugador) ---")
    user = Usuario(username="player_char_test_create", password_hash=generate_password_hash("pass"), email="player_char_create@example.com")
    session.add(user)
    session.flush() # FLUSH: user tiene ID
    
    inv_clan = Inventario(capacidad_slots=1)
    session.add(inv_clan)
    session.flush() # FLUSH: inv_clan tiene ID

    clan = Clan(nombre="Clan Char_test_create", id_lider_usuario=user.id, id_inventario_baluarte=inv_clan.id)
    session.add(clan)
    session.flush() # FLUSH: clan tiene ID

    inv_bastion = Inventario(capacidad_slots=15, capacidad_peso_kg=30.0)
    dano_bastion = Daño(salud_actual=100, salud_max=100)
    session.add_all([inv_bastion, dano_bastion])
    session.flush() # FLUSH: inv_bastion, dano_bastion tienen IDs
    
    cv_bastion = CriaturaViva_Base(hambre_actual=80, hambre_max=100, dano_ataque_base=10, velocidad_movimiento=5.0, id_danio=dano_bastion.id, id_inventario=inv_bastion.id)
    session.add(cv_bastion)
    session.flush() # FLUSH: cv_bastion tiene ID

    bastion = Bastion(
        id_usuario=user.id,
        id_clan=clan.id,
        nombre_personaje="MiHeroe_test_create",
        nivel=1,
        experiencia=0,
        posicion_actual={"x": 10, "y": 0, "z": 10, "mundo": "CLAN_MUNDO_ACTUAL"},
        habilidades_aprendidas=[],
        id_criatura_viva_base=cv_bastion.id
    )
    session.add(bastion)
    session.commit()

    assert bastion.id is not None
    assert bastion.nombre_personaje == "MiHeroe_test_create"
    assert bastion.usuario.username == "player_char_test_create"
    assert bastion.clan.nombre == "Clan Char_test_create"
    assert bastion.criatura_viva_base.danio.salud_max == 100
    print(f"Bastion '{bastion.nombre_personaje}' creado con ID: {bastion.id}")

def test_bastion_unique_user_id(session):
    print("\n--- Test: Unicidad de id_usuario en Bastion ---")
    user1 = Usuario(username="user_for_bastion_unique", password_hash=generate_password_hash("pass"), email="u1_unique@test.com")
    session.add(user1)
    session.flush() # FLUSH: user1 tiene ID
    
    # Crear componentes para el primer Bastion (todos flusheados para obtener IDs)
    inv_clan1 = Inventario(capacidad_slots=1)
    session.add(inv_clan1)
    session.flush() # FLUSH: inv_clan1 tiene ID
    
    clan1 = Clan(nombre="ClanUser1_unique", id_lider_usuario=user1.id, id_inventario_baluarte=inv_clan1.id)
    session.add(clan1)
    session.flush() # FLUSH: clan1 tiene ID

    inv_bastion1 = Inventario(capacidad_slots=15)
    dano_bastion1 = Daño(salud_actual=100, salud_max=100)
    session.add_all([inv_bastion1, dano_bastion1])
    session.flush() # FLUSH: inv_bastion1, dano_bastion1 tienen IDs

    cv_bastion1 = CriaturaViva_Base(hambre_actual=10, hambre_max=10, dano_ataque_base=1, velocidad_movimiento=1.0, id_danio=dano_bastion1.id, id_inventario=inv_bastion1.id)
    session.add(cv_bastion1)
    session.flush() # FLUSH: cv_bastion1 tiene ID

    bastion1 = Bastion(id_usuario=user1.id, nombre_personaje="Char1_unique", id_criatura_viva_base=cv_bastion1.id)
    session.add(bastion1)
    session.flush() # FLUSH para que bastion1 exista en la DB
    print(f"Primer Bastion creado para user {user1.username}.")

    # Intenta crear un segundo Bastion para el mismo usuario (debe fallar)
    print("Intentando crear segundo Bastion para el mismo usuario...")
    inv_bastion2 = Inventario(capacidad_slots=15)
    dano_bastion2 = Daño(salud_actual=100, salud_max=100)
    session.add_all([inv_bastion2, dano_bastion2])
    session.flush()

    cv_bastion2 = CriaturaViva_Base(hambre_actual=10, hambre_max=10, dano_ataque_base=1, velocidad_movimiento=1.0, id_danio=dano_bastion2.id, id_inventario=inv_bastion2.id)
    session.add(cv_bastion2)
    session.flush()

    with pytest.raises(sqlalchemy.exc.IntegrityError) as excinfo:
        bastion2 = Bastion(id_usuario=user1.id, nombre_personaje="Char2_unique", id_criatura_viva_base=cv_bastion2.id)
        session.add(bastion2)
        session.flush() # Aquí debería fallar por la unicidad

    assert "unique constraint" in str(excinfo.value).lower()
    session.rollback() # Limpia la transacción después del fallo
    print("Excepción de id_usuario duplicado en Bastion capturada correctamente.")