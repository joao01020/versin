import pytest
from fastapi.testclient import TestClient
from main import app
from unittest.mock import AsyncMock

@pytest.fixture(scope="session")
def client():
    """Cliente de teste com escopo de sessão para performance."""
    return TestClient(app)

@pytest.fixture(autouse=True)
def mock_ai_service(monkeypatch):
    """
    Garante que qualquer uso do AIService nos testes 
    seja interceptado e retorne um mock, sem depender da API real.
    """
    mock_ai = AsyncMock()
    # Retorno padrão para qualquer análise de IA
    mock_ai.get_analysis.return_value = {
        "content": "Análise gerada pelo teste",
        "is_acceptable": True,
        "impact_level": 1
    }
    # Substitui a classe AIService dentro do main.py
    monkeypatch.setattr("main.AIService", lambda key: mock_ai)
    return mock_ai

@pytest.fixture
def auth_headers():
    """Simulação de headers para rotas protegidas."""
    return {"Authorization": "Bearer fake-token-for-tests"}