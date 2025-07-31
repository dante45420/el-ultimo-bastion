# el-ultimo-bastion/backend/manage.py
# VERSIÓN CORREGIDA - CREA TABLAS PRIMERO, LUEGO LIMPIA
import click
from flask.cli import with_appcontext
from app import create_app, db
from app.models import *
from werkzeug.security import generate_password_hash

app = create_app()

@click.group()
def cli():
    """Comandos de gestión de base de datos."""
    pass

@cli.command('drop_all')
def drop_all_tables():
    """Elimina todas las tablas de la base de datos."""
    print("⚠️  ADVERTENCIA: Esto eliminará TODAS las tablas y datos.")
    confirm = input("¿Estás seguro? Escribe 'CONFIRMAR' para continuar: ")
    if confirm == 'CONFIRMAR':
        with app.app_context():
            db.drop_all()
            print("✅ Todas las tablas han sido eliminadas.")
    else:
        print("❌ Operación cancelada.")

@cli.command('create_tables')
def create_tables():
    """Crea todas las tablas en la base de datos."""
    with app.app_context():
        db.create_all()
        print("✅ Todas las tablas han sido creadas.")

@cli.command('seed')
def seed():
    """
    Crea SOLO los datos mínimos necesarios para que el juego funcione.
    Todo lo demás debe crearse desde el panel de administración.
    """
    with app.app_context():
        print("======================================================")
        print("= CREANDO DATOS MÍNIMOS NECESARIOS                  =")
        print("======================================================")

        # --- CREAR TABLAS SI NO EXISTEN ---
        print("\n[0/4] Asegurando que las tablas existan...")
        db.create_all()
        print("✅ Tablas verificadas/creadas.")

        # --- LIMPIEZA SEGURA ---
        print("\n[1/4] Limpiando base de datos...")
        
        # Función helper para limpiar tabla de forma segura
        def safe_delete(table_class):
            try:
                table_class.query.delete()
                return True
            except Exception as e:
                print(f"⚠️  Advertencia: No se pudo limpiar {table_class.__name__}: {e}")
                return False
        
        # Limpiar instancias (en orden de dependencias)
        safe_delete(InteraccionComercio)
        safe_delete(MisionActiva)
        safe_delete(EventoGlobalActivo)
        safe_delete(InstanciaEdificio)
        safe_delete(InstanciaNPC)
        safe_delete(InstanciaAnimal)
        safe_delete(InstanciaRecursoTerreno)
        safe_delete(InstanciaAldea)
        safe_delete(Bastion)
        safe_delete(Mundo)
        safe_delete(Clan)
        safe_delete(Usuario)
        
        # Limpiar componentes base
        safe_delete(CriaturaViva_Base)
        safe_delete(Daño)
        safe_delete(Inventario)
        
        # Limpiar tipos (todo será creado desde admin panel)
        safe_delete(TipoComercianteOferta)
        safe_delete(TipoMision)
        safe_delete(TipoPista)
        safe_delete(TipoEventoGlobal)
        safe_delete(TipoNPC)
        safe_delete(TipoAnimal)
        safe_delete(TipoRecursoTerreno)
        safe_delete(TipoHabilidad)
        safe_delete(TipoEdificio)
        safe_delete(TipoLootTable)
        safe_delete(TipoObjeto)
        
        db.session.commit()
        print("✅ Base de datos limpia.")

        # --- DATOS MÍNIMOS NECESARIOS ---
        print("\n[2/4] Creando usuario básico...")
        
        admin_email = app.config.get("ADMIN_EMAIL", "admin@example.com")
        admin_password = app.config.get("ADMIN_PASSWORD", "admin123")
        
        user_admin = Usuario(
            username="admin_user", 
            password_hash=generate_password_hash(admin_password), 
            email=admin_email
        )
        db.session.add(user_admin)
        db.session.commit()
        print(f"✅ Usuario creado: {user_admin.username} (ID: {user_admin.id})")

        print("\n[3/4] Creando clan y mundo sandbox...")
        
        # Inventario para el clan
        inv_clan = Inventario(capacidad_slots=100, capacidad_peso_kg=1000.0)
        db.session.add(inv_clan)
        db.session.flush()
        
        # Clan básico
        clan_sandbox = Clan(
            nombre="Clan Sandbox", 
            descripcion="Clan para desarrollo y testing.", 
            id_lider_usuario=user_admin.id, 
            id_inventario_baluarte=inv_clan.id
        )
        db.session.add(clan_sandbox)
        db.session.flush()
        
        # MUNDO SANDBOX CON ID 1 (ÚNICO MUNDO)
        mundo_sandbox = Mundo(
            tipo_mundo="CLAN", 
            id_propietario_clan=clan_sandbox.id, 
            nombre_mundo="Sandbox World",  # Nombre que busca World.gd
            semilla_generacion="SANDBOX_SEED_1", 
            estado_actual_terreno={"size": 50}, 
            configuracion_actual={
                "clima": "NORMAL", 
                "debug_mode": True
            }
        )
        db.session.add(mundo_sandbox)
        db.session.commit()
        print(f"✅ Clan creado: {clan_sandbox.nombre} (ID: {clan_sandbox.id})")
        print(f"✅ Mundo creado: {mundo_sandbox.nombre_mundo} (ID: {mundo_sandbox.id})")

        print("\n[4/4] Creando bastion básico...")
        
        # Componentes para el bastion
        inv_bastion = Inventario(capacidad_slots=25, capacidad_peso_kg=50.0)
        dano_bastion = Daño(salud_actual=100, salud_max=100)
        db.session.add_all([inv_bastion, dano_bastion])
        db.session.flush()
        
        cv_bastion = CriaturaViva_Base(
            hambre_actual=80, 
            hambre_max=100, 
            dano_ataque_base=10, 
            velocidad_movimiento=6.0,
            id_danio=dano_bastion.id, 
            id_inventario=inv_bastion.id
        )
        db.session.add(cv_bastion)
        db.session.flush()
        
        # Bastion del jugador
        bastion_player = Bastion(
            id_usuario=user_admin.id,
            id_clan=clan_sandbox.id,
            nombre_personaje="Aventurero",
            nivel=1,
            experiencia=0,
            posicion_actual={
                "x": 50, "y": 5, "z": 50, 
                "mundo_id": mundo_sandbox.id,
                "id_grafico": "player_male_adventurer", 
                "hitbox_dimensions": {"radius": 0.4, "height": 1.7}
            },
            habilidades_aprendidas=[],  # Sin habilidades iniciales
            id_criatura_viva_base=cv_bastion.id
        )
        db.session.add(bastion_player)
        db.session.commit()
        print(f"✅ Bastion creado: {bastion_player.nombre_personaje} (ID: {bastion_player.id})")

        print("\n======================================================")
        print("= DATOS MÍNIMOS CREADOS EXITOSAMENTE                =")
        print("======================================================")
        print("📋 RESUMEN:")
        print(f"   • 1 Usuario: {user_admin.username}")
        print(f"   • 1 Clan: {clan_sandbox.nombre}")
        print(f"   • 1 Mundo: {mundo_sandbox.nombre_mundo} (ID: {mundo_sandbox.id})")
        print(f"   • 1 Bastion: {bastion_player.nombre_personaje}")
        print("\n🎮 Ahora usa el panel de administración para:")
        print("   • Crear tipos de NPCs")
        print("   • Crear tipos de objetos")
        print("   • Agregar NPCs al mundo")
        print("   • Configurar habilidades y loot tables")

if __name__ == '__main__':
    cli()