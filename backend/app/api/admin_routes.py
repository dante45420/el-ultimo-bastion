# el-ultimo-bastion/backend/api/admin_routes.py
from flask import Blueprint, request, jsonify
from app import db # Asegúrate que 'db' se importa desde 'app'
# Importa solo los modelos y esquemas de la tanda actual si es necesario para alguna ruta
# from app.models import Inventario, Daño, CriaturaViva_Base
# from app.schemas import InventarioSchema, DañoSchema, CriaturaVivaBaseSchema
from flask_cors import CORS # Import CORS

admin_bp = Blueprint('admin', __name__)

@admin_bp.route('/')
def admin_index():
    return "API de administración de El Último Bastión está funcionando."

# No hay rutas CRUD para Tanda 1, solo para probar la DB con tests.
# Las rutas para TipoNPC, etc., se añadirán en tandas posteriores.