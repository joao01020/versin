from pydantic import BaseModel
from typing import List, Optional, Dict

class ChatRequest(BaseModel):
    user_id: str = "default_user"
    message: str
    current_list: List[str] = []
    private_api_key: Optional[str] = None
    history_context: Optional[Dict] = {}