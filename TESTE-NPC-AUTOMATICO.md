# NPC proximo automaticamente

O servidor atende a consulta UDP tipo 7 **somente em 127.0.0.1**, retornando tipo 8 com quatro float32 (x,y,z,yaw) da sessao ativa com estado mais recente. O simulador usa a posicao e um deslocamento inicial de 3 unidades na direcao de yaw.

1. Atualize os arquivos deste pacote no repositorio.
2. Rode GitHub Actions e substitua apenas CPMServer.exe no servidor; a DLL instalada nao precisa mudar.
3. Abra o jogo, entre no mundo e aguarde alguns segundos; execute Start-Visual-Test.ps1 no **mesmo PC do servidor**.
4. Evite ruas com desnivel/obstaculos: o simulador percorre ~30 unidades e usa o Z inicial como solo.

**Limitacoes:** o teste usa o jogador com estado mais recente, nao necessariamente o mais proximo; sem estado do cliente o teste falha com mensagem. O yaw deve seguir a convencao do cliente; caso o NPC apareca em direcao errada, ajuste a transformacao. Nao ha validacao de compilacao Windows neste ambiente.
