# CPM 0.1.0.5 - Native Air + Equip + Melee Controller

## O que foi corrigido

- Salto usa controlador vertical visual proprio; o teste envia Z=0 durante salto e queda de proposito.
- Altura visual do salto limitada a 1,45 m.
- Queda reduz o offset vertical de forma controlada.
- Aterrissagem zera o offset e restaura a altura de solo recebida pela rede.
- Nova fase GUARDANDO ARMA antes do melee.
- Durante melee o simulador envia flags=0, upper=0 e weaponState=0.
- Mira, locomocao, tiro pendente e recarga sao cancelados antes do melee.
- Melee espera 8 ticks (~400 ms) antes de disparar o ataque.
- QuickMelee e MeleeAttack sao enviados separadamente para reforcar a animacao.

## Teste esperado

1. PARADO
2. CAMINHADA
3. CORRIDA
4. AGACHADO
5. PARADO ANTES DO SALTO
6. SALTO - o NPC deve subir mesmo com Z de rede igual a 0
7. QUEDA
8. ATERRISSAGEM
9. RETORNO PARA COMBATE
10. EQUIPANDO ARMA
11. MIRA E TIROS
12. RECARGA
13. GUARDANDO ARMA
14. ATAQUE CORPO A CORPO
15. FINAL PARADO

Se o NPC ainda nao executar visualmente o melee, enviar as ultimas 60 linhas de `%LOCALAPPDATA%\\CPM\\logs\\CPMClient.log` e informar se a arma continuou visivel na mao do NPC durante a fase GUARDANDO ARMA.
