#!/usr/bin/env sh
# Upload the MaameDrone-ArduDeck landing page to https://nyansalabs.com/ardudeck/ (nginx alias to /var/www/ardudeck).
# Needs the id_nyansalabs key in your SSH agent.
set -e
cd "$(dirname "$0")"
rsync -az --delete --exclude deploy.sh -e "ssh -i $HOME/.ssh/id_nyansalabs" ./ root@134.209.0.163:/var/www/ardudeck/
ssh -i "$HOME/.ssh/id_nyansalabs" root@134.209.0.163 'chown -R www-data:www-data /var/www/ardudeck'
echo "Deployed: https://nyansalabs.com/ardudeck/"
