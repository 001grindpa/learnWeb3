from abc import ABC, abstractmethod

class Type(ABC):
    @abstractmethod
    def type_of_bird(cls):
        raise NotImplementedError
    

class Eagle(Type):
    type = "Bald Eagle"

    def __init__(self, origin: str, age: int) -> None:
        self.origin = origin
        self.age = age

    def __repr__(self) -> str:
        return f"<origin='{self.origin}', age='{self.age} years old'>"
    
    @classmethod
    def type_of_bird(cls):
        return f"{cls.type}"
    
bird_1 = Eagle("American", 22)

print(bird_1.type_of_bird())