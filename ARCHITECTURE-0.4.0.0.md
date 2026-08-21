# Arquitetura aérea CPM 0.4.0.0

## Evidência do teste 0.3.0.0

A rede variou o Z de 0.148 até 1.130, enquanto o Z real permaneceu 7.638. O NPC atual não possui corpo/controlador compatível com impulso vertical.

## Nova arquitetura

1. `Character.CPM_Remote_Player` deriva de `Character.TPP_Player`.
2. Um controlador C++ calcula subida, ápice, queda e recuperação de aterrissagem.
3. O `move::Component` aplicará o delta vertical sem teleporte por quadro.
4. O animation graph receberá fase, velocidade vertical, tempo no ar e impacto.
5. TweakXL registra o puppet; ArchiveXL entregará os recursos próprios do CPM.
6. Locomoção, armas e melee aprovados serão migrados somente depois do teste isolado do novo puppet.

## Política de implementação

Nenhum código, workspot ou archive do CyberpunkMP será copiado ou derivado. A licença daquele projeto proíbe uso em produto concorrente. A implementação CPM será independente e baseada nas APIs/reflection públicas do jogo e do RED4ext.

## Estado atual

- Máquina de estados vertical independente: implementada.
- Testes determinísticos de subida/queda/aterrissagem: implementados.
- Registro TweakXL inicial: implementado.
- Montagem no `move::Component`: pendente.
- Asset ArchiveXL/animation graph: pendente.
- Integração com rede: pendente.
