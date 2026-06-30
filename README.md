# orquestrador-drive
Orquestrador automático do Google Drive - JG

## Validacao de acesso da sessao (Claude Code)

Este repositorio inclui um teste rapido para confirmar se a sessao atual
consegue acessar repositorios GitHub sem bloqueio de escopo.

### Como rodar

```bash
bash scripts/validate_session_repo_access.sh \
	https://github.com/jessicagessoli/orquestrador-drive.git
```

### Resultado esperado

- Sucesso: o script retorna codigo `0` e mostra `ACCESS_OK`.
- Falha de escopo/permissao: retorna codigo `2` e mostra `ACCESS_DENIED`.

Isso permite diferenciar, de forma objetiva, falha de sessao/proxy
de problema no repositorio.
