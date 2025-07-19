# el-ultimo-bastion/backend/tests/test_tanda2_types.py
import pytest
from app.models import (
    TipoObjeto, TipoLootTable, TipoHabilidad, TipoEdificio,
    Daño # Necesario para loot_table_id
)
import sqlalchemy.exc

# --- Tests para TipoObjeto ---
def test_create_tipo_objeto_recurso(session):
    print("\n--- Test: Crear TipoObjeto Recurso ---")
    obj = TipoObjeto(nombre="Madera Dura", descripcion="Madera resistente.", id_grafico="hard_wood", tipo_objeto="RECURSO", es_apilable=True, peso_unidad=1.5)
    session.add(obj)
    session.commit()
    assert obj.id is not None
    assert obj.nombre == "Madera Dura"
    assert obj.tipo_objeto == "RECURSO"
    assert obj.es_apilable is True
    print(f"TipoObjeto Recurso '{obj.nombre}' creado con ID: {obj.id}")

def test_create_tipo_objeto_arma(session):
    print("\n--- Test: Crear TipoObjeto Arma ---")
    arma = TipoObjeto(nombre="Hacha de Batalla", descripcion="Hacha pesada de dos manos.", id_grafico="battle_axe", tipo_objeto="ARMA", es_apilable=False, peso_unidad=10.0, valores_especificos={"dano_min": 20, "dano_max": 30, "tipo_dano": "CORTANTE"})
    session.add(arma)
    session.commit()
    assert arma.id is not None
    assert arma.tipo_objeto == "ARMA"
    assert arma.valores_especificos["tipo_dano"] == "CORTANTE"
    print(f"TipoObjeto Arma '{arma.nombre}' creado con ID: {arma.id}")

def test_create_tipo_objeto_herramienta(session):
    print("\n--- Test: Crear TipoObjeto Herramienta ---")
    herramienta = TipoObjeto(nombre="Picota de Hierro", descripcion="Picota robusta para minar.", id_grafico="iron_pickaxe", tipo_objeto="HERRAMIENTA", es_apilable=False, peso_unidad=4.0, valores_especificos={"tipo_herramienta": "PICO", "efectividad_base": 1.2, "tipo_dano": "PICO"})
    session.add(herramienta)
    session.commit()
    assert herramienta.id is not None
    assert herramienta.tipo_objeto == "HERRAMIENTA"
    assert herramienta.valores_especificos["tipo_dano"] == "PICO"
    print(f"TipoObjeto Herramienta '{herramienta.nombre}' creado con ID: {herramienta.id}")

def test_tipo_objeto_unique_name(session):
    print("\n--- Test: Unicidad de nombre en TipoObjeto ---")
    obj1 = TipoObjeto(nombre="Objeto Unico", tipo_objeto="RECURSO")
    session.add(obj1)
    session.flush()

    with pytest.raises(sqlalchemy.exc.IntegrityError) as excinfo:
        obj2 = TipoObjeto(nombre="Objeto Unico", tipo_objeto="POCION") # Mismo nombre
        session.add(obj2)
        session.flush()
    assert "unique constraint" in str(excinfo.value).lower()
    session.rollback()
    print("Excepción de nombre de TipoObjeto duplicado capturada correctamente.")


# --- Tests para TipoLootTable ---
def test_create_tipoloottable_basic(session):
    print("\n--- Test: Crear TipoLootTable Básico ---")
    # Necesitamos un TipoObjeto para referenciar
    obj_test_loot = TipoObjeto(nombre="TestItemLoot", tipo_objeto="RECURSO")
    session.add(obj_test_loot)
    session.flush()

    loot_table = TipoLootTable(
        nombre="Cofre Básico",
        items=[{"id_tipo_objeto": obj_test_loot.id, "min_cantidad": 1, "max_cantidad": 5, "probabilidad": 0.8}]
    )
    session.add(loot_table)
    session.commit()
    assert loot_table.id is not None
    assert loot_table.nombre == "Cofre Básico"
    assert len(loot_table.items) == 1
    assert loot_table.items[0]['id_tipo_objeto'] == obj_test_loot.id
    print(f"TipoLootTable '{loot_table.nombre}' creado con ID: {loot_table.id}")

def test_dano_loot_table_relationship(session):
    print("\n--- Test: Relación Daño - TipoLootTable ---")
    # Crear TipoObjeto y TipoLootTable
    obj_rel_test = TipoObjeto(nombre="RelItem", tipo_objeto="RECURSO")
    session.add(obj_rel_test)
    session.flush()

    loot_table_rel = TipoLootTable(nombre="Loot Relacion", items=[{"id_tipo_objeto": obj_rel_test.id, "probabilidad": 1.0}])
    session.add(loot_table_rel)
    session.flush()

    # Crear Daño referenciando la loot table
    dano_rel = Daño(salud_actual=100, salud_max=100, loot_table_id=loot_table_rel.id)
    session.add(dano_rel)
    session.commit()

    assert dano_rel.id is not None
    assert dano_rel.loot_table_id == loot_table_rel.id
    assert dano_rel.loot_table.nombre == "Loot Relacion" # Verificar acceso a través de relationship
    print(f"Relación Daño con TipoLootTable verificada. Daño ID {dano_rel.id} -> LootTable ID {dano_rel.loot_table.id}")


# --- Tests para TipoHabilidad ---
def test_create_tipo_habilidad_activa(session):
    print("\n--- Test: Crear TipoHabilidad Activa ---")
    habilidad = TipoHabilidad(nombre="Ataque Poderoso", descripcion="Inflige gran daño.", tipo_habilidad="ACTIVA", coste_energia=30, cooldown_segundos=10, valores_habilidad={"dano_extra": 50})
    session.add(habilidad)
    session.commit()
    assert habilidad.id is not None
    assert habilidad.nombre == "Ataque Poderoso"
    assert habilidad.tipo_habilidad == "ACTIVA"
    assert habilidad.coste_energia == 30
    assert habilidad.valores_habilidad["dano_extra"] == 50
    print(f"TipoHabilidad '{habilidad.nombre}' creado con ID: {habilidad.id}")

def test_create_tipo_habilidad_pasiva(session):
    print("\n--- Test: Crear TipoHabilidad Pasiva ---")
    habilidad = TipoHabilidad(nombre="Piel Gruesa", descripcion="Otorga resistencia al daño.", tipo_habilidad="PASIVA", valores_habilidad={"resistencia_porcentaje": 0.1})
    session.add(habilidad)
    session.commit()
    assert habilidad.id is not None
    assert habilidad.tipo_habilidad == "PASIVA"
    assert habilidad.valores_habilidad["resistencia_porcentaje"] == 0.1
    print(f"TipoHabilidad '{habilidad.nombre}' creado con ID: {habilidad.id}")


# --- Tests para TipoEdificio ---
def test_create_tipo_edificio_casa(session):
    print("\n--- Test: Crear TipoEdificio Casa ---")
    # Necesitamos un TipoObjeto para los recursos_costo
    obj_ladrillo = TipoObjeto(nombre="Ladrillo", tipo_objeto="RECURSO")
    session.add(obj_ladrillo)
    session.flush()

    edificio = TipoEdificio(nombre="Casa Familiar", descripcion="Una casa grande.", id_grafico="family_house", recursos_costo=[{"id_tipo_objeto": obj_ladrillo.id, "cantidad": 50}], efectos_aldea={"felicidad_bono": 10}, max_por_aldea=5)
    session.add(edificio)
    session.commit()
    assert edificio.id is not None
    assert edificio.nombre == "Casa Familiar"
    assert edificio.max_por_aldea == 5
    assert edificio.recursos_costo[0]["id_tipo_objeto"] == obj_ladrillo.id
    print(f"TipoEdificio '{edificio.nombre}' creado con ID: {edificio.id}")

def test_tipo_edificio_unique_name(session):
    print("\n--- Test: Unicidad de nombre en TipoEdificio ---")
    edif1 = TipoEdificio(nombre="Edificio Unico", max_por_aldea=1)
    session.add(edif1)
    session.flush()

    with pytest.raises(sqlalchemy.exc.IntegrityError) as excinfo:
        edif2 = TipoEdificio(nombre="Edificio Unico", max_por_aldea=2) # Mismo nombre
        session.add(edif2)
        session.flush()
    assert "unique constraint" in str(excinfo.value).lower()
    session.rollback()
    print("Excepción de nombre de TipoEdificio duplicado capturada correctamente.")