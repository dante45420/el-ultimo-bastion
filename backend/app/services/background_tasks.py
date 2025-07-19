# el-ultimo-bastion/backend/app/services/background_tasks.py
import time
# from app import db # Descomentar si la tarea necesita acceso a la DB
# from app.models import SomeModel # Descomentar y reemplazar con modelos reales

def check_inactive_conversations_job(app_instance):
    """
    Tarea de ejemplo en segundo plano. Simplemente imprime un mensaje.
    """
    with app_instance.app_context():
        while True:
            print(f"[{time.ctime()}] Tarea en segundo plano simulada: Verificando algo...")
            # Aquí iría la lógica real de tu tarea
            time.sleep(60 * 5) # Ejecutar cada 5 minutos