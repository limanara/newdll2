# Runtime de ar por jogador remoto — 0.4.0.0 DEV

Este estágio conecta o controlador vertical determinístico ao runtime nativo da DLL.

## Contrato redscript
- `CPMAirBegin`, `CPMAirStep`, `CPMAirPhase`
- `CPMAirVelocityZ`, `CPMAirPeakZ`
- `CPMAirReset`, `CPMAirRemove`

Cada jogador possui estado isolado e todos os controladores são limpos quando o cliente é descarregado.

## Limite atual
O registro TPP ainda precisa ser instanciado e seu componente de movimento precisa consumir o Z calculado. Este branch continua sem pacote instalável até essa ligação e sua validação.
