# Deployment secrets live on the server (/home/docker/.env) so any machine can deploy.
# This fetches them into the gitignored .env that docker compose reads.
env:
	ssh home 'cat /home/docker/.env' > .env.tmp && mv .env.tmp .env

deploy: env
	DOCKER_CONTEXT=home docker compose down
	DOCKER_CONTEXT=home docker compose up -d --remove-orphans

ansible:
		ansible-playbook -i inventory --ask-become-pass playbook.yaml
