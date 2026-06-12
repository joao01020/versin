# tests/test_chat.py
def test_chat_endpoint_success(client):
    payload = {
        "user_id": "test_user_123",
        "message": "Olá, vamos rimar?",
        "private_api_key": None
    }
    
    response = client.post("/chat", json=payload)
    
    assert response.status_code == 200
    assert response.json()["role"] == "assistant"