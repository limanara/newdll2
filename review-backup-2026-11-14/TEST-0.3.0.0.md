# Teste CPM 0.3.0.0

Execute `Start-Visual-Test.ps1` e observe apenas salto, queda e aterrissagem.

No log, copie todas as linhas iniciadas por:

```text
Ar remoto
```

Interpretação:

- `Altura` aumentando: o impulso físico movimentou a entidade.
- `Fase 2`: queda detectada pela posição real.
- `Acao aterrissagem | Estado 5`: retorno ao chão confirmado.
- `Estado 6`: timeout; o collider não concluiu a aterrissagem.
