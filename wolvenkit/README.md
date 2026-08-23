# Fonte da entidade CPM

O arquivo binário `cpm_remote_player.ent` não é armazenado no GitHub enquanto depender de um recurso original do jogo.

## Entrada necessária

Exporte, pela sua instalação do Cyberpunk 2077 e pelo WolvenKit, um template humanoide compatível. Depois execute:

```powershell
powershell -ExecutionPolicy Bypass -File ".\tools\Prepare-CPM-Entity.ps1" -SourceEnt "C:\caminho\template.ent"
```

Destino esperado:

`wolvenkit/source/archive/cpm/entities/cpm_remote_player.ent`

O archive final deverá fornecer exatamente:

`cpm\entities\cpm_remote_player.ent`

Não renomeie uma cópia qualquer: o arquivo precisa continuar sendo um recurso CR2W válido.
