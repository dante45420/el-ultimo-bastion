# el-ultimo-bastion/backend/tests/test_tanda4_game_state_level2_3.py
import pytest
from app.models import (
    Usuario, Clan, Bastion, Mundo, InstanciaAldea, InstanciaRecursoTerreno,
    InstanciaNPC, InstanciaAnimal, InstanciaEdificio,
    Inventario, Daño, CriaturaViva_Base,
    TipoObjeto, TipoEdificio, TipoNPC, TipoAnimal, TipoRecursoTerreno, TipoLootTable
)
import sqlalchemy.exc
from werkzeug.security import generate_password_hash

# Fixture para crear dependencias comunes para los tests de esta tanda
@pytest.fixture
def common_dependencies_tanda4(session):
    # Usuarios
    user_admin = Usuario(username="admin_t4", password_hash=generate_password_hash("pass"), email="admin_t4@example.com")
    user_player = Usuario(username="player_t4", password_hash=generate_password_hash("pass"), email="player_t4@example.com")
    session.add_all([user_admin, user_player])
    session.flush()

    # Inventarios y Daños para Clanes, Bastiones, etc.
    inv_clan = Inventario(capacidad_slots=10)
    session.add(inv_clan)
    session.flush()
    clan = Clan(nombre="ClanT4", id_lider_usuario=user_admin.id, id_inventario_baluarte=inv_clan.id)
    session.add(clan)
    session.flush()

    inv_bastion = Inventario(capacidad_slots=15)
    dano_bastion = Daño(salud_actual=100, salud_max=100)
    session.add_all([inv_bastion, dano_bastion])
    session.flush()
    cv_bastion = CriaturaViva_Base(hambre_actual=80, hambre_max=100, dano_ataque_base=10, velocidad_movimiento=5.0, id_danio=dano_bastion.id, id_inventario=inv_bastion.id)
    session.add(cv_bastion)
    session.flush()
    bastion = Bastion(id_usuario=user_player.id, id_clan=clan.id, nombre_personaje="HeroT4", id_criatura_viva_base=cv_bastion.id, posicion_actual={"x": 0, "y": 0, "z": 0, "mundo": "CLAN"})
    session.add(bastion)
    session.flush()

    # Mundos
    mundo_clan = Mundo(tipo_mundo="CLAN", id_propietario_clan=clan.id, nombre_mundo="MundoT4_Clan")
    mundo_personal = Mundo(tipo_mundo="PERSONAL", id_propietario_usuario=user_player.id, nombre_mundo="MundoT4_Personal")
    session.add_all([mundo_clan, mundo_personal])
    session.flush()

    # Tipos (minimo necesario para FKs)
    obj_madera = TipoObjeto(nombre="Madera_T4", tipo_objeto="RECURSO")
    obj_piedra = TipoObjeto(nombre="Piedra_T4", tipo_objeto="RECURSO")
    obj_cuero = TipoObjeto(nombre="Cuero_T4", tipo_objeto="RECURSO")
    edif_casa = TipoEdificio(nombre="Casa_T4", max_por_aldea=1, id_grafico="house_t4", recursos_costo=[{"id_tipo_objeto": obj_madera.id, "cantidad": 10}])
    loot_table_test = TipoLootTable(nombre="LootTest_T4", items=[{"id_tipo_objeto": obj_cuero.id, "probabilidad": 1.0}])
    tipo_npc_generico = TipoNPC(nombre="NPC_Gen_T4", rol_npc="GENERICO")
    tipo_animal_ciervo = TipoAnimal(nombre="Ciervo_T4", comportamiento_tipo="PACIFICO")
    tipo_recurso_arbol = TipoRecursoTerreno(nombre="Arbol_T4", salud_base=10, recursos_minables=[{"id_tipo_objeto": obj_madera.id, "cantidad_min": 1}])
    session.add_all([obj_madera, obj_piedra, obj_cuero, edif_casa, loot_table_test, tipo_npc_generico, tipo_animal_ciervo, tipo_recurso_arbol])
    session.flush()
    
    return {
        "user_admin": user_admin, "user_player": user_player, "clan": clan,
        "bastion": bastion, "mundo_clan": mundo_clan, "mundo_personal": mundo_personal,
        "obj_madera": obj_madera, "edif_casa": edif_casa, "loot_table_test": loot_table_test,
        "tipo_npc_generico": tipo_npc_generico, "tipo_animal_ciervo": tipo_animal_ciervo,
        "tipo_recurso_arbol": tipo_recurso_arbol
    }


# --- Tests para InstanciaAldea ---
def test_create_instancia_aldea(session, common_dependencies_tanda4):
    print("\n--- Test: Crear InstanciaAldea ---")
    mundo_clan = common_dependencies_tanda4["mundo_clan"]
    clan = common_dependencies_tanda4["clan"]

    inv_aldea = Inventario(capacidad_slots=100, capacidad_peso_kg=1000.0)
    dano_aldea = Daño(salud_actual=500, salud_max=500)
    session.add_all([inv_aldea, dano_aldea])
    session.flush()

    aldea = InstanciaAldea(
        nombre="Aldea T4",
        id_mundo=mundo_clan.id,
        posicion_central={"x": 100, "y": 0, "z": 100},
        id_clan_propietario=clan.id,
        id_inventario_aldea=inv_aldea.id,
        id_danio_estructura_central=dano_aldea.id
    )
    session.add(aldea)
    session.commit()

    assert aldea.id is not None
    assert aldea.nombre == "Aldea T4"
    assert aldea.mundo_rel.nombre_mundo == "MundoT4_Clan"
    assert aldea.clan_propietario.nombre == "ClanT4"
    assert aldea.inventario_aldea.capacidad_slots == 100
    assert aldea.danio_estructura_central.salud_max == 500
    print(f"InstanciaAldea '{aldea.nombre}' creada con ID: {aldea.id}")


# --- Tests para InstanciaRecursoTerreno ---
def test_create_instancia_recurso_terreno(session, common_dependencies_tanda4):
    print("\n--- Test: Crear InstanciaRecursoTerreno ---")
    mundo_clan = common_dependencies_tanda4["mundo_clan"]
    tipo_recurso_arbol = common_dependencies_tanda4["tipo_recurso_arbol"]

    dano_recurso = Daño(salud_actual=tipo_recurso_arbol.salud_base, salud_max=tipo_recurso_arbol.salud_base)
    session.add(dano_recurso)
    session.flush()

    recurso = InstanciaRecursoTerreno(
        id_tipo_recurso_terreno=tipo_recurso_arbol.id,
        id_mundo=mundo_clan.id,
        posicion={"x": 10, "y": 0, "z": 10},
        esta_agotado=False,
        id_danio=dano_recurso.id
    )
    session.add(recurso)
    session.commit()

    assert recurso.id is not None
    assert recurso.tipo_recurso_terreno.nombre == "Arbol_T4"
    assert recurso.mundo.nombre_mundo == "MundoT4_Clan"
    assert recurso.danio.salud_max == tipo_recurso_arbol.salud_base
    print(f"InstanciaRecursoTerreno '{recurso.tipo_recurso_terreno.nombre}' creada con ID: {recurso.id}")


# --- Tests para InstanciaNPC ---
def test_create_instancia_npc(session, common_dependencies_tanda4):
    print("\n--- Test: Crear InstanciaNPC ---")
    mundo_clan = common_dependencies_tanda4["mundo_clan"]
    tipo_npc_generico = common_dependencies_tanda4["tipo_npc_generico"]

    inv_npc = Inventario(capacidad_slots=5)
    dano_npc = Daño(salud_actual=50, salud_max=50)
    session.add_all([inv_npc, dano_npc])
    session.flush()
    cv_npc = CriaturaViva_Base(hambre_actual=50, hambre_max=50, dano_ataque_base=5, velocidad_movimiento=3.0, id_danio=dano_npc.id, id_inventario=inv_npc.id)
    session.add(cv_npc)
    session.flush()

    npc_instance = InstanciaNPC(
        id_tipo_npc=tipo_npc_generico.id,
        id_criatura_viva_base=cv_npc.id,
        id_mundo=mundo_clan.id,
        posicion={"x": 20, "y": 0, "z": 20},
        esta_vivo=True
    )
    session.add(npc_instance)
    session.commit()

    assert npc_instance.id is not None
    assert npc_instance.tipo_npc.nombre == "NPC_Gen_T4"
    assert npc_instance.criatura_viva_base.id == cv_npc.id
    assert npc_instance.mundo.nombre_mundo == "MundoT4_Clan"
    assert npc_instance.esta_vivo is True
    print(f"InstanciaNPC '{npc_instance.tipo_npc.nombre}' creada con ID: {npc_instance.id}")

def test_instancia_npc_with_aldea_owner(session, common_dependencies_tanda4):
    print("\n--- Test: Crear InstanciaNPC con Aldea como propietario ---")
    mundo_clan = common_dependencies_tanda4["mundo_clan"]
    clan = common_dependencies_tanda4["clan"]
    tipo_npc_generico = common_dependencies_tanda4["tipo_npc_generico"]

    # Crear Aldea
    inv_aldea = Inventario(capacidad_slots=10); dano_aldea = Daño(salud_actual=100, salud_max=100)
    session.add_all([inv_aldea, dano_aldea]); session.flush()
    aldea = InstanciaAldea(nombre="AldeaNPC", id_mundo=mundo_clan.id, posicion_central={"x":1,"y":1,"z":1}, id_clan_propietario=clan.id, id_inventario_aldea=inv_aldea.id, id_danio_estructura_central=dano_aldea.id)
    session.add(aldea); session.flush()

    # Crear componentes para NPC
    inv_npc = Inventario(capacidad_slots=5); dano_npc = Daño(salud_actual=50, salud_max=50)
    session.add_all([inv_npc, dano_npc]); session.flush()
    cv_npc = CriaturaViva_Base(hambre_actual=50, hambre_max=50, dano_ataque_base=5, velocidad_movimiento=3.0, id_danio=dano_npc.id, id_inventario=inv_npc.id)
    session.add(cv_npc); session.flush()

    npc_instance = InstanciaNPC(
        id_tipo_npc=tipo_npc_generico.id,
        id_criatura_viva_base=cv_npc.id,
        id_mundo=mundo_clan.id,
        posicion={"x": 22, "y": 0, "z": 22},
        id_aldea_pertenece=aldea.id # Asignar a la aldea
    )
    session.add(npc_instance)
    session.commit()
    assert npc_instance.aldea_pertenece.nombre == "AldeaNPC"
    print(f"InstanciaNPC '{npc_instance.tipo_npc.nombre}' creada con Aldea '{aldea.nombre}'.")


# --- Tests para InstanciaAnimal ---
def test_create_instancia_animal(session, common_dependencies_tanda4):
    print("\n--- Test: Crear InstanciaAnimal ---")
    mundo_clan = common_dependencies_tanda4["mundo_clan"]
    tipo_animal_ciervo = common_dependencies_tanda4["tipo_animal_ciervo"]
    user_player = common_dependencies_tanda4["user_player"]

    inv_animal = Inventario(capacidad_slots=1)
    dano_animal = Daño(salud_actual=40, salud_max=40)
    session.add_all([inv_animal, dano_animal])
    session.flush()
    cv_animal = CriaturaViva_Base(hambre_actual=60, hambre_max=60, dano_ataque_base=0, velocidad_movimiento=6.0, id_danio=dano_animal.id, id_inventario=inv_animal.id)
    session.add(cv_animal)
    session.flush()

    animal_instance = InstanciaAnimal(
        id_tipo_animal=tipo_animal_ciervo.id,
        id_criatura_viva_base=cv_animal.id,
        id_mundo=mundo_clan.id,
        posicion={"x": 30, "y": 0, "z": 30},
        nivel_carino=0,
        id_dueno_usuario=user_player.id # Ejemplo de dueño
    )
    session.add(animal_instance)
    session.commit()

    assert animal_instance.id is not None
    assert animal_instance.tipo_animal.nombre == "Ciervo_T4"
    assert animal_instance.criatura_viva_base.id == cv_animal.id
    assert animal_instance.dueno_usuario.username == "player_t4"
    print(f"InstanciaAnimal '{animal_instance.tipo_animal.nombre}' creada con ID: {animal_instance.id} y dueño.")


# --- Tests para InstanciaEdificio ---
def test_create_instancia_edificio(session, common_dependencies_tanda4):
    print("\n--- Test: Crear InstanciaEdificio ---")
    mundo_clan = common_dependencies_tanda4["mundo_clan"]
    clan = common_dependencies_tanda4["clan"]
    edif_casa_tipo = common_dependencies_tanda4["edif_casa"]

    # Crear Aldea para que el edificio pertenezca a ella
    inv_aldea = Inventario(capacidad_slots=10); dano_aldea = Daño(salud_actual=100, salud_max=100)
    session.add_all([inv_aldea, dano_aldea]); session.flush()
    aldea = InstanciaAldea(nombre="AldeaEdif", id_mundo=mundo_clan.id, posicion_central={"x":1,"y":1,"z":1}, id_clan_propietario=clan.id, id_inventario_aldea=inv_aldea.id, id_danio_estructura_central=dano_aldea.id)
    session.add(aldea); session.flush()

    # Componentes de Daño para el edificio
    dano_edificio = Daño(salud_actual=200, salud_max=200)
    session.add(dano_edificio)
    session.flush()

    edificio = InstanciaEdificio(
        id_tipo_edificio=edif_casa_tipo.id,
        id_aldea=aldea.id,
        posicion_relativa={"x": 5, "y": 0, "z": 5},
        esta_destruido=False,
        estado_construccion="COMPLETO",
        id_danio=dano_edificio.id
    )
    session.add(edificio)
    session.commit()

    assert edificio.id is not None
    assert edificio.tipo_edificio.nombre == "Casa_T4"
    assert edificio.aldea.nombre == "AldeaEdif"
    assert edificio.danio.salud_max == 200
    print(f"InstanciaEdificio '{edificio.tipo_edificio.nombre}' creada con ID: {edificio.id} en '{edificio.aldea.nombre}'.")