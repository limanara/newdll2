# Teste CPM 0.2.0.2

Execute:

```powershell
powershell -ExecutionPolicy Bypass -File ".\Start-Visual-Test.ps1"
```

Confirme visualmente:

1. Caminhada, corrida e retorno continuam movimentando as pernas.
2. O NPC não congela ao entrar em salto, queda e aterrissagem.
3. A arma desaparece da mão antes do melee.
4. O NPC executa o ataque corpo a corpo.

No log, procure:

- `Acao guardar arma | Estado 5`: slot realmente vazio.
- `Acao guardar arma | Estado 6`: remoção falhou.
- `Acao melee | Estado 2`: comando executando.
- `Acao melee | Estado 5`: comando concluído.
