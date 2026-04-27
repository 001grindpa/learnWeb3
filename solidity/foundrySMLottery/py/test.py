class Father:
    def __init__(self, name, position, breadwinner: bool):
        self.__name = name
        self.__position = position
        self.__breadwinner = breadwinner

    # attribute access configuration
    @property
    def name(self):
        return f"<Name: '{self.__name}'>"
    @name.setter
    def name(self):
        print("You're not allowed to change this attribute.")
    @name.deleter
    def name(self):
        print("You're not allowed to delete this attribute.")

    @property
    def position(self):
        return f"<Name: '{self.__position}'>"
    @position.setter
    def position(self):
        print("You're not allowed to change this attribute.")
    @position.deleter
    def position(self):
        print("You're not allowed to delete this attribute.")

    # methods
    def breadwinner(self):
        if self.__breadwinner == True:
            return "I am the breadwinner"
        return "I am not the breadwinner"

class Son(Father):
    def __init__(self, name, position, breadwinner):
        super().__init__(name=name, position=position, breadwinner=breadwinner)

    
father_1 = Father(name="Aso", position="leader", breadwinner=True)
son_1 = Son(name="Jude", position="follower", breadwinner=False)

print(father_1.breadwinner())
print(son_1.breadwinner())