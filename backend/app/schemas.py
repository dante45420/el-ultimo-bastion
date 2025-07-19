# el-ultimo-bastion/backend/app/schemas.py
from marshmallow import Schema, fields, validate

# --- Esquemas para las clases base/componentes (Tanda 1) ---

class InventarioSchema(Schema):
    id = fields.Int(dump_only=True)
    contenido = fields.Raw(required=True) # JSONB content, expects dict or list
    capacidad_slots = fields.Int(required=True, validate=validate.Range(min=1))
    capacidad_peso_kg = fields.Decimal(required=True, validate=validate.Range(min=0.1))

class DañoSchema(Schema):
    id = fields.Int(dump_only=True)
    salud_actual = fields.Int(required=True, validate=validate.Range(min=0))
    salud_max = fields.Int(required=True, validate=validate.Range(min=1))
    loot_table_id = fields.Int(allow_none=True)

class CriaturaVivaBaseSchema(Schema):
    id = fields.Int(dump_only=True)
    hambre_actual = fields.Int(required=True, validate=validate.Range(min=0))
    hambre_max = fields.Int(required=True, validate=validate.Range(min=1))
    dano_ataque_base = fields.Int(required=True, validate=validate.Range(min=0))
    velocidad_movimiento = fields.Decimal(required=True, validate=validate.Range(min=0.1))
    id_danio = fields.Int(required=True)
    id_inventario = fields.Int(required=True)

# --- Esquemas para los Tipos (configuración) - Tanda 2 ---

class TipoObjetoSchema(Schema):
    id = fields.Int(dump_only=True)
    nombre = fields.Str(required=True, validate=validate.Length(min=1, max=255))
    descripcion = fields.Str(allow_none=True)
    id_grafico = fields.Str(allow_none=True)
    tipo_objeto = fields.Str(required=True, validate=validate.OneOf([
        "CONSTRUCCION", "POCION", "COMIDA", "ARMA", "EQUIPO", "MONTURA",
        "RECURSO", "TESORO", "MISION", "HERRAMIENTA"
    ]))
    es_apilable = fields.Bool(load_default=False)
    peso_unidad = fields.Decimal(load_default=0.1, places=2)
    valores_especificos = fields.Raw(load_default={})

class TipoLootTableSchema(Schema):
    id = fields.Int(dump_only=True)
    nombre = fields.Str(required=True, validate=validate.Length(min=1, max=255))
    items = fields.Raw(required=True)

class TipoHabilidadSchema(Schema):
    id = fields.Int(dump_only=True)
    nombre = fields.Str(required=True, validate=validate.Length(min=1, max=255))
    descripcion = fields.Str(allow_none=True)
    tipo_habilidad = fields.Str(required=True, validate=validate.OneOf([
        "ACTIVA", "PASIVA", "DE_CLAN"
    ]))
    coste_energia = fields.Int(load_default=0, validate=validate.Range(min=0))
    cooldown_segundos = fields.Int(load_default=0, validate=validate.Range(min=0))
    valores_habilidad = fields.Raw(load_default={})

class TipoEdificioSchema(Schema):
    id = fields.Int(dump_only=True)
    nombre = fields.Str(required=True, validate=validate.Length(min=1, max=255))
    descripcion = fields.Str(allow_none=True)
    id_grafico = fields.Str(allow_none=True)
    recursos_costo = fields.Raw(load_default={})
    efectos_aldea = fields.Raw(load_default={})
    max_por_aldea = fields.Int(load_default=1)

class TipoNPCSchema(Schema):
    id = fields.Int(dump_only=True)
    nombre = fields.Str(required=True, validate=validate.Length(min=1, max=255))
    descripcion = fields.Str(allow_none=True)
    id_grafico = fields.Str(allow_none=True)
    rol_npc = fields.Str(required=True, validate=validate.OneOf([
        "CONSTRUCTOR", "MALVADO", "COMERCIANTE", "MAGO", "GENERICO"
    ]))
    comportamiento_ia = fields.Str(allow_none=True)
    habilidades_base = fields.List(fields.Int(), load_default=[])
    valores_rol = fields.Raw(load_default={})
    resistencia_dano = fields.Raw(load_default={})

    # Campos que se envían desde el frontend para inicializar CriaturaViva_Base, Daño, Inventario
    initial_salud_max = fields.Int(required=True, load_only=True)
    initial_hambre_max = fields.Int(required=True, load_only=True)
    initial_dano_ataque_base = fields.Int(required=True, load_only=True)
    initial_velocidad_movimiento = fields.Decimal(required=True, load_only=True)
    initial_inventario_capacidad_slots = fields.Int(required=True, load_only=True)
    initial_inventario_capacidad_peso_kg = fields.Decimal(required=True, load_only=True)
    initial_loot_table_id = fields.Int(allow_none=True, load_only=True)

class TipoAnimalSchema(Schema):
    id = fields.Int(dump_only=True)
    nombre = fields.Str(required=True, validate=validate.Length(min=1, max=255))
    descripcion = fields.Str(allow_none=True)
    id_grafico = fields.Str(allow_none=True)
    comportamiento_tipo = fields.Str(allow_none=True, validate=validate.OneOf([
        "PACIFICO", "HOSTIL", "TERRITORIAL"
    ]))
    es_montable = fields.Bool(load_default=False)
    recursos_obtenibles = fields.Raw(load_default={})
    resistencia_dano = fields.Raw(load_default={})

    initial_salud_max = fields.Int(required=True, load_only=True)
    initial_hambre_max = fields.Int(required=True, load_only=True)
    initial_dano_ataque_base = fields.Int(required=True, load_only=True)
    initial_velocidad_movimiento = fields.Decimal(required=True, load_only=True)
    initial_inventario_capacidad_slots = fields.Int(required=True, load_only=True)
    initial_inventario_capacidad_peso_kg = fields.Decimal(required=True, load_only=True)
    initial_loot_table_id = fields.Int(allow_none=True, load_only=True)

class TipoRecursoTerrenoSchema(Schema):
    id = fields.Int(dump_only=True)
    nombre = fields.Str(required=True, validate=validate.Length(min=1, max=255))
    descripcion = fields.Str(allow_none=True)
    id_grafico = fields.Str(allow_none=True)
    salud_base = fields.Int(required=True, validate=validate.Range(min=1))
    recursos_minables = fields.Raw(load_default={})
    efectividad_herramienta = fields.Raw(load_default={})

    initial_loot_table_id = fields.Int(allow_none=True, load_only=True)

class TipoComercianteOfertaSchema(Schema):
    id = fields.Int(dump_only=True)
    id_tipo_objeto_ofrecido = fields.Int(required=True)
    cantidad_ofrecida = fields.Int(required=True, validate=validate.Range(min=1))
    id_tipo_objeto_demandado = fields.Int(required=True)
    cantidad_demandada = fields.Int(required=True, validate=validate.Range(min=1))
    precio_base_moneda = fields.Decimal(load_default=0.00, places=2)

class TipoMisionSchema(Schema):
    id = fields.Int(dump_only=True)
    nombre = fields.Str(required=True, validate=validate.Length(min=1, max=255))
    descripcion = fields.Str(allow_none=True)
    id_tipo_npc_requerido = fields.Int(allow_none=True)
    nivel_requerido = fields.Int(load_default=0, validate=validate.Range(min=0))
    objetivos = fields.Raw(load_default={})
    recompensa = fields.Raw(load_default={})

class TipoEventoGlobalSchema(Schema):
    id = fields.Int(dump_only=True)
    nombre = fields.Str(required=True, validate=validate.Length(min=1, max=255))
    descripcion = fields.Str(allow_none=True)
    fase_activacion = fields.Str(required=True, validate=validate.OneOf(["LUNES", "VIERNES"]))
    duracion_horas = fields.Int(allow_none=True, validate=validate.Range(min=1))
    efectos_mundo = fields.Raw(load_default={})
    objetivos_clan = fields.Raw(load_default={})
    recompensa_exito = fields.Raw(load_default={})
    consecuencia_fracaso = fields.Raw(load_default={})

class TipoPistaSchema(Schema):
    id = fields.Int(dump_only=True)
    nombre = fields.Str(required=True, validate=validate.Length(min=1, max=255))
    contenido = fields.Str(required=True)
    tipo_contenido = fields.Str(allow_none=True, validate=validate.OneOf([
        "TEXTO", "IMAGEN", "COORDENADAS", "PUZZLE"
    ]))
    id_evento_asociado = fields.Int(allow_none=True)
    ubicacion_juego = fields.Str(allow_none=True)

class TipoLootTableSchema(Schema):
    id = fields.Int(dump_only=True)
    nombre = fields.Str(required=True, validate=validate.Length(min=1, max=255))
    items = fields.Raw(required=True)


# --- Esquemas para las instancias de juego (Datos Dinámicos) - Tanda 3 ---

class UsuarioSchema(Schema):
    id = fields.Int(dump_only=True)
    username = fields.Str(required=True, validate=validate.Length(min=3, max=255))
    password_hash = fields.Str(load_only=True) # Password is write-only for security
    email = fields.Email(allow_none=True)
    fecha_creacion = fields.DateTime(dump_only=True)

class ClanSchema(Schema):
    id = fields.Int(dump_only=True)
    nombre = fields.Str(required=True, validate=validate.Length(min=3, max=255))
    descripcion = fields.Str(allow_none=True)
    id_lider_usuario = fields.Int(required=True)
    nivel_experiencia = fields.Int(load_default=1, validate=validate.Range(min=1))
    id_inventario_baluarte = fields.Int(required=True)

class BastionSchema(Schema):
    id = fields.Int(dump_only=True)
    id_usuario = fields.Int(required=True)
    id_clan = fields.Int(allow_none=True)
    nombre_personaje = fields.Str(required=True, validate=validate.Length(min=3, max=255))
    nivel = fields.Int(load_default=1, validate=validate.Range(min=1))
    experiencia = fields.Int(load_default=0, validate=validate.Range(min=0))
    posicion_actual = fields.Raw(required=True) # {"x": 0, "y": 0, "z": 0, "mundo": "CLAN_MUNDO_ACTUAL"}
    habilidades_aprendidas = fields.List(fields.Int(), load_default=[])
    id_criatura_viva_base = fields.Int(required=True)


class MundoSchema(Schema):
    id = fields.Int(dump_only=True)
    tipo_mundo = fields.Str(required=True, validate=validate.OneOf(["CLAN", "PERSONAL"]))
    id_propietario_clan = fields.Int(allow_none=True)
    id_propietario_usuario = fields.Int(allow_none=True)
    nombre_mundo = fields.Str(allow_none=True)
    semilla_generacion = fields.Str(allow_none=True)
    estado_actual_terreno = fields.Raw(load_default={})
    configuracion_actual = fields.Raw(load_default={})

# --- Esquemas para las instancias de juego (Datos Dinámicos) - TANDAS POSTERIORES ---

class InstanciaNPCSchema(Schema):
    id = fields.Int(dump_only=True)
    id_tipo_npc = fields.Int(required=True)
    id_criatura_viva_base = fields.Int(required=True)
    id_mundo = fields.Int(required=True)
    posicion = fields.Raw(required=True)
    esta_vivo = fields.Bool(load_default=True)
    id_aldea_pertenece = fields.Int(allow_none=True)
    id_clan_pertenece = fields.Int(allow_none=True)
    id_persona_pertenece = fields.Int(allow_none=True)
    restriccion_area = fields.Raw(allow_none=True)
    valores_dinamicos = fields.Raw(load_default={})

class InstanciaAnimalSchema(Schema):
    id = fields.Int(dump_only=True)
    id_tipo_animal = fields.Int(required=True)
    id_criatura_viva_base = fields.Int(required=True)
    id_mundo = fields.Int(required=True)
    posicion = fields.Raw(required=True)
    esta_vivo = fields.Bool(load_default=True)
    nivel_carino = fields.Int(load_default=0, validate=validate.Range(min=0))
    id_dueno_usuario = fields.Int(allow_none=True)

class InstanciaRecursoTerrenoSchema(Schema):
    id = fields.Int(dump_only=True)
    id_tipo_recurso_terreno = fields.Int(required=True)
    id_mundo = fields.Int(required=True)
    posicion = fields.Raw(required=True)
    esta_agotado = fields.Bool(load_default=False)
    tiempo_reaparicion = fields.DateTime(allow_none=True)
    id_danio = fields.Int(allow_none=True)

class InstanciaAldeaSchema(Schema):
    id = fields.Int(dump_only=True)
    nombre = fields.Str(allow_none=True)
    id_mundo = fields.Int(required=True)
    posicion_central = fields.Raw(required=True)
    id_clan_propietario = fields.Int(allow_none=True)
    id_inventario_aldea = fields.Int(required=True)
    recursos_produccion_actual = fields.Raw(load_default={})
    nivel_defensa = fields.Int(load_default=0, validate=validate.Range(min=0))
    id_danio_estructura_central = fields.Int(required=True)
    valores_dinamicos = fields.Raw(load_default={})

class InstanciaEdificioSchema(Schema):
    id = fields.Int(dump_only=True)
    id_tipo_edificio = fields.Int(required=True)
    id_aldea = fields.Int(required=True)
    posicion_relativa = fields.Raw(required=True)
    esta_destruido = fields.Bool(load_default=False)
    estado_construccion = fields.Str(allow_none=True, validate=validate.OneOf([
        "COMPLETO", "EN_PROGRESO", "RUINAS"
    ]))
    id_danio = fields.Int(required=True)

class MisionActivaSchema(Schema):
    id = fields.Int(dump_only=True)
    id_tipo_mision = fields.Int(required=True)
    id_bastion = fields.Int(required=True)
    estado_mision = fields.Str(load_default='ACTIVA', validate=validate.OneOf([
        "ACTIVA", "COMPLETADA", "FALLIDA"
    ]))
    progreso_objetivos = fields.Raw(load_default={})
    fecha_inicio = fields.DateTime(dump_only=True)
    fecha_completado = fields.DateTime(allow_none=True)

class EventoGlobalActivoSchema(Schema):
    id = fields.Int(dump_only=True)
    id_tipo_evento_global = fields.Int(required=True)
    id_mundo_clan = fields.Int(required=True)
    fase_actual = fields.Str(required=True, validate=validate.OneOf([
        "MISTERIO", "EVENTO_VIVO", "CONSECUENCIAS"
    ]))
    fecha_inicio = fields.DateTime(dump_only=True)
    fecha_fin_fase_actual = fields.DateTime(allow_none=True)
    estado_logro_clanes = fields.Raw(load_default={})
    consecuencias_aplicadas = fields.Bool(load_default=False)

class InteraccionComercioSchema(Schema):
    id = fields.Int(dump_only=True)
    id_instancia_npc_comerciante = fields.Int(required=True)
    id_bastion_comprador = fields.Int(required=True)
    id_tipo_objeto_comprado = fields.Int(required=True)
    cantidad_comprada = fields.Int(required=True, validate=validate.Range(min=1))
    id_tipo_objeto_vendido = fields.Int(allow_none=True)
    cantidad_vendida = fields.Int(allow_none=True, validate=validate.Range(min=1))
    precio_total = fields.Decimal(allow_none=True, places=2)
    fecha_interaccion = fields.DateTime(dump_only=True)