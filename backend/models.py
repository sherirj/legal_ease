from sqlalchemy import Column, Integer, String, ForeignKey
from sqlalchemy.orm import relationship
from database import Base

class User(Base):
    __tablename__ = 'users'
    id = Column(Integer, primary_key=True)
    username = Column(String, unique=True)
    password = Column(String)
    role = Column(String)

    client = relationship("Client", uselist=False, back_populates="user")
    lawyer = relationship("Lawyer", uselist=False, back_populates="user")
    lawfirm = relationship("LawFirm", uselist=False, back_populates="user")


class Client(Base):
    __tablename__ = 'clients'
    id = Column(Integer, primary_key=True)
    full_name = Column(String)
    phone = Column(String)
    user_id = Column(Integer, ForeignKey('users.id'))
    user = relationship("User", back_populates="client")


class Lawyer(Base):
    __tablename__ = 'lawyers'
    id = Column(Integer, primary_key=True)
    full_name = Column(String)
    bar_number = Column(String)
    specialization = Column(String)
    user_id = Column(Integer, ForeignKey('users.id'))
    user = relationship("User", back_populates="lawyer")


class LawFirm(Base):
    __tablename__ = 'lawfirms'
    id = Column(Integer, primary_key=True)
    firm_name = Column(String)
    registration_no = Column(String)
    address = Column(String)
    user_id = Column(Integer, ForeignKey('users.id'))
    user = relationship("User", back_populates="lawfirm")
