# Arquitetura do avatar remoto CPM

## Decisão confirmada pelo teste 0.4.0.0

O DynamicEntitySystem criou `NPCPuppet` mesmo quando o registro herdou de `Character.TPP_Player`. O CPM não dependerá mais de conversão para `PlayerPuppet`.

## Pipeline

1. `RemoteAvatarController` calcula XY, yaw e arco vertical em passos por frame.
2. O binding RED4ext aplicará o frame ao componente de movimento da entidade.
3. A fase física selecionará Rising, Falling e Landing.
4. `cpm_remote_player.ent` fornecerá visual, rig, collider e componentes.
5. TweakXL mapeará `Character.CPM_Remote_Player` ao recurso empacotado.

## Regra de publicação

Nenhum ZIP instalável será publicado se o archive da entidade não existir e os testes do controlador não passarem.
