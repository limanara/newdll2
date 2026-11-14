# Revisao do salto - patch de diagnostico e conflito de locomocao

## Causa identificada no codigo
UpdateLocomotion solicitava locomocao terrestre durante estados aereos. Agora interrompe AIMoveToCommand e nao inicia caminhada/corrida enquanto airborne. UpdateNetworkStates passa a executar antes de UpdateLocomotion.

## Diagnostico
O log anterior lia Real Z ANTES do Teleport, portanto nao provava falha. Novos logs `Ar remoto | Fase 11/12/13` medem a posicao logo apos o Teleport; fases 1/2/3 continuam medindo antes do teleporte do frame atual. Compare os dois.

- Fase 11/12 varia e fase 1/2 permanece no solo: o motor restaura a posicao entre frames.
- Ambas permanecem no solo: o Teleport nao esta alterando o NPC.
- Ambas variam mas nao ha animacao: corrigir separadamente o grafo de animacao do NPCPuppet.

## Instalacao
Substitua os arquivos do repositorio pelo conteudo deste pacote e execute o GitHub Actions atual. Instale o CPMClient.dll e CPMClient.reds novos; reinicie o jogo. Nao e necessario alterar o build.yml.

## Limitacoes
Patch de codigo revisado estaticamente, nao testado no Cyberpunk nem compilado com REDscript neste ambiente. O movimento aereo ainda depende da aceitacao do Teleport pelo motor; nao ha garantia de animacao de salto.
