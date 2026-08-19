# Teste CPM 0.1.0.6

## Fases esperadas

1. PARADO
2. CAMINHADA
3. CORRIDA
4. AGACHADO
5. PARADO ANTES DO SALTO
6. SALTO — posição Z sobe progressivamente até 1,45 m
7. QUEDA — posição Z retorna progressivamente ao solo
8. ATERRISSAGEM
9. RETORNO CORRENDO — deslocamento contínuo de X=29 até X=4
10. PARADO APÓS RETORNO
11. EQUIPANDO ARMA
12. MIRA E TIROS
13. RECARGA
14. GUARDANDO ARMA
15. ATAQUE CORPO A CORPO
16. FINAL PARADO

## O que observar

- O NPC deve sair fisicamente do chão durante SALTO.
- Não deve teleportar de X=29 para X=4.
- A arma deve desaparecer da mão antes do melee.
- O PowerShell deve mostrar ATAQUE CORPO A CORPO e FINAL PARADO antes de finalizar.
- O log deve conter detalhe 18, 14, 23, retorno com velocidade 5.50 e os eventos melee.
