# Teste CPM 0.2.0.0

Observe visualmente:

1. caminhada;
2. corrida;
3. agachamento;
4. salto com saída física do chão;
5. queda;
6. aterrissagem;
7. retorno correndo sem deslizar;
8. guardar arma;
9. melee.

O log deve conter linhas no formato:

```text
Visual remoto 2 | Acao movimento | Estado ...
Visual remoto 2 | Acao salto | Estado 1
Visual remoto 2 | Acao queda | Estado 1
Visual remoto 2 | Acao aterrissagem | Estado 1
Visual remoto 2 | Acao melee | Estado ...
```

Os números de estado são retornados diretamente por `AIControllerComponent.GetCommandState`. Envie as últimas 120 linhas do log e informe separadamente se o NPC movimentou o corpo ou apenas mudou de posição.
