#!/bin/bash

OLD_PATH="caminho/antigo"
NEW_PATH="caminho/novo"

echo "🔄 Substituindo path:"
echo "De:  $OLD_PATH"
echo "Para: $NEW_PATH"
echo

# Criar backup antes (opcional, mas recomendado)
echo "📁 Criando backup dos arquivos .gitlab-ci.yml..."
find ./tmp-migracao -type f -name ".gitlab-ci.yml" -exec cp {} {}.bak \;

<<<<<<< HEAD
# Rodar substituição com sed
echo "✏️ Substituindo conteúdo nos arquivos..."
find ./tmp-migracao -type f -name ".gitlab-ci.yml" -exec sed -i "s|- project: '${OLD_PATH}/\([^']*\)'|- project: '${NEW_PATH}/\1'|g" {} \;
=======
while IFS= read -r -d '' file; do
  # Verifica se tem o caminho antigo e não tem "engbr" na mesma linha
  if grep -q "'${OLD_PATH}/" "$file" && ! grep -q "caminho/novo/que/nao/pode/ser/alterado" "$file"; then
    FILES_TO_UPDATE+=("$file")
    echo -e "\n📄 Arquivo: $file"
    grep "^- project: '.*${OLD_PATH}/.*'" "$file"
  fi
done < <(find ./tmp-migracao -type f -name ".gitlab-ci.yml" -print0)
>>>>>>> 4d7c79b (Update replace_gitlab-ci.sh)

echo "✅ Substituição concluída!"
