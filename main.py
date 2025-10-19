from python.task_manager import TaskManager

tm = TaskManager()

def menu():
    print("\nTask Manager")
    print("1. Añadir tarea")
    print("2. Listar tareas")
    print("3. Marcar como hecha")
    print("4. Borrar tarea")
    print("5. Salir")

while True:
    menu()
    opt = input("> ").strip()
    if opt == "1":
        title = input("Título: ")
        desc = input("Descripción (opcional): ")
        t = tm.add_task(title, desc)
        print(f"Tarea creada con id {t.id}")
    elif opt == "2":
        for t in tm.list_tasks():
            status = "✔" if t.done else "·"
            print(f"{t.id}: [{status}] {t.title} - {t.description}")
    elif opt == "3":
        idn = int(input("Id tarea: "))
        if tm.mark_done(idn):
            print("Marcada como hecha.")
        else:
            print("Id no encontrado.")
    elif opt == "4":
        idn = int(input("Id tarea: "))
        if tm.delete_task(idn):
            print("Borrada.")
        else:
            print("Id no encontrado.")
    else:
        break
