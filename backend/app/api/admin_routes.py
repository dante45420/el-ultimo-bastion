# el-ultimo-bastion/backend/app/api/admin_routes.py
from flask import Blueprint, request, jsonify
from app import db
from app.models import (
    TipoObjeto, Mundo, Usuario, Clan, Inventario, Daño, TipoNPC, CriaturaViva_Base, InstanciaNPC,
    TipoAnimal, TipoEdificio, TipoHabilidad, TipoComercianteOferta, TipoMision, TipoEventoGlobal, TipoPista, TipoLootTable,
    Bastion # Añadido Bastion
) # Importar todos los modelos necesarios
from app.schemas import (
    TipoObjetoSchema, MundoSchema, InstanciaNPCSchema, TipoNPCSchema, UsuarioSchema, ClanSchema,
    InventarioSchema, DañoSchema, CriaturaVivaBaseSchema, TipoAnimalSchema, TipoEdificioSchema,
    TipoHabilidadSchema, TipoComercianteOfertaSchema, TipoMisionSchema, TipoEventoGlobalSchema, TipoPistaSchema, TipoLootTableSchema,
    BastionSchema # Añadido BastionSchema
) # Importar todos los esquemas necesarios
from flask_cors import CORS
from sqlalchemy.orm.attributes import flag_modified # Necesario para actualizar JSONB
from sqlalchemy.orm import joinedload 

admin_bp = Blueprint('admin', __name__)

# Esquemas inicializados
tipo_objeto_schema = TipoObjetoSchema()
tipos_objetos_schema = TipoObjetoSchema(many=True)

mundo_schema = MundoSchema()
mundos_schema = MundoSchema(many=True)

instancia_npc_schema = InstanciaNPCSchema()
instancias_npc_schema = InstanciaNPCSchema(many=True)

tipo_npc_schema = TipoNPCSchema()
tipos_npcs_schema = TipoNPCSchema(many=True)

usuario_schema = UsuarioSchema()
usuarios_schema = UsuarioSchema(many=True)

clan_schema = ClanSchema()
clanes_schema = ClanSchema(many=True)

criatura_viva_base_schema = CriaturaVivaBaseSchema()
criaturas_vivas_base_schema = CriaturaVivaBaseSchema(many=True)

bastion_schema = BastionSchema() #
bastiones_schema = BastionSchema(many=True) #


@admin_bp.route('/')
def admin_index():
    return "API de administración de El Último Bastión está funcionando."

# --- RUTAS CRUD PARA TipoObjeto ---
@admin_bp.route('/tipos_objeto', methods=['POST'])
def create_tipo_objeto():
    try:
        data = tipo_objeto_schema.load(request.json)
    except Exception as e:
        return jsonify({"message": "Error de validación de datos", "errors": str(e)}), 400

    try:
        new_obj_type = TipoObjeto(**data)
        db.session.add(new_obj_type)
        db.session.commit()
        return jsonify(tipo_objeto_schema.dump(new_obj_type)), 201
    except Exception as e:
        db.session.rollback()
        if "unique constraint" in str(e):
            return jsonify({"message": "Error de base de datos: Ya existe un objeto con este nombre."}), 409
        return jsonify({"message": "Error interno del servidor", "error": str(e)}), 500

@admin_bp.route('/tipos_objeto', methods=['GET'])
def get_tipos_objeto():
    all_obj_types = TipoObjeto.query.all()
    return jsonify(tipos_objetos_schema.dump(all_obj_types)), 200

@admin_bp.route('/tipos_objeto/<int:obj_id>', methods=['GET'])
def get_tipo_objeto(obj_id):
    obj_type = db.session.get(TipoObjeto, obj_id)
    if not obj_type: return jsonify({"message": "TipoObjeto no encontrado."}), 404
    return jsonify(tipo_objeto_schema.dump(obj_type)), 200

# --- RUTAS CRUD PARA Mundo ---
@admin_bp.route('/mundos', methods=['POST'])
def create_mundo():
    try:
        data = mundo_schema.load(request.json)

        # Validaciones de propietario
        if data.get('tipo_mundo') == 'CLAN':
            if not data.get('id_propietario_clan'):
                return jsonify({"message": "Para tipo_mundo 'CLAN', 'id_propietario_clan' es requerido."}), 400
            if data.get('id_propietario_usuario'): # No debe tener propietario usuario si es CLAN
                return jsonify({"message": "Para tipo_mundo 'CLAN', 'id_propietario_usuario' debe ser nulo."}), 400
            if data.get('id_propietario_clan') and not db.session.get(Clan, data['id_propietario_clan']): # Corrección: validar si id_propietario_clan está presente
                return jsonify({"message": f"Clan con ID {data['id_propietario_clan']} no encontrado."}), 404
        elif data.get('tipo_mundo') == 'PERSONAL':
            if not data.get('id_propietario_usuario'):
                return jsonify({"message": "Para tipo_mundo 'PERSONAL', 'id_propietario_usuario' es requerido."}), 400
            if data.get('id_propietario_clan'): # No debe tener propietario clan si es PERSONAL
                return jsonify({"message": "Para tipo_mundo 'PERSONAL', 'id_propietario_clan' debe ser nulo."}), 400
            if data.get('id_propietario_usuario') and not db.session.get(Usuario, data['id_propietario_usuario']): # Corrección: validar si id_propietario_usuario está presente
                return jsonify({"message": f"Usuario con ID {data['id_propietario_usuario']} no encontrado."}), 404
        else: # Tipo de mundo no válido
            return jsonify({"message": "Tipo de mundo no válido."}), 400

    except Exception as e:
        return jsonify({"message": "Error de validación de datos", "errors": str(e)}), 400

    try:
        new_mundo = Mundo(**data)
        db.session.add(new_mundo)
        db.session.commit()
        return jsonify(mundo_schema.dump(new_mundo)), 201
    except Exception as e:
        db.session.rollback()
        if "unique constraint" in str(e):
            return jsonify({"message": "Error de base de datos: Ya existe un mundo de este tipo para el propietario especificado."}), 409
        return jsonify({"message": "Error interno del servidor", "error": str(e)}), 500

@admin_bp.route('/mundos', methods=['GET'])
def get_mundos():
    all_mundos = Mundo.query.all()
    return jsonify(mundos_schema.dump(all_mundos)), 200

@admin_bp.route('/mundos/<int:mundo_id>', methods=['GET'])
def get_mundo(mundo_id):
    mundo = db.session.get(Mundo, mundo_id)
    if not mundo: return jsonify({"message": "Mundo no encontrado."}), 404
    return jsonify(mundo_schema.dump(mundo)), 200

@admin_bp.route('/mundos/<int:mundo_id>', methods=['PUT'])
def update_mundo(mundo_id):
    mundo = db.session.get(Mundo, mundo_id)
    if not mundo: return jsonify({"message": "Mundo no encontrado."}), 404

    try:
        data = mundo_schema.load(request.json, partial=True)
    except Exception as e:
        return jsonify({"message": "Error de validación de datos", "errors": str(e)}), 400

    try:
        # Validar propietario si se intenta cambiar (y limpiar el otro)
        if 'tipo_mundo' in data:
            if data['tipo_mundo'] == 'CLAN':
                if 'id_propietario_usuario' in data and data['id_propietario_usuario'] is not None:
                    return jsonify({"message": "No se puede asignar propietario de usuario a un mundo tipo CLAN."}), 400
                if 'id_propietario_clan' in data and data['id_propietario_clan'] is not None and not db.session.get(Clan, data['id_propietario_clan']):
                    return jsonify({"message": f"Clan con ID {data['id_propietario_clan']} no encontrado."}), 404
                mundo.id_propietario_usuario = None # Limpiar el otro
            elif data['tipo_mundo'] == 'PERSONAL':
                if 'id_propietario_clan' in data and data['id_propietario_clan'] is not None:
                    return jsonify({"message": "No se puede asignar propietario de clan a un mundo tipo PERSONAL."}), 400
                if 'id_propietario_usuario' in data and data['id_propietario_usuario'] is not None and not db.session.get(Usuario, data['id_propietario_usuario']):
                    return jsonify({"message": f"Usuario con ID {data['id_propietario_usuario']} no encontrado."}), 404
                mundo.id_propietario_clan = None # Limpiar el otro

        for key, value in data.items():
            if key not in ['id_propietario_clan', 'id_propietario_usuario', 'tipo_mundo'] or key in data: # Permitir que los cambios de propietario se hagan aquí si pasan la validación anterior
                setattr(mundo, key, value)
            if key in ['estado_actual_terreno', 'configuracion_actual']:
                flag_modified(mundo, key) # Necesario para JSONB

        db.session.commit()
        return jsonify(mundo_schema.dump(mundo)), 200
    except Exception as e:
        db.session.rollback()
        if "unique constraint" in str(e):
            return jsonify({"message": "Error de base de datos: Ya existe un mundo de este tipo para el propietario especificado."}), 409
        return jsonify({"message": "Error interno del servidor", "error": str(e)}), 500


# --- RUTAS CRUD PARA InstanciaNPC ---
@admin_bp.route('/instancias_npc', methods=['POST'])
def create_instancia_npc():
    try:
        data = instancia_npc_schema.load(request.json)

        if not db.session.get(TipoNPC, data['id_tipo_npc']):
            return jsonify({"message": f"TipoNPC con ID {data['id_tipo_npc']} no encontrado."}), 404
        if not db.session.get(Mundo, data['id_mundo']):
            return jsonify({"message": f"Mundo con ID {data['id_mundo']} no encontrado."}), 404
        
        criatura_viva_base = None
        if data.get('id_criatura_viva_base'):
            criatura_viva_base = db.session.get(CriaturaViva_Base, data['id_criatura_viva_base'])
            if not criatura_viva_base:
                return jsonify({"message": f"CriaturaViva_Base con ID {data['id_criatura_viva_base']} no encontrada."}), 404
        else:
            # Crear Inventario, Daño y CriaturaViva_Base si no se proporciona un ID existente
            new_inventario = Inventario(
                capacidad_slots=data.get('initial_inventario_capacidad_slots', 5),
                capacidad_peso_kg=data.get('initial_inventario_capacidad_peso_kg', 10.0)
            )
            new_danio = Daño(
                salud_actual=data.get('initial_salud_max', 50),
                salud_max=data.get('initial_salud_max', 50),
                loot_table_id=data.get('initial_loot_table_id')
            )
            db.session.add_all([new_inventario, new_danio])
            db.session.flush()

            criatura_viva_base = CriaturaViva_Base(
                hambre_actual=data.get('initial_hambre_max', 50),
                hambre_max=data.get('initial_hambre_max', 50),
                dano_ataque_base=data.get('initial_dano_ataque_base', 5),
                velocidad_movimiento=data.get('initial_velocidad_movimiento', 3.0),
                id_danio=new_danio.id,
                id_inventario=new_inventario.id
            )
            db.session.add(criatura_viva_base)
            db.session.flush()
        
        data['id_criatura_viva_base'] = criatura_viva_base.id
        
        # Limpiar campos initial_X antes de pasar a InstanciaNPC si se crearon
        for key in list(data.keys()):
            if key.startswith('initial_'):
                del data[key]

    except Exception as e:
        db.session.rollback()
        return jsonify({"message": "Error de validación de datos o componentes base", "errors": str(e)}), 400

    try:
        new_inst_npc = InstanciaNPC(**data)
        db.session.add(new_inst_npc)
        db.session.commit()
        return jsonify(instancia_npc_schema.dump(new_inst_npc)), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({"message": "Error interno del servidor al crear InstanciaNPC", "error": str(e)}), 500

@admin_bp.route('/instancias_npc', methods=['GET'])
def get_instancias_npc():
    all_inst_npcs = InstanciaNPC.query.all()
    return jsonify(instancias_npc_schema.dump(all_inst_npcs)), 200

@admin_bp.route('/instancias_npc/<int:inst_id>', methods=['GET'])
def get_instancia_npc(inst_id):
    inst_npc = db.session.get(InstanciaNPC, inst_id)
    if not inst_npc: return jsonify({"message": "InstanciaNPC no encontrada."}), 404
    return jsonify(instancia_npc_schema.dump(inst_npc)), 200

@admin_bp.route('/instancias_npc_by_mundo/<int:mundo_id>', methods=['GET'])
def get_instancias_npc_by_mundo(mundo_id):
    # Corrección: cargar relaciones para que los datos anidados estén disponibles si el schema los pide
    inst_npcs = InstanciaNPC.query.filter_by(id_mundo=mundo_id).all()
    return jsonify(instancias_npc_schema.dump(inst_npcs)), 200

@admin_bp.route('/instancias_npc/<int:inst_id>', methods=['PUT'])
def update_instancia_npc(inst_id):
    inst_npc = db.session.get(InstanciaNPC, inst_id)
    if not inst_npc: return jsonify({"message": "InstanciaNPC no encontrada."}), 404

    try:
        data = instancia_npc_schema.load(request.json, partial=True)
    except Exception as e:
        return jsonify({"message": "Error de validación de datos", "errors": str(e)}), 400

    try:
        # Campos que sí pueden ser actualizados para una instancia (posicion, esta_vivo, etc.)
        allowed_update_keys = ['posicion', 'esta_vivo', 'id_aldea_pertenece', 'id_clan_pertenece', 'id_persona_pertenece', 'restriccion_area', 'valores_dinamicos']
        
        for key in allowed_update_keys:
            if key in data: # Solo actualizar si el campo está presente en la solicitud
                setattr(inst_npc, key, data[key])
                if key in ['posicion', 'restriccion_area', 'valores_dinamicos']:
                    flag_modified(inst_npc, key) # Necesario para JSONB

        db.session.commit()
        return jsonify(instancia_npc_schema.dump(inst_npc)), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({"message": "Error interno del servidor al actualizar InstanciaNPC", "error": str(e)}), 500

# --- RUTAS CRUD PARA BASTION ---
@admin_bp.route('/bastiones', methods=['POST'])
def create_bastion():
    try:
        data = bastion_schema.load(request.json)

        # Validar existencia de Usuario y Clan si se proporcionan
        if not db.session.get(Usuario, data['id_usuario']):
            return jsonify({"message": f"Usuario con ID {data['id_usuario']} no encontrado."}), 404
        if data.get('id_clan') and not db.session.get(Clan, data['id_clan']):
            return jsonify({"message": f"Clan con ID {data['id_clan']} no encontrado."}), 404

        criatura_viva_base = None
        if data.get('id_criatura_viva_base'):
            criatura_viva_base = db.session.get(CriaturaViva_Base, data['id_criatura_viva_base'])
            if not criatura_viva_base:
                return jsonify({"message": f"CriaturaViva_Base con ID {data['id_criatura_viva_base']} no encontrada."}), 404
        else:
            # Crear Inventario, Daño y CriaturaViva_Base si no se proporciona un ID existente
            # Usar valores de los campos initial_X del BastionSchema
            new_inventario = Inventario(
                capacidad_slots=data.get('initial_inventario_capacidad_slots', 25),
                capacidad_peso_kg=data.get('initial_inventario_capacidad_peso_kg', 50.0)
            )
            new_danio = Daño(
                salud_actual=data.get('initial_salud_max', 100),
                salud_max=data.get('initial_salud_max', 100),
                loot_table_id=data.get('initial_loot_table_id') # Puede ser nulo
            )
            db.session.add_all([new_inventario, new_danio])
            db.session.flush() # Obtener IDs antes de crear CriaturaViva_Base

            criatura_viva_base = CriaturaViva_Base(
                hambre_actual=data.get('initial_hambre_max', 80),
                hambre_max=data.get('initial_hambre_max', 100),
                dano_ataque_base=data.get('initial_dano_ataque_base', 10),
                velocidad_movimiento=data.get('initial_velocidad_movimiento', 6.0),
                id_danio=new_danio.id, id_inventario=new_inventario.id
            )
            db.session.add(criatura_viva_base)
            db.session.flush()

        data['id_criatura_viva_base'] = criatura_viva_base.id
        
        # Eliminar los campos initial_X de los datos antes de crear el Bastion
        for key in list(data.keys()):
            if key.startswith('initial_'):
                del data[key]
        
        new_bastion = Bastion(**data)
        db.session.add(new_bastion)
        db.session.commit()
        return jsonify(bastion_schema.dump(new_bastion)), 201

    except Exception as e:
        db.session.rollback()
        if "UniqueConstraint" in str(e): # Detectar error de unicidad para id_usuario
            return jsonify({"message": "Ya existe un Bastion asociado a este usuario."}), 409
        return jsonify({"message": "Error al crear Bastion", "error": str(e)}), 500

@admin_bp.route('/bastiones', methods=['GET'])
def get_bastiones():
    # Cargar relaciones anidadas para evitar N+1 queries y asegurar que los datos estén disponibles
    all_bastiones = Bastion.query.options(
        joinedload(Bastion.criatura_viva_base).joinedload(CriaturaViva_Base.danio),
        joinedload(Bastion.criatura_viva_base).joinedload(CriaturaViva_Base.inventario),
        joinedload(Bastion.usuario),
        joinedload(Bastion.clan)
    ).all()
    return jsonify(bastiones_schema.dump(all_bastiones)), 200


@admin_bp.route('/bastiones/<int:bastion_id>', methods=['GET'])
def get_bastion(bastion_id):
    bastion = db.session.query(Bastion).options( # Usar query(Model).options para joinedload
        joinedload(Bastion.criatura_viva_base).joinedload(CriaturaViva_Base.danio),
        joinedload(Bastion.criatura_viva_base).joinedload(CriaturaViva_Base.inventario),
        joinedload(Bastion.usuario),
        joinedload(Bastion.clan)
    ).filter_by(id=bastion_id).first()

    if not bastion:
        return jsonify({"message": "Bastion no encontrado."}), 404
    return jsonify(bastion_schema.dump(bastion)), 200

@admin_bp.route('/bastiones/<int:bastion_id>', methods=['PUT'])
def update_bastion(bastion_id):
    bastion = db.session.get(Bastion, bastion_id)
    if not bastion:
        return jsonify({"message": "Bastion no encontrado."}), 404

    try:
        # Cargar solo los campos que se pueden actualizar desde el admin panel para configuración
        data = bastion_schema.load(request.json, partial=True)
        
        # Campos permitidos para actualización desde admin panel (NO DINÁMICOS)
        allowed_keys = ['nombre_personaje', 'nivel', 'experiencia', 'id_clan', 'habilidades_aprendidas']

        for key in allowed_keys:
            if key in data:
                setattr(bastion, key, data[key])
                if key == 'habilidades_aprendidas': # Para ARRAY de JSONB
                    flag_modified(bastion, key)
        
        # Si se cambia el clan, validar su existencia (solo si se proporciona)
        if 'id_clan' in data and data['id_clan'] is not None:
             if not db.session.get(Clan, data['id_clan']):
                 return jsonify({"message": f"Clan con ID {data['id_clan']} no encontrado."}), 404

        db.session.commit()
        return jsonify(bastion_schema.dump(bastion)), 200

    except Exception as e:
        db.session.rollback()
        return jsonify({"message": "Error al actualizar Bastion", "error": str(e)}), 500

# --- RUTA PARA SINCRONIZACIÓN DINÁMICA DE ESTADO DEL BASTION DESDE GODOT ---
@admin_bp.route('/bastiones/<int:bastion_id>/sync_game_state', methods=['PUT'])
def sync_bastion_game_state(bastion_id):
    bastion = db.session.get(Bastion, bastion_id)
    if not bastion:
        return jsonify({"message": "Bastion no encontrado."}), 404

    try:
        data = request.json
        
        # Actualizar posición
        if 'posicion_actual' in data and isinstance(data['posicion_actual'], dict):
            bastion.posicion_actual = data['posicion_actual']
            flag_modified(bastion, 'posicion_actual') #

        # Actualizar CriaturaViva_Base stats
        if 'criatura_viva_base' in data and isinstance(data['criatura_viva_base'], dict):
            # Obtener la CriaturaViva_Base asociada al Bastion
            cvb = bastion.criatura_viva_base
            if cvb:
                # Actualizar salud (en el objeto Daño asociado)
                if 'salud_actual' in data['criatura_viva_base']:
                    cvb.danio.salud_actual = data['criatura_viva_base']['salud_actual']
                # Actualizar hambre (directamente en CriaturaViva_Base)
                if 'hambre_actual' in data['criatura_viva_base']:
                    cvb.hambre_actual = data['criatura_viva_base']['hambre_actual']
                # Otros stats como dano_ataque_base o velocidad_movimiento
                # podrían actualizarse aquí si se decide que son dinámicos o que Godot los puede modificar
                # Pero en principio, son configurables, no dinámicos del gameplay

                db.session.add(cvb.danio) # Marcar el Daño para guardar cambios
                db.session.add(cvb) # Marcar la CriaturaViva_Base para guardar cambios
            else:
                print(f"ADVERTENCIA: Bastion ID {bastion_id} no tiene CriaturaViva_Base asociada para sincronizar stats.")


        db.session.commit()
        return jsonify({"message": "Estado de Bastion sincronizado exitosamente."}), 200

    except Exception as e:
        db.session.rollback()
        return jsonify({"message": "Error al sincronizar estado de Bastion", "error": str(e)}), 500

# --- RUTAS PARA DROPDOWNS EN EL FRONTEND ---
@admin_bp.route('/usuarios', methods=['GET'])
def get_all_usuarios():
    usuarios = Usuario.query.all()
    return jsonify(usuarios_schema.dump(usuarios)), 200

@admin_bp.route('/clanes', methods=['GET'])
def get_all_clanes():
    clanes = Clan.query.all()
    return jsonify(clanes_schema.dump(clanes)), 200

@admin_bp.route('/tipos_npc', methods=['GET'])
def get_all_tipos_npc():
    tipos_npc = TipoNPC.query.all()
    return jsonify(tipos_npcs_schema.dump(tipos_npc)), 200

@admin_bp.route('/criaturaviva_bases', methods=['GET'])
def get_all_criatura_viva_bases():
    criatura_viva_bases = CriaturaViva_Base.query.all()
    return jsonify(criaturas_vivas_base_schema.dump(criatura_viva_bases)), 200

@admin_bp.route('/bastiones_by_user/<int:user_id>', methods=['GET'])
def get_bastion_by_user(user_id):
    bastion = db.session.query(Bastion).options( # También aquí
        joinedload(Bastion.criatura_viva_base).joinedload(CriaturaViva_Base.danio),
        joinedload(Bastion.criatura_viva_base).joinedload(CriaturaViva_Base.inventario),
        joinedload(Bastion.usuario),
        joinedload(Bastion.clan)
    ).filter_by(id_usuario=user_id).first()

    if not bastion:
        return jsonify({"message": f"Bastion para el usuario {user_id} no encontrado."}), 404
    return jsonify(bastion_schema.dump(bastion)), 200