# el-ultimo-bastion/backend/run.py

import threading
from app import create_app
import time # Importar time para el ejemplo de background_tasks

app = create_app()

if __name__ == '__main__':
    # Placeholder para las tareas en segundo plano (aún no se implementan completamente)
    # from app.services.background_tasks import check_inactive_conversations_job
    # background_thread = threading.Thread(target=check_inactive_conversations_job, args=(app,), daemon=True)
    # background_thread.start()
    
    print("Backend iniciando. Accede a http://127.0.0.1:5000/")
    app.run(debug=True, use_reloader=False) # use_reloader=False para no reiniciar el hilo