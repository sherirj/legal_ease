from pydantic import BaseModel

class UserBase(BaseModel):
    username: str
    password: str

class ClientCreate(UserBase):
    full_name: str
    phone: str

class LawyerCreate(UserBase):
    full_name: str
    bar_number: str
    specialization: str

class LawFirmCreate(UserBase):
    firm_name: str
    registration_no: str
    address: str
