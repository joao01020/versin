# Versin — Backend Deployment

> **Status:** Parcialmente verificado\
> **Última revisão:** 2026-08-24\
> **Escopo:** deploy da `versin_api`

---

## 1. Provider atual

O backend está implantado em:

```text
Render
```

Endpoint observado:

```text
https://versin.onrender.com
```

---

## 2. Health check

Existe:

```text
GET /health
```

Usado para verificar disponibilidade do serviço.

---

## 3. Inicialização

O repositório contém:

```text
versin_api/start.sh
```

Esse arquivo participa da inicialização do serviço.

---

## 4. Configuração de ambiente

Arquivos locais identificados:

```text
versin_api/.env
versin_api/.env.exemple
```

Valores reais não devem ser documentados nem versionados.

---

## 5. Secrets

Segredos devem ser configurados no ambiente do provider. Exemplos:

```text
Redis
Supabase
provider de IA
segredo interno da API
storage
```

---

## 6. CORS

Foi validado que:

```text
http://localhost:8080
```

recebeu `access-control-allow-origin` quando permitido.

---

## 7. Redis

Redis participa de quota e rate limiting. O rate limiter opera atualmente em
`fail-open` se Redis estiver indisponível.

---

## 8. Keep-alive

Durante desenvolvimento foi configurado monitoramento/cron externo para realizar
chamadas periódicas ao servidor Render e reduzir períodos de inatividade.

Isso é uma solução operacional, não lógica de negócio.

---

## 9. Logs e observabilidade

O backend utiliza logs simples em vários services. Ainda não foi confirmada
infraestrutura dedicada de:

```text
APM
tracing
error tracking
metrics
alerting
```

Nenhum secret ou JWT deve ser escrito em logs.

---

## 10. Escalabilidade

Ainda precisam ser auditados:

- múltiplas instâncias;
- workers;
- concorrência de quota;
- timeouts do provider;
- retries;
- cold start;
- conexão Supabase;
- comportamento Redis.

---

## 11. Fluxo conceitual de deploy

```text
Git
  │
  ▼
branch de produção
  │
  ▼
Render build
  │
  ▼
start.sh
  │
  ▼
FastAPI
  │
  ▼
/health
```

A configuração exata de auto-deploy ainda precisa ser confirmada.

---

## 12. Checklist de produção

- [ ] secrets fora do repositório;
- [ ] `.env` ignorado;
- [ ] CORS revisado;
- [ ] health check configurado;
- [ ] logs sanitizados;
- [ ] JWT validado;
- [ ] rate limit testado;
- [ ] quota testada;
- [ ] Redis monitorado;
- [ ] timeouts configurados;
- [ ] testes automatizados;
- [ ] alertas definidos;
- [ ] rollback documentado.

---

## 13. Pendências

Ainda precisamos confirmar:

- build command;
- start command efetivo;
- branch de produção;
- auto-deploy;
- número de workers;
- região;
- política de rollback;
- monitoramento externo atual.
