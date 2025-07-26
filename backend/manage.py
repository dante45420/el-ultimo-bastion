# el-ultimo-bastion/backend/manage.py

import click
import os
from datetime import datetime, timedelta
from decimal import Decimal, ROUND_DOWN
from app import create_app, db
from app.models import (
    Inventario, Daño, CriaturaViva_Base,
    TipoObjeto, TipoEdificio, TipoHabilidad, TipoComercianteOferta,
    TipoNPC, TipoAnimal, TipoRecursoTerreno, TipoMision, TipoEventoGlobal,
    TipoPista, TipoLootTable,
    Usuario, Clan, Bastion, Mundo, InstanciaNPC, InstanciaAnimal,
    InstanciaRecursoTerreno, InstanciaAldea, InstanciaEdificio,
    MisionActiva, EventoGlobalActivo, InteraccionComercio
)
from werkzeug.security import generate_password_hash

app = create_app()

@click.group()
def cli():
    """Comandos de línea para la gestión de la base de datos y la aplicación."""
    pass

@cli.command('create_all_tables')
@click.option('--force', is_flag=True, help='Elimina las tablas existentes antes de crearlas. ¡Úsalo con cautela!')
def create_all_tables(force):
    """Crea todas las tablas de la base de datos usando SQLAlchemy directamente."""
    with app.app_context():
        if force:
            print("Eliminando todas las tablas existentes (FORZADO)...")
            db.drop_all()
            print("Tablas eliminadas.")
        print("Creando todas las tablas...")
        db.create_all()
        print("Tablas creadas exitosamente.")

@cli.command('drop_all_tables')
def drop_all_tables():
    """Elimina todas las tablas de la base de datos usando SQLAlchemy directamente."""
    with app.app_context():
        if click.confirm('¿Estás seguro de que quieres eliminar TODAS las tablas? Esta acción es irreversible.'):
            print("Eliminando todas las tablas...")
            db.drop_all()
            print("Tablas eliminadas exitosamente.")
        else:
            print("Operación cancelada.")

@cli.command('seed')
def seed():
    """
    Puebla la base de datos con datos iniciales de tipos y algunos ejemplos de instancia.
    """
    with app.app_context():
        print("=====================================================")
        print("= INICIANDO PROCESO DE SEEDING COMPLETO DE JUEGO    =")
        print("=====================================================")

        # --- 1. Limpieza de tablas ---
        print("\n[Paso 1/4] Limpiando tablas de instancias y tipos...")
        InteraccionComercio.query.delete()
        MisionActiva.query.delete()
        EventoGlobalActivo.query.delete()
        InstanciaEdificio.query.delete()
        InstanciaNPC.query.delete()
        InstanciaAnimal.query.delete()
        InstanciaRecursoTerreno.query.delete()
        InstanciaAldea.query.delete()
        Mundo.query.delete()
        Bastion.query.delete()
        Clan.query.delete()
        Usuario.query.delete()

        CriaturaViva_Base.query.delete()
        Daño.query.delete()
        Inventario.query.delete()

        TipoComercianteOferta.query.delete()
        TipoMision.query.delete()
        TipoPista.query.delete()
        TipoEventoGlobal.query.delete()
        TipoNPC.query.delete()
        TipoAnimal.query.delete()
        TipoRecursoTerreno.query.delete()
        TipoHabilidad.query.delete()
        TipoEdificio.query.delete()
        TipoLootTable.query.delete()
        TipoObjeto.query.delete()

        db.session.commit()
        print("-> Base de datos limpia de datos de juego.")

        # --- 2. Creación de Tipos (Configuración) y Componentes Base ---
        print("\n[Paso 2/4] Creando Tipos de Objetos, Habilidades, Loot Tables, Edificios, Animales, Recursos Terreno, NPCs, Comerciante Ofertas, Misiones, Eventos Globales, Pistas y Componentes Base...")

        # Objetos Básicos
        obj_madera = TipoObjeto(nombre="Madera", descripcion="Bloque de madera básico.", id_grafico="wood_log", tipo_objeto="RECURSO", es_apilable=True, peso_unidad=1.0)
        obj_piedra = TipoObjeto(nombre="Piedra", descripcion="Bloque de piedra básico.", id_grafico="stone_block", tipo_objeto="RECURSO", es_apilable=True, peso_unidad=2.0)
        obj_espada_hierro = TipoObjeto(nombre="Espada de Hierro", descripcion="Espada básica de hierro.", id_grafico="iron_sword", tipo_objeto="ARMA", es_apilable=False, peso_unidad=5.0, valores_especificos={"dano_min": 10, "dano_max": 15, "tipo_dano": "CORTANTE"})
        obj_pocion_curacion = TipoObjeto(nombre="Poción de Curación", descripcion="Restaura un poco de salud.", id_grafico="hp_potion", tipo_objeto="POCION", es_apilable=True, peso_unidad=0.5, valores_especificos={"efecto": "curacion", "cantidad": 30})
        obj_carne_cruda = TipoObjeto(nombre="Carne Cruda", descripcion="Carne de animal cruda.", id_grafico="raw_meat", tipo_objeto="COMIDA", es_apilable=True, peso_unidad=0.7, valores_especificos={"restaura_hambre": 15})
        obj_cuero = TipoObjeto(nombre="Cuero", descripcion="Piel curtida.", id_grafico="leather", tipo_objeto="RECURSO", es_apilable=True, peso_unidad=0.8)
        obj_oro = TipoObjeto(nombre="Moneda de Oro", descripcion="Moneda de oro para comercio.", id_grafico="gold_coin", tipo_objeto="TESORO", es_apilable=True, peso_unidad=0.01)
        obj_picota_basica = TipoObjeto(nombre="Picota Básica", descripcion="Herramienta para minar piedra.", id_grafico="basic_pickaxe", tipo_objeto="HERRAMIENTA", es_apilable=False, peso_unidad=3.0, valores_especificos={"tipo_herramienta": "PICO", "efectividad_base": 1.0, "tipo_dano": "PICO"})

        db.session.add_all([obj_madera, obj_piedra, obj_espada_hierro, obj_pocion_curacion, obj_carne_cruda, obj_cuero, obj_oro, obj_picota_basica])
        db.session.commit()
        print(f"-> {db.session.query(TipoObjeto).count()} Tipos de Objetos creados.")

        # Habilidades Básicas
        hab_ataque_basico = TipoHabilidad(nombre="Ataque Básico", descripcion="Un golpe simple.", tipo_habilidad="ACTIVA", coste_energia=0, cooldown_segundos=1, valores_habilidad={"multiplicador_dano": 1.0})
        hab_construir_rapido = TipoHabilidad(nombre="Construcción Rápida", descripcion="Reduce el tiempo de construcción.", tipo_habilidad="PASIVA", valores_habilidad={"reduccion_tiempo_porcentaje": 0.2})
        hab_bola_fuego = TipoHabilidad(nombre="Bola de Fuego", descripcion="Lanza una bola de fuego.", tipo_habilidad="ACTIVA", coste_energia=20, cooldown_segundos=5, valores_habilidad={"dano_magico": 50, "rango": 15})
        hab_teletransportar = TipoHabilidad(nombre="Teletransporte Corto", descripcion="Se teletransporta una distancia corta.", tipo_habilidad="ACTIVA", coste_energia=30, cooldown_segundos=10, valores_habilidad={"distancia": 10})
        hab_comerciar = TipoHabilidad(nombre="Habilidad de Comercio", descripcion="Permite iniciar intercambios.", tipo_habilidad="PASIVA")
        hab_grito_maldito = TipoHabilidad(nombre="Grito Maldito", descripcion="Aturde enemigos cercanos.", tipo_habilidad="ACTIVA", coste_energia=15, cooldown_segundos=8, valores_habilidad={"rango": 8, "duracion_aturdimiento": 3})

        db.session.add_all([hab_ataque_basico, hab_construir_rapido, hab_bola_fuego, hab_teletransportar, hab_comerciar, hab_grito_maldito])
        db.session.commit()
        print(f"-> {db.session.query(TipoHabilidad).count()} Tipos de Habilidad creados.")

        # Loot Tables
        loot_table_goblin = TipoLootTable(nombre="Loot Goblin Básico", items=[
            {"id_tipo_objeto": obj_carne_cruda.id, "min_cantidad": 1, "max_cantidad": 2, "probabilidad": 0.8},
            {"id_tipo_objeto": obj_cuero.id, "min_cantidad": 0, "max_cantidad": 1, "probabilidad": 0.4}
        ])
        loot_table_jefe = TipoLootTable(nombre="Loot de Jefe", items=[
            {"id_tipo_objeto": obj_oro.id, "min_cantidad": 10, "max_cantidad": 50, "probabilidad": 1.0},
            {"id_tipo_objeto": obj_espada_hierro.id, "min_cantidad": 1, "max_cantidad": 1, "probabilidad": 0.1}
        ])
        db.session.add_all([loot_table_goblin, loot_table_jefe])
        db.session.commit()
        print(f"-> {db.session.query(TipoLootTable).count()} Tipos de Loot Tables creados.")

        # Tipo Edificio
        edif_casa = TipoEdificio(nombre="Casa Pequeña", descripcion="Una humilde casa.", id_grafico="house_basic", recursos_costo=[{"id_tipo_objeto": obj_madera.id, "cantidad": 20}], efectos_aldea={}, max_por_aldea=10)
        edif_barracas = TipoEdificio(nombre="Barracas", descripcion="Entrena guardias.", id_grafico="barracks", recursos_costo=[{"id_tipo_objeto": obj_piedra.id, "cantidad": 50}, {"id_tipo_objeto": obj_madera.id, "cantidad": 30}], efectos_aldea={"defensa_bono": 20}, max_por_aldea=1)
        db.session.add_all([edif_casa, edif_barracas])
        db.session.commit()
        print(f"-> {db.session.query(TipoEdificio).count()} Tipos de Edificios creados.")

        # Tipo Animal (requiere TipoObjeto para recursos_obtenibles)
        animal_ciervo = TipoAnimal(nombre="Ciervo", descripcion="Animal pacífico, fuente de carne y cuero.", id_grafico="deer_01", comportamiento_tipo="PACIFICO", es_montable=False, recursos_obtenibles=[{"id_tipo_objeto": obj_carne_cruda.id, "cantidad_min": 1, "cantidad_max": 3, "cooldown": 3600}], resistencia_dano={})
        animal_lobo = TipoAnimal(nombre="Lobo", descripcion="Depredador territorial.", id_grafico="wolf_01", comportamiento_tipo="TERRITORIAL", es_montable=False, resistencia_dano={"CORTANTE": 1.2, "CONTUNDENTE": 0.8})
        animal_caballo = TipoAnimal(nombre="Caballo Salvaje", descripcion="Puede ser domesticado y montado.", id_grafico="horse_wild_01", comportamiento_tipo="PACIFICO", es_montable=True, resistencia_dano={})
        db.session.add_all([animal_ciervo, animal_lobo, animal_caballo])
        db.session.commit()
        print(f"-> {db.session.query(TipoAnimal).count()} Tipos de Animales creados.")

        # Tipo Recurso Terreno (requiere TipoObjeto para recursos_minables)
        rec_arbol = TipoRecursoTerreno(nombre="Arbol de Roble", descripcion="Fuente de madera.", id_grafico="oak_tree", salud_base=50, recursos_minables=[{"id_tipo_objeto": obj_madera.id, "cantidad_min": 5, "cantidad_max": 10}], efectividad_herramienta={"HACHA": 1.5, "PICO": 0.5})
        rec_vetametal = TipoRecursoTerreno(nombre="Veta de Metal", descripcion="Fuente de piedra y minerales.", id_grafico="metal_ore", salud_base=80, recursos_minables=[{"id_tipo_objeto": obj_piedra.id, "cantidad_min": 3, "cantidad_max": 8}], efectividad_herramienta={"PICO": 1.5, "HACHA": 0.5})
        db.session.add_all([rec_arbol, rec_vetametal])
        db.session.commit()
        print(f"-> {db.session.query(TipoRecursoTerreno).count()} Tipos de Recursos de Terreno creados.")

        # Tipo NPC (requiere TipoHabilidad y TipoLootTable)
        # Primero crea las bases CriaturaViva_Base que se referenciarán en TipoNPC
        inv_cv_base_1 = Inventario(capacidad_slots=5, capacidad_peso_kg=10.0)
        dano_cv_base_1 = Daño(salud_actual=50, salud_max=50, loot_table_id=None) # Aldeano
        db.session.add_all([inv_cv_base_1, dano_cv_base_1]); db.session.flush()
        cv_base_aldeano = CriaturaViva_Base(hambre_actual=50, hambre_max=50, dano_ataque_base=5, velocidad_movimiento=3.0, id_danio=dano_cv_base_1.id, id_inventario=inv_cv_base_1.id)
        db.session.add(cv_base_aldeano); db.session.flush()

        inv_cv_base_2 = Inventario(capacidad_slots=20, capacidad_peso_kg=200.0)
        dano_cv_base_2 = Daño(salud_actual=120, salud_max=120, loot_table_id=None) # Constructor
        db.session.add_all([inv_cv_base_2, dano_cv_base_2]); db.session.flush()
        cv_base_constructor = CriaturaViva_Base(hambre_actual=100, hambre_max=100, dano_ataque_base=2, velocidad_movimiento=2.0, id_danio=dano_cv_base_2.id, id_inventario=inv_cv_base_2.id)
        db.session.add(cv_base_constructor); db.session.flush()

        inv_cv_base_3 = Inventario(capacidad_slots=3, capacidad_peso_kg=5.0)
        dano_cv_base_3 = Daño(salud_actual=80, salud_max=80, loot_table_id=loot_table_goblin.id) # Malvado
        db.session.add_all([inv_cv_base_3, dano_cv_base_3]); db.session.flush()
        cv_base_malvado = CriaturaViva_Base(hambre_actual=70, hambre_max=70, dano_ataque_base=15, velocidad_movimiento=4.0, id_danio=dano_cv_base_3.id, id_inventario=inv_cv_base_3.id)
        db.session.add(cv_base_malvado); db.session.flush()

        inv_cv_base_4 = Inventario(capacidad_slots=50, capacidad_peso_kg=500.0)
        dano_cv_base_4 = Daño(salud_actual=150, salud_max=150, loot_table_id=None) # Comerciante
        db.session.add_all([inv_cv_base_4, dano_cv_base_4]); db.session.flush()
        cv_base_comerciante = CriaturaViva_Base(hambre_actual=100, hambre_max=100, dano_ataque_base=1, velocidad_movimiento=1.0, id_danio=dano_cv_base_4.id, id_inventario=inv_cv_base_4.id)
        db.session.add(cv_base_comerciante); db.session.flush()

        inv_cv_base_5 = Inventario(capacidad_slots=15, capacidad_peso_kg=30.0)
        dano_cv_base_5 = Daño(salud_actual=90, salud_max=90, loot_table_id=None) # Mago
        db.session.add_all([inv_cv_base_5, dano_cv_base_5]); db.session.flush()
        cv_base_mago = CriaturaViva_Base(hambre_actual=80, hambre_max=80, dano_ataque_base=5, velocidad_movimiento=3.0, id_danio=dano_cv_base_5.id, id_inventario=inv_cv_base_5.id)
        db.session.add(cv_base_mago); db.session.flush()

        print(f"-> {db.session.query(CriaturaViva_Base).count()} CriaturaViva_Base templates creadas.")


        npc_generico = TipoNPC(
            nombre="Aldeano Pacifista", descripcion="Un simple aldeano que deambula.",
            id_grafico="human_villager_01", rol_npc="GENERICO",
            comportamiento_ia="Deambula aleatoriamente, huye si es atacado.",
            habilidades_base=[], resistencia_dano={},
            valores_rol={"hitbox_dimensions": {"radius": 0.4, "height": 1.7}} # Añadido para NPC.gd
        )
        npc_constructor = TipoNPC(
            nombre="Maestro Constructor", descripcion="NPC dedicado a construir y reparar estructuras. Necesita recursos.",
            id_grafico="human_builder_01", rol_npc="CONSTRUCTOR",
            comportamiento_ia="Busca recursos en el inventario de la aldea y construye/repara edificios.",
            habilidades_base=[hab_construir_rapido.id], resistencia_dano={},
            valores_rol={"cooldown_construccion_segundos": 60, "recursos_por_construccion_unidad": [{"id_tipo_objeto": obj_madera.id, "cantidad": 2}], "hitbox_dimensions": {"radius": 0.4, "height": 1.7}} # Añadido
        )
        npc_malvado = TipoNPC(
            nombre="Goblin Merodeador", descripcion="Un ser hostil que ataca jugadores, NPCs y animales.",
            id_grafico="goblin_warrior_01", rol_npc="MALVADO",
            comportamiento_ia="Patrulla un área, ataca a cualquier CriaturaViva que vea.",
            habilidades_base=[hab_grito_maldito.id], resistencia_dano={"CORTANTE": 0.8, "CONTUNDENTE": 1.2},
            valores_rol={"rango_vision": 20, "tipo_target_preferido": ["BASTION", "NPC", "ANIMAL"], "hitbox_dimensions": {"radius": 0.3, "height": 1.5}} # Añadido
        )
        npc_comerciante = TipoNPC(
            nombre="Mercader Errante", descripcion="Ofrece bienes y busca recursos, precios variables.",
            id_grafico="human_merchant_01", rol_npc="COMERCIANTE",
            comportamiento_ia="Se mueve entre aldeas, ofrece trades, reajusta precios según oferta/demanda local.",
            habilidades_base=[hab_comerciar.id], resistencia_dano={},
            valores_rol={"ofertas_comercio_ids": [], "margen_beneficio_base": 0.1, "hitbox_dimensions": {"radius": 0.4, "height": 1.7}} # Añadido
        )
        npc_mago = TipoNPC(
            nombre="Archimago Solitario", descripcion="Un poderoso mago con habilidades arcanas.",
            id_grafico="human_mage_01", rol_npc="MAGO",
            comportamiento_ia="Defiende puntos clave, puede lanzar hechizos de apoyo o ataque.",
            habilidades_base=[hab_bola_fuego.id, hab_teletransportar.id], resistencia_dano={"MAGICO_FUEGO": 0.5, "MAGICO_HIELO": 1.5},
            valores_rol={"mana_max": 100, "regeneracion_mana_por_segundo": 5, "pociones_creables_ids": [obj_pocion_curacion.id], "cooldown_creacion_pocion_segundos": 120, "hitbox_dimensions": {"radius": 0.4, "height": 1.7}} # Añadido
        )
        db.session.add_all([npc_generico, npc_constructor, npc_malvado, npc_comerciante, npc_mago])
        db.session.commit()
        print(f"-> {db.session.query(TipoNPC).count()} Tipos de NPCs creados.")

        # Tipo Comerciante Oferta (requiere TipoObjeto)
        oferta_oro_cuero = TipoComercianteOferta(id_tipo_objeto_ofrecido=obj_oro.id, cantidad_ofrecida=10, id_tipo_objeto_demandado=obj_cuero.id, cantidad_demandada=1, precio_base_moneda=0.0)
        db.session.add(oferta_oro_cuero)
        db.session.commit()
        # Actualizar NPC comerciante con la oferta (esto es fuera de la definición de TipoNPC para evitar FK circular)
        npc_comerciante.valores_rol["ofertas_comercio_ids"] = [oferta_oro_cuero.id]
        db.session.add(npc_comerciante)
        db.session.commit()
        print(f"-> {db.session.query(TipoComercianteOferta).count()} Tipos de Ofertas de Comerciante creados y asignados.")

        # Tipo Mision (requiere TipoNPC y TipoObjeto)
        mision_cazar_lobo = TipoMision(nombre="Caza del Lobo Ferroz", descripcion="Caza 3 lobos para asegurar la aldea.", id_tipo_npc_requerido=npc_generico.id, nivel_requerido=1, objetivos={"derrotar_npcs": [{"id_tipo_npc": animal_lobo.id, "cantidad": 3}]}, recompensa={"xp": 50, "items": [{"id_tipo_objeto": obj_cuero.id, "cantidad": 2}]})
        db.session.add(mision_cazar_lobo)
        db.session.commit()
        print(f"-> {db.session.query(TipoMision).count()} Tipos de Misiones creados.")

        # Tipo Evento Global (requiere TipoNPC)
        evento_plaga = TipoEventoGlobal(nombre="La Plaga de Sombras", descripcion="Una oscura plaga afecta a los animales, volviéndolos hostiles.", fase_activacion="VIERNES", duracion_horas=48, efectos_mundo={"animales_hostiles_extra": 5}, objetivos_clan={"derrotar_npcs_tipo": [{"id_tipo_npc": npc_malvado.id, "cantidad": 10}]}, recompensa_exito={"xp_clan": 100}, consecuencia_fracaso={"npcs_malvados_permanentes": 2})
        db.session.add(evento_plaga)
        db.session.commit()
        print(f"-> {db.session.query(TipoEventoGlobal).count()} Tipos de Eventos Globales creados.")

        # Tipo Pista (requiere TipoEventoGlobal)
        pista_ritual = TipoPista(nombre="Pista del Ritual Oscuro", contenido="La luna roja, la cueva de las sombras, el sacrificio...", tipo_contenido="TEXTO", id_evento_asociado=evento_plaga.id, ubicacion_juego="Dentro de un tomo en la vieja biblioteca.")
        db.session.add(pista_ritual)
        db.session.commit()
        print(f"-> {db.session.query(TipoPista).count()} Tipos de Pistas creados.")


        # --- 3. Creación de Instancias de Juego (Estado Inicial) ---
        print("\n[Paso 3/4] Creación de Instancias de Juego (Usuario, Clan, Mundo, Bastion, etc.)...")

        # Usuario
        admin_email = app.config.get("ADMIN_EMAIL")
        admin_password = app.config.get("ADMIN_PASSWORD")

        user_admin = Usuario(username="admin_user", password_hash=generate_password_hash(admin_password), email=admin_email)
        # user_player.id debería ser 2 si se inserta después de admin_user
        user_player = Usuario(username="player_one", password_hash=generate_password_hash("secure_player_pass"), email="player@example.com")
        user_free = Usuario(username="free_player", password_hash=generate_password_hash("free_pass"), email="free@example.com") # Nuevo usuario para Sandbox
        db.session.add_all([user_admin, user_player, user_free])
        db.session.commit() # Commit para que los IDs se generen
        print(f"-> {db.session.query(Usuario).count()} Usuarios creados. ID de player_one: {user_player.id}") # Imprimir ID

        # Clan
        inv_clan_baluarte = Inventario(capacidad_slots=100, capacidad_peso_kg=1000.0)
        db.session.add(inv_clan_baluarte)
        db.session.flush()

        clan_guardianes = Clan(nombre="Los Guardianes del Alba", descripcion="Defensores de la luz.", id_lider_usuario=user_admin.id, id_inventario_baluarte=inv_clan_baluarte.id)

        inv_clan_free = Inventario(capacidad_slots=50, capacidad_peso_kg=500.0)
        db.session.add(inv_clan_free)
        db.session.flush()
        clan_free = Clan(nombre="Clan Libre", descripcion="Un clan sin ataduras.", id_lider_usuario=user_free.id, id_inventario_baluarte=inv_clan_free.id)

        db.session.add_all([clan_guardianes, clan_free])
        db.session.commit()
        print(f"-> {db.session.query(Clan).count()} Clanes creados.")

        # Mundos
        mundo_clan_principal = Mundo(tipo_mundo="CLAN", id_propietario_clan=clan_guardianes.id, nombre_mundo="Mundo Principal de Juego", semilla_generacion="SEMILLA_CLAN_XYZ", configuracion_actual={"clima": "NORMAL"})
        mundo_sandbox = Mundo(tipo_mundo="CLAN", id_propietario_clan=clan_free.id, nombre_mundo="Mundo Sandbox para Devs", semilla_generacion="SANDBOX_SEED_1", estado_actual_terreno={}, 
                                  configuracion_actual={"clima": "SOLEADO", "debug_mode": True, "terrain_size": 50, "terrain_height_scale": 10.0, "noise_octaves": 5, "noise_lacunarity": 2.0, "noise_period": 20.0}) # Añadidos nuevos parámetros para terreno
        mundo_personal_player = Mundo(tipo_mundo="PERSONAL", id_propietario_usuario=user_player.id, nombre_mundo="Refugio de PlayerOne", semilla_generacion="SEMILLA_PERSONAL_ABC")
        db.session.add_all([mundo_clan_principal, mundo_sandbox, mundo_personal_player])
        db.session.commit()
        print(f"-> {db.session.query(Mundo).count()} Mundos creados.")

        # Bastion (Personaje del Jugador)
        inv_player_bastion = Inventario(capacidad_slots=25, capacidad_peso_kg=50.0)
        db.session.add(inv_player_bastion)
        dano_player_bastion = Daño(salud_actual=100, salud_max=100)
        db.session.add(dano_player_bastion)
        db.session.flush()

        cv_player_bastion = CriaturaViva_Base(
            hambre_actual=80, hambre_max=100, dano_ataque_base=10, velocidad_movimiento=6.0,
            id_danio=dano_player_bastion.id, id_inventario=inv_player_bastion.id
        )
        db.session.add(cv_player_bastion)
        db.session.flush()

        bastion_player_one = Bastion(
            id_usuario=user_player.id, # Usar el ID del usuario player_one
            id_clan=clan_guardianes.id,
            nombre_personaje="AventureroHeroico",
            nivel=5,
            experiencia=1200,
            # Añadir id_grafico y hitbox_dimensions aquí para que Player.gd los cargue
            posicion_actual={"x": 50, "y": 5, "z": 50, "mundo_id": mundo_sandbox.id, "id_grafico": "player_male_adventurer", "hitbox_dimensions": {"radius": 0.4, "height": 1.7}},
            habilidades_aprendidas=[hab_ataque_basico.id],
            id_criatura_viva_base=cv_player_bastion.id
        )
        db.session.add(bastion_player_one)
        db.session.commit()
        print(f"-> {db.session.query(Bastion).count()} Bastiones creados. ID de AventureroHeroico: {bastion_player_one.id}")


        # --- 4. Creación de Instancias de Juego (Nivel 2 y 3) - Tanda 4 y 5 ---
        print("\n[Paso 4/4] Creación de Instancias de Aldeas, NPCs, Animales, Recursos Terreno, Edificios, Misiones y Eventos Activos, Interacciones Comerciales...")

        # Instancia Aldea
        inv_aldea_principal = Inventario(capacidad_slots=200, contenido={}, capacidad_peso_kg=2000.0)
        dano_aldea_principal = Daño(salud_actual=500, salud_max=500, loot_table_id=None)
        db.session.add_all([inv_aldea_principal, dano_aldea_principal])
        db.session.flush()

        aldea_valle = InstanciaAldea(
            nombre="Pueblo del Valle",
            id_mundo=mundo_clan_principal.id, # Asignada al mundo principal de juego
            posicion_central={"x": 100, "y": 0, "z": 100},
            id_clan_propietario=clan_guardianes.id,
            id_inventario_aldea=inv_aldea_principal.id,
            recursos_produccion_actual={"madera": 10, "piedra": 5},
            nivel_defensa=10,
            id_danio_estructura_central=dano_aldea_principal.id,
            valores_dinamicos={"prosperidad": 0.8}
        )
        db.session.add(aldea_valle)
        db.session.commit()
        print(f"-> {db.session.query(InstanciaAldea).count()} Instancias de Aldea creadas.")

        # Instancia Recurso Terreno
        dano_arbol_inst = Daño(salud_actual=rec_arbol.salud_base, salud_max=rec_arbol.salud_base, loot_table_id=None)
        db.session.add(dano_arbol_inst); db.session.flush()
        rec_arbol_instance = InstanciaRecursoTerreno(
            id_tipo_recurso_terreno=rec_arbol.id,
            id_mundo=mundo_clan_principal.id,
            posicion={"x": 110, "y": 0, "z": 110},
            esta_agotado=False,
            id_danio=dano_arbol_inst.id
        )
        db.session.add(rec_arbol_instance)
        db.session.commit()
        print(f"-> {db.session.query(InstanciaRecursoTerreno).count()} Instancias de Recurso Terreno creadas.")

        # Instancia NPC
        # Aldeano dentro de la aldea
        inv_npc_aldeano = Inventario(capacidad_slots=5, capacidad_peso_kg=10.0)
        dano_npc_aldeano = Daño(salud_actual=50, salud_max=50, loot_table_id=None)
        db.session.add_all([inv_npc_aldeano, dano_npc_aldeano])
        db.session.flush()
        cv_npc_aldeano_inst = CriaturaViva_Base(
            hambre_actual=50, hambre_max=50, dano_ataque_base=5, velocidad_movimiento=3.0,
            id_danio=dano_npc_aldeano.id, id_inventario=inv_npc_aldeano.id
        )
        db.session.add(cv_npc_aldeano_inst); db.session.flush()

        inst_aldeano = InstanciaNPC(
            id_tipo_npc=npc_generico.id,
            id_criatura_viva_base=cv_npc_aldeano_inst.id,
            id_mundo=aldea_valle.id_mundo, # En el mismo mundo que la aldea
            posicion={"x": 102, "y": 0, "z": 102},
            id_aldea_pertenece=aldea_valle.id
        )
        db.session.add(inst_aldeano)

        # Goblin merodeador (en Mundo Sandbox)
        inv_npc_goblin_inst = Inventario(capacidad_slots=3, capacidad_peso_kg=5.0)
        dano_npc_goblin_inst = Daño(salud_actual=80, salud_max=80, loot_table_id=loot_table_goblin.id)
        db.session.add_all([inv_npc_goblin_inst, dano_npc_goblin_inst])
        db.session.flush()
        cv_npc_goblin_inst = CriaturaViva_Base(
            hambre_actual=70, hambre_max=70, dano_ataque_base=15, velocidad_movimiento=4.0,
            id_danio=dano_npc_goblin_inst.id, id_inventario=inv_npc_goblin_inst.id
        )
        db.session.add(cv_npc_goblin_inst); db.session.flush()

        inst_goblin_sandbox = InstanciaNPC(
            id_tipo_npc=npc_malvado.id,
            id_criatura_viva_base=cv_npc_goblin_inst.id,
            id_mundo=mundo_sandbox.id, # <-- Asignado al Mundo Sandbox
            posicion={"x": 5, "y": 1, "z": 5}, # <-- Posición en el Sandbox
            restriccion_area={"tipo": "RECT", "coords": [0,0,0,10,10,10]}
        )
        db.session.add(inst_goblin_sandbox)
        db.session.commit()
        print(f"-> {db.session.query(InstanciaNPC).count()} Instancias de NPC creadas.")

        # Instancia Animal
        inv_animal_ciervo_inst = Inventario(capacidad_slots=1, capacidad_peso_kg=10.0)
        dano_animal_ciervo_inst = Daño(salud_actual=40, salud_max=40, loot_table_id=loot_table_goblin.id)
        db.session.add_all([inv_animal_ciervo_inst, dano_animal_ciervo_inst])
        db.session.flush()
        cv_animal_ciervo_inst = CriaturaViva_Base(
            hambre_actual=60, hambre_max=60, dano_ataque_base=0, velocidad_movimiento=6.0,
            id_danio=dano_animal_ciervo_inst.id, id_inventario=inv_animal_ciervo_inst.id
        )
        db.session.add(cv_animal_ciervo_inst); db.session.flush()

        inst_ciervo_sandbox = InstanciaAnimal(
            id_tipo_animal=animal_ciervo.id,
            id_criatura_viva_base=cv_animal_ciervo_inst.id,
            id_mundo=mundo_sandbox.id, # <-- Asignado al Mundo Sandbox
            posicion={"x": 8, "y": 1, "z": 8}, # <-- Posición en el Sandbox
            nivel_carino=0
        )
        db.session.add(inst_ciervo_sandbox)
        db.session.commit()
        print(f"-> {db.session.query(InstanciaAnimal).count()} Instancias de Animal creadas.")

        # Instancia Edificio
        dano_edif_casa_inst = Daño(salud_actual=200, salud_max=200, loot_table_id=None)
        db.session.add(dano_edif_casa_inst); db.session.flush()

        inst_casa_aldea = InstanciaEdificio(
            id_tipo_edificio=edif_casa.id,
            id_aldea=aldea_valle.id,
            posicion_relativa={"x": 5, "y": 0, "z": 5},
            esta_destruido=False,
            estado_construccion="COMPLETO",
            id_danio=dano_edif_casa_inst.id
        )
        db.session.add(inst_casa_aldea)
        db.session.commit()
        print(f"-> {db.session.query(InstanciaEdificio).count()} Instancias de Edificio creadas.")

        # Mision Activa (en el mundo principal)
        mision_act_1 = MisionActiva(id_tipo_mision=mision_cazar_lobo.id, id_bastion=bastion_player_one.id, estado_mision="ACTIVA", progreso_objetivos={"derrotar_npcs": [{"id_tipo_npc": animal_lobo.id, "cantidad_actual": 0, "cantidad_requerida": 3}]})
        db.session.add(mision_act_1)
        db.session.commit()
        print(f"-> {db.session.query(MisionActiva).count()} Misiones Activas creadas.")

        # Evento Global Activo (en el mundo principal)
        evento_activo_1 = EventoGlobalActivo(id_tipo_evento_global=evento_plaga.id, id_mundo_clan=mundo_clan_principal.id, fase_actual="MISTERIO")
        db.session.add(evento_activo_1)
        db.session.commit()
        print(f"-> {db.session.query(EventoGlobalActivo).count()} Eventos Globales Activos creados.")

        # Interaccion Comercio (ejemplo de registro, usando InstanciaNPC existente)
        # Crear una instancia NPC para que el comercio tenga un ref válido, con su propia CVB
        inv_npc_comerciante_seed_data = Inventario(capacidad_slots=50, capacidad_peso_kg=500.0)
        dano_npc_comerciante_seed_data = Daño(salud_actual=150, salud_max=150, loot_table_id=None)
        db.session.add_all([inv_npc_comerciante_seed_data, dano_npc_comerciante_seed_data])
        db.session.flush()
        cv_npc_comerciante_seed_data = CriaturaViva_Base(hambre_actual=100, hambre_max=100, dano_ataque_base=1, velocidad_movimiento=1.0, id_danio=dano_npc_comerciante_seed_data.id, id_inventario=inv_npc_comerciante_seed_data.id)
        db.session.add(cv_npc_comerciante_seed_data); db.session.flush()

        inst_npc_comerciante_seed_data = InstanciaNPC(
            id_tipo_npc=npc_comerciante.id,
            id_criatura_viva_base=cv_npc_comerciante_seed_data.id,
            id_mundo=mundo_clan_principal.id, # En el mundo principal
            posicion={"x": 108, "y": 0, "z": 108}
        )
        db.session.add(inst_npc_comerciante_seed_data); db.session.flush()

        interaccion_comercial_1 = InteraccionComercio(
            id_instancia_npc_comerciante=inst_npc_comerciante_seed_data.id,
            id_bastion_comprador=bastion_player_one.id,
            id_tipo_objeto_comprado=obj_madera.id,
            cantidad_comprada=10,
            precio_total=Decimal('100.00')
        )
        db.session.add(interaccion_comercial_1)
        db.session.commit()
        print(f"-> {db.session.query(InteraccionComercio).count()} Interacciones de Comercio creadas.")


        print("\n=====================================================")
        print("= PROCESO DE SEEDING FINALIZADO EXITOSAMENTE        =")
        print("=====================================================")


# Este bloque final asegura que el script pueda ser llamado desde la línea de comandos
if __name__ == '__main__':
    cli()