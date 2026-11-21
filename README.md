# Veiga Digital Play — recuperação a partir do APK 1.13.0

Este diretório é uma **ferramenta local de diagnóstico** para o aplicativo Veiga Digital Play, versão 1.13.0. Não é o projeto do outro app "Veiga Digital Player" nem contém um APK alterado.

## Como usar

1. Clique em **Code → Download ZIP** neste repositório.
2. Extraia o ZIP no Windows.
3. Arraste seu arquivo `Veiga_Digital_Play_1.13.0.apk` para `executar_analise.bat`.
4. O programa cria a pasta `Documentos\VeigaDigitalPlay\Inspecao-...` com `RESUMO.txt`, inventário do APK e cópia apenas dos assets em formato de texto.
5. Se os comandos oficiais **Apktool**, **JADX**, **aapt** ou **apksigner** estiverem instalados, coleta também o Manifest, dados da assinatura, recursos e código decompilado.

O script não instala o APK nem executa seu conteúdo, não altera o arquivo original e não envia o APK para o GitHub.

## O que será estudado
- Identificador Android, `versionCode` e assinatura, se houver `aapt`/`apksigner`.
- Player e tratamento das teclas `KEYCODE_DPAD_CENTER`, `KEYCODE_ENTER`, `KEYCODE_BACK`.
- Menu sobreposto à reprodução, categorias e seleção pelo controle remoto.
- Interface atual, ícones, splash e assets acessíveis.
- Compatibilidade de atualizações: para instalar por cima da versão antiga, é necessário **o mesmo identificador de pacote e uma assinatura compatível**. A chave privada **não** pode ser obtida do APK.

## Limitações

A recuperação por JADX/Apktool pode ser incompleta, sobretudo se o app estiver ofuscado ou protegido. Uma versão reconstruída que use **uma nova chave** não substituirá a instalação antiga automaticamente. Isso não é um defeito que possa ser corrigido alterando só o `versionCode`.

## Privacidade

Não faça commit de APKs comerciais, playlist M3U, URLs com credenciais, hashes ou relatórios sem revisão. Este repositório é público. A análise deve continuar local no Windows.
