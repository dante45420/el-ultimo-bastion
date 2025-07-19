# el-ultimo-bastion/backend/tests/test_tanda5_game_state_level4.py
import pytest
from app.models import (
    Usuario, Clan, Bastion, Mundo, InstanciaNPC, InstanciaAnimal, TipoNPC, TipoAnimal, TipoMision, TipoEventoGlobal, TipoObjeto,
    Inventario, Daño, CriaturaViva_Base, MisionActiva, EventoGlobalActivo, InteraccionComercio
)
import sqlalchemy.exc
from werkzeug.security import generate_password_hash
from datetime import datetime, timedelta
from decimal import Decimal
from sqlalchemy.orm.attributes import flag_modified # <--- AÑADIR/VERIFICAR ESTA IMPORTACIÓN


# Fixture para crear dependencias comunes para los tests de esta tanda (copiado y adaptado)
@pytest.fixture
def common_dependencies_tanda5(session):
    # Usuarios
    user_admin = Usuario(username="admin_t5", password_hash=generate_password_hash("pass"), email="admin_t5@example.com")
    user_player = Usuario(username="player_t5", password_hash=generate_password_hash("pass"), email="player_t5@example.com")
    session.add_all([user_admin, user_player])
    session.flush()

    # Inventarios y Daños para Clanes, Bastiones, etc.
    inv_clan = Inventario(capacidad_slots=10)
    session.add(inv_clan)
    session.flush()
    clan = Clan(nombre="ClanT5", id_lider_usuario=user_admin.id, id_inventario_baluarte=inv_clan.id)
    session.add(clan)
    session.flush()

    inv_bastion = Inventario(capacidad_slots=15)
    dano_bastion = Daño(salud_actual=100, salud_max=100)
    session.add_all([inv_bastion, dano_bastion])
    session.flush()
    cv_bastion = CriaturaViva_Base(hambre_actual=80, hambre_max=100, dano_ataque_base=10, velocidad_movimiento=5.0, id_danio=dano_bastion.id, id_inventario=inv_bastion.id)
    session.add(cv_bastion)
    session.flush()
    bastion = Bastion(id_usuario=user_player.id, id_clan=clan.id, nombre_personaje="HeroT5", id_criatura_viva_base=cv_bastion.id, posicion_actual={"x": 0, "y": 0, "z": 0, "mundo": "CLAN"})
    session.add(bastion)
    session.flush()

    # Mundos
    mundo_clan = Mundo(tipo_mundo="CLAN", id_propietario_clan=clan.id, nombre_mundo="MundoT5_Clan")
    mundo_personal = Mundo(tipo_mundo="PERSONAL", id_propietario_usuario=user_player.id, nombre_mundo="MundoT5_Personal")
    session.add_all([mundo_clan, mundo_personal])
    session.flush()

    # Tipos (mínimo necesario para FKs)
    obj_madera = TipoObjeto(nombre="Madera_T5", tipo_objeto="RECURSO")
    obj_piedra = TipoObjeto(nombre="Piedra_T5", tipo_objeto="RECURSO")
    obj_cuero = TipoObjeto(nombre="Cuero_T5", tipo_objeto="RECURSO")
    obj_oro = TipoObjeto(nombre="Oro_T5", tipo_objeto="TESORO")

    tipo_npc_generico = TipoNPC(nombre="NPC_Gen_T5", rol_npc="GENERICO")
    tipo_animal_lobo = TipoAnimal(nombre="Lobo_T5", comportamiento_tipo="HOSTIL")
    
    tipo_mision_test = TipoMision(
        nombre="Mision_Test_T5", 
        descripcion="Desafío de prueba.", 
        nivel_requerido=1, 
        objetivos={"derrotar_npcs": [{"id_tipo_npc": tipo_npc_generico.id, "cantidad": 1}]}, 
        recompensa={"xp": 10}
    )
    tipo_evento_test = TipoEventoGlobal(
        nombre="Evento_Test_T5", 
        descripcion="Un evento de prueba.", 
        fase_activacion="VIERNES", 
        duracion_horas=24
    )

    session.add_all([obj_madera, obj_piedra, obj_cuero, obj_oro, tipo_npc_generico, tipo_animal_lobo, tipo_mision_test, tipo_evento_test])
    session.flush()
    
    # Crear un NPC para interacciones de comercio
    inv_npc_comerciante = Inventario(capacidad_slots=10)
    dano_npc_comerciante = Daño(salud_actual=100, salud_max=100)
    session.add_all([inv_npc_comerciante, dano_npc_comerciante])
    session.flush()
    cv_npc_comerciante = CriaturaViva_Base(hambre_actual=50, hambre_max=50, dano_ataque_base=5, velocidad_movimiento=3.0, id_danio=dano_npc_comerciante.id, id_inventario=inv_npc_comerciante.id)
    session.add(cv_npc_comerciante); session.flush()
    inst_npc_comerciante = InstanciaNPC(
        id_tipo_npc=tipo_npc_generico.id, # Usamos el genérico, aunque el rol sea "COMERCIANTE" para el test
        id_criatura_viva_base=cv_npc_comerciante.id,
        id_mundo=mundo_clan.id,
        posicion={"x": 50, "y": 0, "z": 50},
        esta_vivo=True
    )
    session.add(inst_npc_comerciante); session.flush()

    return {
        "user_admin": user_admin, "user_player": user_player, "clan": clan,
        "bastion": bastion, "mundo_clan": mundo_clan, "mundo_personal": mundo_personal,
        "tipo_mision_test": tipo_mision_test, "tipo_evento_test": tipo_evento_test,
        "inst_npc_comerciante": inst_npc_comerciante, "obj_oro": obj_oro, "obj_cuero": obj_cuero,
        "tipo_npc_generico": tipo_npc_generico, "tipo_animal_lobo": tipo_animal_lobo
    }


# --- Tests para MisionActiva ---
def test_create_mision_activa(session, common_dependencies_tanda5):
    print("\n--- Test: Crear MisionActiva ---")
    bastion = common_dependencies_tanda5["bastion"]
    tipo_mision_test = common_dependencies_tanda5["tipo_mision_test"]

    mision_activa = MisionActiva(
        id_tipo_mision=tipo_mision_test.id,
        id_bastion=bastion.id,
        estado_mision="ACTIVA",
        progreso_objetivos={"derrotar_npcs": [{"id_tipo_npc": 1, "cantidad_actual": 0, "cantidad_requerida": 1}]} # Ejemplo de objetivo
    )
    session.add(mision_activa)
    session.commit()

    assert mision_activa.id is not None
    assert mision_activa.bastion.nombre_personaje == "HeroT5"
    assert mision_activa.tipo_mision.nombre == "Mision_Test_T5"
    assert mision_activa.estado_mision == "ACTIVA"
    assert mision_activa.progreso_objetivos["derrotar_npcs"][0]["cantidad_actual"] == 0
    print(f"MisionActiva '{mision_activa.tipo_mision.nombre}' creada para '{mision_activa.bastion.nombre_personaje}'.")

def test_update_mision_progress(session, common_dependencies_tanda5):
    print("\n--- Test: Actualizar Progreso de MisionActiva ---")
    bastion = common_dependencies_tanda5["bastion"]
    # Nota: Asegúrate que el id_tipo_objeto usado en objetivos existe.
    obj_dummy = TipoObjeto(nombre="DummyItem", tipo_objeto="RECURSO")
    session.add(obj_dummy); session.flush()

    tipo_mision_test = TipoMision(nombre="Mision_Update", nivel_requerido=1, objetivos={"recolectar": [{"id_tipo_objeto": obj_dummy.id, "cantidad": 5}]}, recompensa={})
    session.add(tipo_mision_test); session.flush()
    
    mision_activa = MisionActiva(id_tipo_mision=tipo_mision_test.id, id_bastion=bastion.id, estado_mision="ACTIVA", progreso_objetivos={"recolectar": [{"id_tipo_objeto": obj_dummy.id, "cantidad_actual": 2, "cantidad_requerida": 5}]})
    session.add(mision_activa)
    session.commit() # <--- Primer commit para persistir el objeto

    print(f"DEBUG: Progreso antes de la actualización (objeto en memoria): {mision_activa.progreso_objetivos['recolectar'][0]['cantidad_actual']}")

    # Simular progreso
    mision_activa.progreso_objetivos["recolectar"][0]["cantidad_actual"] = 4
    # CLAVE: Forzar a SQLAlchemy a reconocer que el campo JSONB ha sido modificado
    flag_modified(mision_activa, "progreso_objetivos") # <--- AÑADIR ESTA LÍNEA CLAVE
    session.add(mision_activa) # Marcar el objeto como modificado (aunque flag_modified ya lo hace dirty)
    session.commit() # <--- Segundo commit para persistir el cambio en JSONB

    print(f"DEBUG: Progreso después del commit (objeto en memoria): {mision_activa.progreso_objetivos['recolectar'][0]['cantidad_actual']}")

    # CLAVE: Obtener una nueva instancia para asegurar la lectura desde la DB
    # Aunque expire() y refresh() a veces funcionan, get() es el más robusto aquí.
    retrieved_mision = session.get(MisionActiva, mision_activa.id) # Obtener una nueva instancia

    print(f"DEBUG: Progreso después de recuperar de la DB: {retrieved_mision.progreso_objetivos['recolectar'][0]['cantidad_actual']}")

    assert retrieved_mision.progreso_objetivos["recolectar"][0]["cantidad_actual"] == 4
    print(f"Progreso de MisionActiva actualizado a {retrieved_mision.progreso_objetivos['recolectar'][0]['cantidad_actual']}.")



# --- Tests para EventoGlobalActivo ---
def test_create_evento_global_activo(session, common_dependencies_tanda5):
    print("\n--- Test: Crear EventoGlobalActivo ---")
    mundo_clan = common_dependencies_tanda5["mundo_clan"]
    tipo_evento_test = common_dependencies_tanda5["tipo_evento_test"]

    # Simular una fecha de inicio y fin de fase
    fecha_inicio = datetime.now()
    fecha_fin_fase = fecha_inicio + timedelta(hours=24)

    evento_activo = EventoGlobalActivo(
        id_tipo_evento_global=tipo_evento_test.id,
        id_mundo_clan=mundo_clan.id,
        fase_actual="MISTERIO",
        fecha_inicio=fecha_inicio,
        fecha_fin_fase_actual=fecha_fin_fase,
        estado_logro_clanes={"clan_id_1": "EN_PROGRESO"},
        consecuencias_aplicadas=False
    )
    session.add(evento_activo)
    session.commit()

    assert evento_activo.id is not None
    assert evento_activo.tipo_evento_global.nombre == "Evento_Test_T5"
    assert evento_activo.mundo_clan.nombre_mundo == "MundoT5_Clan"
    assert evento_activo.fase_actual == "MISTERIO"
    assert evento_activo.consecuencias_aplicadas is False
    print(f"EventoGlobalActivo '{evento_activo.tipo_evento_global.nombre}' creado con ID: {evento_activo.id}.")

def test_update_evento_global_fase(session, common_dependencies_tanda5):
    print("\n--- Test: Actualizar Fase de EventoGlobalActivo ---")
    mundo_clan = common_dependencies_tanda5["mundo_clan"]
    tipo_evento_test = TipoEventoGlobal(nombre="Evento_Update", fase_activacion="LUNES", duracion_horas=12)
    session.add(tipo_evento_test); session.flush()

    evento_activo = EventoGlobalActivo(id_tipo_evento_global=tipo_evento_test.id, id_mundo_clan=mundo_clan.id, fase_actual="MISTERIO")
    session.add(evento_activo); session.commit() # <--- Primer commit para persistir el objeto

    evento_activo.fase_actual = "EVENTO_VIVO"
    evento_activo.fecha_fin_fase_actual = datetime.now() + timedelta(hours=10)
    evento_activo.estado_logro_clanes = {"clan_id_1": "EXITO"}
    session.add(evento_activo) # Marcar el objeto como modificado
    session.commit() # <--- Segundo commit para persistir los cambios

    session.refresh(evento_activo) # <--- AÑADIR/VERIFICAR ESTA LÍNEA CLAVE, DEBE IR DESPUÉS DEL COMMIT
    retrieved_evento = session.get(EventoGlobalActivo, evento_activo.id) # Opcional: obtener de nuevo, pero refresh es suficiente

    assert retrieved_evento.fase_actual == "EVENTO_VIVO"
    assert retrieved_evento.estado_logro_clanes["clan_id_1"] == "EXITO"
    print(f"Fase de EventoGlobalActivo actualizada a '{retrieved_evento.fase_actual}'.")


# --- Tests para InteraccionComercio ---
def test_create_interaccion_comercio(session, common_dependencies_tanda5):
    print("\n--- Test: Crear InteraccionComercio ---")
    bastion = common_dependencies_tanda5["bastion"]
    inst_npc_comerciante = common_dependencies_tanda5["inst_npc_comerciante"]
    obj_oro = common_dependencies_tanda5["obj_oro"]
    obj_cuero = common_dependencies_tanda5["obj_cuero"]

    interaccion = InteraccionComercio(
        id_instancia_npc_comerciante=inst_npc_comerciante.id,
        id_bastion_comprador=bastion.id,
        id_tipo_objeto_comprado=obj_oro.id,
        cantidad_comprada=10,
        id_tipo_objeto_vendido=obj_cuero.id,
        cantidad_vendida=1,
        precio_total=Decimal('100.00')
    )
    session.add(interaccion)
    session.commit()

    assert interaccion.id is not None
    assert interaccion.instancia_npc_comerciante.id == inst_npc_comerciante.id
    assert interaccion.bastion_comprador.id == bastion.id
    assert interaccion.tipo_objeto_comprado.nombre == "Oro_T5"
    assert interaccion.cantidad_comprada == 10
    assert interaccion.precio_total == Decimal('100.00')
    print(f"InteraccionComercio creada con ID: {interaccion.id}.")

def test_interaccion_comercio_only_buy(session, common_dependencies_tanda5):
    print("\n--- Test: InteraccionComercio (solo compra) ---")
    bastion = common_dependencies_tanda5["bastion"]
    inst_npc_comerciante = common_dependencies_tanda5["inst_npc_comerciante"]
    obj_pocion = TipoObjeto(nombre="Pocion_T5", tipo_objeto="POCION"); session.add(obj_pocion); session.flush()

    interaccion = InteraccionComercio(
        id_instancia_npc_comerciante=inst_npc_comerciante.id,
        id_bastion_comprador=bastion.id,
        id_tipo_objeto_comprado=obj_pocion.id,
        cantidad_comprada=2,
        precio_total=Decimal('50.00')
        # id_tipo_objeto_vendido y cantidad_vendida son NULL en este caso
    )
    session.add(interaccion)
    session.commit()

    assert interaccion.id is not None
    assert interaccion.tipo_objeto_comprado.nombre == "Pocion_T5"
    assert interaccion.id_tipo_objeto_vendido is None
    assert interaccion.cantidad_vendida is None
    print(f"InteraccionComercio (solo compra) creada con ID: {interaccion.id}.")