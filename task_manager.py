import json
from dataclasses import dataclass, asdict
from typing import List, Optional
from datetime import datetime
from pathlib import Path

DATA_FILE = Path("tasks.json")

@dataclass  #para definir una clase de datos simple
class Task:
    id: int
    title: str
    description: str = ""
    done: bool = False
    created_at: str = None

    def __post_init__(self): #se ejecuta automáticamente después del método __init__
        if self.created_at is None:
            self.created_at = datetime.utcnow().isoformat()

class TaskManager:
    def __init__(self, data_file: Path = DATA_FILE):
        self.data_file = data_file
        self.tasks: List[Task] = []
        self._load()

    def _load(self):#cargar las tareas desde el archivo JSON, que se genera automáticamente si no existe
        if self.data_file.exists():
            with open(self.data_file, "r", encoding="utf-8") as f:
                raw = json.load(f)
            self.tasks = [Task(**t) for t in raw]
        else:
            self.tasks = []

    def _save(self):
        with open(self.data_file, "w", encoding="utf-8") as f:
            json.dump([asdict(t) for t in self.tasks], f, indent=2, ensure_ascii=False)

    def _next_id(self) -> int:
        return max((t.id for t in self.tasks), default=0) + 1

    def add_task(self, title: str, description: str = "") -> Task:
        t = Task(id=self._next_id(), title=title, description=description)
        self.tasks.append(t)
        self._save()
        return t

    def list_tasks(self, only_pending: bool = False) -> List[Task]:
        return [t for t in self.tasks if not only_pending or not t.done]

    def mark_done(self, task_id: int) -> bool:
        t = self._find(task_id)
        if t:
            t.done = True
            self._save()
            return True
        return False

    def delete_task(self, task_id: int) -> bool:
        t = self._find(task_id)
        if t:
            self.tasks.remove(t)
            self._save()
            return True
        return False

    def _find(self, task_id: int) -> Optional[Task]:
        for t in self.tasks:
            if t.id == task_id:
                return t
        return None
