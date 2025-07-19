# el-ultimo-bastion/backend/app/models.py
from app import db
from sqlalchemy.dialects.postgresql import JSONB, ARRAY
from sqlalchemy.schema import UniqueConstraint
from sqlalchemy import text # Importar text para FKs que necesitan forward declaration si se usan con .relationship más tarde

# --- CLASES BASE DE COMPOSICIÓN (COMPONENTES REUTILIZABLES) ---

class Inventario(db.Model):
    __tablename__ = 'inventario'
    id = db.Column(db.Integer, primary_key=True)
    contenido = db.Column(JSONB, default={})
    capacidad_slots = db.Column(db.Integer, default=10, nullable=False)
    capacidad_peso_kg = db.Column(db.Numeric(10, 2), default=100.00, nullable=False)

    def __repr__(self):
        return f'<Inventario {self.id}>'

class Daño(db.Model):
    __tablename__ = 'dano'
    id = db.Column(db.Integer, primary_key=True)
    salud_actual = db.Column(db.Integer, nullable=False)
    salud_max = db.Column(db.Integer, nullable=False)
    # loot_table_id: Ahora referenciará TipoLootTable, que se define en esta tanda.
    # La FK se añadirá aquí directamente, ya que TipoLootTable existirá en la misma migración.
    loot_table_id = db.Column(db.Integer, db.ForeignKey('tipoloottable.id'), nullable=True)
    loot_table = db.relationship('TipoLootTable', backref='daños_asociados', lazy=True)

    def __repr__(self):
        return f'<Daño {self.id} Salud:{self.salud_actual}/{self.salud_max}>'

class CriaturaViva_Base(db.Model):
    __tablename__ = 'criaturaviva_base'
    id = db.Column(db.Integer, primary_key=True)
    hambre_actual = db.Column(db.Integer, nullable=False)
    hambre_max = db.Column(db.Integer, nullable=False)
    dano_ataque_base = db.Column(db.Integer, nullable=False)
    velocidad_movimiento = db.Column(db.Numeric(10, 2), nullable=False)

    id_danio = db.Column(db.Integer, db.ForeignKey('dano.id'), unique=True, nullable=False)
    danio = db.relationship('Daño', backref='criatura_viva_base', uselist=False, lazy=True)

    id_inventario = db.Column(db.Integer, db.ForeignKey('inventario.id'), unique=True, nullable=False)
    inventario = db.relationship('Inventario', backref='criatura_viva_base', uselist=False, lazy=True)

    def __repr__(self):
        return f'<CriaturaViva_Base {self.id} Salud:{self.danio.salud_actual}>'


# --- TABLAS DE CONFIGURACIÓN (DEFINICIONES DE TIPOS DE ENTIDADES) ---

class TipoObjeto(db.Model):
    __tablename__ = 'tipoobjeto'
    id = db.Column(db.Integer, primary_key=True)
    nombre = db.Column(db.String(255), unique=True, nullable=False)
    descripcion = db.Column(db.Text)
    id_grafico = db.Column(db.String(255))
    tipo_objeto = db.Column(db.String(100), nullable=False) # "CONSTRUCCION", "POCION", "COMIDA", "ARMA", "EQUIPO", "MONTURA", "RECURSO", "TESORO", "MISION"
    es_apilable = db.Column(db.Boolean, default=False)
    peso_unidad = db.Column(db.Numeric(10, 2), default=0.1, nullable=False)
    # MODIFICADO: Valores específicos ahora incluyen tipo_dano para armas/herramientas
    valores_especificos = db.Column(JSONB, default={})

    def __repr__(self):
        return f'<TipoObjeto {self.nombre}>'

class TipoLootTable(db.Model):
    __tablename__ = 'tipoloottable'
    id = db.Column(db.Integer, primary_key=True)
    nombre = db.Column(db.String(255), unique=True, nullable=False)
    # items: [{"id_tipo_objeto": 1, "min_cantidad": 1, "max_cantidad": 3, "probabilidad": 0.5}]
    items = db.Column(JSONB, default=[]) # Contiene IDs de TipoObjeto

    def __repr__(self):
        return f'<TipoLootTable {self.nombre}>'

class TipoHabilidad(db.Model):
    __tablename__ = 'tipohabilidad'
    id = db.Column(db.Integer, primary_key=True)
    nombre = db.Column(db.String(255), unique=True, nullable=False)
    descripcion = db.Column(db.Text)
    tipo_habilidad = db.Column(db.String(100), nullable=False) # "ACTIVA", "PASIVA", "DE_CLAN"
    coste_energia = db.Column(db.Integer, default=0, nullable=False)
    cooldown_segundos = db.Column(db.Integer, default=0, nullable=False)
    valores_habilidad = db.Column(JSONB, default={})

    def __repr__(self):
        return f'<TipoHabilidad {self.nombre}>'

class TipoEdificio(db.Model):
    __tablename__ = 'tipoedificio'
    id = db.Column(db.Integer, primary_key=True)
    nombre = db.Column(db.String(255), unique=True, nullable=False)
    descripcion = db.Column(db.Text)
    id_grafico = db.Column(db.String(255))
    recursos_costo = db.Column(JSONB, default={}) # [{"id_tipo_objeto": 1, "cantidad": 10}]
    efectos_aldea = db.Column(JSONB, default={}) # {"produccion_bono": 5, "defensa_bono": 10}
    max_por_aldea = db.Column(db.Integer, default=1, nullable=False)

    def __repr__(self):
        return f'<TipoEdificio {self.nombre}>'

# --- CLASES PARA TANDAS POSTERIORES (Incluyendo las adiciones de JSONB para resistencia/efectividad) ---

# Forward declaration para TipoNPC, TipoAnimal, InstanciaAldea, InstanciaEdificio
# Esto es necesario si se referencian antes de su definición completa
class TipoNPC(db.Model):
    __tablename__ = 'tiponpc'
    id = db.Column(db.Integer, primary_key=True)
    nombre = db.Column(db.String(255), unique=True, nullable=False)
    descripcion = db.Column(db.Text)
    id_grafico = db.Column(db.String(255))
    rol_npc = db.Column(db.String(100), nullable=False)
    comportamiento_ia = db.Column(db.Text)
    habilidades_base = db.Column(ARRAY(db.Integer), default=[])
    valores_rol = db.Column(JSONB, default={})
    # ADICIÓN DE TIPO DE DAÑO/RESISTENCIA:
    resistencia_dano = db.Column(JSONB, default={}) # {"TIPO_DAÑO": multiplicador}

    def __repr__(self):
        return f'<TipoNPC {self.nombre}>'

class TipoAnimal(db.Model):
    __tablename__ = 'tipoanimal'
    id = db.Column(db.Integer, primary_key=True)
    nombre = db.Column(db.String(255), unique=True, nullable=False)
    descripcion = db.Column(db.Text)
    id_grafico = db.Column(db.String(255))
    comportamiento_tipo = db.Column(db.String(100), nullable=False)
    es_montable = db.Column(db.Boolean, default=False, nullable=False)
    recursos_obtenibles = db.Column(JSONB, default={})
    # ADICIÓN DE TIPO DE DAÑO/RESISTENCIA:
    resistencia_dano = db.Column(JSONB, default={}) # {"TIPO_DAÑO": multiplicador}

    def __repr__(self):
        return f'<TipoAnimal {self.nombre}>'

class TipoRecursoTerreno(db.Model):
    __tablename__ = 'tiporecursoterreno'
    id = db.Column(db.Integer, primary_key=True)
    nombre = db.Column(db.String(255), unique=True, nullable=False)
    descripcion = db.Column(db.Text)
    id_grafico = db.Column(db.String(255))
    salud_base = db.Column(db.Integer, nullable=False)
    recursos_minables = db.Column(JSONB, default={})
    # ADICIÓN DE EFECTIVIDAD DE HERRAMIENTA:
    efectividad_herramienta = db.Column(JSONB, default={}) # {"TIPO_HERRAMIENTA": multiplicador}

    def __repr__(self):
        return f'<TipoRecursoTerreno {self.nombre}>'

class TipoComercianteOferta(db.Model):
    __tablename__ = 'tipocomercianteoferta'
    id = db.Column(db.Integer, primary_key=True)
    id_tipo_objeto_ofrecido = db.Column(db.Integer, db.ForeignKey('tipoobjeto.id'), nullable=False)
    tipo_objeto_ofrecido = db.relationship('TipoObjeto', foreign_keys=[id_tipo_objeto_ofrecido], lazy=True)
    cantidad_ofrecida = db.Column(db.Integer, nullable=False)
    id_tipo_objeto_demandado = db.Column(db.Integer, db.ForeignKey('tipoobjeto.id'), nullable=False)
    tipo_objeto_demandado = db.relationship('TipoObjeto', foreign_keys=[id_tipo_objeto_demandado], lazy=True)
    cantidad_demandada = db.Column(db.Integer, nullable=False)
    precio_base_moneda = db.Column(db.Numeric(10, 2), default=0.00, nullable=False)

    def __repr__(self):
        return f'<TipoComercianteOferta {self.id}>'

class TipoMision(db.Model):
    __tablename__ = 'tipomision'
    id = db.Column(db.Integer, primary_key=True)
    nombre = db.Column(db.String(255), unique=True, nullable=False)
    descripcion = db.Column(db.Text)
    id_tipo_npc_requerido = db.Column(db.Integer, db.ForeignKey('tiponpc.id'))
    tipo_npc_requerido = db.relationship('TipoNPC', lazy=True)
    nivel_requerido = db.Column(db.Integer, default=0, nullable=False)
    objetivos = db.Column(JSONB, default={})
    recompensa = db.Column(JSONB, default={})

    def __repr__(self):
        return f'<TipoMision {self.nombre}>'

class TipoEventoGlobal(db.Model):
    __tablename__ = 'tipoeventoglobal'
    id = db.Column(db.Integer, primary_key=True)
    nombre = db.Column(db.String(255), unique=True, nullable=False)
    descripcion = db.Column(db.Text)
    fase_activacion = db.Column(db.String(100), nullable=False)
    duracion_horas = db.Column(db.Integer)
    efectos_mundo = db.Column(JSONB, default={})
    objetivos_clan = db.Column(JSONB, default={})
    recompensa_exito = db.Column(JSONB, default={})
    consecuencia_fracaso = db.Column(JSONB, default={})

    def __repr__(self):
        return f'<TipoEventoGlobal {self.nombre}>'

class TipoPista(db.Model):
    __tablename__ = 'tipopista'
    id = db.Column(db.Integer, primary_key=True)
    nombre = db.Column(db.String(255), unique=True, nullable=False)
    contenido = db.Column(db.Text)
    tipo_contenido = db.Column(db.String(100))
    id_evento_asociado = db.Column(db.Integer, db.ForeignKey('tipoeventoglobal.id'))
    evento_asociado = db.relationship('TipoEventoGlobal', lazy=True)
    ubicacion_juego = db.Column(db.Text)

    def __repr__(self):
        return f'<TipoPista {self.nombre}>'


# --- TABLAS DE ESTADO DEL JUEGO (DATOS DINÁMICOS) ---

class Usuario(db.Model):
    __tablename__ = 'usuario'
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(255), unique=True, nullable=False)
    password_hash = db.Column(db.String(255), nullable=False)
    email = db.Column(db.String(255), unique=True)
    fecha_creacion = db.Column(db.DateTime, default=db.func.current_timestamp())

    def __repr__(self):
        return f'<Usuario {self.username}>'

class Clan(db.Model):
    __tablename__ = 'clan'
    id = db.Column(db.Integer, primary_key=True)
    nombre = db.Column(db.String(255), unique=True, nullable=False)
    descripcion = db.Column(db.Text)
    id_lider_usuario = db.Column(db.Integer, db.ForeignKey('usuario.id'))
    lider = db.relationship('Usuario', backref='clanes_liderados', lazy=True)
    nivel_experiencia = db.Column(db.Integer, default=1, nullable=False)

    id_inventario_baluarte = db.Column(db.Integer, db.ForeignKey('inventario.id'), unique=True, nullable=False)
    inventario_baluarte = db.relationship('Inventario', backref='clan_baluarte', uselist=False, lazy=True)

    def __repr__(self):
        return f'<Clan {self.nombre}>'

class Bastion(db.Model):
    __tablename__ = 'bastion'
    id = db.Column(db.Integer, primary_key=True)
    id_usuario = db.Column(db.Integer, db.ForeignKey('usuario.id'), unique=True, nullable=False)
    usuario = db.relationship('Usuario', backref='bastion_personaje', uselist=False, lazy=True)
    id_clan = db.Column(db.Integer, db.ForeignKey('clan.id'))
    clan = db.relationship('Clan', backref='miembros_bastion', lazy=True)
    nombre_personaje = db.Column(db.String(255), nullable=False)
    nivel = db.Column(db.Integer, default=1, nullable=False)
    experiencia = db.Column(db.Integer, default=0, nullable=False)
    posicion_actual = db.Column(JSONB) # {"x": 0, "y": 0, "z": 0, "mundo": "CLAN_MUNDO_ACTUAL"}
    habilidades_aprendidas = db.Column(ARRAY(db.Integer), default=[], nullable=False) # Array de IDs de TipoHabilidad

    id_criatura_viva_base = db.Column(db.Integer, db.ForeignKey('criaturaviva_base.id'), unique=True, nullable=False)
    criatura_viva_base = db.relationship('CriaturaViva_Base', backref='bastion_personaje', uselist=False, lazy=True)

    def __repr__(self):
        return f'<Bastion {self.nombre_personaje}>'

class Mundo(db.Model):
    __tablename__ = 'mundo'
    id = db.Column(db.Integer, primary_key=True)
    tipo_mundo = db.Column(db.String(50), nullable=False) # "CLAN", "PERSONAL"
    id_propietario_clan = db.Column(db.Integer, db.ForeignKey('clan.id'))
    propietario_clan = db.relationship('Clan', backref='mundos_clan', lazy=True)
    id_propietario_usuario = db.Column(db.Integer, db.ForeignKey('usuario.id'))
    propietario_usuario = db.relationship('Usuario', backref='mundos_personales', lazy=True)
    nombre_mundo = db.Column(db.String(255))
    semilla_generacion = db.Column(db.Text)
    estado_actual_terreno = db.Column(JSONB, default={})
    configuracion_actual = db.Column(JSONB, default={})

    __table_args__ = (
        UniqueConstraint('tipo_mundo', 'id_propietario_clan', name='_unique_clan_world_per_clan'),
        UniqueConstraint('tipo_mundo', 'id_propietario_usuario', name='_unique_personal_world_per_user'),
    )

    def __repr__(self):
        return f'<Mundo {self.nombre_mundo} ({self.tipo_mundo})>'

class InstanciaAldea(db.Model):
    __tablename__ = 'instanciaaldea'
    id = db.Column(db.Integer, primary_key=True)
    nombre = db.Column(db.String(255))

    id_mundo = db.Column(db.Integer, db.ForeignKey('mundo.id'), nullable=False)
    mundo_rel = db.relationship('Mundo', backref='aldeas_en_mundo', lazy=True)

    posicion_central = db.Column(JSONB, nullable=False)
    id_clan_propietario = db.Column(db.Integer, db.ForeignKey('clan.id'))
    clan_propietario = db.relationship('Clan', backref='aldeas_propias', lazy=True)

    id_inventario_aldea = db.Column(db.Integer, db.ForeignKey('inventario.id'), unique=True, nullable=False)
    inventario_aldea = db.relationship('Inventario', backref='aldea_instancia', uselist=False, lazy=True)

    recursos_produccion_actual = db.Column(JSONB, default={})
    nivel_defensa = db.Column(db.Integer, default=0, nullable=False)

    id_danio_estructura_central = db.Column(db.Integer, db.ForeignKey('dano.id'), unique=True, nullable=False)
    danio_estructura_central = db.relationship('Daño', backref='aldea_estructura_central', uselist=False, lazy=True)

    valores_dinamicos = db.Column(JSONB, default={})

    def __repr__(self):
        # Asegúrate que mundo_rel está cargado antes de acceder a .nombre_mundo
        # o usa un try-except si lazy='select' es el valor por defecto
        mundo_nombre = self.mundo_rel.nombre_mundo if self.mundo_rel else "Desconocido"
        return f'<InstanciaAldea {self.nombre} en {mundo_nombre}>'


class InstanciaNPC(db.Model):
    __tablename__ = 'instancianpc'
    id = db.Column(db.Integer, primary_key=True)
    id_tipo_npc = db.Column(db.Integer, db.ForeignKey('tiponpc.id'), nullable=False)
    tipo_npc = db.relationship('TipoNPC', backref='instancias', lazy=True)

    id_criatura_viva_base = db.Column(db.Integer, db.ForeignKey('criaturaviva_base.id'), unique=True, nullable=False)
    criatura_viva_base = db.relationship('CriaturaViva_Base', backref='instancia_npc', uselist=False, lazy=True)

    id_mundo = db.Column(db.Integer, db.ForeignKey('mundo.id'), nullable=False)
    mundo = db.relationship('Mundo', backref='npcs_en_mundo', lazy=True)

    posicion = db.Column(JSONB, nullable=False)
    esta_vivo = db.Column(db.Boolean, default=True, nullable=False)

    # Relaciones de pertenencia (opcionales)
    id_aldea_pertenece = db.Column(db.Integer, db.ForeignKey('instanciaaldea.id'))
    aldea_pertenece = db.relationship('InstanciaAldea', foreign_keys=[id_aldea_pertenece], backref='npcs_en_aldea', lazy=True)

    id_clan_pertenece = db.Column(db.Integer, db.ForeignKey('clan.id'))
    clan_pertenece = db.relationship('Clan', backref='npcs_del_clan', lazy=True)
    id_persona_pertenece = db.Column(db.Integer, db.ForeignKey('usuario.id'))
    persona_pertenece = db.relationship('Usuario', backref='npcs_personales', lazy=True)

    restriccion_area = db.Column(JSONB)
    valores_dinamicos = db.Column(JSONB, default={})

    def __repr__(self):
        return f'<InstanciaNPC {self.tipo_npc.nombre} en {self.mundo.nombre_mundo}>'

class InstanciaAnimal(db.Model):
    __tablename__ = 'instanciaanimal'
    id = db.Column(db.Integer, primary_key=True)
    id_tipo_animal = db.Column(db.Integer, db.ForeignKey('tipoanimal.id'), nullable=False)
    tipo_animal = db.relationship('TipoAnimal', backref='instancias', lazy=True)

    id_criatura_viva_base = db.Column(db.Integer, db.ForeignKey('criaturaviva_base.id'), unique=True, nullable=False)
    criatura_viva_base = db.relationship('CriaturaViva_Base', backref='instancia_animal', uselist=False, lazy=True)

    id_mundo = db.Column(db.Integer, db.ForeignKey('mundo.id'), nullable=False)
    mundo = db.relationship('Mundo', backref='animales_en_mundo', lazy=True)

    posicion = db.Column(JSONB, nullable=False)
    esta_vivo = db.Column(db.Boolean, default=True, nullable=False)
    nivel_carino = db.Column(db.Integer, default=0, nullable=False)
    id_dueno_usuario = db.Column(db.Integer, db.ForeignKey('usuario.id'))
    dueno_usuario = db.relationship('Usuario', backref='animales_domesticados', lazy=True)

    def __repr__(self):
        return f'<InstanciaAnimal {self.tipo_animal.nombre} en {self.mundo.nombre_mundo}>'

class InstanciaRecursoTerreno(db.Model):
    __tablename__ = 'instanciarecursoterreno'
    id = db.Column(db.Integer, primary_key=True)
    id_tipo_recurso_terreno = db.Column(db.Integer, db.ForeignKey('tiporecursoterreno.id'), nullable=False)
    tipo_recurso_terreno = db.relationship('TipoRecursoTerreno', backref='instancias', lazy=True)

    id_mundo = db.Column(db.Integer, db.ForeignKey('mundo.id'), nullable=False)
    mundo = db.relationship('Mundo', backref='recursos_en_mundo', lazy=True)

    posicion = db.Column(JSONB, nullable=False)
    esta_agotado = db.Column(db.Boolean, default=False, nullable=False)
    tiempo_reaparicion = db.Column(db.DateTime)

    id_danio = db.Column(db.Integer, db.ForeignKey('dano.id'), unique=True) # Puede ser nulo si no tiene salud individual
    danio = db.relationship('Daño', backref='instancia_recurso_terreno', uselist=False, lazy=True)

    def __repr__(self):
        return f'<InstanciaRecursoTerreno {self.tipo_recurso_terreno.nombre} en {self.mundo.nombre_mundo}>'




class InstanciaEdificio(db.Model):
    __tablename__ = 'instanciaedificio'
    id = db.Column(db.Integer, primary_key=True)
    id_tipo_edificio = db.Column(db.Integer, db.ForeignKey('tipoedificio.id'), nullable=False)
    tipo_edificio = db.relationship('TipoEdificio', backref='instancias', lazy=True)

    id_aldea = db.Column(db.Integer, db.ForeignKey('instanciaaldea.id'), nullable=False)
    aldea = db.relationship('InstanciaAldea', backref='edificios_en_aldea', lazy=True)

    posicion_relativa = db.Column(JSONB, nullable=False)
    esta_destruido = db.Column(db.Boolean, default=False, nullable=False)
    estado_construccion = db.Column(db.String(50)) # "COMPLETO", "EN_PROGRESO", "RUINAS"

    id_danio = db.Column(db.Integer, db.ForeignKey('dano.id'), unique=True, nullable=False)
    danio = db.relationship('Daño', backref='instancia_edificio', uselist=False, lazy=True)

    def __repr__(self):
        return f'<InstanciaEdificio {self.tipo_edificio.nombre} en Aldea:{self.aldea.nombre}>'

class MisionActiva(db.Model):
    __tablename__ = 'misionactiva'
    id = db.Column(db.Integer, primary_key=True)
    id_tipo_mision = db.Column(db.Integer, db.ForeignKey('tipomision.id'), nullable=False)
    tipo_mision = db.relationship('TipoMision', backref='misiones_activas', lazy=True)

    id_bastion = db.Column(db.Integer, db.ForeignKey('bastion.id'), nullable=False)
    bastion = db.relationship('Bastion', backref='misiones_activas', lazy=True)

    estado_mision = db.Column(db.String(50), default='ACTIVA', nullable=False)
    progreso_objetivos = db.Column(JSONB, default={})
    fecha_inicio = db.Column(db.DateTime, default=db.func.current_timestamp(), nullable=False)
    fecha_completado = db.Column(db.DateTime)

    def __repr__(self):
        return f'<MisionActiva {self.tipo_mision.nombre} para {self.bastion.nombre_personaje}>'

class EventoGlobalActivo(db.Model):
    __tablename__ = 'eventoglobalactivo'
    id = db.Column(db.Integer, primary_key=True)
    id_tipo_evento_global = db.Column(db.Integer, db.ForeignKey('tipoeventoglobal.id'), nullable=False)
    tipo_evento_global = db.relationship('TipoEventoGlobal', backref='eventos_activos', lazy=True)

    id_mundo_clan = db.Column(db.Integer, db.ForeignKey('mundo.id'), nullable=False)
    mundo_clan = db.relationship('Mundo', backref='eventos_activos', lazy=True)

    fase_actual = db.Column(db.String(100), nullable=False)
    fecha_inicio = db.Column(db.DateTime, default=db.func.current_timestamp(), nullable=False)
    fecha_fin_fase_actual = db.Column(db.DateTime)
    estado_logro_clanes = db.Column(JSONB, default={})
    consecuencias_aplicadas = db.Column(db.Boolean, default=False, nullable=False)

    def __repr__(self):
        return f'<EventoGlobalActivo {self.tipo_evento_global.nombre} en {self.mundo_clan.nombre_mundo}>'

class InteraccionComercio(db.Model):
    __tablename__ = 'interaccioncomercio'
    id = db.Column(db.Integer, primary_key=True)
    id_instancia_npc_comerciante = db.Column(db.Integer, db.ForeignKey('instancianpc.id'), nullable=False)
    instancia_npc_comerciante = db.relationship('InstanciaNPC', backref='transacciones_comerciales', lazy=True)

    id_bastion_comprador = db.Column(db.Integer, db.ForeignKey('bastion.id'), nullable=False)
    bastion_comprador = db.relationship('Bastion', backref='compras_realizadas', lazy=True)

    id_tipo_objeto_comprado = db.Column(db.Integer, db.ForeignKey('tipoobjeto.id'), nullable=False)
    tipo_objeto_comprado = db.relationship('TipoObjeto', foreign_keys=[id_tipo_objeto_comprado], lazy=True)
    cantidad_comprada = db.Column(db.Integer, nullable=False)

    id_tipo_objeto_vendido = db.Column(db.Integer, db.ForeignKey('tipoobjeto.id'))
    tipo_objeto_vendido = db.relationship('TipoObjeto', foreign_keys=[id_tipo_objeto_vendido], lazy=True)
    cantidad_vendida = db.Column(db.Integer)

    precio_total = db.Column(db.Numeric(10, 2))
    fecha_interaccion = db.Column(db.DateTime, default=db.func.current_timestamp(), nullable=False)

    def __repr__(self):
        return f'<InteraccionComercio {self.id}>'