# el-ultimo-bastion/backend/tests/test_tanda1_components.py
import pytest
from app.models import Inventario, Daño, CriaturaViva_Base
import sqlalchemy.exc # Importa esto para capturar las excepciones específicas

# Test para Inventario
def test_create_inventario(session):
    """
    Simula la creación de un inventario y verifica su estado inicial.
    """
    print("\n--- Test: Crear Inventario ---")
    inv = Inventario(capacidad_slots=20, capacidad_peso_kg=150.0)
    session.add(inv)
    session.commit() # Simula el commit a la DB
    print(f"Inventario creado con ID: {inv.id}")

    assert inv.id is not None
    assert inv.contenido == {} # Debe ser un diccionario vacío por defecto
    assert inv.capacidad_slots == 20
    assert inv.capacidad_peso_kg == 150.0

    retrieved_inv = session.get(Inventario, inv.id)
    assert retrieved_inv.capacidad_slots == 20
    print("Inventario recuperado y verificado correctamente.")

def test_update_inventario_content(session):
    """
    Simula la adición de ítems a un inventario y su actualización.
    """
    print("\n--- Test: Actualizar Contenido de Inventario ---")
    inv = Inventario(capacidad_slots=10, capacidad_peso_kg=50.0)
    session.add(inv)
    session.commit()
    print(f"Inventario inicial creado con ID: {inv.id}")

    # Simular añadir ítems (referenciando TipoObjeto, aunque no los creamos aquí para este test específico)
    inv.contenido = {"id_tipo_objeto_1": 5, "id_tipo_objeto_2": 1}
    session.add(inv)
    session.commit()
    print(f"Contenido actualizado a: {inv.contenido}")

    retrieved_inv = session.get(Inventario, inv.id)
    assert retrieved_inv.contenido == {"id_tipo_objeto_1": 5, "id_tipo_objeto_2": 1}
    print("Contenido del inventario actualizado y verificado.")

# Test para Daño
def test_create_dano_basic(session):
    """
    Simula la creación de un componente de daño básico.
    """
    print("\n--- Test: Crear Daño Básico ---")
    dano = Daño(salud_actual=100, salud_max=100) # loot_table_id es None por defecto
    session.add(dano)
    session.commit()
    print(f"Componente Daño creado con ID: {dano.id}")

    assert dano.id is not None
    assert dano.salud_actual == 100
    assert dano.salud_max == 100
    assert dano.loot_table_id is None # Verificar que es None si no se provee
    print("Componente Daño verificado correctamente.")

def test_update_dano_health_value(session):
    """
    Simula recibir daño y actualizar el valor de salud.
    """
    print("\n--- Test: Actualizar Salud de Daño ---")
    dano = Daño(salud_actual=100, salud_max=100)
    session.add(dano)
    session.commit()
    print(f"Salud inicial de Daño ID {dano.id}: {dano.salud_actual}")

    dano.salud_actual = 75 # Simular recibir daño
    session.add(dano)
    session.commit()
    print(f"Salud actualizada a: {dano.salud_actual}")

    retrieved_dano = session.get(Daño, dano.id)
    assert retrieved_dano.salud_actual == 75
    print("Salud de Daño actualizada y verificada.")

# Test para CriaturaViva_Base
def test_create_criaturaviva_base(session):
    """
    Simula la creación de una base de criatura viva con sus componentes de daño e inventario.
    """
    print("\n--- Test: Crear CriaturaViva_Base ---")
    # Crear componentes asociados
    inv = Inventario(capacidad_slots=10, capacidad_peso_kg=30.0)
    dano = Daño(salud_actual=100, salud_max=100)
    session.add_all([inv, dano])
    session.flush() # Importante para obtener IDs antes de usarlos

    cv_base = CriaturaViva_Base(
        hambre_actual=80, hambre_max=100, dano_ataque_base=15, velocidad_movimiento=5.5,
        id_danio=dano.id, id_inventario=inv.id
    )
    session.add(cv_base)
    session.commit()
    print(f"CriaturaViva_Base creada con ID: {cv_base.id}")

    assert cv_base.id is not None
    assert cv_base.hambre_actual == 80
    assert cv_base.dano_ataque_base == 15
    assert cv_base.danio.salud_max == 100 # Acceso a través de la relación
    assert cv_base.inventario.capacidad_slots == 10 # Acceso a través de la relación
    print("CriaturaViva_Base creada y relaciones verificadas.")

def test_criaturaviva_base_unique_id_danio(session):
    """
    Verifica que id_danio es único para CriaturaViva_Base.
    """
    print("\n--- Test: Unicidad de id_danio en CriaturaViva_Base ---")
    # Crear componentes para la primera CriaturaViva_Base
    inv1 = Inventario(capacidad_slots=10, capacidad_peso_kg=10.0)
    dano1 = Daño(salud_actual=100, salud_max=100)
    session.add_all([inv1, dano1])
    session.flush() # Obtener IDs

    cv1 = CriaturaViva_Base(hambre_actual=10, hambre_max=10, dano_ataque_base=1, velocidad_movimiento=1.0, id_danio=dano1.id, id_inventario=inv1.id)
    session.add(cv1)
    session.flush()
    print(f"Primera CriaturaViva_Base (ID: {cv1.id}) creada con id_danio={dano1.id}.")

    # Intentar crear una segunda CriaturaViva_Base usando el MISMO id_danio (dano1.id)
    print("Intentando crear CriaturaViva_Base con id_danio duplicado...")
    inv_new = Inventario(capacidad_slots=10, capacidad_peso_kg=10.0) # Nuevo inventario para evitar colisión de inv
    session.add(inv_new)
    session.flush()

    with pytest.raises(sqlalchemy.exc.IntegrityError) as excinfo:
        cv_fail = CriaturaViva_Base(hambre_actual=10, hambre_max=10, dano_ataque_base=1, velocidad_movimiento=1.0, id_danio=dano1.id, id_inventario=inv_new.id)
        session.add(cv_fail)
        session.flush() # Esto debería fallar

    assert "unique constraint" in str(excinfo.value).lower()
    print("Excepción de id_danio duplicado capturada correctamente.")
    session.rollback() # Limpiar la transacción con el fallo

# --- NUEVO TEST 2: Verificar unicidad de id_inventario en CriaturaViva_Base ---
def test_criaturaviva_base_unique_id_inventario(session):
    """
    Verifica que id_inventario es único para CriaturaViva_Base.
    """
    print("\n--- Test: Unicidad de id_inventario en CriaturaViva_Base ---")
    # Crear componentes para la primera CriaturaViva_Base (en este nuevo test)
    inv1 = Inventario(capacidad_slots=10, capacidad_peso_kg=10.0)
    dano1 = Daño(salud_actual=100, salud_max=100)
    session.add_all([inv1, dano1])
    session.flush()

    cv1 = CriaturaViva_Base(hambre_actual=10, hambre_max=10, dano_ataque_base=1, velocidad_movimiento=1.0, id_danio=dano1.id, id_inventario=inv1.id)
    session.add(cv1)
    session.flush()
    print(f"Primera CriaturaViva_Base (ID: {cv1.id}) creada con id_inventario={inv1.id}.")

    # Intentar crear una segunda CriaturaViva_Base usando el MISMO id_inventario (inv1.id)
    print("Intentando crear CriaturaViva_Base con id_inventario duplicado...")
    dano_new = Daño(salud_actual=100, salud_max=100) # Nuevo daño para evitar colisión de daño
    session.add(dano_new)
    session.flush()

    with pytest.raises(sqlalchemy.exc.IntegrityError) as excinfo:
        cv_fail = CriaturaViva_Base(hambre_actual=10, hambre_max=10, dano_ataque_base=1, velocidad_movimiento=1.0, id_danio=dano_new.id, id_inventario=inv1.id)
        session.add(cv_fail)
        session.flush() # Esto debería fallar

    assert "unique constraint" in str(excinfo.value).lower()
    print("Excepción de id_inventario duplicado capturada correctamente.")
    session.rollback() # Limpiar la transacción con el fallo
