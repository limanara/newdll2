# Correcao experimental do pulo remoto

O NPCPuppet pode ignorar PhysicalImpulseEvent. A rotina aerea agora usa Z de rede e suaviza X/Y.

Substitua o REDscript em `resources/r6/scripts/CPM/CPMClient.reds` na instalacao cliente, e reinicie o jogo para recompilar os scripts.

Testes pendentes: pulo parado, correndo, duplo, queda de altura e aterrissagem. Nao foi compilado ou testado no Cyberpunk 2077. A tecnica usa teleporte por frame durante o ar e pode apresentar jitter ou problemas de animacao dependendo do NPCPuppet.
