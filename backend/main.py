from fastapi import FastAPI, Depends, HTTPException
from sqlalchemy.orm import Session
from models import User, Client, Lawyer, LawFirm
from schemas import ClientCreate, LawyerCreate, LawFirmCreate
from database import SessionLocal
from utils import hash_password
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_credentials=True, allow_methods=["*"], allow_headers=["*"])

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@app.post("/register/client")
def register_client(client_data: ClientCreate, db: Session = Depends(get_db)):
    if db.query(User).filter(User.username == client_data.username).first():
        raise HTTPException(status_code=400, detail="Username taken")
    user = User(username=client_data.username, password=hash_password(client_data.password), role="client")
    db.add(user)
    db.flush()  # Get user.id
    client = Client(full_name=client_data.full_name, phone=client_data.phone, user_id=user.id)
    db.add(client)
    db.commit()
    return {"msg": "Client registered successfully"}

@app.post("/register/lawyer")
def register_lawyer(lawyer_data: LawyerCreate, db: Session = Depends(get_db)):
    if db.query(User).filter(User.username == lawyer_data.username).first():
        raise HTTPException(status_code=400, detail="Username taken")
    user = User(username=lawyer_data.username, password=hash_password(lawyer_data.password), role="lawyer")
    db.add(user)
    db.flush()
    lawyer = Lawyer(
        full_name=lawyer_data.full_name,
        bar_number=lawyer_data.bar_number,
        specialization=lawyer_data.specialization,
        user_id=user.id
    )
    db.add(lawyer)
    db.commit()
    return {"msg": "Lawyer registered successfully"}

@app.post("/register/lawfirm")
def register_lawfirm(data: LawFirmCreate, db: Session = Depends(get_db)):
    if db.query(User).filter(User.username == data.username).first():
        raise HTTPException(status_code=400, detail="Username taken")
    user = User(username=data.username, password=hash_password(data.password), role="lawfirm")
    db.add(user)
    db.flush()
    lawfirm = LawFirm(
        firm_name=data.firm_name,
        registration_no=data.registration_no,
        address=data.address,
        user_id=user.id
    )
    db.add(lawfirm)
    db.commit()
    return {"msg": "Law Firm registered successfully"}
