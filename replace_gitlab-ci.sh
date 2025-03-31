#!/bin/bash

# Caminhos antigos e novos (substitua conforme necessário)
OLD_PATH="caminho/antigo"
NEW_PATH="caminho/novo"

echo "🔄 Substituindo path:"
echo "De:  $OLD_PATH"
echo "Para: $NEW_PATH"
echo

# Criar backup antes (opcional, mas recomendado)
echo "📁 Criando backup dos arquivos .gitlab-ci.yml..."
find ./tmp-migracao -type f -name ".gitlab-ci.yml" -exec cp {} {}.bak \;

# Rodar substituição com sed
echo "✏️ Substituindo conteúdo nos arquivos..."
find ./tmp-migracao -type f -name ".gitlab-ci.yml" -exec sed -i "s|- project: '${OLD_PATH}/\([^']*\)'|- project: '${NEW_PATH}/\1'|g" {} \;

echo "✅ Substituição concluída!"
