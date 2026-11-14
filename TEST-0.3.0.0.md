# Teste de salto apos revisao

Execute Start-Visual-Test.ps1 -AirOnly para dois saltos parados proximos.
Leia REVISAO-SALTO.md antes de instalar o REDscript.

- Rede Z: altura enviada. Real Z: posicao medida da entidade.
- Pico: pico da rede, nao pico fisico confirmado.
- Fases 1/2: amostra anterior a solicitacao de teleporte atual.
- Fases 11/12: logo apos solicitar; processamento pode ser diferido.
- Acao salto Estado 2: solicitacao enviada; nao confirma animacao.
- Acao aterrissagem Estado -2: salto acabou sem elevacao real superior a 0.10m.
- Estado 6: timeout, nao aterrissagem confirmada.
- Estado 5: ciclo encerrado; em salto com elevacao de rede houve tambem
  elevacao real medida. Nao comprova colisao de aterrissagem ou pose correta.

Aceite visual pendente: Real Z acompanha arco, pose de salto e queda aparecem,
aterrissagem retorna ao idle e segundo salto funciona. Depois testar correndo,
queda de plataforma, duplo salto e perda de rede.
